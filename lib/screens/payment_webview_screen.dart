import 'dart:async';

import 'package:flutter/services.dart';

import '../core/app_feedback.dart';

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
  String? error;
  bool slow = false;
  Timer? watchdog;
  static const external = MethodChannel('com.fasobiblio.app/external');

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            watchdog?.cancel();
            if (mounted) {
              setState(() {
                error = null;
                slow = false;
              });
            }
            watchdog = Timer(const Duration(seconds: 30), () {
              if (mounted) setState(() => slow = true);
            });
          },
          onPageFinished: (_) {
            watchdog?.cancel();
          },
          onWebResourceError: (failure) {
            if (failure.isForMainFrame == true && mounted) {
              setState(
                () => error = 'La page de paiement n’a pas pu se charger. Vérifiez votre connexion ou ouvrez-la dans votre navigateur.',
              );
            }
          },
          onProgress: (value) {
            if (mounted) setState(() => progress = value);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri?.scheme == 'tel') {
              _external(request.url);
              return NavigationDecision.prevent;
            }
            if (uri == null || uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }
            _inspect(uri);
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final uri = Uri.tryParse(change.url ?? '');
            if (uri != null) _inspect(uri);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _inspect(Uri uri) {
    if (completed ||
        !{
          'fasobiblio.com',
          'www.fasobiblio.com',
        }.contains(uri.host.toLowerCase())) {
      return;
    }
    final target = '${uri.path}#${uri.fragment}'.toLowerCase();
    if (!target.contains('livraison')) return;
    completed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<void> _external(String url) async {
    try {
      await external.invokeMethod<bool>('open', {'url': url});
    } catch (_) {
      if (mounted) {
        showToast(context, 'Impossible d’ouvrir ce lien sur cet appareil.');
      }
    }
  }

  @override
  void dispose() {
    watchdog?.cancel();
    super.dispose();
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
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(AppIcons.close),
            tooltip: 'Fermer',
          ),
        ],
      ),
      body: Column(
        children: [
          if (progress < 100)
            LinearProgressIndicator(
              value: progress == 0 ? null : progress / 100,
              color: AppColors.blue,
            ),
          if (error != null || slow)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error ?? 'Le chargement prend plus de temps que prévu. Vous pouvez continuer dans votre navigateur.',
              ),
            ),
          Expanded(child: WebViewWidget(controller: controller)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _external(widget.url),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Continuer dans le navigateur'),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Vérifier mon paiement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
