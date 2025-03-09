
import 'dart:async';
import 'package:dart_macros/dart_macros.dart';

// Configuration macros
@MacroFile()
@Define('PLATFORM', 'android')
@Define('__DEBUG__', true)
@Define('API_VERSION', 2)
@Define('ENABLE_ANALYTICS', true)
@Define('EXPERIMENTAL_FEATURES', true)
@Define('MIN_LOG_LEVEL', 'debug')
@Define('MOCK_MODE', false)
@Define('ERROR_REPORTING', true)
@Define('NETWORK_TIMEOUT', 5000)  // milliseconds
@Define('MAX_RETRIES', 3)
class ApiConfig {}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  final String? code;
  ApiException(this.message, {this.code});
  @override
  String toString() => code != null ? '[$code] $message' : message;
}

class ConfigurationError extends ApiException {
  ConfigurationError(super.message, {super.code});
}

class NetworkError extends ApiException {
  NetworkError(super.message, {super.code});
}

// API Implementation
class Api {
  bool _initialized = false;
  final stopwatch = Stopwatch();
  final _errors = <String>[];
  Timer? _networkMonitor;
  bool _isNetworkAvailable = true;
  int _retryCount = 0;

  // Logging levels in order of severity
  static const logLevels = ['debug', 'info', 'warn', 'error'];

