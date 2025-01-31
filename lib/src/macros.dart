/// Utility class for accessing macro values at runtime
class Macros {
  static final Map<String, dynamic> _values = {};

  /// Get a macro value by name
  static T get<T>(String name) {
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

  /// Internal method to set macro value (used by the build system)
  static void _define(String name, dynamic value) {
    _values[name] = value;
  }

  /// Internal method to clear all macros (used for testing)
  static void _reset() {
    _values.clear();
  }
}