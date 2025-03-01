/// Library for defining and managing macro definitions in the dart_macros package.
///
/// This library provides the core types and classes for representing different
/// kinds of macros and their definitions in the system.
library;

import 'location.dart';

/// Represents the different types of macros supported by the system.
///
/// Each type has different characteristics and usage patterns:
/// * [object] - Simple replacement macros
/// * [function] - Macros with parameters
/// * [predefined] - Built-in system macros
/// * [conditional] - Compilation control macros
enum MacroType {
  /// Object-like macros that perform simple text replacement.
  ///
  /// Example:
  /// ```dart
  /// #define VERSION "1.0.0"
  /// ```
  object,

  /// Function-like macros that accept parameters.
  ///
  /// Example:
  /// ```dart
  /// #define MAX(a, b) ((a) > (b) ? (a) : (b))
  /// ```
  function,

  /// Built-in system macros that provide predefined functionality.
  ///
  /// These macros are typically used for:
  /// * Compiler information
  /// * Platform detection
  /// * Build configuration
  predefined,

  /// Macros used for conditional compilation.
  ///
  /// Example:
  /// ```dart
  /// #ifdef DEBUG
  /// // Debug-only code
  /// #endif
  /// ```
  conditional
}

/// Represents a macro definition in the system.
///
/// A macro definition includes:
/// * The macro name
/// * Optional parameters (for function-like macros)
/// * Replacement text
/// * Type information
/// * Source location
///
/// This class provides factory constructors for creating different types of macros
/// and utility methods for checking macro properties.
class MacroDefinition {
  /// The identifier used to reference this macro.
  final String name;

  /// The list of parameter names for function-like macros.
  ///
  /// Empty for non-function macros.
  final List<String> parameters;

  /// The text or code that replaces the macro when it's used.
  final String replacement;

  /// The type of this macro, determining its behavior.
  final MacroType type;

  /// The location where this macro was defined in the source code.
  final Location location;

  /// Whether this macro is currently active and can be used.
  ///
  /// A macro might be inactive if it was undefined using #undef.
  bool isActive = true;

  /// Creates a new [MacroDefinition] with the specified properties.
  ///
  /// This is the base constructor used by the factory constructors.
  MacroDefinition({
    required this.name,
    this.parameters = const [],
    required this.replacement,
    required this.type,
    required this.location,
  });

  /// Creates an object-like macro definition.
  ///
  /// Object-like macros are simple replacements without parameters.
  ///
  /// Example:
  /// ```dart
  /// final macro = MacroDefinition.object(
  ///   name: 'VERSION',
  ///   replacement: '"1.0.0"',
  ///   location: someLocation,
  /// );
  /// ```
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

  /// Creates a function-like macro definition.
  ///
  /// Function-like macros take parameters that are substituted in the replacement.
  ///
  /// Example:
  /// ```dart
  /// final macro = MacroDefinition.function(
  ///   name: 'MAX',
  ///   parameters: ['a', 'b'],
  ///   replacement: '((a) > (b) ? (a) : (b))',
  ///   location: someLocation,
  /// );
  /// ```
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

  /// Whether this is a function-like macro that accepts parameters.
  bool get isFunction => type == MacroType.function;

  /// Whether this is an object-like macro for simple replacement.
  bool get isObject => type == MacroType.object;

  /// Whether this is a predefined system macro.
  bool get isPredefined => type == MacroType.predefined;

  /// Whether this is a conditional compilation macro.
  bool get isConditional => type == MacroType.conditional;

  @override
  String toString() {
    if (isFunction) {
      return '#define $name(${parameters.join(", ")}) $replacement';
    }
    return '#define $name $replacement';
  }
}
