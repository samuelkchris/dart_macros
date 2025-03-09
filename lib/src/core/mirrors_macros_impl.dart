/// Implementation of the MacrosInterface using dart:mirrors for VM and web platforms.
///
/// This file provides the reflection-based implementation of the Macros system,
/// which scans for macro annotations at runtime. This implementation is used
/// on platforms that support the dart:mirrors library (primarily Dart VM and web).
///
/// IMPORTANT: This implementation cannot be used on Flutter for iOS or Android,
/// as those platforms do not support dart:mirrors. For those platforms, the
/// mobile_macros_impl.dart implementation is used instead.
library;

import 'dart:mirrors';
import 'package:stack_trace/stack_trace.dart';
import 'package:path/path.dart' as path;

import '../features/predefined_macros/definitions.dart';
import '../annotations/annotations.dart';
import 'macros_interface.dart';

/// Implementation of MacrosInterface using dart:mirrors for reflection-based macro processing.
///
/// This class provides a complete implementation of the macro system that:
/// 1. Detects macro annotations at runtime using reflection
/// 2. Provides accurate file/line information using stack traces
/// 3. Supports both value macros and function-like macros
///
/// Example:
/// ```dart
/// // This class never needs to be instantiated directly by users
/// // Instead, use the Macros facade class
/// ```
class MacrosImplementation implements MacrosInterface {
  /// Storage for all macro values.
  ///
  /// Maps macro names to their values, which can be of any type
  /// (String, num, bool, etc.) depending on the macro definition.
  static final Map<String, dynamic> _values = {};

  /// Storage for function-like macros.
  ///
  /// Maps macro names to their function definitions, which include
  /// parameters and expression templates.
  static final Map<String, _MacroFunction> _functionMacros = {};

  /// Tracks whether the macro system has been initialized.
  static bool _initialized = false;

  /// Initializes the macro system if it hasn't been already.
  ///
  /// This method ensures macros are initialized exactly once by:
  /// 1. Checking if initialization has already occurred
  /// 2. Loading standard macros from definitions
  /// 3. Processing macro annotations via reflection
  ///
  /// This is called automatically when accessing macros, so manual
  /// initialization is typically not required.
  @override
  void initialize() {
    if (_initialized) return;

    // Initialize standard macros from predefined definitions
    for (final entry in standardMacros.entries) {
      _functionMacros[entry.key] = _MacroFunction(
        parameters: entry.value.parameters,
        expression: entry.value.expression,
      );
    }

    // Process annotations using reflection
    final mirrors = currentMirrorSystem();
    for (var lib in mirrors.libraries.values) {
      for (var decl in lib.declarations.values) {
        _processAnnotations(decl);
      }
    }

    _initialized = true;
  }

  /// Processes macro annotations on a declaration.
  ///
  /// Examines the declaration's metadata for macro annotations and registers
  /// any found macros in the appropriate storage.
  ///
  /// Parameters:
  /// - [decl]: The declaration mirror to process for macro annotations
  void _processAnnotations(DeclarationMirror decl) {
    for (var metadata in decl.metadata) {
      final reflectee = metadata.reflectee;

      // Handle @Define annotations for value macros
      if (reflectee is Define) {
        _values[reflectee.name] = reflectee.value;
      }
      // Handle @DefineMacro annotations for function-like macros
      else if (reflectee is DefineMacro) {
        _functionMacros[reflectee.name] = _MacroFunction(
          parameters: reflectee.parameters,
          expression: reflectee.expression,
        );
      }
    }
  }

  /// Defines a new macro or updates an existing one.
  ///
  /// This method allows programmatic definition of macros at runtime,
  /// which can be useful for dynamically configuring your application.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to define
  /// - [value]: The value to associate with the macro
  @override
  void define(String name, dynamic value) {
    initialize();
    _values[name] = value;
  }

  /// Registers a new function-like macro.
  ///
  /// This method is primarily used for platforms that don't support
  /// annotation scanning through reflection.
  ///
  /// Parameters:
  /// - [name]: The name of the function-like macro
  /// - [parameters]: List of parameter names the macro accepts
  /// - [expression]: The template expression that will be expanded
  void registerFunctionMacro(String name, List<String> parameters, String expression) {
    initialize();
    _functionMacros[name] = _MacroFunction(
      parameters: parameters,
      expression: expression,
    );
  }

  /// Gets a map of all currently defined macro values.
  ///
  /// This method provides access to all defined macro values for
  /// inspection or processing. The returned map is unmodifiable
  /// to prevent accidental modification of the macro registry.
  ///
  /// Returns:
  /// An unmodifiable map containing all macro names and their values
  @override
  Map<String, dynamic> getAllValues() {
    initialize();
    return Map.unmodifiable(_values);
  }

