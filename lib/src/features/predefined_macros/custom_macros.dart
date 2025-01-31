import 'dart:io';

import '../../core/exceptions.dart';
import '../../core/location.dart';
import '../../core/macro_definition.dart';

/// Manages user-defined predefined macros
class CustomMacros {
  final Map<String, MacroDefinition> _customMacros = {};

  /// Define a new custom predefined macro
  void define({
    required String name,
    required String value,
    required Location location,
  }) {
    // Validate macro name
    if (!_isValidMacroName(name)) {
      throw MacroDefinitionException(
        'Invalid custom macro name: $name. Must start with underscore.',
        location,
      );
    }

    // Create macro definition
    _customMacros[name] = MacroDefinition(
      name: name,
      replacement: value,
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Define multiple custom macros at once
  void defineAll(Map<String, String> macros, Location location) {
    macros.forEach((name, value) {
      define(name: name, value: value, location: location);
    });
  }

  /// Get all custom predefined macros
  Map<String, MacroDefinition> getCustomMacros() {
    return Map.unmodifiable(_customMacros);
  }

  /// Check if a custom macro is defined
  bool isDefined(String name) => _customMacros.containsKey(name);

  /// Undefine a custom macro
  void undefine(String name) {
    _customMacros.remove(name);
  }

  /// Clear all custom macros
  void clear() {
    _customMacros.clear();
  }

  /// Get a specific custom macro
  MacroDefinition? getMacro(String name) => _customMacros[name];

  /// Validate a custom macro name
  bool _isValidMacroName(String name) {
    // Custom predefined macros must start with underscore
    return name.startsWith('_') &&
        RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name);
  }
}

/// Extension for environment variable macros
extension EnvironmentMacros on CustomMacros {
  /// Load environment variables as macros
  void loadEnvironmentVariables(Location location) {
    final env = Platform.environment;

    env.forEach((key, value) {
      final macroName = '_ENV_${key.toUpperCase()}';
      if (_isValidMacroName(macroName)) {
        define(
          name: macroName,
          value: value,
          location: location,
        );
      }
    });
  }
}

/// Extension for build configuration macros
extension BuildConfigMacros on CustomMacros {
  /// Load build configuration as macros
  void loadBuildConfig(Map<String, dynamic> config, Location location) {
    void processValue(String prefix, dynamic value) {
      if (value is Map) {
        value.forEach((key, val) {
          processValue('${prefix}_${key.toString().toUpperCase()}', val);
        });
      } else {
        final macroName = '_CONFIG_$prefix';
        if (_isValidMacroName(macroName)) {
          define(
            name: macroName,
            value: value.toString(),
            location: location,
          );
        }
      }
    }

    config.forEach((key, value) {
      processValue(key.toUpperCase(), value);
    });
  }
}

/// Extension for feature flag macros
extension FeatureFlagMacros on CustomMacros {
  /// Load feature flags as macros
  void loadFeatureFlags(Map<String, bool> flags, Location location) {
    flags.forEach((key, value) {
      final macroName = '_FEATURE_${key.toUpperCase()}';
      if (_isValidMacroName(macroName)) {
        define(
          name: macroName,
          value: value ? '1' : '0',
          location: location,
        );
      }
    });
  }
}

/// Extension for version macros
extension VersionMacros on CustomMacros {
  /// Parse and define version-related macros
  void defineVersion(String version, Location location) {
    final parts = version.split('.');
    if (parts.length >= 2) {
      define(
        name: '_VERSION_MAJOR',
        value: parts[0],
        location: location,
      );
      define(
        name: '_VERSION_MINOR',
        value: parts[1],
        location: location,
      );
      if (parts.length >= 3) {
        define(
          name: '_VERSION_PATCH',
          value: parts[2],
          location: location,
        );
      }
      define(
        name: '_VERSION_STRING',
        value: '"$version"',
        location: location,
      );
    }
  }
}