// lib/errors/oops_error_guard.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_error.dart';
import 'oops_screen.dart';

class OopsErrorGuard {
  static GlobalKey<NavigatorState>? _navKey;
  static bool _showing = false;

  /// Call this ONCE in main(): OopsErrorGuard.install(navigatorKey);
  static void install(GlobalKey<NavigatorState> navigatorKey) {
    _navKey = navigatorKey;

    // Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _routeFor(ApiFailure.from(details.exception, details.stack));
    };

    // Uncaught async errors (since Flutter 3.3+)
    // PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    //   _pushOops(ApiFailure.from(error, stack));
    //   return true; // mark as handled
    // };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _routeFor(ApiFailure.from(error, stack));
      return true;
    };

    // (Optional) Replace default red screen
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFF0F172A),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: OopsPage(failure: ApiFailure.from(details.exception, details.stack)),
          ),
        ),
      );
    };
  }

  /// Use if you want to wrap a SINGLE future and auto-show page on error.
  static Future<T> guard<T>(Future<T> Function() futureFn, {VoidCallback? onRetry}) async {
    try {
      return await futureFn();
    } catch (e, st) {
      _routeFor(ApiFailure.from(e, st), onRetry: onRetry);
      rethrow;
    }
  }

  /// Show Oops manually
  static void show(ApiFailure failure, {VoidCallback? onRetry}) => _routeFor(failure, onRetry: onRetry);

  static void _routeFor(ApiFailure failure, {VoidCallback? onRetry}) {
    final nav = _navKey?.currentState;
    // if (nav == null) return;
    // if (_showing) return;
    if (nav == null || _showing) return;

    _showing = true;



    // 🔴 SPECIAL CASE: subscription expired → pretty page
    if (failure is ApiSubscriptionExpiredFailure) {
      nav.pushNamedAndRemoveUntil(
        '/subscription-expired',
            (r) => r.settings.name != '/subscription-expired',
        arguments: {'message': failure.message},
      ).whenComplete(() => _showing = false);
      return;
    }

    // Avoid stacking multiple pages quickly
    nav.push(MaterialPageRoute(
      builder: (_) => OopsPage(failure: failure, onRetry: onRetry),
      settings: const RouteSettings(name: 'OopsPage'),
      fullscreenDialog: true,
    )).whenComplete(() {
      _showing = false;
    });
  }
}
