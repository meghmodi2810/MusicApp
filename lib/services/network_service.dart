import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Network connectivity service for offline mode detection
class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  bool _isOnline = true;
  bool _hasShownOfflineDialog = false;
  Timer? _connectivityCheckTimer;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Initialize the network service
  void initialize() {
    _checkConnectivity();
    // Check connectivity every 10 seconds
    _connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    final previousState = _isOnline;
    
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      _isOnline = false;
    } on TimeoutException catch (_) {
      _isOnline = false;
    } catch (_) {
      _isOnline = false;
    }

    // Notify listeners if state changed
    if (previousState != _isOnline) {
      notifyListeners();
      _hasShownOfflineDialog = false; // Reset when state changes
    }
  }

  /// Manual retry for connectivity check
  Future<bool> retry() async {
    await _checkConnectivity();
    return _isOnline;
  }

  /// Show offline dialog with retry option
  void showOfflineDialog(BuildContext context, {VoidCallback? onRetry}) {
    if (_hasShownOfflineDialog) return;
    _hasShownOfflineDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('No Internet Connection'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are currently offline. Some features may not be available.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can still listen to downloaded songs.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _hasShownOfflineDialog = false;
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final isConnected = await retry();
                if (context.mounted) {
                  Navigator.pop(context);
                  _hasShownOfflineDialog = false;
                  
                  if (isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.wifi, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Back online!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    if (onRetry != null) onRetry();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Still offline. Please check your connection.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show a simple offline banner
  void showOfflineBanner(BuildContext context) {
    if (!_hasShownOfflineDialog) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(child: Text('You are offline')),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  showOfflineDialog(context);
                },
                child: const Text('RETRY', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _hasShownOfflineDialog = true;
    }
  }

  @override
  void dispose() {
    _connectivityCheckTimer?.cancel();
    super.dispose();
  }
}

/// Widget to wrap app and show offline indicator
class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final bool showBanner;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkService>(
      builder: (context, networkService, _) {
        // Show banner when going offline
        if (networkService.isOffline && showBanner) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            networkService.showOfflineBanner(context);
          });
        }

        return Stack(
          children: [
            child,
            if (networkService.isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.orange,
                  elevation: 4,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Offline Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}