import '../../core/exceptions.dart';
import '../../core/location.dart';

/// Evaluates conditional expressions in macro preprocessing
class ConditionalEvaluator {
  /// The defined macros
  final Map<String, String> _defines;

  ConditionalEvaluator(this._defines);

  /// Evaluate a conditional expression
  bool evaluate(String expression, Location location) {
    try {
      // Replace defined() operator
      expression = _handleDefinedOperator(expression);

      // Replace macro values
      expression = _expandMacros(expression);

      // Parse and evaluate
      return _evaluateExpression(expression);
    } catch (e) {
      throw ConditionalCompilationException(
        'Invalid conditional expression: $expression',
        location,
      );
    }
  }

  /// Handle the defined() operator
  String _handleDefinedOperator(String expr) {
    final pattern = RegExp(r'defined\s*\(\s*(\w+)\s*\)');
    return expr.replaceAllMapped(pattern, (match) {
      final macro = match.group(1)!;
      return _defines.containsKey(macro) ? '1' : '0';
    });
  }

  /// Expand macros in the expression
  String _expandMacros(String expr) {
    var result = expr;
    for (final entry in _defines.entries) {
      // Only replace whole words, not parts of words
      final pattern = RegExp(r'\b${entry.key}\b');
      result = result.replaceAll(pattern, entry.value);
    }
    return result;
  }

  /// Evaluate a preprocessor expression
  bool _evaluateExpression(String expr) {
    // Remove whitespace
    expr = expr.trim();

    // Handle parentheses
    if (expr.startsWith('(') && expr.endsWith(')')) {
      return _evaluateExpression(expr.substring(1, expr.length - 1));
    }

    // Handle logical operators
    if (expr.contains('||')) {
      final parts = _splitOutsideParens(expr, '||');
      return parts.any((part) => _evaluateExpression(part));
    }
    if (expr.contains('&&')) {
      final parts = _splitOutsideParens(expr, '&&');
      return parts.every((part) => _evaluateExpression(part));
    }

    // Handle comparison operators
    if (expr.contains('==')) {
      final parts = _splitOutsideParens(expr, '==');
      return _compareValues(parts[0], parts[1], (a, b) => a == b);
    }
    if (expr.contains('!=')) {
      final parts = _splitOutsideParens(expr, '!=');
      return _compareValues(parts[0], parts[1], (a, b) => a != b);
    }
    if (expr.contains('>=')) {
      final parts = _splitOutsideParens(expr, '>=');
      return _compareValues(parts[0], parts[1], (a, b) => a >= b);
    }
    if (expr.contains('<=')) {
      final parts = _splitOutsideParens(expr, '<=');
      return _compareValues(parts[0], parts[1], (a, b) => a <= b);
    }
    if (expr.contains('>')) {
      final parts = _splitOutsideParens(expr, '>');
      return _compareValues(parts[0], parts[1], (a, b) => a > b);
    }
    if (expr.contains('<')) {
      final parts = _splitOutsideParens(expr, '<');
      return _compareValues(parts[0], parts[1], (a, b) => a < b);
    }

    // Handle unary operators
    if (expr.startsWith('!')) {
      return !_evaluateExpression(expr.substring(1));
    }

    // Handle numeric literals
    if (expr == '0' || expr.toLowerCase() == 'false') {
      return false;
    }
    if (expr == '1' || expr.toLowerCase() == 'true') {
      return true;
    }

    // Try parsing as number
    final number = num.tryParse(expr);
    if (number != null) {
      return number != 0;
    }

    // Default to false for undefined values
    return false;
  }

  /// Split expression by operator respecting parentheses
  List<String> _splitOutsideParens(String expr, String operator) {
    var parts = <String>[];
    var current = StringBuffer();
    var parenCount = 0;

    for (var i = 0; i < expr.length;) {
      if (expr.startsWith('(', i)) {
        parenCount++;
        current.write('(');
        i++;
      } else if (expr.startsWith(')', i)) {
        parenCount--;
        current.write(')');
        i++;
      } else if (parenCount == 0 && expr.startsWith(operator, i)) {
        parts.add(current.toString().trim());
        current.clear();
        i += operator.length;
      } else {
        current.write(expr[i]);
        i++;
      }
    }

    if (current.isNotEmpty) {
      parts.add(current.toString().trim());
    }

    return parts;
  }

  /// Compare two values using a comparison function
  bool _compareValues(String a, String b, bool Function(num, num) compare) {
    final numA = num.tryParse(a.trim());
    final numB = num.tryParse(b.trim());

    if (numA != null && numB != null) {
      return compare(numA, numB);
    }

    // Fall back to string comparison
    return compare(a.trim().hashCode.toDouble(), b.trim().hashCode.toDouble());
  }
}