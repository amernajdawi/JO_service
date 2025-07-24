import 'package:flutter/material.dart';
import 'package:jo_service_app/services/background_service.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  static AppLifecycleManager? _instance;
  
  factory AppLifecycleManager() {
    return _instance ??= AppLifecycleManager._internal();
  }
  
  AppLifecycleManager._internal();
  
  bool _isInitialized = false;
  
  void initialize() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }
  }
  
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App went to background
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        // App is being closed
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call, notification panel)
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
  
  void _onAppResumed() {
    print("App resumed - checking for updates");
    _checkForUpdatesWhenResumed();
  }
  
  void _onAppPaused() {
    print("App paused - starting background tasks");
    BackgroundService.saveAppState();
    BackgroundService.startBackgroundTasks();
  }
  
  void _onAppDetached() {
    print("App detached - cleaning up");
    BackgroundService.saveAppState();
  }
  
  Future<void> _checkForUpdatesWhenResumed() async {
    try {
      // Get app state from when it was backgrounded
      final appState = await BackgroundService.getAppState();
      
      if (appState['was_running_in_background'] == true) {
        final lastActiveStr = appState['last_active'] as String?;
        
        if (lastActiveStr != null) {
          final lastActive = DateTime.parse(lastActiveStr);
          final timeDifference = DateTime.now().difference(lastActive);
          
          // If app was in background for more than 5 minutes, check for updates
          if (timeDifference.inMinutes > 5) {
            await BackgroundService.showNotification(
              'Welcome back!',
              'Your app was running in the background. Checking for updates...',
            );
            
            // You can trigger data refresh here
            // For example, refresh user bookings, provider updates, etc.
          }
        }
        
        // Clear the background flag
        await BackgroundService.saveAppState();
      }
    } catch (e) {
      print("Error checking updates on resume: $e");
    }
  }
}
