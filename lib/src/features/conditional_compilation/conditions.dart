import '../../core/exceptions.dart';
import '../../core/location.dart';

/// Evaluates conditional expressions in macro preprocessing.
///
/// The [ConditionalEvaluator] handles evaluation of conditional expressions
/// similar to those found in C preprocessor directives like #if, #ifdef, etc.
/// It supports a variety of operations including logical operations (&&, ||),
/// comparison operations (==, !=, >, <, >=, <=), and the defined() operator.
///
/// This evaluator is a key component of the conditional compilation system,
/// enabling compile-time decisions based on macro definitions and expressions.
///
/// Example usage:
/// ```dart
/// final evaluator = ConditionalEvaluator({'VERSION': '1.0.0', 'DEBUG': 'true'});
/// final result = evaluator.evaluate('VERSION == "1.0.0" && DEBUG', location);
/// ```
class ConditionalEvaluator {
  /// The map of defined macros and their values.
  ///
  /// Keys are macro names and values are their string representations.
  /// These definitions are used when evaluating expressions.
  final Map<String, String> _defines;

  /// Creates a new conditional evaluator with the specified macro definitions.
  ///
  /// Parameters:
  /// - [_defines]: Map of macro names to their string values
  ConditionalEvaluator(this._defines);

  /// Evaluates a conditional expression and returns a boolean result.
  ///
  /// This method processes the expression in several stages:
  /// 1. Handles the `defined()` operator by replacing it with '1' or '0'
  /// 2. Expands macro references to their values
  /// 3. Evaluates the resulting expression to a boolean value
  ///
  /// Parameters:
  /// - [expression]: The conditional expression to evaluate
  /// - [location]: The source location for error reporting
  ///
  /// Returns:
  /// A boolean result of the expression evaluation.
  ///
  /// Throws:
  /// - [ConditionalCompilationException] if the expression is invalid
  bool evaluate(String expression, Location location) {
    try {
      /* Replace defined() operator */
      expression = _handleDefinedOperator(expression);

      /* Replace macro values */
      expression = _expandMacros(expression);

      /* Parse and evaluate the expression */
      return _evaluateExpression(expression);
    } catch (e) {
      throw ConditionalCompilationException(
        'Invalid conditional expression: $expression',
        location,
      );
    }
  }

  /// Handles the defined() operator in expressions.
  ///
  /// Replaces occurrences of defined(MACRO) with '1' if the macro is defined,
  /// or '0' if it's not defined. This mimics C preprocessor behavior.
  ///
  /// Parameters:
  /// - [expr]: The expression containing defined() operations
  ///
  /// Returns:
  /// The expression with defined() operations replaced with '1' or '0'
  String _handleDefinedOperator(String expr) {
    final pattern = RegExp(r'defined\s*\(\s*(\w+)\s*\)');
    return expr.replaceAllMapped(pattern, (match) {
      final macro = match.group(1)!;
      return _defines.containsKey(macro) ? '1' : '0';
    });
  }

  /// Expands macro references in an expression to their values.
  ///
  /// Replaces each macro name with its corresponding value from the _defines map.
  /// Only replaces whole words to avoid partial replacements in identifiers.
  ///
  /// Parameters:
  /// - [expr]: The expression containing macro references
  ///
  /// Returns:
  /// The expression with macro references expanded to their values
  String _expandMacros(String expr) {
    var result = expr;
    for (final entry in _defines.entries) {
      /* Only replace whole words, not parts of words */
      final pattern = RegExp(r'\b${entry.key}\b');
      result = result.replaceAll(pattern, entry.value);
    }
    return result;
  }

  /// Evaluates a preprocessor expression to a boolean result.
  ///
  /// This method recursively evaluates expressions with proper operator precedence.
  /// It handles logical operators (&&, ||), comparison operators (==, !=, >, <, >=, <=),
  /// parenthesized expressions, and literal values.
  ///
  /// Parameters:
  /// - [expr]: The preprocessor expression to evaluate
  ///
  /// Returns:
  /// The boolean result of evaluating the expression
  bool _evaluateExpression(String expr) {
    /* Remove whitespace */
    expr = expr.trim();

    /* Handle parenthesized expressions */
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _evaluateExpression(expr.substring(1, expr.length - 1));
    }

    /* Handle logical OR operator (||) */
    if (expr.contains('||')) {
      final parts = _splitOutsideParens(expr, '||');
      return parts.any((part) => _evaluateExpression(part));
    }

