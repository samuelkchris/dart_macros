/// Library for handling macro-related exceptions in the dart_macros package.
///
/// This library provides a hierarchy of exception classes for different types
/// of errors that can occur during macro processing.
library;

import 'location.dart';

/// Base class for all macro-related exceptions in the system.
///
/// This class provides common functionality for all macro exceptions:
/// * Error message storage
/// * Source code location tracking
/// * Formatted string representation
///
/// All specific macro exceptions should extend this class.
abstract class MacroException implements Exception {
  /// A descriptive message explaining the error.
  final String message;

  /// The source code location where the error occurred.
  /// May be null if the location is not known or relevant.
  final Location? location;

  /// Creates a new [MacroException] with the given [message] and optional [location].
  const MacroException(this.message, [this.location]);

  @override
  String toString() {
    if (location != null) {
      return 'MacroException: $message at $location';
    }
    return 'MacroException: $message';
  }
}

/// Exception thrown when there's an error in macro definition syntax or semantics.
///
/// This exception is typically thrown when:
/// * The macro syntax is invalid
/// * The macro parameters are incorrectly specified
/// * The macro replacement text is malformed
class MacroDefinitionException extends MacroException {
  /// Creates a new [MacroDefinitionException] with the given [message] and optional [location].
  const MacroDefinitionException(super.message, [super.location]);
}

/// Exception thrown when a macro is used incorrectly.
///
/// This exception is typically thrown when:
/// * Wrong number of arguments are provided
/// * Invalid argument types are used
/// * The macro is used in an invalid context
class MacroUsageException extends MacroException {
  /// Creates a new [MacroUsageException] with the given [message] and optional [location].
  const MacroUsageException(super.message, [super.location]);
}

/// Exception thrown when attempting to use a macro that hasn't been defined.
///
/// This exception includes the name of the undefined macro to help with debugging.
class UndefinedMacroException extends MacroException {
  /// The name of the macro that was not found in the macro definitions.
  final String macroName;

  /// Creates a new [UndefinedMacroException] for the given [macroName] and optional [location].
  const UndefinedMacroException(this.macroName, [Location? location])
      : super('Undefined macro: $macroName', location);
}

/// Exception thrown when there's an error with macro arguments.
///
/// This exception is typically thrown when:
/// * Required arguments are missing
/// * Argument types don't match expected types
/// * Arguments contain invalid expressions
class MacroArgumentException extends MacroException {
  /// Creates a new [MacroArgumentException] with the given [message] and optional [location].
  const MacroArgumentException(super.message, [super.location]);
}

/// Exception thrown when a recursive macro definition is detected.
///
/// This exception includes the chain of macro names that form the recursion
/// to help identify the cycle in the definitions.
class RecursiveMacroException extends MacroException {
  /// The sequence of macro names that form the recursive chain.
  /// For example: ["A", "B", "C", "A"] represents A -> B -> C -> A recursion.
  final List<String> macroChain;

  /// Creates a new [RecursiveMacroException] with the given recursion [macroChain]
  /// and optional [location].
  RecursiveMacroException(this.macroChain, [Location? location])
      : super(
          'Recursive macro definition detected: ${macroChain.join(" -> ")}',
          location,
        );
}

/// Exception thrown when there's an error in conditional compilation directives.
///
/// This exception is typically thrown when:
/// * Invalid condition syntax
/// * Unmatched #if/#endif directives
/// * Invalid expressions in conditions
class ConditionalCompilationException extends MacroException {
  /// Creates a new [ConditionalCompilationException] with the given [message] and optional [location].
  const ConditionalCompilationException(super.message, [super.location]);
}
