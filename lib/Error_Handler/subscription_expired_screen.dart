// lib/screens/subscription_expired_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final message = (args['message'] ?? 'Your subscription package has expired. Please renew to continue.').toString();

    final theme = Theme.of(context);
    const accent = Color(0xFF005E6A);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 60),
              CircleAvatar(
                radius: 46,
                backgroundColor: accent.withOpacity(0.12),
                child: const Icon(Icons.lock_clock_rounded, size: 44, color: accent),
              ),
              const SizedBox(height: 18),
              Text('Subscription Expired',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor, height: 1.5)),
              // const Spacer(),
              const SizedBox(height: 30),

              Row(
                children: [
                  // Expanded(
                  //   child: OutlinedButton.icon(
                  //     onPressed: () => Navigator.of(context).maybePop(),
                  //     icon: const Icon(Icons.arrow_back),
                  //     label: const Text('Back'),
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openRenew,
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Renew Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRenew() async {
    final uri = Uri.parse('https://skillsconnect.in/');
    // Try external app (browser). On web, open a new tab.
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok) {
      // Fallback to in-app webview if external open fails
      await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webOnlyWindowName: '_blank',
      );
    }
  }

}
