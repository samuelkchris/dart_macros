import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import '../../../../../dart_macros.dart';
import '../../core/condition_parser.dart';
import '../../core/location.dart';
import '../../core/evaluator.dart';
import '../environments/environment_data.dart';

/// Built-in macro functions extension
extension MacroFunctions on Macros {
  // Math operations
  static num SQUARE(dynamic x) => _evalMacro('SQUARE', [x]) as num;

  static num CUBE(dynamic x) => _evalMacro('CUBE', [x]) as num;

  static num POW(dynamic x, dynamic n) => _evalMacro('POW', [x, n]) as num;

  // Comparison operations
  static dynamic MAX(dynamic a, dynamic b) => _evalMacro('MAX', [a, b]);

  static dynamic MIN(dynamic a, dynamic b) => _evalMacro('MIN', [a, b]);

  static dynamic CLAMP(dynamic x, dynamic low, dynamic high) =>
      _evalMacro('CLAMP', [x, low, high]);

  // String operations
  static String STRINGIFY(dynamic x) => _evalMacro('STRINGIFY', [x]).toString();

  static String CONCAT(dynamic a, dynamic b) {
    if (a == null || b == null) return '';
    return '$a$b';
  }

  static void PRINT_VAR(dynamic var_) => print(_evalMacro('PRINT_VAR', [var_]));

  // Debug operations
  static void DEBUG_PRINT(String message) {
    if (IS_DEBUG()) {
      final file = Macros.file;
      final line = Macros.line;
      print('Debug [$file:$line]: $message');
    }
  }

  static void LOG_CALL(String funcName) {
    final file = Macros.file;
    final line = Macros.line;
    print('Calling $funcName at $file:$line');
  }

  // Feature flag operations
  static bool IS_FEATURE_ENABLED(String featureFlag) =>
      Macros.get<bool>('_FEATURE_${featureFlag.toUpperCase()}') ?? false;

  // Internal evaluator
  static dynamic _evalMacro(String name, List<dynamic> args) {
    try {
      final result = ExpressionEvaluator.evaluate(name);
      return result;
    } catch (e) {
      throw MacroUsageException('Error evaluating macro $name: $e');
    }
  }

  // Debug checks
  static bool IS_DEBUG() => Macros.get<bool>('__DEBUG__') ?? false;

  // Platform checks
  static bool IS_PLATFORM(String platform) =>
      Macros.get<String>('PLATFORM') == platform;

  // API version checks
  static bool IS_V2_API() => Macros.get<int>('API_VERSION') >= 2;

  static bool IS_LEGACY_API() => Macros.get<int>('API_VERSION') < 2;

  static bool HAS_FEATURE(String feature) =>
      Macros.get<bool>('FEATURE_${feature.toUpperCase()}');

  static bool IF(String condition) {
    final defines = getAllValues();
    final parser = ConditionParser(defines);
    return parser.evaluate(condition);
  }

  static bool IFDEF(String symbol) {
    return IF('#ifdef $symbol');
  }

  static bool IFNDEF(String symbol) {
    return IF('#ifndef $symbol');
  }

  static bool IF_PLATFORM(String platform) {
    return IF('PLATFORM == "$platform"');
  }

  static bool IF_VERSION_GTE(int version) {
    return IF('API_VERSION >= $version');
  }

  // Helpers
  static Map<String, dynamic> getAllValues() {
    return Macros.getAllValues();
  }

