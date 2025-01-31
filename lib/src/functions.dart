import 'macros.dart';
import 'core/exceptions.dart';
import 'core/evaluator.dart';

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
      final result =
          Macros.processMacro(name, args.map((e) => e.toString()).toList());

      if (result == null) return null;

      return ExpressionEvaluator.evaluate(result);
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
      Macros.get<bool>('FEATURE_${feature.toUpperCase()}') ?? false;

  static String _getLocationInfo() {
    final file = Macros.file;
    final line = Macros.line;
    return '[$file:$line]';
  }
}
