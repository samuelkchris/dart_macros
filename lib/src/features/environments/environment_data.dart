import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../../core/location.dart';
import '../../core/macro_processor.dart';
import '../resource_loading/resource_loader.dart';

/// Manages environment data access for macros and build-time configuration.
class EnvironmentData {
  /// Whitelist of allowed environment variables.
  /// You can also allow variables with specific prefixes.
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
  static final Map<String, String> _envCache = {};

  /// Retrieves a snapshot of allowed environment variables.
  ///
  /// If a cached version is available, it returns that. Otherwise,
  /// it filters [Platform.environment] based on [_allowedEnvVars],
  /// adds build-time constants, caches, and returns the result.
  static Map<String, String> getEnvironmentSnapshot() {
    if (_envCache.isNotEmpty) {
      return Map.unmodifiable(_envCache);
    }

    final env = Platform.environment;
    final snapshot = <String, String>{};

    // Add whitelisted environment variables (exact match or prefix)
    for (final key in env.keys) {
      if (_isAllowedEnvVar(key)) {
        snapshot[key] = env[key]!;
      }
    }

    // Add build-time constants from Platform.
    snapshot['DART_VERSION'] = Platform.version;
    snapshot['PLATFORM_OS'] = Platform.operatingSystem;
    snapshot['PLATFORM_VERSION'] = Platform.operatingSystemVersion;
    snapshot['PLATFORM_LOCALE'] = Platform.localeName;
    snapshot['PLATFORM_NUMBER_OF_PROCESSORS'] =
        Platform.numberOfProcessors.toString();

    _envCache.addAll(snapshot);
    return Map.unmodifiable(snapshot);
  }

  /// Checks if a given environment variable [name] is allowed.
  ///
  /// Returns `true` if the variable matches an exact name in [_allowedEnvVars]
  /// or if it starts with any prefix that ends with an underscore.
  static bool _isAllowedEnvVar(String name) {
    // Direct match check.
    if (_allowedEnvVars.contains(name)) return true;

    // Check for allowed prefixes.
    return _allowedEnvVars.any(
          (prefix) => prefix.endsWith('_') && name.startsWith(prefix),
    );
  }

  /// Retrieves the build configuration snapshot by merging data from
  /// build.yaml and Dart defines.
  static Future<Map<String, String>> getBuildConfig(Location location) async {
    final config = <String, String>{};

    // Load configuration from build.yaml (if available)
    final buildConfig = await _loadBuildConfig(location);
    if (buildConfig != null) {
      config.addAll(buildConfig);
    }

    // Merge Dart defines from the environment.
    final dartDefines = _getDartDefines();
    config.addAll(dartDefines);

    return Map.unmodifiable(config);
  }

  /// Attempts to load build configuration from a build.yaml file located
  /// at the project root. Returns a flattened map if found, or null otherwise.
  static Future<Map<String, String>?> _loadBuildConfig(Location location) async {
    try {
      final projectRoot = ResourceLoader.findProjectRoot(location.file);
      final buildFile = File(path.join(projectRoot, 'build.yaml'));

      if (await buildFile.exists()) {
        final content = await buildFile.readAsString();
        final yaml = loadYaml(content) as Map?;
        if (yaml != null) {
          return _flattenMap(yaml);
        }
      }
    } catch (e) {
      // Silently fail: build configuration is optional.
    }
    return null;
  }

  /// Extracts Dart defines from the environment that start with 'DART_DEFINE_'.
  ///
  /// Returns a map where the prefix 'DART_DEFINE_' is removed from the key.
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
  /// For example: `{a: {b: c}}` becomes `{'a.b': 'c'}`.
  /// An optional [prefix] can be provided for recursive calls.
  static Map<String, String> _flattenMap(Map yaml, [String prefix = '']) {
    final result = <String, String>{};

    yaml.forEach((key, value) {
      final newKey =
      prefix.isEmpty ? key.toString() : '$prefix.$key';
      if (value is Map) {
        result.addAll(_flattenMap(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });

    return result;
  }
}

/// Extension for [MacroProcessor] to integrate environment data
/// as compile-time macros.
extension EnvironmentExtension on MacroProcessor {
  /// Defines environment and build configuration variables as macros.
  ///
  /// For each allowed environment variable, a macro is defined with the name
  /// `_ENV_$key` and for each build configuration value with `_BUILD_$key`.
  Future<void> defineEnvironmentMacros(Location location) async {
    // Define environment variables as macros.
    final env = EnvironmentData.getEnvironmentSnapshot();
    env.forEach((key, value) {
      define(
        name: '_ENV_$key',
        replacement: value,
        location: location,
      );
    });

    // Define build configuration variables as macros.
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