  /// Resource operations
  static Future<String> LOAD_RESOURCE(String resourcePath) async {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );
    return ResourceLoader.loadResource(resourcePath, location);
  }

  static Future<void> LOAD_PROPERTIES(String propertiesPath) async {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );
    final content = await ResourceLoader.loadResource(propertiesPath, location);

    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        final name = parts[0].trim();
        final value = parts[1].trim();

        // Try to convert value to appropriate type
        if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
          Macros.define(name, value.toLowerCase() == 'true');
        } else if (num.tryParse(value) != null) {
          Macros.define(name, num.parse(value));
        } else {
          Macros.define(name, value);
        }
      }
    }
  }

  /// Load and define macros from a JSON file
  static Future<void> LOAD_JSON(String jsonPath) async {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );
    final content = await ResourceLoader.loadResource(jsonPath, location);

    final Map<String, dynamic> json = jsonDecode(content);
    _defineFromJson('', json);
  }

  /// Recursively define macros from a JSON/YAML map
  static void _defineFromJson(String prefix, dynamic value) {
    if (value is Map) {
      if (prefix.isNotEmpty) {
        value.forEach((key, val) {
          _defineFromJson('$prefix.$key', val);
        });
      } else {
        value.forEach((key, val) {
          _defineFromJson(key, val);
        });
      }
    } else if (value is List) {
      Macros.define(prefix, value);
    } else if (value is bool) {
      Macros.define(prefix, value);
    } else if (value is num) {
      Macros.define(prefix, value);
    } else {
      Macros.define(prefix, value.toString());
    }
  }

  /// Convert YamlMap to regular Map recursively
  static dynamic _convertYamlToMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        yaml.entries
            .map((e) => MapEntry(e.key.toString(), _convertYamlToMap(e.value))),
      );
    }
    if (yaml is YamlList) {
      return yaml.map(_convertYamlToMap).toList();
    }
    return yaml;
  }

  /// Load and define macros from a YAML file
  static Future<void> LOAD_YAML(String yamlPath) async {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );
    final content = await ResourceLoader.loadResource(yamlPath, location);

    final yamlDoc = loadYaml(content);
    final map = _convertYamlToMap(yamlDoc) as Map<String, dynamic>;
    _defineFromJson('', map); // Reuse the JSON define logic
  }

  /// Get the directory path of a resource
  static String RESOURCE_DIR(String resourcePath) {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );

    // Try to get all possible paths
    final allPaths = ResourceLoader.getAllPossiblePaths(resourcePath, location);

    // Check each path for existence
    for (final fullPath in allPaths) {
      if (FileSystemEntity.isFileSync(fullPath)) {
        return path.dirname(fullPath);
      }
    }

    // If no file exists, return the first potential location
    return path.dirname(allPaths.first);
  }

  /// Check if a resource exists in any of the possible locations
  static Future<bool> RESOURCE_EXISTS(String resourcePath) async {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );

    // Try all possible paths
    final allPaths = ResourceLoader.getAllPossiblePaths(resourcePath, location);

    // Check each path
    for (final fullPath in allPaths) {
      if (await File(fullPath).exists()) {
        // Also verify extension is allowed
        if (ResourceLoader.isAllowedExtension(fullPath)) {
          return true;
        }
      }
    }

    return false;
  }

  // static void _defineFromMap(String prefix, Map<String, dynamic> map) {
  //   map.forEach((key, value) {
  //     final macroName = prefix.isEmpty ? key : '${prefix}_$key';
  //
  //     if (value is Map) {
  //       _defineFromMap(macroName, value);
  //     } else if (value is List) {
  //       Macros.define(macroName, value);
  //     } else {
  //       Macros.define(macroName, value.toString());
  //     }
  //   });
  // }

  /// Get an environment variable value
  static String? ENV(String name) {
    final snapshot = EnvironmentData.getEnvironmentSnapshot();
    return snapshot[name];
  }

  /// Get a build configuration value
  static Future<String?> BUILD_CONFIG(String key) async {
    final location = Location(
      file: Macros.file,
      line: Macros.line,
      column: 1,
    );
    final config = await EnvironmentData.getBuildConfig(location);
    return config[key];
  }

  /// Check if running in a CI environment
  static bool IS_CI() {
    final env = EnvironmentData.getEnvironmentSnapshot();
    return env['CI'] == 'true' ||
        env.containsKey('BUILD_NUMBER') ||
        env.containsKey('GITHUB_SHA');
  }

  /// Get the current platform information
  static Map<String, String> PLATFORM_INFO() {
    final env = EnvironmentData.getEnvironmentSnapshot();
    return {
      'os': env['PLATFORM_OS']!,
      'version': env['PLATFORM_VERSION']!,
      'locale': env['PLATFORM_LOCALE']!,
      'processors': env['PLATFORM_NUMBER_OF_PROCESSORS']!,
    };
  }

  /// Get all environment variables with a specific prefix
  static Map<String, String> ENV_WITH_PREFIX(String prefix) {
    final snapshot = EnvironmentData.getEnvironmentSnapshot();
    return Map.fromEntries(
        snapshot.entries.where((e) => e.key.startsWith(prefix)));
  }
}

extension JsonMacros on Macros {
  static String TO_JSON(Map<String, dynamic> data) => jsonEncode(data);

  static Map<String, dynamic> FROM_JSON(String json) =>
      jsonDecode(json) as Map<String, dynamic>;
}

extension DataClassMacros on Macros {
  static T COPY_WITH<T>(T obj, Map<String, dynamic> updates) {
    final map = DataClassMacros.TO_MAP(obj);
    map.addAll(updates);
    return DataClassMacros.FROM_MAP<T>(map);
  }

  static Map<String, dynamic> TO_MAP(dynamic obj) {
    if (obj is Map) return Map<String, dynamic>.from(obj);
    return obj.toMap() as Map<String, dynamic>;
  }

  static T FROM_MAP<T>(Map<String, dynamic> map) {
    final type = T.toString();
    return Macros.get<T>('${type}_fromMap')!;
  }
}
