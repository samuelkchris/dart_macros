import 'dart:io';

import '../../core/exceptions.dart';
import '../../core/location.dart';
import '../../core/macro_definition.dart';

/// Manages user-defined predefined macros.
///
/// The [CustomMacros] class provides facilities for defining, managing, and
/// validating custom predefined macros. These macros follow specific naming
/// conventions and can come from various sources including environment
/// variables, build configuration, feature flags, and version information.
///
/// This class forms a key part of the extensibility of the macro system,
/// allowing additional macros to be defined beyond the system defaults.
///
/// Example usage:
/// ```dart
/// final customMacros = CustomMacros();
/// customMacros.define(
///   name: '_MY_MACRO',
///   value: 'my value',
///   location: location,
/// );
/// ```
class CustomMacros {
  /// Storage for custom predefined macro definitions.
  ///
  /// Maps macro names to their definitions, which include replacement
  /// text and metadata.
  final Map<String, MacroDefinition> _customMacros = {};

  /// Defines a new custom predefined macro.
  ///
  /// Creates a new macro with the specified name and value, validating
  /// that the name follows the required convention (must start with underscore).
  ///
  /// Parameters:
  /// - [name]: The name of the macro to define (must start with underscore)
  /// - [value]: The replacement text for the macro
  /// - [location]: The source location for error reporting
  ///
  /// Throws:
  /// - [MacroDefinitionException] if the macro name is invalid
  void define({
    required String name,
    required String value,
    required Location location,
  }) {
    /* Validate macro name */
    if (!_isValidMacroName(name)) {
      throw MacroDefinitionException(
        'Invalid custom macro name: $name. Must start with underscore.',
        location,
      );
    }

    /* Create macro definition */
    _customMacros[name] = MacroDefinition(
      name: name,
      replacement: value,
      type: MacroType.predefined,
      location: location,
    );
  }

  /// Defines multiple custom macros at once.
  ///
  /// Convenience method to define several macros in a single operation.
  ///
  /// Parameters:
  /// - [macros]: Map of macro names to their values
  /// - [location]: The source location for error reporting
  void defineAll(Map<String, String> macros, Location location) {
    macros.forEach((name, value) {
      define(name: name, value: value, location: location);
    });
  }

  /// Gets all custom predefined macros.
  ///
  /// Returns an unmodifiable view of the custom macro definitions.
  ///
  /// Returns:
  /// An unmodifiable map of macro names to their definitions
  Map<String, MacroDefinition> getCustomMacros() {
    return Map.unmodifiable(_customMacros);
  }

  /// Checks if a custom macro is defined.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to check
  ///
  /// Returns:
  /// true if the macro is defined, false otherwise
  bool isDefined(String name) => _customMacros.containsKey(name);

  /// Undefines a custom macro.
  ///
  /// Removes a previously defined custom macro.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to undefine
  void undefine(String name) {
    _customMacros.remove(name);
  }

  /// Clears all custom macros.
  ///
  /// Removes all custom macro definitions.
  void clear() {
    _customMacros.clear();
  }

  /// Gets a specific custom macro definition.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to retrieve
  ///
  /// Returns:
  /// The macro definition, or null if not defined
  MacroDefinition? getMacro(String name) => _customMacros[name];

  /// Validates a custom macro name.
  ///
  /// Custom predefined macros must start with underscore and
  /// follow standard identifier naming rules.
  ///
  /// Parameters:
  /// - [name]: The macro name to validate
  ///
  /// Returns:
  /// true if the name is valid, false otherwise
  bool _isValidMacroName(String name) {
    // Custom predefined macros must start with underscore
    return name.startsWith('_') &&
        RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name);
  }
}

/// Extension for environment variable macros.
///
/// This extension adds the ability to define macros based on
/// environment variables, prefixed with '_ENV_'.
extension EnvironmentMacros on CustomMacros {
  /// Loads environment variables as macros.
  ///
  /// Creates macros for each environment variable, with names
  /// of the form '_ENV_VARIABLE_NAME'.
  ///
  /// Parameters:
  /// - [location]: The source location for error reporting
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

/// Extension for build configuration macros.
///
/// This extension adds the ability to define macros based on
/// build configuration, prefixed with '_CONFIG_'.
extension BuildConfigMacros on CustomMacros {
  /// Loads build configuration as macros.
  ///
  /// Creates macros for each configuration value, with names
  /// of the form '_CONFIG_KEY'. Handles nested configurations
  /// by flattening with underscores.
  ///
  /// Parameters:
  /// - [config]: The build configuration map
  /// - [location]: The source location for error reporting
  void loadBuildConfig(Map<String, dynamic> config, Location location) {
    /* Recursive helper to process nested configuration */
    void processValue(String prefix, dynamic value) {
      if (value is Map) {
        /* Process nested maps recursively */
        value.forEach((key, val) {
          processValue('${prefix}_${key.toString().toUpperCase()}', val);
        });
      } else {
        /* Define leaf node as macro */
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

    /* Process the configuration */
    config.forEach((key, value) {
      processValue(key.toUpperCase(), value);
    });
  }
}

/// Extension for feature flag macros.
///
/// This extension adds the ability to define macros based on
/// feature flags, prefixed with '_FEATURE_'.
extension FeatureFlagMacros on CustomMacros {
  /// Loads feature flags as macros.
  ///
  /// Creates macros for each feature flag, with names of
  /// the form '_FEATURE_FLAG_NAME' and values of '1' for
  /// true and '0' for false.
  ///
  /// Parameters:
  /// - [flags]: Map of feature flag names to boolean values
  /// - [location]: The source location for error reporting
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

/// Extension for version macros.
///
/// This extension adds the ability to define macros based on
/// semantic version information.
extension VersionMacros on CustomMacros {
  /// Parses and defines version-related macros.
  ///
  /// Given a semantic version string (e.g., "1.2.3"), defines
  /// macros for major, minor, patch, and full version.
  ///
  /// Parameters:
  /// - [version]: The version string in semantic versioning format
  /// - [location]: The source location for error reporting
  void defineVersion(String version, Location location) {
    final parts = version.split('.');
    if (parts.length >= 2) {
      /* Define major version */
      define(
        name: '_VERSION_MAJOR',
        value: parts[0],
        location: location,
      );

      /* Define minor version */
      define(
        name: '_VERSION_MINOR',
        value: parts[1],
        location: location,
      );

      /* Define patch version if available */
      if (parts.length >= 3) {
        define(
          name: '_VERSION_PATCH',
          value: parts[2],
          location: location,
        );
      }

      /* Define full version string */
      define(
        name: '_VERSION_STRING',
        value: '"$version"',
        location: location,
      );
    }
  }
}