import 'dart:collection';

import 'location.dart';
import 'macro_definition.dart';
import 'exceptions.dart';

/// The main engine responsible for macro processing
class MacroProcessor {
  /// Storage for defined macros
  final Map<String, MacroDefinition> _macros = {};

  /// Stack to detect recursive macro expansions
  final Queue<String> _expansionStack = Queue();

  /// Maximum recursion depth for macro expansion
  static const int _maxRecursionDepth = 500;

  /// Defines a new macro
  void define({
    required String name,
    List<String> parameters = const [],
    required String replacement,
    required Location location,
  }) {
    // Validate macro name
    if (!_isValidMacroName(name)) {
      throw MacroDefinitionException(
        'Invalid macro name: $name',
        location,
      );
    }

    // Create appropriate macro type
    final macro = parameters.isEmpty
        ? MacroDefinition.object(
            name: name,
            replacement: replacement,
            location: location,
          )
        : MacroDefinition.function(
            name: name,
            parameters: parameters,
            replacement: replacement,
            location: location,
          );

    _macros[name] = macro;
  }

  /// Undefines an existing macro
  void undefine(String name) {
    if (!_macros.containsKey(name)) {
      throw UndefinedMacroException(name);
    }
    _macros.remove(name);
  }

  /// Checks if a macro is defined
  bool isDefined(String name) => _macros.containsKey(name);

  /// Process source code and expand all macros
  String process(String source, {required String filePath}) {
    var result = source;
    var location = Location(file: filePath, line: 1, column: 1);

    // First pass: Process macro definitions
    result = _processDefinitions(result, location);

    // Second pass: Expand macros
    result = _expandMacros(result, location);

    return result;
  }

  /// Process macro definitions in the source
  String _processDefinitions(String source, Location location) {
    final lines = source.split('\n');
    final processedLines = <String>[];
    var currentLine = 0;

    for (final line in lines) {
      currentLine++;
      final trimmed = line.trim();

      // Skip empty lines and comments
      if (trimmed.isEmpty || trimmed.startsWith('//')) {
        processedLines.add(line);
        continue;
      }

      // Handle macro definitions
      if (trimmed.startsWith('#define')) {
        _handleDefine(
          line,
          Location(
            file: location.file,
            line: currentLine,
            column: line.indexOf('#define') + 1,
          ),
        );
      } else {
        processedLines.add(line);
      }
    }

    return processedLines.join('\n');
  }

  /// Handle a #define directive
  void _handleDefine(String line, Location location) {
    final parts = line.substring(7).trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      throw MacroDefinitionException(
        'Invalid macro definition',
        location,
      );
    }

    final name = parts[0];
    if (name.contains('(')) {
      _handleFunctionMacro(line, location);
    } else {
      _handleObjectMacro(parts, location);
    }
  }

  /// Handle object-like macro definition
  void _handleObjectMacro(List<String> parts, Location location) {
    if (parts.length < 2) {
      throw MacroDefinitionException(
        'Object-like macro requires a replacement',
        location,
      );
    }

    final name = parts[0];
    final replacement = parts.sublist(1).join(' ');

    define(
      name: name,
      replacement: replacement,
      location: location,
    );
  }

  /// Handle function-like macro definition
  void _handleFunctionMacro(String line, Location location) {
    final match = RegExp(r'(\w+)\(([\w\s,]*)\)\s+(.+)').firstMatch(line);
    if (match == null) {
      throw MacroDefinitionException(
        'Invalid function-like macro definition',
        location,
      );
    }

    final name = match.group(1)!;
    final params = match
        .group(2)!
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final replacement = match.group(3)!;

    define(
      name: name,
      parameters: params,
      replacement: replacement,
      location: location,
    );
  }

  /// Expand all macros in the source
  String _expandMacros(String source, Location location) {
    var result = source;
    var changed = true;

    // Continue expanding until no more changes are made
    while (changed) {
      changed = false;
      final expanded = _expandMacrosOnce(result, location);

      if (expanded != result) {
        result = expanded;
        changed = true;
      }
    }

    return result;
  }

  /// Perform one pass of macro expansion
  String _expandMacrosOnce(String source, Location location) {
    var result = source;

    // Expand function-like macros
    for (final macro in _macros.values.where((m) => m.isFunction)) {
      final pattern = RegExp('${macro.name}\\((.*?)\\)');
      result = result.replaceAllMapped(pattern, (match) {
        return _expandFunctionMacro(
          macro,
          match.group(1)!,
          location,
        );
      });
    }

    // Expand object-like macros
    for (final macro in _macros.values.where((m) => m.isObject)) {
      result = result.replaceAll(macro.name, macro.replacement);
    }

    return result;
  }

  /// Expand a function-like macro
  String _expandFunctionMacro(
    MacroDefinition macro,
    String argsString,
    Location location,
  ) {
    // Check recursion
    if (_expansionStack.length >= _maxRecursionDepth) {
      throw RecursiveMacroException(_expansionStack.toList(), location);
    }

    _expansionStack.addLast(macro.name);
    try {
      final args = _parseArguments(argsString);

      if (args.length != macro.parameters.length) {
        throw MacroArgumentException(
          'Macro ${macro.name} requires ${macro.parameters.length} arguments, '
          'but ${args.length} were provided',
          location,
        );
      }

      var replacement = macro.replacement;
      for (var i = 0; i < macro.parameters.length; i++) {
        replacement = replacement.replaceAll(
          macro.parameters[i],
          args[i],
        );
      }

      return replacement;
    } finally {
      _expansionStack.removeLast();
    }
  }

  /// Parse macro arguments, handling nested parentheses
  List<String> _parseArguments(String argsString) {
    final args = <String>[];
    var current = StringBuffer();
    var depth = 0;

    for (var i = 0; i < argsString.length; i++) {
      final char = argsString[i];

      if (char == '(' && depth > 0) {
        depth++;
        current.write(char);
      } else if (char == ')' && depth > 0) {
        depth--;
        current.write(char);
      } else if (char == '(') {
        depth++;
      } else if (char == ',') {
        if (depth == 0) {
          args.add(current.toString().trim());
          current.clear();
        } else {
          current.write(char);
        }
      } else {
        current.write(char);
      }
    }

    if (current.isNotEmpty) {
      args.add(current.toString().trim());
    }

    return args;
  }

  /// Validate macro name
  bool _isValidMacroName(String name) {
    return RegExp(r'^[a-zA-Z_]\w*$').hasMatch(name);
  }
}
