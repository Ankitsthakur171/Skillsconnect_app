import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String url;
  final String? title;

  const InAppWebViewScreen({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  InAppWebViewController? _controller;
  int _progress = 0;
  bool _pageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffebf6f7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? 'Web',
          style: const TextStyle(color: Color(0xff003840)),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
             color: Colors.white,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(widget.url),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                allowFileAccess: true,
                allowContentAccess: true,
                domStorageEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                useShouldOverrideUrlLoading: true,
                transparentBackground: false,
                supportZoom: false,
              ),
                initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          javaScriptEnabled: true,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: false,
        ),
      ),
            
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress);
              },
            
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri == null) return NavigationActionPolicy.ALLOW;
            
                if (uri.scheme != 'http' && uri.scheme != 'https') {
                  try {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                  return NavigationActionPolicy.CANCEL;
                }
            
                return NavigationActionPolicy.ALLOW;
              },
            
              onLoadStop: (controller, url) async {
                if (mounted) setState(() => _pageLoaded = true);
                await controller.evaluateJavascript(source: r'''
                (function () {
                  document.querySelectorAll('a[target="_blank"]').forEach(function(a){
                    a.removeAttribute('target');
                  });
                  window.open = function (u) {
                    window.location.href = u;
                    return null;
                  };
                })();
              ''');
              },
            
              
              androidOnPermissionRequest:
                  (controller, origin, resources) async {
                return PermissionRequestResponse( 
                  resources: resources,
                  action: PermissionRequestResponseAction.GRANT,
                );
              },
            
              onWebViewCreated: (controller) {
                _controller = controller;
              },
            ),
          ),

          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100.0,
              minHeight: 2,
            ),
          if (!_pageLoaded)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF005E6A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
