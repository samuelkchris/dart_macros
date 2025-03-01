/// A Dart package for defining and retrieving macro annotations dynamically.
///
/// This package provides the ability to define, process, and retrieve macro
/// annotations, along with a set of predefined macros (e.g., file name,
/// line number, function name, current date, and time).
///
/// # Usage
///
/// Import the package and use the `Macro` annotation and `Macros` utility.
///
/// ```dart
/// import 'your_package_name/macros.dart';
///
/// @Macro('example', 'This is a macro value')
/// void someAnnotatedFunction() {}
///
/// void main() {
///   // Initialize and retrieve macros
///   Macros.initialize();
///
///   final macroValue = Macros.get<String>('example');
///   print('Macro Value: $macroValue');
///   print('Current File: ${Macros.file}');
/// }
/// ```
library;

import 'dart:mirrors';
import 'package:stack_trace/stack_trace.dart';

/// Annotation class for macros.
///
/// Use this class to annotate code elements with macro metadata.
class Macro {
  /// The name of the macro.
  final String name;

  /// The value associated with the macro.
  final dynamic value;

  /// Creates a new macro annotation with a name and value.
  const Macro(this.name, this.value);
}

/// Utility class for macro processing.
///
/// This class provides methods to initialize, define, and retrieve macro values.
class Macros {
  /// Internal storage for macro values.
  static final Map<String, dynamic> _values = {};

  /// Initializes macros by scanning annotations in all libraries.
  ///
  /// - Retrieves and processes all annotated elements within the current mirror system.
  /// - Sets predefined macros (e.g., `__FILE__`, `__LINE__`, `__FUNCTION__`, `__DATE__`, `__TIME__`).
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

  /// Processes a single declaration to extract macro annotations.
  ///
  /// - If the declaration has a `Macro` annotation, its value is stored in `_values`.
  static void _processDeclaration(DeclarationMirror decl) {
    for (var metadata in decl.metadata) {
      if (metadata.reflectee is Macro) {
        final macro = metadata.reflectee as Macro;
        _values[macro.name] = macro.value;
      }
    }
  }

  /// Retrieves the value of a macro by its name.
  ///
  /// - If the macro system is not initialized, it initializes it automatically.
  /// - Throws `StateError` if the macro with the given name is not defined.
  ///
  /// - [name]: The name of the macro to retrieve.
  /// - Returns: The value of the macro, cast to the specified type [T].
  static T get<T>(String name) {
    if (_values.isEmpty) {
      initialize();
    }

    if (!_values.containsKey(name)) {
      throw StateError('Macro $name is not defined');
    }
    return _values[name] as T;
  }

  /// Retrieves the current file name where the macro is accessed.
  static String get file => get('__FILE__');

  /// Retrieves the current line number where the macro is accessed.
  static int get line => get('__LINE__');

  /// Retrieves the current date where the macro is accessed (in ISO format).
  static String get date => get('__DATE__');

  /// Retrieves the current time where the macro is accessed (in ISO format).
  static String get time => get('__TIME__');

  /// Retrieves the name of the function where the macro is accessed.
  static String get function => get('__FUNCTION__');
}
