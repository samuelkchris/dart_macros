/// Helper utilities for using dart_macros in Flutter applications.
///
/// This file provides convenience methods for Flutter applications to use the
/// dart_macros system effectively. Since Flutter on iOS and Android doesn't support
/// the reflection capabilities of dart:mirrors, macros can't be discovered automatically
/// through annotations. This class bridges that gap by providing a way to manually
/// register macros that would otherwise be detected automatically.
///
/// This class is specifically designed for Flutter applications and should be used
/// in conjunction with the main Macros class to ensure a smooth experience across
/// all platforms.
library;

import 'macros.dart';

/// Helper to register macros for Flutter applications.
///
/// The [FlutterMacros] class offers utility methods to make it easier to use
/// dart_macros in Flutter applications, where reflection-based annotation scanning
/// is not available. It provides:
///
/// 1. Methods to manually register macros from annotation objects
/// 2. Platform-specific initialization for common macro values
///
/// Typical usage would be to call [initialize] at the start of your application,
/// then use [registerFromAnnotations] to register any annotation-based macros.
///
/// Example:
/// ```dart
/// void main() {
///   // Initialize platform-specific values
///   FlutterMacros.initialize();
///
///   // Register macros that would normally be annotations
///   FlutterMacros.registerFromAnnotations([
///     Define('VERSION', '1.0.0'),
///     Define('MAX_ITEMS', 100),
///     DefineMacro('SQUARE', 'x * x', parameters: ['x']),
///   ]);
///
///   // Now use macros as normal
///   runApp(MyApp());
/// }
/// ```
class FlutterMacros {
  /// Registers macros from annotation objects.
  ///
  /// This method accepts a list of annotation objects and registers them
  /// as macros. It's designed to provide a way to use the same annotation
  /// classes in Flutter applications that would be automatically detected
  /// on platforms that support reflection.
  ///
  /// Parameters:
  /// - [annotatedClasses]: A list of annotation objects to register as macros
  ///
  /// The method recognizes two types of annotations:
  /// - [Define] for simple value macros
  /// - [DefineMacro] for function-like macros with parameters
  ///
  /// Example:
  /// ```dart
  /// FlutterMacros.registerFromAnnotations([
  ///   Define('VERSION', '1.0.0'),
  ///   Define('MAX_ITEMS', 100),
  ///   Define('DEBUG', true),
  ///   DefineMacro('SQUARE', 'x * x', parameters: ['x']),
  ///   DefineMacro('MAX', 'a > b ? a : b', parameters: ['a', 'b']),
  /// ]);
  /// ```
  static void registerFromAnnotations(List<Object> annotatedClasses) {
    for (final obj in annotatedClasses) {
      // Extract annotations using runtime type checking
      if (obj is Define) {
        Macros.registerMacro(obj.name, obj.value);
      } else if (obj is DefineMacro) {
        Macros.registerFunctionMacro(
            obj.name,
            obj.parameters,
            obj.expression
        );
      }
    }
  }

  /// Initializes common macros and platform-specific values.
  ///
  /// This method sets up platform-specific macro values that are typically
  /// needed by most applications. It should be called once at application
  /// startup before any other macro operations.
  ///
  /// The method registers:
  /// - Platform identifier as 'flutter'
  /// - Debug flag (can be overridden if needed)
  /// - Other common platform-specific values
  ///
  /// You can override any of these values later by calling
  /// [Macros.registerMacro] with the same name.
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   // Initialize default platform values
  ///   FlutterMacros.initialize();
  ///
  ///   // Override debug flag based on application configuration
  ///   Macros.registerMacro('DEBUG', isDebugMode);
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  static void initialize() {
    // Register platform identifier
    Macros.registerMacro('__PLATFORM__', 'flutter');

    // Set default debug flag (developers should override this based on their needs)
    Macros.registerMacro('DEBUG', true);

    // Register additional platform-specific values
    final now = DateTime.now();
    Macros.registerMacro('__BUILD_TIME__', now.toIso8601String());

    // Register Flutter-specific values
    // These could be expanded based on what's available in Flutter
    Macros.registerMacro('__FLUTTER_MODE__', 'debug'); // Could be updated to reflect actual mode
  }

  /// Configures platform-specific values for different Flutter targets.
  ///
  /// This method extends the basic initialization with more platform-specific
  /// values based on the target platform. It's useful for applications that
  /// need to differentiate between iOS, Android, and other Flutter targets.
  ///
  /// Parameters:
  /// - [platform]: The specific platform target ('ios', 'android', etc.)
  /// - [debug]: Whether the application is in debug mode
  /// - [additionalValues]: A map of additional macro values to register
  ///
  /// Example:
  /// ```dart
  /// // In your main.dart file
  /// void main() {
  ///   FlutterMacros.initialize();
  ///
  ///   // Configure platform-specific details
  ///   FlutterMacros.configurePlatform(
  ///     platform: 'android',
  ///     debug: kDebugMode,
  ///     additionalValues: {
  ///       'ANDROID_API_LEVEL': 30,
  ///       'SUPPORT_MATERIAL3': true,
  ///     },
  ///   );
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  static void configurePlatform({
    required String platform,
    required bool debug,
    Map<String, dynamic> additionalValues = const {},
  }) {
    // Update platform identifier
    Macros.registerMacro('__PLATFORM__', platform);

    // Update debug flag
    Macros.registerMacro('DEBUG', debug);

    // Register platform-specific flags
    Macros.registerMacro('IS_IOS', platform == 'ios');
    Macros.registerMacro('IS_ANDROID', platform == 'android');
    Macros.registerMacro('IS_WEB', platform == 'web');

    // Register additional values
    for (final entry in additionalValues.entries) {
      Macros.registerMacro(entry.key, entry.value);
    }
  }
}