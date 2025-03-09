/// Implementation of the MacrosInterface for Flutter mobile platforms (iOS/Android).
///
/// This file provides a non-reflection implementation of the Macros system
/// that works on platforms without dart:mirrors support (primarily Flutter on iOS and Android).
/// Instead of automatically scanning for annotations, this implementation requires
/// manual registration of macros through explicit API calls.
///
/// IMPORTANT: This implementation is used automatically on Flutter for iOS and Android
/// through conditional imports. Users should always use the main Macros class and
/// not interact with this implementation directly.
library;

import 'package:stack_trace/stack_trace.dart';
import '../features/predefined_macros/definitions.dart';
import 'macros_interface.dart';

/// Implementation of MacrosInterface for platforms without reflection support.
///
/// This class provides an alternative implementation of the macro system that:
/// 1. Loads predefined macros automatically
/// 2. Requires manual registration of custom macros
/// 3. Provides accurate file/line information using stack traces
/// 4. Supports both value macros and function-like macros
///
/// This implementation is used automatically on platforms without dart:mirrors
/// support (Flutter for iOS and Android). Users should always use the main
/// Macros facade class instead of working with this implementation directly.
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
  ///
  /// Unlike the mirrors-based implementation, this method does not
  /// automatically scan for annotations, as reflection is not available.
  /// Instead, macros must be registered manually using the define and
  /// registerFunctionMacro methods.
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

    // Initialize platform-specific predefined macros
    _initializePredefinedMacros();

    _initialized = true;
  }

  /// Initializes platform-specific predefined macros.
  ///
  /// This method sets up common predefined macros that would normally
  /// be determined by the system, such as platform indicators and
  /// debug flags.
  void _initializePredefinedMacros() {
    // Initialize with some default values that may be overridden later
    _values['__PLATFORM__'] = 'flutter';
    _values['DEBUG'] = false;

    // Other platform-specific values could be added here
    // These could be expanded based on what's available in Flutter
  }

  /// Defines a new macro or updates an existing one.
  ///
  /// This method allows programmatic definition of macros at runtime,
  /// which is especially important on platforms without reflection support
  /// as it's the primary way to define macros.
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
  /// This method is essential for platforms without reflection support,
  /// as it's the only way to define function-like macros.
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
      // Format the file path
      // Note: In Flutter, we can't reliably get a file path relative to project root,
      // so we use the absolute URI instead
      final file = userFrame.uri.toString();

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
  /// Returns the path of the source file from which this getter is called.
  /// On mobile platforms, this is typically a URI rather than a relative path.
  ///
  /// Returns:
  /// A string containing the source file path/URI
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
  /// explicit registration since annotation scanning is not available).
  ///
  /// Returns:
  /// true if the application is in debug mode, false otherwise
  @override
  bool get isDebug => get<bool>('DEBUG');

  /// Gets the current platform identifier.
  ///
  /// This getter relies on a '__PLATFORM__' macro being defined.
  /// For Flutter applications, this will typically be set to 'flutter'.
  ///
  /// Returns:
  /// A string identifying the platform (e.g., "flutter", "android", "ios")
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