    /* Handle logical AND operator (&&) */
    if (expr.contains('&&')) {
      final parts = _splitOutsideParens(expr, '&&');
      return parts.every((part) => _evaluateExpression(part));
    }

    /* Handle equality operator (==) */
    if (expr.contains('==')) {
      final parts = _splitOutsideParens(expr, '==');
      return _compareValues(parts[0], parts[1], (a, b) => a == b);
    }

    /* Handle inequality operator (!=) */
    if (expr.contains('!=')) {
      final parts = _splitOutsideParens(expr, '!=');
      return _compareValues(parts[0], parts[1], (a, b) => a != b);
    }

    /* Handle greater than or equal operator (>=) */
    if (expr.contains('>=')) {
      final parts = _splitOutsideParens(expr, '>=');
      return _compareValues(parts[0], parts[1], (a, b) => a >= b);
    }

    /* Handle less than or equal operator (<=) */
    if (expr.contains('<=')) {
      final parts = _splitOutsideParens(expr, '<=');
      return _compareValues(parts[0], parts[1], (a, b) => a <= b);
    }

    /* Handle greater than operator (>) */
    if (expr.contains('>')) {
      final parts = _splitOutsideParens(expr, '>');
      return _compareValues(parts[0], parts[1], (a, b) => a > b);
    }

    /* Handle less than operator (<) */
    if (expr.contains('<')) {
      final parts = _splitOutsideParens(expr, '<');
      return _compareValues(parts[0], parts[1], (a, b) => a < b);
    }

    /* Handle logical NOT operator (!) */
    if (expr.startsWith('!')) {
      return !_evaluateExpression(expr.substring(1));
    }

    /* Handle boolean literals */
    if (expr == '0' || expr.toLowerCase() == 'false') {
      return false;
    }
    if (expr == '1' || expr.toLowerCase() == 'true') {
      return true;
    }

    /* Try parsing as number (non-zero numbers evaluate to true) */
    final number = num.tryParse(expr);
    if (number != null) {
      return number != 0;
    }

    /* Default to false for undefined values or invalid expressions */
    return false;
  }

  /// Splits an expression by an operator, respecting parenthesized groups.
  ///
  /// This method correctly handles splitting expressions by operators when
  /// parenthesized sub-expressions are present, ensuring that operators inside
  /// parentheses don't cause incorrect splits.
  ///
  /// Parameters:
  /// - [expr]: The expression to split
  /// - [operator]: The operator to split by
  ///
  /// Returns:
  /// A list of expression parts split by the operator
  List<String> _splitOutsideParens(String expr, String operator) {
    var parts = <String>[];
    var current = StringBuffer();
    var parenCount = 0;

    for (var i = 0; i < expr.length;) {
      if (expr.startsWith('(', i)) {
        /* Increment parenthesis depth and add character */
        parenCount++;
        current.write('(');
        i++;
      } else if (expr.startsWith(')', i)) {
        /* Decrement parenthesis depth and add character */
        parenCount--;
        current.write(')');
        i++;
      } else if (parenCount == 0 && expr.startsWith(operator, i)) {
        /* Found operator outside parentheses - create split */
        parts.add(current.toString().trim());
        current.clear();
        i += operator.length;
      } else {
        /* Add character to current buffer */
        current.write(expr[i]);
        i++;
      }
    }

    /* Add final part if non-empty */
    if (current.isNotEmpty) {
      parts.add(current.toString().trim());
    }

    return parts;
  }

  /// Compares two values using a comparison function.
  ///
  /// This method attempts to compare values numerically if possible,
  /// falling back to string-based comparison when necessary.
  ///
  /// Parameters:
  /// - [a]: First value to compare
  /// - [b]: Second value to compare
  /// - [compare]: Function that defines the comparison operation
  ///
  /// Returns:
  /// The boolean result of the comparison
  bool _compareValues(String a, String b, bool Function(num, num) compare) {
    final numA = num.tryParse(a.trim());
    final numB = num.tryParse(b.trim());

    /* If both values are numeric, compare them directly */
    if (numA != null && numB != null) {
      return compare(numA, numB);
    }

    /* Fall back to string comparison using hash codes */
    return compare(a.trim().hashCode.toDouble(), b.trim().hashCode.toDouble());
  }
}
