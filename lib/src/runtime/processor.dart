import 'dart:mirrors';

import '../annotations/annotations.dart';

/// Runtime processor for macro discovery and evaluation.
///
/// The [RuntimeMacroProcessor] provides a reflection-based implementation for
/// discovering and initializing macros at runtime. It scans all libraries in the
/// current isolate for macro annotations and makes them available for use.
///
/// Note: This implementation uses dart:mirrors, which is not supported on
/// Flutter for iOS and Android. For mobile platform support, an alternative
/// implementation that uses code generation instead of runtime reflection
/// should be used. See [CodeGenMacroProcessor] for a build-time alternative.
///
/// Example usage (desktop/web only):
/// ```dart
/// void main() {
///   RuntimeMacroProcessor.initialize();
///   final value = RuntimeMacroProcessor.getValue<String>('VERSION');
///   print('Version: $value');
/// }
/// ```
class RuntimeMacroProcessor {
  /// Storage for all macro values discovered or defined at runtime.
  ///
  /// The keys are macro names and values are the corresponding macro values.
  /// Values can be of any type (String, num, bool, etc.) depending on the
  /// macro definition.
  static final Map<String, dynamic> _macroValues = {};

  /// Initializes the macro system by scanning all libraries for macro annotations.
  ///
  /// This method:
  /// 1. Gets the current isolate's mirror system
  /// 2. Processes all available libraries for macro definitions
  /// 3. Adds predefined system macros like __FILE__, __LINE__, etc.
  ///
  /// This should be called early in your application's lifecycle to ensure
  /// all macros are available when needed.
  ///
  /// Note: This method uses reflection and is not compatible with Flutter
  /// on iOS or Android. Consider using the code generation approach for
  /// those platforms.
  static void initialize() {
    /* Get the current isolate */
    final currentMirror = currentMirrorSystem();

    /* Process all libraries in the current isolate */
    for (var lib in currentMirror.libraries.values) {
      _processLibrary(lib);
    }

    /* Initialize predefined system macros */
    _addPredefinedMacros();
  }

  /// Processes a library to find macro definitions.
  ///
  /// Scans all declarations in the provided library and processes any
  /// that contain macro annotations.
  ///
  /// Parameters:
  /// - [library]: The library mirror to process
  static void _processLibrary(LibraryMirror library) {
    /* Process all declarations in the library */
    for (var declaration in library.declarations.values) {
      if (declaration is MethodMirror) {
        _processMethod(declaration);
      }
    }
  }

  /// Processes a method to find macro definitions from annotations.
  ///
  /// Examines the method's metadata for [Define] annotations and
  /// registers any found macros in the [_macroValues] map.
  ///
  /// Parameters:
  /// - [method]: The method mirror to process
  static void _processMethod(MethodMirror method) {
    /* Check each annotation on the method */
    for (var metadata in method.metadata) {
      var annotation = metadata.reflectee;

      /* If it's a Define annotation, register the macro */
      if (annotation is Define) {
        _macroValues[annotation.name] = annotation.value;
      }
    }
  }

  /// Adds predefined system macros to the macro registry.
  ///
  /// This initializes standard system macros such as:
  /// - __FILE__: Current source file (updated on use)
  /// - __LINE__: Current line number (updated on use)
  /// - __DATE__: Compilation date
  /// - __TIME__: Compilation time
  static void _addPredefinedMacros() {
    final now = DateTime.now();

    /* Initialize with placeholder values for location-dependent macros */
    _macroValues['__FILE__'] = 'runtime_file'; // Will be updated on use
    _macroValues['__LINE__'] = 0; // Will be updated on use

    /* Initialize time-based macros */
    _macroValues['__DATE__'] = '${_getMonth(now.month)} ${now.day} ${now.year}';
    _macroValues['__TIME__'] = '${now.hour}:${now.minute}:${now.second}';
  }

  /// Retrieves a macro value with the specified type.
  ///
  /// This method returns the value of the macro with the specified name,
  /// cast to the requested type. If the macro doesn't exist, it throws
  /// a StateError.
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
  static T getValue<T>(String name) {
    if (!_macroValues.containsKey(name)) {
      throw StateError('Macro $name is not defined');
    }
    return _macroValues[name] as T;
  }

  /// Gets the abbreviated name of a month.
  ///
  /// Converts a month number (1-12) to its three-letter abbreviation.
  ///
  /// Parameters:
  /// - [month]: The month number (1-12)
  ///
  /// Returns:
  /// A three-letter abbreviation of the month name (e.g., 'Jan', 'Feb', etc.)
  static String _getMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  /// Updates the file and line information for location-dependent macros.
  ///
  /// This updates the values of the __FILE__ and __LINE__ macros to reflect
  /// the current source location. This is typically called automatically
  /// when macro values are accessed.
  ///
  /// Parameters:
  /// - [file]: The current source file path
  /// - [line]: The current line number
  static void updateLocation(String file, int line) {
    _macroValues['__FILE__'] = file;
    _macroValues['__LINE__'] = line;
  }
}