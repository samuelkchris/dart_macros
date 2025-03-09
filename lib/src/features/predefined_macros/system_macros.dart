import 'dart:io';

import '../../core/location.dart';
import '../../core/macro_definition.dart';

/// Manages system-defined macros.
///
/// The [SystemMacros] class handles the creation and management of built-in
/// predefined macros that provide information about the system, environment,
/// and compilation context. These macros include file paths, timestamps,
/// platform information, and debug settings.
///
/// These system macros are automatically available in all macro processing
/// contexts and provide essential contextual information for conditional
/// compilation and other macro operations.
///
/// Example usage:
/// ```dart
/// final systemMacros = SystemMacros();
/// final macros = systemMacros.getPredefinedMacros(location);
/// ```
class SystemMacros {
  /// Gets all predefined system macros.
  ///
  /// This method creates and returns a map of all system-defined macros,
  /// including file and line information, date and time, version information,
  /// debug status, and platform details.
  ///
  /// Parameters:
  /// - [location]: The source location for which to create macros
  ///
  /// Returns:
  /// A map of predefined macro names to their definitions
  Map<String, MacroDefinition> getPredefinedMacros(Location location) {
    return {
      /* Current file path macro */
      '__FILE__': MacroDefinition(
        name: '__FILE__',
        replacement: location.file,
        type: MacroType.predefined,
        location: location,
      ),

      /* Current line number macro */
      '__LINE__': MacroDefinition(
        name: '__LINE__',
        replacement: '${location.line}',
        type: MacroType.predefined,
        location: location,
      ),

      /* Current date macro */
      '__DATE__': _createDateMacro(location),

      /* Current time macro */
      '__TIME__': _createTimeMacro(location),

      /* Current timestamp macro (ISO format) */
      '__TIMESTAMP__': _createTimestampMacro(location),

      /* Dart version macro */
      '__DART_VERSION__': _createDartVersionMacro(location),

      /* Debug mode macro */
      '__DEBUG__': _createDebugMacro(location),

      /* Platform identification macro */
      '__PLATFORM__': _createPlatformMacro(location),
    };
  }

  /// Creates the __DATE__ macro.
  ///
  /// Generates a macro containing the current date in the format "Mon DD YYYY".
  ///
  /// Parameters:
  /// - [location]: The source location for the macro
  ///
  /// Returns:
  /// A macro definition for the __DATE__ macro
  MacroDefinition _createDateMacro(Location location) {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final date = '${months[now.month - 1]} ${now.day} ${now.year}';

    return MacroDefinition(
      name: '__DATE__',
      replacement: '"$date"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Creates the __TIME__ macro.
  ///
  /// Generates a macro containing the current time in the format "HH:MM:SS".
  ///
  /// Parameters:
  /// - [location]: The source location for the macro
  ///
  /// Returns:
  /// A macro definition for the __TIME__ macro
  MacroDefinition _createTimeMacro(Location location) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    return MacroDefinition(
      name: '__TIME__',
      replacement: '"$time"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Creates the __TIMESTAMP__ macro.
  ///
  /// Generates a macro containing the current timestamp in ISO 8601 format.
  ///
  /// Parameters:
  /// - [location]: The source location for the macro
  ///
  /// Returns:
  /// A macro definition for the __TIMESTAMP__ macro
  MacroDefinition _createTimestampMacro(Location location) {
    final now = DateTime.now();
    return MacroDefinition(
      name: '__TIMESTAMP__',
      replacement: '"${now.toIso8601String()}"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Creates the __DART_VERSION__ macro.
  ///
  /// Generates a macro containing the current Dart SDK version.
  ///
  /// Parameters:
  /// - [location]: The source location for the macro
  ///
  /// Returns:
  /// A macro definition for the __DART_VERSION__ macro
  MacroDefinition _createDartVersionMacro(Location location) {
    return MacroDefinition(
      name: '__DART_VERSION__',
      replacement: '"${Platform.version}"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Creates the __DEBUG__ macro.
  ///
  /// Generates a macro indicating whether the application is in debug mode.
  /// The value is '1' for debug mode and '0' for release mode.
  ///
  /// Parameters:
  /// - [location]: The source location for the macro
  ///
  /// Returns:
  /// A macro definition for the __DEBUG__ macro
  MacroDefinition _createDebugMacro(Location location) {
    const debug = bool.fromEnvironment('dart.vm.debug');
    return MacroDefinition(
      name: '__DEBUG__',
      replacement: debug ? '1' : '0',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Creates the __PLATFORM__ macro.
  ///
  /// Generates a macro containing the current platform identifier
  /// (android, ios, linux, macos, windows).
  ///
  /// Parameters:
  /// - [location]: The source location for the macro
  ///
  /// Returns:
  /// A macro definition for the __PLATFORM__ macro
  MacroDefinition _createPlatformMacro(Location location) {
    String platform = '';

    /* Determine the current platform */
    if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else if (Platform.isLinux) {
      platform = 'linux';
    } else if (Platform.isMacOS) {
      platform = 'macos';
    } else if (Platform.isWindows) {
      platform = 'windows';
    }
    // Note: Platform.isWeb is not available in dart:io

    return MacroDefinition(
      name: '__PLATFORM__',
      replacement: '"$platform"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Updates location-dependent macros.
  ///
  /// This method updates the __FILE__ and __LINE__ macros to reflect
  /// a new source location. This is useful when processing code spans
  /// different files or positions.
  ///
  /// Parameters:
  /// - [macros]: The map of macros to update
  /// - [location]: The new source location
  void updateLocation(
      Map<String, MacroDefinition> macros,
      Location location,
      ) {
    /* Update file path macro */
    macros['__FILE__'] = MacroDefinition(
      name: '__FILE__',
      replacement: location.file,
      type: MacroType.predefined,
      location: location,
    );

    /* Update line number macro */
    macros['__LINE__'] = MacroDefinition(
      name: '__LINE__',
      replacement: '${location.line}',
      type: MacroType.predefined,
      location: location,
    );
  }
}