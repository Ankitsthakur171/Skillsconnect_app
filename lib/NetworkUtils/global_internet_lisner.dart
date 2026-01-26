import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'network_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NetworkGuard {
  static StreamSubscription? _subscription;
  static bool _dialogOpen = false;

  static void startMonitoring() {
    _subscription ??= Connectivity().onConnectivityChanged.listen((_) async {
      final hasConnection = await InternetConnectionChecker.instance.hasConnection;

      if (!hasConnection && !_dialogOpen) {
        _dialogOpen = true;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const NoInternetPage(),
          ),
        );
      } else if (hasConnection && _dialogOpen) {
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
        _dialogOpen = false;
      }
    });
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
