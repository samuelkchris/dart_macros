import 'dart:mirrors';
import 'package:stack_trace/stack_trace.dart';
import 'package:path/path.dart' as path;
import 'features/predefined_macros/definitions.dart';
import 'annotations/annotations.dart';

class Macros {
  static final Map<String, dynamic> _values = {};
  static final Map<String, _MacroFunction> _functionMacros = {};
  static bool _initialized = false;

  /// Initialize macros immediately
  static void _initialize() {
    if (_initialized) return;

    // Initialize standard macros from definitions
    for (final entry in standardMacros.entries) {
      _functionMacros[entry.key] = _MacroFunction(
        parameters: entry.value.parameters,
        expression: entry.value.expression,
      );
    }

    // Process annotations
    final mirrors = currentMirrorSystem();
    for (var lib in mirrors.libraries.values) {
      for (var decl in lib.declarations.values) {
        _processAnnotations(decl);
      }
    }

    _initialized = true;
  }

  static void _processAnnotations(DeclarationMirror decl) {
    for (var metadata in decl.metadata) {
      final reflectee = metadata.reflectee;
      if (reflectee is Define) {
        _values[reflectee.name] = reflectee.value;
      } else if (reflectee is DefineMacro) {
        _functionMacros[reflectee.name] = _MacroFunction(
          parameters: reflectee.parameters,
          expression: reflectee.expression,
        );
      }
    }
  }

  /// Define a macro value
  static void define(String name, dynamic value) {
    _initialize();
    _values[name] = value;
  }

  /// Get all current macro values
  static Map<String, dynamic> getAllValues() {
    _initialize();
    return Map.unmodifiable(_values);
  }

  /// Update location-based macros

  static void _updateLocation() {
    final trace = Trace.current();
    Frame? userFrame;
    for (var frame in trace.frames) {
      if (!frame.library.startsWith('dart:') &&
          !frame.library.startsWith('package:dart_macros/')) {
        userFrame = frame;
        break;
      }
    }

    if (userFrame != null) {
      final file = userFrame.uri.scheme == 'file'
          ? path.relative(userFrame.uri.toFilePath())
          : userFrame.uri.toString();

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

      _values.addAll({
        '__FILE__': file,
        '__LINE__': userFrame.line,
        '__FUNCTION__': userFrame.member,
        '__DATE__': '${months[now.month - 1]} ${now.day} ${now.year}',
        '__TIME__': '${now.hour}:${now.minute}:${now.second}',
      });
    }
  }

  /// Process a function-like macro
  static String processMacro(String name, List<String> arguments) {
    _initialize();

    final macro = _functionMacros[name];
    if (macro == null) {
      throw StateError('Function-like macro $name is not defined');
    }

    if (arguments.length != macro.parameters.length) {
      throw ArgumentError(
          'Macro $name expects ${macro.parameters.length} arguments, '
          'but got ${arguments.length}');
    }

    return macro.evaluate(arguments);
  }

  /// Get a macro value
  static T get<T>(String name) {
    _initialize();
    _updateLocation();

    if (!_values.containsKey(name)) {
      throw StateError('Macro $name is not defined');
    }
    return _values[name] as T;
  }

  // Predefined macro getters
  static String get file {
    _initialize();
    _updateLocation();
    return get('__FILE__');
  }

  static int get line {
    _initialize();
    _updateLocation();
    return get('__LINE__');
  }

  static String get date {
    _initialize();
    _updateLocation();
    return get('__DATE__');
  }

  static String get time {
    _initialize();
    _updateLocation();
    return get('__TIME__');
  }

  // Environment check
  static bool get isDebug => get<bool>('DEBUG');

  static String get platform => get<String>('__PLATFORM__');
}

/// Represents a function-like macro
class _MacroFunction {
  final List<String> parameters;
  final String expression;

  _MacroFunction({
    required this.parameters,
    required this.expression,
  });

  String evaluate(List<String> arguments) {
    var result = expression;

    // Replace parameters with arguments
    for (var i = 0; i < parameters.length; i++) {
      result = result.replaceAll(
          RegExp(r'\b' + parameters[i] + r'\b'), arguments[i]);
    }

    return result;
  }
}
