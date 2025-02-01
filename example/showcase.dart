// example/showcase.dart

import 'package:dart_macros/dart_macros.dart';

// 1. Configuration Setup
@MacroFile()
@Define('APP_NAME', 'MacroShowcase')
@Define('VERSION', '1.0.0')
@Define('BUILD_NUMBER', 42)
@Define('__DEBUG__', true)

// 2. Feature Flags
@Define('FEATURE_DARK_MODE', true)
@Define('FEATURE_ANALYTICS', true)
@Define('FEATURE_CLOUD_SYNC', false)

// 3. Environment Configuration
@Define('API_URL', 'https://api.example.com')
@Define('MAX_RETRIES', 3)
@Define('TIMEOUT_MS', 5000)
@Define('PLATFORM', 'android')

class AppConfig {
  // App won't initialize twice
  static bool _initialized = false;

  // Configuration getters
  static String get appName => Macros.get<String>('APP_NAME');
  static String get version => Macros.get<String>('VERSION');
  static int get buildNumber => Macros.get<int>('BUILD_NUMBER');
  static String get fullVersion =>
      MacroFunctions.CONCAT('v$version', '(${buildNumber})');

  // Feature checks
  static bool get isDarkModeEnabled =>
      MacroFunctions.HAS_FEATURE('DARK_MODE');
  static bool get isAnalyticsEnabled =>
      MacroFunctions.HAS_FEATURE('ANALYTICS');
  static bool get isCloudSyncEnabled =>
      MacroFunctions.HAS_FEATURE('CLOUD_SYNC');
}

class Analytics {
  void logEvent(String event, {Map<String, dynamic>? params}) {
    if (!AppConfig.isAnalyticsEnabled) return;

    MacroFunctions.DEBUG_PRINT('Logging event: $event');
    if (params != null) {
      MacroFunctions.DEBUG_PRINT('Parameters: $params');
    }
  }
}

class ApiClient {
  final String baseUrl = Macros.get<String>('API_URL');
  final int maxRetries = Macros.get<int>('MAX_RETRIES');
  final int timeout = Macros.get<int>('TIMEOUT_MS');

  Future<void> makeRequest(String endpoint) async {
    MacroFunctions.LOG_CALL('makeRequest');

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        MacroFunctions.DEBUG_PRINT(
            'Attempt $attempt/$maxRetries: $baseUrl$endpoint'
        );

        // Simulate API call
        await Future.delayed(Duration(milliseconds: 100));
        return;
      } catch (e) {
        MacroFunctions.DEBUG_PRINT('Request failed: $e');
        if (attempt == maxRetries) rethrow;
      }
    }
  }
}

class ThemeManager {
  String _currentTheme = 'light';

  void initialize() {
    MacroFunctions.LOG_CALL('ThemeManager.initialize');

    if (AppConfig.isDarkModeEnabled) {
      _currentTheme = 'dark';
      MacroFunctions.DEBUG_PRINT('Dark mode enabled');
    }
  }

  String get theme => _currentTheme;
}

class CloudSync {
  Future<void> sync() async {
    MacroFunctions.LOG_CALL('CloudSync.sync');

    if (!AppConfig.isCloudSyncEnabled) {
      MacroFunctions.DEBUG_PRINT('Cloud sync is disabled');
      return;
    }

    MacroFunctions.DEBUG_PRINT('Starting cloud sync');
    await Future.delayed(Duration(seconds: 1));
    MacroFunctions.DEBUG_PRINT('Cloud sync complete');
  }
}

class App {
  final analytics = Analytics();
  final apiClient = ApiClient();
  final themeManager = ThemeManager();
  final cloudSync = CloudSync();

  Future<void> initialize() async {
    MacroFunctions.LOG_CALL('App.initialize');

    MacroFunctions.DEBUG_PRINT('Starting ${AppConfig.appName} initialization');
    MacroFunctions.DEBUG_PRINT('Version: ${AppConfig.fullVersion}');

    // Platform-specific initialization
    if (MacroFunctions.IS_PLATFORM('android')) {
      MacroFunctions.DEBUG_PRINT('Initializing Android components');
    }

    // Initialize components
    themeManager.initialize();

    // Log startup
    analytics.logEvent('app_start', params: {
      'version': AppConfig.version,
      'build': AppConfig.buildNumber,
      'platform': Macros.get<String>('PLATFORM'),
    });

    await apiClient.makeRequest('/init');
    await cloudSync.sync();

    MacroFunctions.DEBUG_PRINT('Initialization complete');
  }
}

void main() async {
  await initializeDartMacros();

  final app = App();
  await app.initialize();

  // Simulate some app usage
  print('\nSimulating app usage...\n');

  app.analytics.logEvent('user_action', params: {
    'action': 'button_click',
    'screen': 'main',
  });

  await app.apiClient.makeRequest('/data');

  print('\nSimulation complete');
}