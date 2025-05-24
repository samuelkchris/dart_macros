/// A parser that evaluates conditional expressions based on defined macro values.
///
/// The [ConditionParser] is used to evaluate conditions commonly found in
/// preprocessor directives, such as `#ifdef`, `#ifndef`, and general boolean
/// expressions. It supports:
/// * Preprocessor-style checks (`#ifdef`, `#ifndef`)
/// * Equality comparisons (`==`)
/// * Greater than or equal comparisons (`>=`)
/// * Logical AND (`&&`)
/// * Logical OR (`||`)
/// * Direct value checks
class ConditionParser {
  /// Map of defined macro names to their values.
  ///
  /// This map contains all macro definitions that can be referenced in conditions.
  final Map<String, dynamic> _defines;

  /// Creates a new [ConditionParser] with the given macro definitions.
  ///
  /// Example:
  /// ```dart
  /// final parser = ConditionParser({
  ///   'DEBUG': true,
  ///   'API_VERSION': 2,
  ///   'PLATFORM': 'android'
  /// });
  /// ```
  ConditionParser(this._defines);

  /// Evaluates a conditional expression and returns its boolean result.
  ///
  /// The condition can be any of the supported expression types:
  /// * `#ifdef SYMBOL` - checks if SYMBOL is defined
  /// * `#ifndef SYMBOL` - checks if SYMBOL is not defined
  /// * `value1 == value2` - equality comparison
  /// * `value1 >= value2` - greater than or equal comparison
  /// * `condition1 && condition2` - logical AND
  /// * `condition1 || condition2` - logical OR
  ///
  /// Example:
  /// ```dart
  /// parser.evaluate('#ifdef DEBUG'); // true if DEBUG is defined
  /// parser.evaluate('API_VERSION >= 2'); // true if API_VERSION >= 2
  /// parser.evaluate('PLATFORM == "android"'); // true if PLATFORM equals "android"
  /// ```
  ///
  /// [condition] The condition to evaluate
  /// Returns `true` if the condition evaluates to true, `false` otherwise
  bool evaluate(String condition) {
    condition = condition.trim();

    if (condition.startsWith('#ifdef ')) {
      final symbol = condition.substring(7).trim();
      return _defines.containsKey(symbol);
    }

    if (condition.startsWith('#ifndef ')) {
      final symbol = condition.substring(8).trim();
      return !_defines.containsKey(symbol);
    }

    if (condition.contains('==')) {
      final parts = condition.split('==').map((e) => e.trim()).toList();
      return _getValue(parts[0]) == _getValue(parts[1]);
    }

    if (condition.contains('>=')) {
      final parts = condition.split('>=').map((e) => e.trim()).toList();
      final left = _getValue(parts[0]);
      final right = _getValue(parts[1]);
      return (left is num && right is num) ? left >= right : false;
    }

    if (condition.contains('&&')) {
      final parts = condition.split('&&').map((e) => e.trim());
      return parts.every((part) => evaluate(part));
    }

    if (condition.contains('||')) {
      final parts = condition.split('||').map((e) => e.trim());
      return parts.any((part) => evaluate(part));
    }

    return _getValue(condition) == true;
  }

  /// Gets the value of a condition part, handling literals and macro lookups.
  ///
  /// This method:
  /// * Handles string literals (quoted strings)
  /// * Handles number literals (integers and doubles)
  /// * Looks up values in the defines map
  ///
  /// [key] The key or literal to get the value for
  /// Returns the value of the key or literal
  dynamic _getValue(String key) {
    if (key.startsWith('"') && key.endsWith('"')) {
      return key.substring(1, key.length - 1);
    }

    if (key.contains('.')) {
      return double.tryParse(key);
    }
    final intValue = int.tryParse(key);
    if (intValue != null) return intValue;

    return _defines[key];
  }
}

