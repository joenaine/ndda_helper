import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UpToDateScreen extends StatefulWidget {
  const UpToDateScreen({super.key});

  @override
  State<UpToDateScreen> createState() => _UpToDateScreenState();
}

class _UpToDateScreenState extends State<UpToDateScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String _currentTitle = 'UpToDate';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
              // Try to get page title
              _controller?.getTitle().then((title) {
                if (mounted && title != null) {
                  setState(() => _currentTitle = title);
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://utd.libook.xyz/'));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Reload button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller?.reload();
            },
            tooltip: 'Reload',
          ),
          // Home button
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              _controller?.loadRequest(Uri.parse('https://utd.libook.xyz/'));
            },
            tooltip: 'Home',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ),
          if (_isLoading && _controller != null)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

