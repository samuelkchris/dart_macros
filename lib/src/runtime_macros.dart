import 'dart:mirrors';
import 'package:stack_trace/stack_trace.dart';

class Macro {
  final String name;
  final dynamic value;

  const Macro(this.name, this.value);
}

class Macros {
  static final Map<String, dynamic> _values = {};

  /// Initialize macros by scanning annotations
  static void initialize() {
    // Get the current mirror system
    final mirrors = currentMirrorSystem();

    // Scan all libraries
    for (var lib in mirrors.libraries.values) {
      // Look for Macro annotations
      for (var decl in lib.declarations.values) {
        _processDeclaration(decl);
      }
    }

    // Set predefined macros
    final trace = Trace.current();
    final frame = trace.frames[1]; // Get caller's frame

    _values.addAll({
      '__FILE__': frame.uri.toString(),
      '__LINE__': frame.line,
      '__FUNCTION__': frame.member,
      '__DATE__': DateTime.now().toIso8601String().split('T')[0],
      '__TIME__': DateTime.now().toIso8601String().split('T')[1].split('.')[0],
    });
  }

  static void _processDeclaration(DeclarationMirror decl) {
    for (var metadata in decl.metadata) {
      if (metadata.reflectee is Macro) {
        final macro = metadata.reflectee as Macro;
        _values[macro.name] = macro.value;
      }
    }
  }

  /// Get a macro value
  static T get<T>(String name) {
    if (_values.isEmpty) {
      initialize();
    }

    if (!_values.containsKey(name)) {
      throw StateError('Macro $name is not defined');
    }
    return _values[name] as T;
  }

  /// Predefined macros
  static String get file => get('__FILE__');

  static int get line => get('__LINE__');

  static String get date => get('__DATE__');

  static String get time => get('__TIME__');

  static String get function => get('__FUNCTION__');
}
