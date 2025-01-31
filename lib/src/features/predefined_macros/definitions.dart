const _standardMacros = {
  // Math operations
  'SQUARE': _MacroDefinition(
    parameters: ['x'],
    expression: '((x) * (x))',
  ),
  'CUBE': _MacroDefinition(
    parameters: ['x'],
    expression: '((x) * (x) * (x))',
  ),
  'POW': _MacroDefinition(
    parameters: ['x', 'n'],
    expression: 'pow((x), (n))',
  ),

  // Comparison operations
  'MAX': _MacroDefinition(
    parameters: ['a', 'b'],
    expression: '((a) > (b) ? (a) : (b))',
  ),
  'MIN': _MacroDefinition(
    parameters: ['a', 'b'],
    expression: '((a) < (b) ? (a) : (b))',
  ),
  'CLAMP': _MacroDefinition(
    parameters: ['x', 'low', 'high'],
    expression: 'MIN(MAX((x), (low)), (high))',
  ),

  // String operations
  'STRINGIFY': _MacroDefinition(
    parameters: ['x'],
    expression: '"(x)"',
  ),
  'CONCAT': _MacroDefinition(
    parameters: ['a', 'b'],
    expression: '((a).toString() + (b).toString())',
  ),
  'PRINT_VAR': _MacroDefinition(
    parameters: ['var'],
    expression: 'print("Variable (var) = " + (var).toString())',
  ),

  // Type operations
  'CAST': _MacroDefinition(
    parameters: ['value', 'type'],
    expression: '((value) as (type))',
  ),
  'IS_TYPE': _MacroDefinition(
    parameters: ['value', 'type'],
    expression: '((value) is (type))',
  ),
};

class _MacroDefinition {
  final List<String> parameters;
  final String expression;

  const _MacroDefinition({
    required this.parameters,
    required this.expression,
  });
}

Map<String, _MacroDefinition> get standardMacros => _standardMacros;
