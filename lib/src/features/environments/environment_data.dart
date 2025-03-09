import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../../core/location.dart';
import '../../core/macro_processor.dart';
import '../resource_loading/resource_loader.dart';

/// Manages environment data access for macros and build-time configuration.
///
/// The [EnvironmentData] class provides secure, controlled access to environment
/// variables and build configuration for use in macro processing. It implements
/// a whitelist approach to environment variables and handles reading configuration
/// from build.yaml files.
///
/// This class is essential for integrating system and build environment information
/// into the macro system, allowing macros to be sensitive to the development
/// environment and build settings.
///
/// Example usage:
/// ```dart
/// final env = EnvironmentData.getEnvironmentSnapshot();
/// final buildConfig = await EnvironmentData.getBuildConfig(location);
/// ```
class EnvironmentData {
  /// Whitelist of allowed environment variables.
  ///
  /// This set contains both exact variable names and prefix patterns (ending with '_').
  /// Only variables matching these patterns will be exposed to the macro system,
  /// providing security by preventing access to sensitive environment variables.
  static const _allowedEnvVars = {
    // Exact matches:
    'DART_SDK_VERSION',
    'FLUTTER_ROOT',
    'PUB_CACHE',
    'PUB_HOSTED_URL',

    // Platform/architecture:
    'PROCESSOR_ARCHITECTURE',
    'NUMBER_OF_PROCESSORS',

    // Common CI variables:
    'CI',
    'BUILD_NUMBER',
    'BUILD_ID',
    'GITHUB_SHA',
    'GITHUB_REF',

    // Custom prefixes:
    'DART_DEFINE_',
    'BUILD_',
    'APP_',
    // You can add additional prefixes if needed:
    'CUSTOM_',
  };

  /// Cache for environment snapshots to avoid redundant computation.
  ///
  /// This cache improves performance by storing the filtered environment
  /// snapshot after it's first created, avoiding repeated processing.
  static final Map<String, String> _envCache = {};

  /// Retrieves a snapshot of allowed environment variables.
  ///
  /// This method provides a filtered view of the environment, including only
  /// variables that match the whitelist in [_allowedEnvVars]. It also adds
  /// platform information as additional variables.
  ///
  /// If a cached version is available, it returns that. Otherwise, it filters
  /// [Platform.environment] based on [_allowedEnvVars], adds build-time
  /// constants, caches the result, and returns it.
  ///
  /// Returns:
  /// An unmodifiable map containing allowed environment variables and platform information
  static Map<String, String> getEnvironmentSnapshot() {
    /* Return cached version if available */
    if (_envCache.isNotEmpty) {
      return Map.unmodifiable(_envCache);
    }

    final env = Platform.environment;
    final snapshot = <String, String>{};

    /* Add whitelisted environment variables (exact match or prefix) */
    for (final key in env.keys) {
      if (_isAllowedEnvVar(key)) {
        snapshot[key] = env[key]!;
      }
    }

    /* Add build-time constants from Platform */
    snapshot['DART_VERSION'] = Platform.version;
    snapshot['PLATFORM_OS'] = Platform.operatingSystem;
    snapshot['PLATFORM_VERSION'] = Platform.operatingSystemVersion;
    snapshot['PLATFORM_LOCALE'] = Platform.localeName;
    snapshot['PLATFORM_NUMBER_OF_PROCESSORS'] =
        Platform.numberOfProcessors.toString();

    /* Cache and return the result */
    _envCache.addAll(snapshot);
    return Map.unmodifiable(snapshot);
  }

  /// Checks if a given environment variable [name] is allowed.
  ///
  /// Variables are allowed if they exactly match a name in [_allowedEnvVars]
  /// or if they start with any prefix in [_allowedEnvVars] that ends with
  /// an underscore.
  ///
  /// Parameters:
  /// - [name]: The environment variable name to check
  ///
  /// Returns:
  /// `true` if the variable is allowed, `false` otherwise
  static bool _isAllowedEnvVar(String name) {
    /* Direct match check */
    if (_allowedEnvVars.contains(name)) return true;

    /* Check for allowed prefixes */
    return _allowedEnvVars.any(
          (prefix) => prefix.endsWith('_') && name.startsWith(prefix),
    );
  }