  @Debug()
  Future<void> initialize() async {
    try {
      if (_initialized) {
        _log('Already initialized', 'debug');
        return;
      }

      await initializeDartMacros();
      await _validateConfiguration();
      _logSystemInfo();
      _startNetworkMonitoring();

      _log('=== Initialization ===', 'info');
      if (MacroFunctions.IS_DEBUG()) {
        _log('Initializing API in debug mode', 'debug');
        await setupDebugLogging();
        _startProfiling();
      }

      // Mock mode check
      if (Macros.get<bool>('MOCK_MODE')) {
        _log('Running in MOCK mode', 'warn');
        await _initializeMock();
      } else {
        await _initializeReal();
      }

      if (MacroFunctions.IS_DEBUG()) {
        _stopProfiling('Initialization');
      }

      _initialized = true;
      _log('=== End Initialization ===\n', 'info');
    } catch (e, stackTrace) {
      _handleError('Initialization failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> dispose() async {
    _log('Disposing API resources', 'debug');
    _networkMonitor?.cancel();
    _initialized = false;
    await cleanup();
  }

  Future<void> _validateConfiguration() async {
    // Validate platform
    final platform = Macros.get<String>('PLATFORM');
    if (!['android', 'ios', 'web'].contains(platform)) {
      throw ConfigurationError('Invalid platform: $platform', code: 'INVALID_PLATFORM');
    }

    // Validate API version
    final apiVersion = Macros.get<int>('API_VERSION');
    if (apiVersion < 1 || apiVersion > 2) {
      throw ConfigurationError('Invalid API version: $apiVersion', code: 'INVALID_VERSION');
    }

    // Validate log level
    final logLevel = Macros.get<String>('MIN_LOG_LEVEL').toLowerCase();
    if (!logLevels.contains(logLevel)) {
      throw ConfigurationError('Invalid log level: $logLevel', code: 'INVALID_LOG_LEVEL');
    }

    // Validate timeouts
    final timeout = Macros.get<int>('NETWORK_TIMEOUT');
    if (timeout < 1000 || timeout > 30000) {
      throw ConfigurationError('Invalid network timeout: $timeout', code: 'INVALID_TIMEOUT');
    }
  }

  void _log(String message, String level) {
    final currentLevel = Macros.get<String>('MIN_LOG_LEVEL').toLowerCase();
    if (logLevels.indexOf(level) >= logLevels.indexOf(currentLevel)) {
      final timestamp = DateTime.now().toIso8601String();
      final prefix = level.toUpperCase().padRight(5);
      print('[$timestamp] $prefix: $message');
    }
  }

  void _handleError(String message, dynamic error, StackTrace stackTrace) {
    _errors.add('$message: $error');
    _log('$message: $error', 'error');

    if (MacroFunctions.IS_DEBUG()) {
      _log('Stack trace:\n$stackTrace', 'debug');
    }

    if (Macros.get<bool>('ERROR_REPORTING')) {
      _reportError(message, error, stackTrace);
    }
  }

  Future<void> _reportError(String message, dynamic error, StackTrace stackTrace) async {
    _log('Reporting error to service: $message', 'debug');
    // Simulated error reporting
    await Future.delayed(Duration(milliseconds: 100));
  }

  void _startNetworkMonitoring() {
    _networkMonitor?.cancel();
    _networkMonitor = Timer.periodic(Duration(seconds: 30), (_) {
      _checkNetworkStatus();
    });
  }

  Future<void> _checkNetworkStatus() async {
    try {
      // Simulate network check
      await Future.delayed(Duration(milliseconds: 100));
      final wasAvailable = _isNetworkAvailable;
      _isNetworkAvailable = true;

      if (!wasAvailable && _isNetworkAvailable) {
        _log('Network connection restored', 'info');
      }
    } catch (e) {
      _isNetworkAvailable = false;
      _log('Network connection lost', 'warn');
    }
  }

  void _logSystemInfo() {
    _log('System Information:', 'info');
    _log('Platform: ${Macros.get<String>("PLATFORM")}', 'debug');
    _log('Debug Mode: ${MacroFunctions.IS_DEBUG()}', 'debug');
    _log('API Version: ${Macros.get<int>("API_VERSION")}', 'info');
    _log('Analytics: ${Macros.get<bool>("ENABLE_ANALYTICS")}', 'debug');
    _log('Experimental: ${Macros.get<bool>("EXPERIMENTAL_FEATURES")}', 'debug');
    _log('Log Level: ${Macros.get<String>("MIN_LOG_LEVEL").toUpperCase()}', 'debug');
    _log('Network Timeout: ${Macros.get<int>("NETWORK_TIMEOUT")}ms', 'debug');
  }

  Future<void> _initializeReal() async {
    // Platform-specific initialization
    if (MacroFunctions.IS_PLATFORM('android')) {
      await initializeAndroid();
    } else if (MacroFunctions.IS_PLATFORM('ios')) {
      await initializeIOS();
    } else {
      await initializeWeb();
    }

    // Feature initialization
    await _initializeFeatures();
  }

  Future<void> _initializeMock() async {
    _log('Mock platform initialized', 'info');
    _log('Mock features initialized', 'info');
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> performOperation() async {
    try {
      if (!_initialized) {
        throw StateError('API not initialized');
      }

      if (!_isNetworkAvailable && !Macros.get<bool>('MOCK_MODE')) {
        throw NetworkError('Network unavailable', code: 'NETWORK_UNAVAILABLE');
      }

      _log('=== Performing Operation ===', 'info');
      if (MacroFunctions.IS_DEBUG()) {
        _startProfiling();
      }

      if (Macros.get<bool>('MOCK_MODE')) {
        await _mockOperation();
      } else {
        await _performWithRetry(() => doWork());
      }

      if (MacroFunctions.IS_DEBUG()) {
        _stopProfiling('Operation');
      }
      _log('=== Operation Complete ===\n', 'info');
    } catch (e, stackTrace) {
      _handleError('Operation failed', e, stackTrace);
      rethrow;
    }
  }

  Future<T> _performWithRetry<T>(Future<T> Function() operation) async {
    _retryCount = 0;
    final maxRetries = Macros.get<int>('MAX_RETRIES');

    while (true) {
      try {
        return await operation();
      } catch (e) {
        _retryCount++;
        if (_retryCount >= maxRetries) rethrow;
        _log('Operation failed, retrying ($_retryCount/$maxRetries)...', 'warn');
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
      }
    }
  }

  Future<void> _mockOperation() async {
    _log('Performing mock operation', 'debug');
    await Future.delayed(Duration(milliseconds: 100));
  }

  @Debug()
  void _startProfiling() {
    stopwatch.reset();
    stopwatch.start();
  }

  @Debug()
  void _stopProfiling(String operation) {
    stopwatch.stop();
    _log('$operation took ${stopwatch.elapsedMilliseconds}ms', 'debug');
  }

  @Debug()
  Future<void> setupDebugLogging() async {
    _log('Setting up debug logging', 'debug');
    _log('Log level: ${Macros.get<String>("MIN_LOG_LEVEL").toUpperCase()}', 'debug');
    await Future.delayed(Duration(milliseconds: 50)); // Simulate setup
  }

  Future<void> _initializeFeatures() async {
    // API version features
    if (Macros.get<int>('API_VERSION') >= 2) {
      await setupV2Features();
    } else {
      await setupLegacyFeatures();
    }

    // Analytics
    if (Macros.get<bool>('ENABLE_ANALYTICS')) {
      _log('Initializing analytics', 'info');
      await Future.delayed(Duration(milliseconds: 50));
    }

    // Experimental features
    if (Macros.get<bool>('EXPERIMENTAL_FEATURES')) {
      _log('Enabling experimental features', 'info');
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  @PlatformSpecific({'android', 'ios', 'web'})
  Future<void> doWork() async {
    if (!_isNetworkAvailable && !Macros.get<bool>('MOCK_MODE')) {
      throw NetworkError('Network unavailable during operation');
    }

    if (MacroFunctions.IS_PLATFORM('android')) {
      _log('Doing Android-specific work', 'info');
      if (MacroFunctions.IS_DEBUG()) {
        _log('Android SDK Version: 33', 'debug');
      }
    } else if (MacroFunctions.IS_PLATFORM('ios')) {
      _log('Doing iOS-specific work', 'info');
      if (MacroFunctions.IS_DEBUG()) {
        _log('iOS Version: 15.0', 'debug');
      }
    } else {
      _log('Doing web-specific work', 'info');
      if (MacroFunctions.IS_DEBUG()) {
        _log('Browser: Chrome', 'debug');
      }
    }

    await Future.delayed(Duration(milliseconds: 200)); // Simulate work
  }

  @Platform('android')
  Future<void> initializeAndroid() async {
    _log('Initializing Android platform', 'info');
    await Future.delayed(Duration(milliseconds: 100));
  }

  @Platform('ios')
  Future<void> initializeIOS() async {
    _log('Initializing iOS platform', 'info');
    await Future.delayed(Duration(milliseconds: 100));
  }

  @Platform('web')
  Future<void> initializeWeb() async {
    _log('Initializing Web platform', 'info');
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> setupV2Features() async {
    _log('Setting up V2 features', 'info');
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> setupLegacyFeatures() async {
    _log('Setting up legacy features', 'info');
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> cleanup() async {
    _log('Cleaning up resources', 'debug');
    await Future.delayed(Duration(milliseconds: 100));
  }
}

void main() async {
  final api = Api();
  try {
    await api.initialize();
    await api.performOperation();
    await api.initialize();  // Test re-initialization

    // Simulate some work
    await Future.delayed(Duration(seconds: 1));

    // Test another operation
    await api.performOperation();

    // Clean up
    await api.dispose();
  } catch (e, stackTrace) {
    print('Main error handler: $e');
    if (MacroFunctions.IS_DEBUG()) {
      print('Stack trace:\n$stackTrace');
    }
  }
}