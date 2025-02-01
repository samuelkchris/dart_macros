class ConditionParser {
  final Map<String, dynamic> _defines;

  ConditionParser(this._defines);

  bool evaluate(String condition) {
    condition = condition.trim();

    // Handle ifdef equivalent
    if (condition.startsWith('#ifdef ')) {
      final symbol = condition.substring(7).trim();
      return _defines.containsKey(symbol);
    }

    // Handle ifndef equivalent
    if (condition.startsWith('#ifndef ')) {
      final symbol = condition.substring(8).trim();
      return !_defines.containsKey(symbol);
    }

    // Handle equality
    if (condition.contains('==')) {
      final parts = condition.split('==').map((e) => e.trim()).toList();
      return _getValue(parts[0]) == _getValue(parts[1]);
    }

    // Handle greater than or equal
    if (condition.contains('>=')) {
      final parts = condition.split('>=').map((e) => e.trim()).toList();
      final left = _getValue(parts[0]);
      final right = _getValue(parts[1]);
      return (left is num && right is num) ? left >= right : false;
    }

    // Handle AND conditions
    if (condition.contains('&&')) {
      final parts = condition.split('&&').map((e) => e.trim());
      return parts.every((part) => evaluate(part));
    }

    // Handle OR conditions
    if (condition.contains('||')) {
      final parts = condition.split('||').map((e) => e.trim());
      return parts.any((part) => evaluate(part));
    }

    // Simple value check
    return _getValue(condition) == true;
  }

  dynamic _getValue(String key) {
    // Handle string literals
    if (key.startsWith('"') && key.endsWith('"')) {
      return key.substring(1, key.length - 1);
    }

    // Handle number literals
    if (key.contains('.')) {
      return double.tryParse(key);
    }
    final intValue = int.tryParse(key);
    if (intValue != null) return intValue;

    // Look up in defines
    return _defines[key];
  }
}