  /// Updates location-based macros based on the current call stack.
  ///
  /// This method:
  /// 1. Examines the current call stack to find the user code frame
  /// 2. Extracts file path, line number, and function name information
  /// 3. Updates __FILE__, __LINE__, __FUNCTION__, and time-based macros
  ///
  /// This is called automatically when accessing macros to ensure
  /// location-dependent macros are accurate.
  void _updateLocation() {
    final trace = Trace.current();
    Frame? userFrame;

    // Find the first non-library frame in the call stack
    for (var frame in trace.frames) {
      if (!frame.library.startsWith('dart:') &&
          !frame.library.startsWith('package:dart_macros/')) {
        userFrame = frame;
        break;
      }
    }

    if (userFrame != null) {
      // Format the file path for better readability
      final file = userFrame.uri.scheme == 'file'
          ? path.relative(userFrame.uri.toFilePath())
          : userFrame.uri.toString();

      // Get current timestamp information
      final now = DateTime.now();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      // Update all location-based and time-based macros
      _values.addAll({
        '__FILE__': file,
        '__LINE__': userFrame.line,
        '__FUNCTION__': userFrame.member,
        '__DATE__': '${months[now.month - 1]} ${now.day} ${now.year}',
        '__TIME__': '${now.hour}:${now.minute}:${now.second}',
      });
    }
  }

  /// Processes a function-like macro with arguments.
  ///
  /// This method evaluates a function-like macro by substituting the
  /// provided arguments into the macro's expression template.
  ///
  /// Parameters:
  /// - [name]: The name of the function-like macro to process
  /// - [arguments]: The list of arguments to pass to the macro
  ///
  /// Returns:
  /// The result of the macro expansion as a string
  ///
  /// Throws:
  /// - StateError: If the specified macro is not defined
  /// - ArgumentError: If the wrong number of arguments is provided
  @override
  String processMacro(String name, List<String> arguments) {
    initialize();

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

  /// Gets the value of a macro with the specified type.
  ///
  /// This is the primary method for accessing macro values. It ensures
  /// the macro system is initialized and location-based macros are updated
  /// before retrieving the requested value.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to retrieve
  ///
  /// Returns:
  /// The value of the macro cast to type T
  ///
  /// Throws:
  /// - StateError: If the macro with the specified name is not defined
  /// - TypeError: If the macro's value cannot be cast to type T
  @override
  T get<T>(String name) {
    initialize();
    _updateLocation();

    if (!_values.containsKey(name)) {
      throw StateError('Macro $name is not defined');
    }
    return _values[name] as T;
  }

  /// Gets the current source file path.
  ///
  /// Returns the path of the source file from which this getter is called,
  /// relative to the project root if possible.
  ///
  /// Returns:
  /// A string containing the source file path
  @override
  String get file {
    initialize();
    _updateLocation();
    return get('__FILE__');
  }

  /// Gets the current line number.
  ///
  /// Returns the line number from which this getter is called.
  ///
  /// Returns:
  /// An integer representing the line number
  @override
  int get line {
    initialize();
    _updateLocation();
    return get('__LINE__');
  }

  /// Gets the current date.
  ///
  /// Returns the date in the format "MMM DD YYYY" (e.g., "Jan 01 2025").
  ///
  /// Returns:
  /// A string containing the formatted date
  @override
  String get date {
    initialize();
    _updateLocation();
    return get('__DATE__');
  }

  /// Gets the current time.
  ///
  /// Returns the time in the format "HH:MM:SS" (e.g., "12:30:45").
  ///
  /// Returns:
  /// A string containing the formatted time
  @override
  String get time {
    initialize();
    _updateLocation();
    return get('__TIME__');
  }

  /// Checks if the application is in debug mode.
  ///
  /// This getter relies on a 'DEBUG' macro being defined (usually via
  /// a @Define annotation or build configuration).
  ///
  /// Returns:
  /// true if the application is in debug mode, false otherwise
  @override
  bool get isDebug => get<bool>('DEBUG');

  /// Gets the current platform identifier.
  ///
  /// This getter relies on a '__PLATFORM__' macro being defined
  /// (usually set automatically by the system macros).
  ///
  /// Returns:
  /// A string identifying the platform (e.g., "android", "ios", "web")
  @override
  String get platform => get<String>('__PLATFORM__');
}

/// Represents a function-like macro with parameters and an expression template.
///
/// The [_MacroFunction] class is responsible for storing the definition of
/// a function-like macro and evaluating it with provided arguments.
class _MacroFunction {
  /// The list of parameter names for the macro.
  ///
  /// These names will be replaced with the actual arguments when
  /// the macro is evaluated.
  final List<String> parameters;

  /// The expression template for the macro.
  ///
  /// This template contains parameter names that will be replaced
  /// with actual arguments during evaluation.
  final String expression;

  /// Creates a new function-like macro definition.
  ///
  /// Parameters:
  /// - [parameters]: The list of parameter names
  /// - [expression]: The expression template
  _MacroFunction({
    required this.parameters,
    required this.expression,
  });

  /// Evaluates the macro by substituting arguments into the expression.
  ///
  /// This method replaces each parameter in the expression template
  /// with the corresponding argument provided.
  ///
  /// Parameters:
  /// - [arguments]: The list of argument values to substitute
  ///
  /// Returns:
  /// The resulting expression after parameter substitution
  String evaluate(List<String> arguments) {
    var result = expression;

    // Replace each parameter with its corresponding argument
    for (var i = 0; i < parameters.length; i++) {
      result = result.replaceAll(
          RegExp(r'\b' + parameters[i] + r'\b'), arguments[i]);
    }

    return result;
  }
}