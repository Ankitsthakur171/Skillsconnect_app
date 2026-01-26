import 'package:flutter/material.dart';
import 'app_error.dart';

class OopsPage extends StatelessWidget {
  final ApiFailure failure;
  final VoidCallback? onRetry;

  const OopsPage({super.key, required this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🔹 White background
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin:  const EdgeInsets.all(24),
              color: const Color(0xffe5ebeb),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Error Icon
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),

                    // 🔹 Title
                    Text(
                      'Oops! Something went wrong',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // // 🔹 Error message
                    // Text(
                    //   failure.message,
                    //   textAlign: TextAlign.center,
                    //   style: const TextStyle(
                    //     color: Colors.black54,
                    //     height: 1.4,
                    //     fontSize: 15,
                    //   ),
                    // ),
                    //
                    // const SizedBox(height: 24),

                    // 🔹 Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop(); // 🔹 previous page pe le jayega
                            } else {
                              Navigator.of(context).pushReplacementNamed('/'); // 🔹 fallback (home page)
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (onRetry != null)
                          ElevatedButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
