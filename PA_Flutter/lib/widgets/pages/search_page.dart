import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late InAppWebViewController _webViewController;
  final TextEditingController _urlController = TextEditingController();
  String _url = "https://www.google.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        title: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'Search or enter URL',
          ),
          onSubmitted: (url) {
            setState(() {
              _url = url;
            });
            _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(_url)));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _webViewController.goBack(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _webViewController.goForward(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController.reload(),
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_url)),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStart: (controller, url) {
          setState(() {
            _urlController.text = url.toString();
          });
        },
      ),
    );
  }
}