  /// Retrieves the build configuration snapshot by merging data from
  /// build.yaml and Dart defines.
  ///
  /// This method:
  /// 1. Attempts to load configuration from build.yaml if available
  /// 2. Extracts Dart defines from environment variables
  /// 3. Merges these two sources into a single configuration map
  ///
  /// Parameters:
  /// - [location]: The source location for error reporting and file resolution
  ///
  /// Returns:
  /// An unmodifiable map containing the merged build configuration
  static Future<Map<String, String>> getBuildConfig(Location location) async {
    final config = <String, String>{};

    /* Load configuration from build.yaml (if available) */
    final buildConfig = await _loadBuildConfig(location);
    if (buildConfig != null) {
      config.addAll(buildConfig);
    }

    /* Merge Dart defines from the environment */
    final dartDefines = _getDartDefines();
    config.addAll(dartDefines);

    return Map.unmodifiable(config);
  }

  /// Attempts to load build configuration from a build.yaml file located
  /// at the project root.
  ///
  /// This method:
  /// 1. Finds the project root directory
  /// 2. Locates and reads the build.yaml file if it exists
  /// 3. Parses the YAML content and flattens it into a string map
  ///
  /// Parameters:
  /// - [location]: The source location for resolving the project root
  ///
  /// Returns:
  /// A flattened map of the build configuration, or null if the file doesn't exist
  static Future<Map<String, String>?> _loadBuildConfig(Location location) async {
    try {
      /* Find project root and build file */
      final projectRoot = ResourceLoader.findProjectRoot(location.file);
      final buildFile = File(path.join(projectRoot, 'build.yaml'));

      /* Read and parse the build file if it exists */
      if (await buildFile.exists()) {
        final content = await buildFile.readAsString();
        final yaml = loadYaml(content) as Map?;
        if (yaml != null) {
          return _flattenMap(yaml);
        }
      }
    } catch (e) {
      /* Silently fail: build configuration is optional */
    }
    return null;
  }

  /// Extracts Dart defines from the environment that start with 'DART_DEFINE_'.
  ///
  /// This method processes environment variables with the DART_DEFINE_ prefix,
  /// which is commonly used with the --dart-define flag in build systems.
  ///
  /// Returns:
  /// A map where the prefix 'DART_DEFINE_' is removed from the key
  static Map<String, String> _getDartDefines() {
    final defines = <String, String>{};
    Platform.environment.forEach((key, value) {
      if (key.startsWith('DART_DEFINE_')) {
        defines[key.substring(12)] = value;
      }
    });
    return defines;
  }

  /// Flattens a nested YAML [Map] into dot-notation.
  ///
  /// This method converts a hierarchical map structure (common in YAML)
  /// into a flat map where nested keys are represented with dot notation.
  ///
  /// For example: `{a: {b: c}}` becomes `{'a.b': 'c'}`
  ///
  /// Parameters:
  /// - [yaml]: The nested map to flatten
  /// - [prefix]: An optional prefix for recursive calls
  ///
  /// Returns:
  /// A flattened string map with dot-notation keys
  static Map<String, String> _flattenMap(Map yaml, [String prefix = '']) {
    final result = <String, String>{};

    yaml.forEach((key, value) {
      final newKey =
      prefix.isEmpty ? key.toString() : '$prefix.$key';

      if (value is Map) {
        /* Recurse for nested maps */
        result.addAll(_flattenMap(value, newKey));
      } else {
        /* Add leaf nodes */
        result[newKey] = value.toString();
      }
    });

    return result;
  }
}

/// Extension for [MacroProcessor] to integrate environment data
/// as compile-time macros.
///
/// This extension allows the macro processor to define macros based on
/// environment variables and build configuration, making this information
/// accessible within the macro system.
extension EnvironmentExtension on MacroProcessor {
  /// Defines environment and build configuration variables as macros.
  ///
  /// This method:
  /// 1. Gets allowed environment variables and defines them as _ENV_* macros
  /// 2. Gets build configuration values and defines them as _BUILD_* macros
  ///
  /// Parameters:
  /// - [location]: The source location for error reporting and file resolution
  ///
  /// Returns:
  /// A Future that completes when all macros have been defined
  Future<void> defineEnvironmentMacros(Location location) async {
    /* Define environment variables as macros */
    final env = EnvironmentData.getEnvironmentSnapshot();
    env.forEach((key, value) {
      define(
        name: '_ENV_$key',
        replacement: value,
        location: location,
      );
    });

    /* Define build configuration variables as macros */
    final buildConfig = await EnvironmentData.getBuildConfig(location);
    buildConfig.forEach((key, value) {
      define(
        name: '_BUILD_$key',
        replacement: value,
        location: location,
      );
    });
  }
}