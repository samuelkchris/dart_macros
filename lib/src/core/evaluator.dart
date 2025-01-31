class ExpressionEvaluator {
  static dynamic evaluate(String expression) {
    // Remove outer parentheses if they exist
    expression = expression.trim();
    while (expression.startsWith('(') && expression.endsWith(')')) {
      expression = expression.substring(1, expression.length - 1).trim();
    }

    // Handle string concatenation
    if (expression.contains('+') && !_containsOnlyNumbers(expression)) {
      return _evaluateStringConcat(expression);
    }

    // Handle arithmetic expressions
    if (_isArithmeticExpression(expression)) {
      return _evaluateArithmetic(expression);
    }

    // Handle comparison expressions
    if (_isComparisonExpression(expression)) {
      return _evaluateComparison(expression);
    }

    // Try parsing as number
    final number = num.tryParse(expression);
    if (number != null) return number;

    // Return as is for strings and other values
    return _unquote(expression);
  }

  static bool _containsOnlyNumbers(String expr) {
    final parts = expr.split('+').map((e) => e.trim());
    return parts.every((part) => num.tryParse(part) != null);
  }

  static String _evaluateStringConcat(String expr) {
    final parts = expr.split('+').map((e) => evaluate(e.trim()).toString());
    return parts.join('');
  }

  static String _unquote(String text) {
    if (text.startsWith('"') && text.endsWith('"')) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }

  static bool _isArithmeticExpression(String expr) {
    return expr.contains('*') ||
        (expr.contains('+') && _containsOnlyNumbers(expr)) ||
        expr.contains('-') ||
        expr.contains('/');
  }

  static bool _isComparisonExpression(String expr) {
    return expr.contains('>') || expr.contains('<') ||
        expr.contains('>=') || expr.contains('<=') ||
        expr.contains('==') || expr.contains('!=');
  }

  static dynamic _evaluateArithmetic(String expr) {
    // Handle multiplication
    if (expr.contains('*')) {
      final parts = expr.split('*').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) * (parts[1] as num);
      }
    }

    // Handle division
    if (expr.contains('/')) {
      final parts = expr.split('/').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) / (parts[1] as num);
      }
    }

    // Handle addition
    if (expr.contains('+')) {
      final parts = expr.split('+').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) + (parts[1] as num);
      }
    }

    // Handle subtraction
    if (expr.contains('-')) {
      final parts = expr.split('-').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) - (parts[1] as num);
      }
    }

    throw FormatException('Invalid arithmetic expression: $expr');
  }

  static dynamic _evaluateComparison(String expr) {
    // Handle greater than or equal
    if (expr.contains('>=')) {
      final parts = expr.split('>=').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) >= (parts[1] as num);
      }
    }

    // Handle less than or equal
    if (expr.contains('<=')) {
      final parts = expr.split('<=').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) <= (parts[1] as num);
      }
    }

    // Handle greater than
    if (expr.contains('>')) {
      final parts = expr.split('>').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) > (parts[1] as num);
      }
    }

    // Handle less than
    if (expr.contains('<')) {
      final parts = expr.split('<').map((e) => evaluate(e.trim())).toList();
      if (parts.every((e) => e is num)) {
        return (parts[0] as num) < (parts[1] as num);
      }
    }

    throw FormatException('Invalid comparison expression: $expr');
  }

  static dynamic _evaluateTernary(String expr) {
    final qIndex = expr.indexOf('?');
    final cIndex = expr.indexOf(':', qIndex);

    if (qIndex == -1 || cIndex == -1) {
      throw FormatException('Invalid ternary expression: $expr');
    }

    final condition = evaluate(expr.substring(0, qIndex).trim());
    final ifTrue = expr.substring(qIndex + 1, cIndex).trim();
    final ifFalse = expr.substring(cIndex + 1).trim();

    return condition == true ? evaluate(ifTrue) : evaluate(ifFalse);
  }
}
