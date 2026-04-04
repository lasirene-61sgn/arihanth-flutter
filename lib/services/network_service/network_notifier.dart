// providers/network_provider.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final networkStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  final streamController = StreamController<bool>.broadcast();

  void updateConnectionStatus(List<ConnectivityResult> results) {
    // On web, results will typically have one item.
    // If any result is not "none", we consider it online.
    final hasConnection = results.any((result) => result != ConnectivityResult.none);
    streamController.add(hasConnection);
  }

  // Listen to connectivity changes (now emits List<ConnectivityResult>)
  final subscription = connectivity.onConnectivityChanged.listen(updateConnectionStatus);

  // Seed initial value
  connectivity.checkConnectivity().then((results) {
    updateConnectionStatus(results);
  });

  ref.onDispose(() {
    subscription.cancel();
    streamController.close();
  });

  return streamController.stream;
});