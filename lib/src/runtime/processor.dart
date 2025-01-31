import 'dart:mirrors';

import '../annotations.dart';

/// Runtime macro processor
class RuntimeMacroProcessor {
  static final Map<String, dynamic> _macroValues = {};

  /// Initialize macros by scanning annotations on current isolate
  static void initialize() {
    // Get the current isolate
    final currentMirror = currentMirrorSystem();

    // Process all libraries
    for (var lib in currentMirror.libraries.values) {
      _processLibrary(lib);
    }

    // Add predefined macros
    _addPredefinedMacros();
  }

  /// Process a library for macro definitions
  static void _processLibrary(LibraryMirror library) {
    // Process all declarations in the library
    for (var declaration in library.declarations.values) {
      if (declaration is MethodMirror) {
        _processMethod(declaration);
      }
    }
  }

  /// Process a method for macro definitions
  static void _processMethod(MethodMirror method) {
    for (var metadata in method.metadata) {
      var annotation = metadata.reflectee;
      if (annotation is Define) {
        _macroValues[annotation.name] = annotation.value;
      }
    }
  }

  /// Add predefined system macros
  static void _addPredefinedMacros() {
    final now = DateTime.now();

    _macroValues['__FILE__'] = 'runtime_file'; // Will be updated on use
    _macroValues['__LINE__'] = 0; // Will be updated on use
    _macroValues['__DATE__'] = '${_getMonth(now.month)} ${now.day} ${now.year}';
    _macroValues['__TIME__'] = '${now.hour}:${now.minute}:${now.second}';
  }

  /// Get a macro value
  static T getValue<T>(String name) {
    if (!_macroValues.containsKey(name)) {
      throw StateError('Macro $name is not defined');
    }
    return _macroValues[name] as T;
  }

  /// Get month name abbreviation
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

  /// Update file and line information
  static void updateLocation(String file, int line) {
    _macroValues['__FILE__'] = file;
    _macroValues['__LINE__'] = line;
  }
}
