import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/theme.dart';

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({super.key, required this.url});
  final String url;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController controller;
  var progress = 0;
  var completed = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (value) { if (mounted) setState(() => progress = value); },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || uri.scheme != 'https') return NavigationDecision.prevent;
          _inspect(uri);
          return NavigationDecision.navigate;
        },
        onUrlChange: (change) {
          final uri = Uri.tryParse(change.url ?? '');
          if (uri != null) _inspect(uri);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  void _inspect(Uri uri) {
    if (completed || !{'fasobiblio.com', 'www.fasobiblio.com'}.contains(uri.host.toLowerCase())) return;
    final target = '${uri.path}#${uri.fragment}'.toLowerCase();
    if (!target.contains('livraison')) return;
    completed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<bool> _leave() async {
    if (await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop || !await _leave() || !context.mounted) return;
      Navigator.of(context).pop(false);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Paiement sécurisé'),
        actions: [IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close_rounded), tooltip: 'Fermer')],
      ),
      body: Column(children: [
        if (progress < 100) LinearProgressIndicator(value: progress == 0 ? null : progress / 100, color: AppColors.blue),
        Expanded(child: WebViewWidget(controller: controller)),
      ]),
    ),
  );
}
