import 'location.dart';

/// Represents a macro type in the system
enum MacroType {
  /// Object-like macros (simple replacements)
  object,

  /// Function-like macros (with parameters)
  function,

  /// Predefined system macros
  predefined,

  /// Conditional compilation macros
  conditional
}

/// Represents a macro definition in the system
class MacroDefinition {
  /// The name of the macro
  final String name;

  /// The parameters for function-like macros
  final List<String> parameters;

  /// The replacement text/expression
  final String replacement;

  /// The type of macro
  final MacroType type;

  /// Source location information
  final Location location;

  /// Whether the macro is currently active (not undefined)
  bool isActive = true;

  MacroDefinition({
    required this.name,
    this.parameters = const [],
    required this.replacement,
    required this.type,
    required this.location,
  });

  /// Creates an object-like macro
  factory MacroDefinition.object({
    required String name,
    required String replacement,
    required Location location,
  }) {
    return MacroDefinition(
      name: name,
      replacement: replacement,
      type: MacroType.object,
      location: location,
    );
  }

  /// Creates a function-like macro
  factory MacroDefinition.function({
    required String name,
    required List<String> parameters,
    required String replacement,
    required Location location,
  }) {
    return MacroDefinition(
      name: name,
      parameters: parameters,
      replacement: replacement,
      type: MacroType.function,
      location: location,
    );
  }

  /// Whether this is a function-like macro
  bool get isFunction => type == MacroType.function;

  /// Whether this is an object-like macro
  bool get isObject => type == MacroType.object;

  /// Whether this is a predefined macro
  bool get isPredefined => type == MacroType.predefined;

  /// Whether this is a conditional macro
  bool get isConditional => type == MacroType.conditional;

  @override
  String toString() {
    if (isFunction) {
      return '#define $name(${parameters.join(", ")}) $replacement';
    }
    return '#define $name $replacement';
  }
}
