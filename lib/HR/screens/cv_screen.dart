import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:skillsconnect/HR/model/applicant_details_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/services.dart' show rootBundle, MethodChannel;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_saver/file_saver.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'EnterOtpScreen.dart';

class CVViewSection extends StatefulWidget {
  final Applicant applicant;

  const CVViewSection({super.key, required this.applicant});

  @override
  State<CVViewSection> createState() => _CVViewSectionState();
}

class _CVViewSectionState extends State<CVViewSection> {
  bool showZoomView = false;
  late PdfViewerController _pdfViewerController;

  // 🔔 Local notifications
  final FlutterLocalNotificationsPlugin _notifs =
      FlutterLocalNotificationsPlugin();

  // ✅ Native Android notification channel
  static MethodChannel _notify = MethodChannel('skillsconnect/notify');
  void dbg(String msg) => debugPrint("🔔 [CV-NOTIF] $msg");

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _initLocalNotifs(); // ⬅️ init here
  }

  Future<void> _initLocalNotifs() async {
    dbg("initLocalNotifs: starting…");

    try {
      // (A) iOS/Android init settings
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // (B) initialization
      final details = await _notifs.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
        onDidReceiveNotificationResponse: (resp) async {
          final payload = resp.payload ?? '';
          if (payload.isEmpty) {
            dbg("tap: empty payload");
            return;
          }
          // ✅ External viewer (not your app’s PDF widget)
          final result = await OpenFilex.open(payload);
          dbg("tap: OpenFilex.open -> ${result.type} | ${result.message}");
        },
      );

      dbg("initialize returned: $details");

      // (C) Android 13+ runtime 'POST_NOTIFICATIONS' via plugin OR permission_handler
      if (Platform.isAndroid) {
        final sdk = await _getAndroidVersion();
        if (sdk >= 33) {
          dbg("SDK $sdk >= 33 -> requesting notification permission");
          // Using both just in case OEM weirdness
          final grantedByPlugin = await _notifs
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission();
          dbg("plugin.requestNotificationsPermission() -> $grantedByPlugin");

          final notifPH = await Permission.notification.request();
          dbg("permission_handler notification -> ${notifPH.isGranted}");
        }
      }

      // (D) Create/ensure channel (some OEMs need explicit create)
      const channel = AndroidNotificationChannel(
        'cv_downloads',
        'CV Downloads',
        description: 'Notification when CV is downloaded',
        importance: Importance.high,
      );
      // Ask runtime notification permission (Android 13+)
      await _notifs
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      dbg("channel ensured: ${channel.id}");

      // 🔔 Make sure the channel exists (Android 8+)
      final android = _notifs
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'cv_downloads',
          'CV Downloads',
          description: 'Notification when CV is downloaded',
          importance: Importance.high,
        ),
      );

      // (E) App launch details (agar app notification se open hua)
      final launchDetails = await _notifs.getNotificationAppLaunchDetails();
      dbg(
        "launchDetails: launchedFromNotification=${launchDetails?.didNotificationLaunchApp} payload='${launchDetails?.notificationResponse?.payload}'",
      );
    } catch (e, st) {
      dbg("init error: $e");
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _downloadPDF() async {
    try {
      final url = widget.applicant.resumeUrl;

      // 1) Permissions (Android)
      bool isGranted = true;
      if (Platform.isAndroid) {
        final sdk = await _getAndroidVersion();
        if (sdk >= 33) {
          isGranted = (await Permission.photos.request()).isGranted;
        } else {
          isGranted = (await Permission.storage.request()).isGranted;
        }
        if (!isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              showErrorSnackBar(context, "Please Storage Permission Allow"),
            );
          }
          return;
        }
      }

      // 2) Fetch
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        return;
      }

      // 3) Name
      final base = (widget.applicant.name ?? 'Resume').replaceAll(
        RegExp(r'[^a-zA-Z0-9_\-]'),
        '_',
      );
      final fileName = '${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isAndroid) {
        final sdk = await _getAndroidVersion();

        // A) Always keep a cache copy (for FileProvider)
        final cacheDir = await getTemporaryDirectory();
        final cachePath = '${cacheDir.path}/$fileName';
        await File(cachePath).writeAsBytes(resp.bodyBytes);

        // B) Optional user save (SAF) for Android 10+
        if (sdk >= 29) {
          final tmpDir = await getTemporaryDirectory();
          final tmpPath = '${tmpDir.path}/$fileName';
          await File(tmpPath).writeAsBytes(resp.bodyBytes);

          final savedPath = await FlutterFileDialog.saveFile(
            params: SaveFileDialogParams(
              sourceFilePath: tmpPath,
              fileName: fileName,
              mimeTypesFilter: const ['application/pdf'],
              localOnly: true,
            ),
          );

          // 🛑 User ne dialog cancel kar diya -> Koi success snackbar / notification nahi
          if (savedPath == null) {
            dbg("User cancelled save dialog");
            if (mounted) {
              // ScaffoldMessenger.of(
              //   context,
              // ).showSnackBar(showErrorSnackBar(context, "Download cancelled"));
              showErrorSnackBar(context, "Download cancelled");

            }
            return;
          }
          // NOTE: no return here ✅
        } else {
          // Legacy public Downloads
          final downloads = Directory('/storage/emulated/0/Download');
          final out = File('${downloads.path}/$fileName');
          await out.writeAsBytes(resp.bodyBytes);
        }

        // C) Show NATIVE notification (tap → external viewer)
        try {
          await _notify.invokeMethod('showFileOpenNotification', {
            'name': fileName,
            'path': cachePath, // use cache path for FileProvider
            'mime': 'application/pdf',
          });
        } catch (e) {
          dbg('native notify error: $e');
          await OpenFilex.open(cachePath); // last resort
        }

        if (mounted) {
          // ScaffoldMessenger.of(
          //   context,
          // ).showSnackBar(showSuccesSnackBar(context, "CV Downloaded"));
          showSuccessSnackBar(context, "CV Downloaded");
        }
        return; // return only once here ✅
      }

      // ---- iOS ----
      final docs = await getApplicationDocumentsDirectory();
      final out = File('${docs.path}/$fileName');
      await out.writeAsBytes(resp.bodyBytes);

      if (mounted) {
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(showSuccesSnackBar(context, "CV Downloaded"));
        showSuccessSnackBar(context, "CV Downloaded");

      }

      // Small iOS notif (ok to keep)
      await _notifs.show(
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 20),
        'CV Downloaded',
        fileName,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'cv_downloads',
            'CV Downloads',
            channelDescription: 'Notification when CV is downloaded',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: out.path,
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<int> _getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CV PDF Viewer (Zoom toggle)
          Container(
            height: 470,
            width: 310,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x1A000000)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SfPdfViewer.network(
                widget.applicant.resumeUrl,
                controller: _pdfViewerController, //  Add controller
                key: ValueKey(widget.applicant.resumeUrl),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const SizedBox(width: 25),

              /// Zoom Button
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xff003840),
                child: IconButton(
                  icon: Image.asset(
                    'assets/zoom.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  onPressed: () {
                    setState(() {
                      showZoomView = !showZoomView;
                      double currentZoom = _pdfViewerController.zoomLevel;
                      _pdfViewerController.zoomLevel = currentZoom == 1.0
                          ? 2.0
                          : 1.0; // Toggle zoom
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

              /// Download Button
              ElevatedButton.icon(
                onPressed: _downloadPDF,
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  "Download CV",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff003840),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 70,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ), // ✅ Rectangular with little radius
        ),
        duration: Duration(seconds: 2),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// OLD CODE

//
// import 'package:flutter/material.dart';
// import 'package:skillsconnect/HR/model/applicant_details_model.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'package:file_saver/file_saver.dart';
// import 'package:mime/mime.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter_file_dialog/flutter_file_dialog.dart';
//
//
//
//
// class CVViewSection extends StatefulWidget {
//   final Applicant applicant;
//
//   const CVViewSection({super.key, required this.applicant});
//
//   @override
//   State<CVViewSection> createState() => _CVViewSectionState();
// }
//
// class _CVViewSectionState extends State<CVViewSection> {
//   bool showZoomView = false;
//   late PdfViewerController _pdfViewerController;
//
//   @override
//   void initState() {
//     super.initState();
//     _pdfViewerController = PdfViewerController();
//   }
//
//
//   Future<void> _downloadPDF() async {
//     try {
//       final url = widget.applicant.resumeUrl;
//
//       // 🧩 Step 1: Runtime permission check (Android version specific)
//       bool isGranted = false;
//       if (Platform.isAndroid) {
//         final sdk = await _getAndroidVersion();
//
//         if (sdk >= 33) {
//           // Android 13+ => new "Photos & Videos" permission
//           final photos = await Permission.photos.request();
//           isGranted = photos.isGranted;
//         } else {
//           // Android 12 aur neeche => normal storage permission
//           final storage = await Permission.storage.request();
//           isGranted = storage.isGranted;
//         }
//
//         if (!isGranted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Please Storage Permission Allow")),
//           );
//           return;
//         }
//       }
//
//       // ---- 2) PDF fetch ----
//       final resp = await http.get(Uri.parse(url));
//       if (resp.statusCode != 200) {
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   SnackBar(content: Text("Download fail हुआ: HTTP ${resp.statusCode}")),
//         // );
//         return;
//       }
//
//       // ---- 3) File name ----
//       final base = (widget.applicant.name ?? 'Resume')
//           .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
//       final fileName = '${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';
//
//       // ---- 4) Scoped storage (Android 10+)
//       if (Platform.isAndroid) {
//         final sdk = await _getAndroidVersion();
//
//         if (sdk >= 29) {
//           final tmpDir = await getTemporaryDirectory();
//           final tmpPath = '${tmpDir.path}/$fileName';
//           final tmpFile = File(tmpPath);
//           await tmpFile.writeAsBytes(resp.bodyBytes);
//
//           final savedUri = await FlutterFileDialog.saveFile(
//             params: SaveFileDialogParams(
//               sourceFilePath: tmpPath,
//               fileName: fileName,
//               mimeTypesFilter: const ['application/pdf'],
//             ),
//           );
//
//           if (savedUri == null) {
//             // ScaffoldMessenger.of(context).showSnackBar(
//             //   const SnackBar(content: Text("❌ Save cancel हुआ")),
//             // );
//             return;
//           }
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             showSuccesSnackBar(context, "CV Downloaded"),
//           );
//           return;
//         } else {
//           final downloads = Directory('/storage/emulated/0/Download');
//           final out = File('${downloads.path}/$fileName');
//           await out.writeAsBytes(resp.bodyBytes);
//           // ScaffoldMessenger.of(context).showSnackBar(
//           //   SnackBar(content: Text("File Saved: ${out.path}")),
//           // );
//           return;
//         }
//       }
//
//       // ---- iOS ----
//       final docs = await getApplicationDocumentsDirectory();
//       final out = File('${docs.path}/$fileName');
//       await out.writeAsBytes(resp.bodyBytes);
//       ScaffoldMessenger.of(context).showSnackBar(
//         // SnackBar(content: Text("✅ Saved: ${out.path}")),
//         showSuccesSnackBar(context, "Saved: ${out.path}"),
//
//       );
//     } catch (e) {
//       print("Error: $e");
//       // ScaffoldMessenger.of(context).showSnackBar(
//       //   // showErrorSnackBar(context, "Error: $e"),
//       //
//       // );
//     }
//   }
//
//
//   // Future<void> _downloadPDF() async {
//   //   try {
//   //     final url = widget.applicant.resumeUrl;
//   //
//   //
//   //     // Pehle permission check karo (sab version ke liye safe)
//   //     final status = await Permission.storage.request();
//   //     if (!status.isGranted) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text("Please Storage Permission Allow")),
//   //       );
//   //       return;
//   //     }
//   //
//   //     // ---- 1) PDF fetch ----
//   //     final resp = await http.get(Uri.parse(url));
//   //     if (resp.statusCode != 200) {
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         SnackBar(content: Text("Failed to download: HTTP ${resp.statusCode}")),
//   //       );
//   //       return;
//   //     }
//   //
//   //     // Safe filename
//   //     final base = (widget.applicant.name ?? 'Resume')
//   //         .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
//   //     final fileName = '${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';
//   //
//   //     // ---- 2) Android version check ----
//   //     if (Platform.isAndroid) {
//   //       final sdk = await _getAndroidVersion();
//   //
//   //       if (sdk >= 29) {
//   //         // ANDROID 10+ (Scoped Storage): SAF dialog -> user picks location (usually Downloads)
//   //         // Step A: write to temp first
//   //         final tmpDir = await getTemporaryDirectory();
//   //         final tmpPath = '${tmpDir.path}/$fileName';
//   //         final tmpFile = File(tmpPath);
//   //         await tmpFile.writeAsBytes(resp.bodyBytes);
//   //
//   //         // Step B: show native "Save to" dialog (suggested name = fileName)
//   //         final savedUri = await FlutterFileDialog.saveFile(
//   //           params: SaveFileDialogParams(
//   //             sourceFilePath: tmpPath,
//   //             fileName: fileName,
//   //             // filter helpful but optional:
//   //             mimeTypesFilter: const ['application/pdf'],
//   //             localOnly: true,
//   //           ),
//   //         );
//   //
//   //         if (savedUri == null) {
//   //           ScaffoldMessenger.of(context).showSnackBar(
//   //             const SnackBar(content: Text("Save cancelled")),
//   //           );
//   //           return;
//   //         }
//   //
//   //         ScaffoldMessenger.of(context).showSnackBar(
//   //           const SnackBar(content: Text("✅ Saved to Downloads.")),
//   //         );
//   //         return;
//   //       } else {
//   //         // ANDROID 9-: direct write to public Downloads (needs storage permission)
//   //         final st = await Permission.storage.request();
//   //         if (!st.isGranted) {
//   //           ScaffoldMessenger.of(context).showSnackBar(
//   //             const SnackBar(content: Text("Storage permission is required")),
//   //           );
//   //           return;
//   //         }
//   //         final downloads = Directory('/storage/emulated/0/Download');
//   //         final out = File('${downloads.path}/$fileName');
//   //         await out.writeAsBytes(resp.bodyBytes);
//   //         ScaffoldMessenger.of(context).showSnackBar(
//   //           SnackBar(content: Text("✅ Saved: ${out.path}")),
//   //         );
//   //         return;
//   //       }
//   //     }
//   //
//   //     // ---- iOS / other platforms ----
//   //     final docs = await getApplicationDocumentsDirectory();
//   //     final out = File('${docs.path}/$fileName');
//   //     await out.writeAsBytes(resp.bodyBytes);
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text("✅ Saved: ${out.path}")),
//   //     );
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text("Error: $e")),
//   //     );
//   //   }
//   // }
//
//
//   Future<int> _getAndroidVersion() async {
//     final deviceInfo = DeviceInfoPlugin();
//     final androidInfo = await deviceInfo.androidInfo;
//     return androidInfo.version.sdkInt;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // CV PDF Viewer (Zoom toggle)
//           Container(
//             height: 470,
//             width: 310,
//             margin: const EdgeInsets.symmetric(horizontal: 24),
//             decoration: BoxDecoration(
//               border: Border.all(color: const Color(0x1A000000)),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: SfPdfViewer.network(
//                 widget.applicant.resumeUrl,
//                 controller: _pdfViewerController, //  Add controller
//                 key: ValueKey(widget.applicant.resumeUrl),
//               ),
//             ),
//
//           ),
//
//           const SizedBox(height: 12),
//
//           Row(
//             children: [
//               const SizedBox(width: 25),
//
//               /// Zoom Button
//               CircleAvatar(
//                 radius: 24,
//                 backgroundColor: const Color(0xff003840),
//                 child: IconButton(
//                   icon: Image.asset(
//                     'assets/zoom.png',
//                     width: 24,
//                     height: 24,
//                     fit: BoxFit.contain,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       showZoomView = !showZoomView;
//                       double currentZoom = _pdfViewerController.zoomLevel;
//                       _pdfViewerController.zoomLevel = currentZoom == 1.0 ? 2.0 : 1.0; // Toggle zoom
//                     });
//                   },
//                 ),
//               ),
//
//               const SizedBox(width: 12),
//
//               /// Download Button
//               ElevatedButton.icon(
//                 onPressed: _downloadPDF,
//                 icon: const Icon(Icons.file_download_outlined, color: Colors.white),
//                 label: const Text(
//                   "Download CV",
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xff003840),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 12),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   showSuccesSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: TextStyle(color: Colors.white, fontSize: 14),
//         ),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10), // ✅ Rectangular with little radius
//         ),
//         duration: Duration(seconds: 2),
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//     );
//   }
//
//   showErrorSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: TextStyle(color: Colors.white, fontSize: 14),
//         ),
//         backgroundColor: Colors.red.shade600,
//         behavior: SnackBarBehavior.floating,
//         margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10), // ✅ Rectangular with little radius
//         ),
//         duration: Duration(seconds: 2),
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//     );
//   }
//
//
// }
