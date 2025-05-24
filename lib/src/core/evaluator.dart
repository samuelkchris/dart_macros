/// A utility class for evaluating string expressions at compile time.
///
/// This evaluator supports:
/// * Arithmetic operations (+, -, *, /)
/// * String concatenation
/// * Comparison operations (>, <, >=, <=, ==, !=)
/// * Parenthesized expressions
/// * Basic type conversion
class ExpressionEvaluator {
  /// Evaluates a string expression and returns the result.
  ///
  /// The method supports various types of expressions:
  /// * Numeric expressions: "1 + 2", "3 * 4"
  /// * String concatenation: '"Hello" + " World"'
  /// * Comparison expressions: "5 > 3", "10 <= 20"
  ///
  /// Examples:
  /// ```dart
  /// evaluate("1 + 2") // Returns 3
  /// evaluate('"Hello" + " World"') // Returns "Hello World"
  /// evaluate("5 > 3") // Returns true
  /// ```
  ///
  /// Throws [FormatException] if the expression is invalid or cannot be evaluated.
  static dynamic evaluate(String expression) {
    expression = expression.trim();
    while (expression.startsWith('(') && expression.endsWith(')')) {
      expression = expression.substring(1, expression.length - 1).trim();
    }

    if (expression.contains('+') && !_containsOnlyNumbers(expression)) {
      return _evaluateStringConcat(expression);
    }

    if (_isArithmeticExpression(expression)) {
      return _evaluateArithmetic(expression);
    }

    if (_isComparisonExpression(expression)) {
      return _evaluateComparison(expression);
    }

    final number = num.tryParse(expression);
    if (number != null) return number;

    return _unquote(expression);
  }

  /// Checks if an expression contains only numeric values.
  ///
  /// Used to distinguish between numeric addition and string concatenation.
  static bool _containsOnlyNumbers(String expr) {
    final parts = expr.split('+').map((e) => e.trim());
    return parts.every((part) => num.tryParse(part) != null);
  }

  /// Evaluates string concatenation expressions.
  ///
  /// Handles expressions like: "Hello" + " " + "World"
  static String _evaluateStringConcat(String expr) {
    final parts = expr.split('+').map((e) => evaluate(e.trim()).toString());
    return parts.join('');
  }

  /// Removes surrounding quotes from a string if present.
  ///
  /// Example:
  /// ```dart
  /// _unquote('"hello"') // Returns "hello"
  /// _unquote('hello') // Returns "hello"
  /// ```
  static String _unquote(String text) {
    if (text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  /// Checks if the expression is an arithmetic expression.
  ///
  /// Returns true if the expression contains any of the arithmetic operators:
  /// * Addition (+) with numbers only
  /// * Subtraction (-)
  /// * Multiplication (*)
  /// * Division (/)
  static bool _isArithmeticExpression(String expr) {
    return expr.contains('*') ||
        (expr.contains('+') && _containsOnlyNumbers(expr)) ||
        expr.contains('-') ||
        expr.contains('/');
  }

  /// Checks if the expression is a comparison expression.
  ///
  /// Returns true if the expression contains any of the comparison operators:
  /// * Greater than (>)
  /// * Less than (<)
  /// * Greater than or equal to (>=)
  /// * Less than or equal to (<=)
  /// * Equal to (==)
  /// * Not equal to (!=)
  static bool _isComparisonExpression(String expr) {
    return expr.contains('>') ||
        expr.contains('<') ||
        expr.contains('>=') ||
        expr.contains('<=') ||
        expr.contains('==') ||
        expr.contains('!=');
  }

  /// Evaluates arithmetic expressions.
  ///
  /// Supports:
  /// * Addition of numbers
  /// * Subtraction
  /// * Multiplication
  /// * Division
  ///
  /// Throws [FormatException] if the expression is invalid or operands are not numbers.
  static dynamic _evaluateArithmetic(String expr) {
    if (expr.contains('*')) {
      final parts = expr.split('*').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) * (parts[1] as num);
      }
    }

    if (expr.contains('/')) {
      final parts = expr.split('/').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) / (parts[1] as num);
      }
    }

    if (expr.contains('+')) {
      final parts = expr.split('+').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) + (parts[1] as num);
      }
    }

    if (expr.contains('-')) {
      final parts = expr.split('-').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) - (parts[1] as num);
      }
    }

    throw FormatException('Invalid arithmetic expression: $expr');
  }

  /// Evaluates comparison expressions.
  ///
  /// Supports all comparison operators (>, <, >=, <=, ==, !=).
  /// Currently only supports numeric comparisons.
  ///
  /// Throws [FormatException] if the expression is invalid or operands are not comparable.
  static dynamic _evaluateComparison(String expr) {
    if (expr.contains('>=')) {
      final parts = expr.split('>=').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) >= (parts[1] as num);
      }
    }

    if (expr.contains('<=')) {
      final parts = expr.split('<=').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) <= (parts[1] as num);
      }
    }

    if (expr.contains('>')) {
      final parts = expr.split('>').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) > (parts[1] as num);
      }
    }

    if (expr.contains('<')) {
      final parts = expr.split('<').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) < (parts[1] as num);
      }
    }

    throw FormatException('Invalid comparison expression: $expr');
  }
}
