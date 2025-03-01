import 'dart:io';

import '../../core/location.dart';
import '../../core/macro_definition.dart';

/// Manages system-defined macros
class SystemMacros {
  /// Get all predefined system macros
  Map<String, MacroDefinition> getPredefinedMacros(Location location) {
    return {
      '__FILE__': MacroDefinition(
        name: '__FILE__',
        replacement: location.file,
        type: MacroType.predefined,
        location: location,
      ),
      '__LINE__': MacroDefinition(
        name: '__LINE__',
        replacement: '${location.line}',
        type: MacroType.predefined,
        location: location,
      ),
      '__DATE__': _createDateMacro(location),
      '__TIME__': _createTimeMacro(location),
      '__TIMESTAMP__': _createTimestampMacro(location),
      '__DART_VERSION__': _createDartVersionMacro(location),
      '__DEBUG__': _createDebugMacro(location),
      '__PLATFORM__': _createPlatformMacro(location),
    };
  }

  /// Create the __DATE__ macro
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

  /// Create the __TIME__ macro
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

  /// Create the __TIMESTAMP__ macro
  MacroDefinition _createTimestampMacro(Location location) {
    final now = DateTime.now();
    return MacroDefinition(
      name: '__TIMESTAMP__',
      replacement: '"${now.toIso8601String()}"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Create the __DART_VERSION__ macro
  MacroDefinition _createDartVersionMacro(Location location) {
    return MacroDefinition(
      name: '__DART_VERSION__',
      replacement: '"${Platform.version}"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Create the __DEBUG__ macro
  MacroDefinition _createDebugMacro(Location location) {
    const debug = bool.fromEnvironment('dart.vm.debug');
    return MacroDefinition(
      name: '__DEBUG__',
      replacement: debug ? '1' : '0',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Create the __PLATFORM__ macro
  MacroDefinition _createPlatformMacro(Location location) {
    String platform = '';
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
    // else if (Platform.isWeb) platform = 'web';

    return MacroDefinition(
      name: '__PLATFORM__',
      replacement: '"$platform"',
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Update location-dependent macros
  void updateLocation(
    Map<String, MacroDefinition> macros,
    Location location,
  ) {
    macros['__FILE__'] = MacroDefinition(
      name: '__FILE__',
      replacement: location.file,
      type: MacroType.predefined,
      location: location,
    );
    macros['__LINE__'] = MacroDefinition(
      name: '__LINE__',
      replacement: '${location.line}',
      type: MacroType.predefined,
      location: location,
    );
  }
}
