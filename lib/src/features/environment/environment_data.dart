import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../dart_macros.dart';
import '../../core/location.dart';
import 'package:yaml/yaml.dart';


/// Manages environment data access for macros
class EnvironmentData {
  /// Whitelist of allowed environment variables
  static const _allowedEnvVars = {
    // Build-related
    'DART_SDK_VERSION',
    'FLUTTER_ROOT',
    'PUB_CACHE',
    'PUB_HOSTED_URL',

    // Platform/architecture
    'PROCESSOR_ARCHITECTURE',
    'NUMBER_OF_PROCESSORS',

    // Common CI variables
    'CI',
    'BUILD_NUMBER',
    'BUILD_ID',
    'GITHUB_SHA',
    'GITHUB_REF',

    // Custom prefixes
    'DART_DEFINE_',
    'BUILD_',
    'APP_',
  };

  /// Cache of environment snapshots
  static final Map<String, String> _envCache = {};

  /// Get a snapshot of allowed environment variables
  static Map<String, String> getEnvironmentSnapshot() {
    // Return cached version if available
    if (_envCache.isNotEmpty) {
      return Map.unmodifiable(_envCache);
    }

    final env = Platform.environment;
    final snapshot = <String, String>{};

    // Add whitelisted environment variables
    for (final key in env.keys) {
      if (_isAllowedEnvVar(key)) {
        snapshot[key] = env[key]!;
      }
    }

    // Add build-time constants
    snapshot['DART_VERSION'] = Platform.version;
    snapshot['PLATFORM_OS'] = Platform.operatingSystem;
    snapshot['PLATFORM_VERSION'] = Platform.operatingSystemVersion;
    snapshot['PLATFORM_LOCALE'] = Platform.localeName;
    snapshot['PLATFORM_NUMBER_OF_PROCESSORS'] = Platform.numberOfProcessors.toString();

    // Cache the snapshot
    _envCache.addAll(snapshot);
    return Map.unmodifiable(snapshot);
  }

  /// Check if an environment variable is allowed
  static bool _isAllowedEnvVar(String name) {
    // Check direct matches
    if (_allowedEnvVars.contains(name)) return true;

    // Check prefixes
    return _allowedEnvVars.any((prefix) =>
    prefix.endsWith('_') && name.startsWith(prefix));
  }

  /// Get a build configuration snapshot
  static Future<Map<String, String>> getBuildConfig(Location location) async {
    final config = <String, String>{};

    // Try to load from build.yaml if it exists
    final buildConfig = await _loadBuildConfig(location);
    if (buildConfig != null) {
      config.addAll(buildConfig);
    }

    // Add Dart defines
    final dartDefines = _getDartDefines();
    config.addAll(dartDefines);

    return Map.unmodifiable(config);
  }

  /// Load build configuration from build.yaml
  static Future<Map<String, String>?> _loadBuildConfig(Location location) async {
    try {
      final projectRoot = ResourceLoader._findProjectRoot(location.file);
      final buildFile = File(path.join(projectRoot, 'build.yaml'));

      if (await buildFile.exists()) {
        final content = await buildFile.readAsString();
        final yaml = loadYaml(content) as Map?;

        if (yaml != null) {
          return _flattenMap(yaml);
        }
      }
    } catch (e) {
      // Silently fail - build config is optional
    }
    return null;
  }

  /// Get Dart defines from environment
  static Map<String, String> _getDartDefines() {
    final defines = <String, String>{};

    Platform.environment.forEach((key, value) {
      if (key.startsWith('DART_DEFINE_')) {
        defines[key.substring(12)] = value;
      }
    });

    return defines;
  }

  /// Flatten a nested map into dot-notation
  static Map<String, String> _flattenMap(Map yaml, [String prefix = '']) {
    final result = <String, String>{};

    yaml.forEach((key, value) {
      final newKey = prefix.isEmpty ? key.toString() : '$prefix.$key';

      if (value is Map) {
        result.addAll(_flattenMap(value, newKey));
      } else {
        result[newKey] = value.toString();
      }
    });

    return result;
  }
}

/// Extension for MacroProcessor to support environment data
extension EnvironmentExtension on MacroProcessor {
  /// Define environment variables as macros
  Future<void> defineEnvironmentMacros(Location location) async {
    // Get environment snapshot
    final env = EnvironmentData.getEnvironmentSnapshot();
    env.forEach((key, value) {
      define(
        name: '_ENV_$key',
        replacement: value,
        location: location,
      );
    });

    // Get build configuration
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