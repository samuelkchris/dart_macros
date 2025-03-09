import 'package:dart_macros/dart_macros.dart';

/// Configuration for the task tracker app.
///
/// This class uses dart_macros for code generation to create
/// environment-specific configurations at build time.
@MacroFile()
class AppConfig {
  // Environment
  @Define('ENVIRONMENT', '{{environment}}')
  static const String environment = '';

  // App Information
  @Define('APP_NAME', 'Task Tracker')
  static const String appName = 'Task Tracker';

  @Define('APP_VERSION', '1.0.0')
  static const String appVersion = '1.0.0';

  // API Configuration
  @Define('API_BASE_URL', '{{apiConfig.baseUrl}}')
  static const String apiBaseUrl = '';

  @Define('API_TIMEOUT', '{{apiConfig.timeout}}')
  static const int apiTimeout = 0;

  @Define('API_MOCK_RESPONSES', '{{apiConfig.mockResponses}}')
  static const bool apiMockResponses = false;

  // Feature Flags
  @Define('FEATURE_DARK_MODE', '{{featureFlags.enableDarkMode}}')
  static const bool enableDarkMode = false;

  @Define('FEATURE_NOTIFICATIONS', '{{featureFlags.enableNotifications}}')
  static const bool enableNotifications = false;

  @Define('FEATURE_SYNC', '{{featureFlags.enableSync}}')
  static const bool enableSync = false;

  @Define('FEATURE_PREMIUM', '{{featureFlags.enablePremiumFeatures}}')
  static const bool enablePremiumFeatures = false;

  // Function-like macros for conditional code
  @DefineMacro(
    'IN_DEVELOPMENT',
    'ENVIRONMENT == "development"',
  )
  static bool isDevelopment() => false;

  @DefineMacro(
    'SHOW_DEBUG_INFO',
    'ENVIRONMENT == "development" || ENVIRONMENT == "staging"',
  )
  static bool showDebugInfo() => false;

  @DefineMacro(
    'HAS_PREMIUM',
    'FEATURE_PREMIUM',
  )
  static bool hasPremium() => false;

  // Initialize configuration
  static void initialize() {
    // Initialize base macros
    FlutterMacros.initialize();

    // Register environment-specific configurations
    FlutterMacros.registerFromAnnotations([
      Define('ENVIRONMENT', environment),
      Define('API_BASE_URL', apiBaseUrl),
      Define('API_TIMEOUT', apiTimeout),
      Define('API_MOCK_RESPONSES', apiMockResponses),
      Define('FEATURE_DARK_MODE', enableDarkMode),
      Define('FEATURE_NOTIFICATIONS', enableNotifications),
      Define('FEATURE_SYNC', enableSync),
      Define('FEATURE_PREMIUM', enablePremiumFeatures),
    ]);
  }
}
