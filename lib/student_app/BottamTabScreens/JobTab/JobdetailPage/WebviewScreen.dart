import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final Map<String, String>? extraHeaders;

  const AppWebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.extraHeaders,
  });

  @override
  State<AppWebViewScreen> createState() => _AppWebViewScreenState();
}

class _AppWebViewScreenState extends State<AppWebViewScreen> {
  InAppWebViewController? _controller;

  bool _isLoading = true;
  bool _isExiting = false;
  bool _hideWebView = false;

  void _exitPage() async {
    setState(() {
      _isExiting = true;
      _hideWebView = true;
    });

    await Future.delayed(const Duration(milliseconds: 180));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _exitPage();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(55.h),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppBar(
              title: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20.sp,
                  color: const Color(0xFF003840),
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.w),
                  ),
                  child: Center(
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18.sp,
                        color: const Color(0xFF003840),
                      ),
                      onPressed: _exitPage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (!_hideWebView)
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(widget.url),
                    headers: widget.extraHeaders ?? {},
                  ),
                  initialOptions: InAppWebViewGroupOptions(
                    crossPlatform: InAppWebViewOptions(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                    android: AndroidInAppWebViewOptions(
                      useHybridComposition: true,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStart: (controller, url) {
                    if (!_isExiting) setState(() => _isLoading = true);
                  },
                  onLoadStop: (controller, url) async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!_isExiting && mounted) setState(() => _isLoading = false);
                  },
                  onLoadError: (controller, url, code, message) {
                    if (!_isExiting && mounted) setState(() => _isLoading = false);
                  },
                ),

              AnimatedOpacity(
                opacity: _isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
