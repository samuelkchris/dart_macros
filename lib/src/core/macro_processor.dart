/// Library for processing and expanding macros in the dart_macros package.
///
/// This library provides the core functionality for:
/// * Defining macros
/// * Processing macro definitions
/// * Expanding macro usages
/// * Handling macro recursion
library;

import 'dart:collection';

import 'package:dart_macros/src/core/data_processor.dart';

import '../annotations/data.dart';
import 'location.dart';
import 'macro_definition.dart';
import 'exceptions.dart';

/// The main engine responsible for macro processing and expansion.
///
/// This class handles:
/// * Macro definition and management
/// * Macro expansion and substitution
/// * Recursion detection and prevention
/// * Error handling and validation
class MacroProcessor {
  /// Storage for all defined macros, keyed by macro name.
  final Map<String, MacroDefinition> _macros = {};

  /// Stack for tracking macro expansion to detect recursion.
  ///
  /// Each element represents a macro being expanded in the current chain.
  final Queue<String> _expansionStack = Queue();

  /// Maximum allowed depth for macro expansion to prevent infinite recursion.
  static const int _maxRecursionDepth = 500;

  /// Defines a new macro in the system.
  ///
  /// This method creates either an object-like or function-like macro
  /// based on whether parameters are provided.
  ///
  /// Parameters:
  /// * [name] - The identifier for the macro
  /// * [parameters] - Optional list of parameter names for function-like macros
  /// * [replacement] - The text/code that replaces the macro
  /// * [location] - Source location for error reporting
  ///
  /// Throws [MacroDefinitionException] if the macro name is invalid.
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

  /// Removes a macro definition from the system.
  ///
  /// Parameters:
  /// * [name] - The name of the macro to undefine
  ///
  /// Throws [UndefinedMacroException] if the macro doesn't exist.
  void undefine(String name) {
    if (!_macros.containsKey(name)) {
      throw UndefinedMacroException(name);
    }
    _macros.remove(name);
  }

  /// Checks if a macro with the given name is defined.
  ///
  /// Parameters:
  /// * [name] - The name of the macro to check
  ///
  /// Returns true if the macro exists, false otherwise.
  bool isDefined(String name) => _macros.containsKey(name);

  /// Processes source code and expands all macro usages.
  ///
  /// This method performs a two-pass process:
  /// 1. Process macro definitions (#define directives)
  /// 2. Expand macro usages in the code
  ///
  /// Parameters:
  /// * [source] - The source code to process
  /// * [filePath] - Path of the source file for error reporting
  ///
  /// Returns the processed source code with all macros expanded.
  String process(String source, {required String filePath}) {
    var result = source;
    var location = Location(file: filePath, line: 1, column: 1);

    // First pass: Process macro definitions
    result = _processDefinitions(result, location);

    // Second pass: Expand macros
    result = _expandMacros(result, location);

    return result;
  }

  /// Processes macro definitions in the source code.
  ///
  /// Scans the source code line by line looking for #define directives
  /// and processes them accordingly.
  ///
  /// Parameters:
  /// * [source] - The source code to process
  /// * [location] - Starting location for error reporting
  ///
  /// Returns the source code with macro definitions removed.
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

  /// Processes a single #define directive.
  ///
  /// Determines whether it's an object-like or function-like macro
  /// and delegates to the appropriate handler.
  ///
  /// Parameters:
  /// * [line] - The line containing the #define directive
  /// * [location] - Source location for error reporting
  ///
  /// Throws [MacroDefinitionException] if the directive is invalid.
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

  /// Processes an object-like macro definition.
  ///
  /// Example:
  /// ```dart
  /// #define VERSION "1.0.0"
  /// ```
  ///
  /// Parameters:
  /// * [parts] - The tokenized parts of the macro definition
  /// * [location] - Source location for error reporting
  ///
  /// Throws [MacroDefinitionException] if the definition is invalid.
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

  /// Processes a function-like macro definition.
  ///
  /// Example:
  /// ```dart
  /// #define MAX(a, b) ((a) > (b) ? (a) : (b))
  /// ```
  ///
  /// Parameters:
  /// * [line] - The complete macro definition line
  /// * [location] - Source location for error reporting
  ///
  /// Throws [MacroDefinitionException] if the definition is invalid.
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

  /// Expands all macro usages in the source code.
  ///
  /// Repeatedly expands macros until no more expansions are possible.
  /// This handles nested macro expansions correctly.
  ///
  /// Parameters:
  /// * [source] - The source code to process
  /// * [location] - Source location for error reporting
  ///
  /// Returns the fully expanded source code.
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

  /// Performs a single pass of macro expansion.
  ///
  /// First expands function-like macros, then object-like macros.
  ///
  /// Parameters:
  /// * [source] - The source code to process
  /// * [location] - Source location for error reporting
  ///
  /// Returns the source code with one level of macros expanded.
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

  /// Expands a single function-like macro invocation.
  ///
  /// Handles parameter substitution and recursion detection.
  ///
  /// Parameters:
  /// * [macro] - The macro definition to expand
  /// * [argsString] - The argument string from the macro invocation
  /// * [location] - Source location for error reporting
  ///
  /// Returns the expanded macro replacement.
  ///
  /// Throws:
  /// * [RecursiveMacroException] if recursion limit is exceeded
  /// * [MacroArgumentException] if arguments are invalid
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

  /// Parses macro arguments, handling nested parentheses correctly.
  ///
  /// Example:
  /// ```dart
  /// _parseArguments("a, f(1, 2), c") // Returns ["a", "f(1, 2)", "c"]
  /// ```
  ///
  /// Parameters:
  /// * [argsString] - The string containing macro arguments
  ///
  /// Returns a list of parsed argument strings.
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

  /// Validates a macro name according to the language rules.
  ///
  /// A valid macro name:
  /// * Starts with a letter or underscore
  /// * Contains only letters, numbers, and underscores
  ///
  /// Parameters:
  /// * [name] - The macro name to validate
  ///
  /// Returns true if the name is valid, false otherwise.
  bool _isValidMacroName(String name) {
    return RegExp(r'^[a-zA-Z_]\w*$').hasMatch(name);
  }
}

/// Extension for handling @Data annotations in the macro processor.
///
/// Provides functionality to process @Data annotations and generate
/// the corresponding utility methods.
extension DataAnnotationHandler on MacroProcessor {
  /// Processes a @Data annotation on a class.
  ///
  /// Parses the annotation arguments and generates the requested
  /// utility methods based on the configuration.
  ///
  /// Parameters:
  /// * [source] - The source code containing the annotation
  /// * [className] - The name of the annotated class
  /// * [location] - Source location for error reporting
  void handleDataAnnotation(
      String source, String className, Location location) {
    // Look for @Data annotation
    final dataMatch = RegExp(r'@Data\((.*?)\)').firstMatch(source);
    if (dataMatch != null) {
      final annotationArgs = dataMatch.group(1) ?? '';
      final data = Data(
        generateToString: !annotationArgs.contains('generateToString: false'),
        generateEquality: !annotationArgs.contains('generateEquality: false'),
        generateJson: !annotationArgs.contains('generateJson: false'),
      );

      processDataClass(data, className, location);
    }
  }
}
