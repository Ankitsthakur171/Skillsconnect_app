import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),

          // ✅ NEW: handle external schemes + prevent blank/new-window issue
          onNavigationRequest: (req) async {
            final uri = Uri.tryParse(req.url);
            if (uri == null) return NavigationDecision.navigate;

            // webview me sirf http/https allow
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              // external open (tel:, mailto:, intent:, etc.)
              // ignore errors silently
              try {
                // url_launcher already in your project
                // import is in LoginScreen, but add in this file too if missing:
                // import 'package:url_launcher/url_launcher.dart';
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },

          // ✅ NEW: fix target=_blank / window.open => open in same webview
          onPageFinished: (url) async {
            try {
              await _controller.runJavaScript(r'''
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
            } catch (_) {}
          },
          onHttpError: (e) => debugPrint('WebView HTTP error: ${e.response?.statusCode}'),
          onWebResourceError: (e) => debugPrint('WebView resource error: ${e.description}'),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffebf6f7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // ✅ iOS-style back icon (Material)
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: Text(widget.title ?? 'Web',style: TextStyle(color: Color(0xff003840)),),
        actions: [
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100)
            LinearProgressIndicator(value: _progress / 100.0, minHeight: 2),
        ],
      ),
    );
  }
}
