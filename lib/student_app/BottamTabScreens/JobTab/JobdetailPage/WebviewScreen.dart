import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'dart:io';

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

class _AppWebViewScreenState extends State<AppWebViewScreen> with RouteAware {
  InAppWebViewController? _controller;
  PullToRefreshController? _pullToRefreshController;

  bool _isLoading = true;
  bool _isExiting = false;
  bool _hideWebView = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _loadingTimeoutTimer;
  static const Duration _loadingTimeout = Duration(seconds: 30);
    bool _snackBarShown = false;


  @override
  void initState() {
    super.initState();
    print('🔗 WebView initializing with URL: ${widget.url}');
    // Start timeout timer
    _startLoadingTimeout();
    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: const Color(0xFF005E6A)),
      onRefresh: () async {
        if (_controller == null) return;
        if (Platform.isAndroid) {
          await _controller?.reload();
        } else if (Platform.isIOS) {
          final currentUrl = await _controller?.getUrl();
          if (currentUrl != null) {
            await _controller?.loadUrl(urlRequest: URLRequest(url: currentUrl));
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

    void _showSnackBarOnce(BuildContext context, String message,
      {int cooldownSeconds = 3}) {
    if (_snackBarShown) return;
    _snackBarShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.4.sp)),
        backgroundColor: Colors.green,
        duration: Duration(seconds: cooldownSeconds),
      ),
    );
    Future.delayed(Duration(seconds: cooldownSeconds), () {
      _snackBarShown = false;
    });
  }


  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(_loadingTimeout, () {
      if (_isLoading && mounted && !_isExiting) {
        print('⏱️ WebView loading timeout after ${_loadingTimeout.inSeconds}s');
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Page loading took too long. Please check your internet connection.';
        });
      }
    });
  }

  void _exitPage() async {
    setState(() {
      _isExiting = true;
      _hideWebView = true;
    });

    await Future.delayed(const Duration(milliseconds: 180));

    if (mounted) Navigator.pop(context);
  }

  void _retryLoadPage() {
    print('🔄 WebView retrying page load');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _hideWebView = false;
    });
    _startLoadingTimeout();
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _exitPage();
        return false;
      },
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
        ),
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
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.w,
                      ),
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
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // WebView
                  if (!_hideWebView)
                    InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(widget.url),
                        headers: widget.extraHeaders ?? {},
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                      ),
                      pullToRefreshController: _pullToRefreshController,
                      initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                          javaScriptEnabled: true,
                          mediaPlaybackRequiresUserGesture: false,
                          transparentBackground: false,
                              // Keep non-transparent to avoid initial black flash
                          useShouldOverrideUrlLoading: true,
                        ),
                        android: AndroidInAppWebViewOptions(
                          useHybridComposition:
                              false, // Use texture mode so Flutter overlays (loading) render above the webview
                        ),
                      ),
                      onWebViewCreated: (controller) {
                        print('✅ WebView created successfully');
                        _controller = controller;
                        controller.addJavaScriptHandler(
                          handlerName: 'CloseSCWebView',
                          callback: (args) {
                            final status = args.isNotEmpty ? args[0] : null;

                            if (status == 'success' || status == 'error' || status == 'back') {
                              Navigator.of(context).pop(status);
                              if (status == 'back') {
                                // _showSnackBarOnce(context, "Job application submission failed. Please try again.");
                                print('🔔 WebView requested close with error status');
                              } else
                              if(status == 'success') {
                                _showSnackBarOnce(context, "Job application submitted successfully!");
                                print('🔔 WebView requested close with success status');
                              } else {
                                print('🔔 WebView requested close with error status');
                              }
                            }
                          },
                        );
                      },
                      onLoadStart: (controller, url) {
                        print('📥 WebView loading started: $url');
                        if (!_isExiting) {
                          setState(() => _isLoading = true);
                          _startLoadingTimeout();
                        }
                      },
                      onLoadStop: (controller, url) async {
                        print('✅ WebView loading stopped: $url');
                        _loadingTimeoutTimer?.cancel();
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (!_isExiting && mounted) {
                          setState(() => _isLoading = false);
                        }
                        _pullToRefreshController?.endRefreshing();
                      },
                      onLoadError: (controller, url, code, message) {
                        print(
                          '❌ WebView load error - Code: $code, Message: $message',
                        );
                        _loadingTimeoutTimer?.cancel();
                        if (!_isExiting && mounted) {
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                            _errorMessage = 'Failed to load page: $message';
                          });
                        }
                        _pullToRefreshController?.endRefreshing();
                      },
                      onLoadHttpError: (controller, url, statusCode, description) {
                        print(
                          '❌ WebView HTTP error - Code: $statusCode, Description: $description',
                        );
                        _loadingTimeoutTimer?.cancel();
                        if (!_isExiting && mounted) {
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                            _errorMessage =
                                'HTTP Error $statusCode: $description';
                          });
                        }
                        _pullToRefreshController?.endRefreshing();
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                            print(
                              '🔀 URL navigation: ${navigationAction.request.url}',
                            );
                            return NavigationActionPolicy.ALLOW;
                          },
                    ),

                  // Loading Indicator
                  if (_isLoading)
                    AnimatedOpacity(
                      opacity: _isLoading ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF005E6A),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Loading page...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: const Color(0xFF003840),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Error Screen
                  if (_hasError && !_isLoading)
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64.sp,
                                color: Colors.red.shade400,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Unable to Load Page',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF003840),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 32.h),
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton.icon(
                                  onPressed: _retryLoadPage,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF005E6A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: OutlinedButton.icon(
                                  onPressed: _exitPage,
                                  icon: const Icon(Icons.close),
                                  label: const Text('Close'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF003840),
                                    side: const BorderSide(
                                      color: Color(0xFF003840),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
