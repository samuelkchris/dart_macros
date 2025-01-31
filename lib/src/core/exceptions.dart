import 'location.dart';

/// Base class for all macro-related exceptions
abstract class MacroException implements Exception {
  /// The error message
  final String message;

  /// The location where the error occurred
  final Location? location;

  const MacroException(this.message, [this.location]);

  @override
  String toString() {
    if (location != null) {
      return 'MacroException: $message at $location';
    }
    return 'MacroException: $message';
  }
}

/// Thrown when there's an error in macro definition
class MacroDefinitionException extends MacroException {
  const MacroDefinitionException(String message, [Location? location])
      : super(message, location);
}

/// Thrown when there's an error in macro usage
class MacroUsageException extends MacroException {
  const MacroUsageException(String message, [Location? location])
      : super(message, location);
}

/// Thrown when a macro is undefined but used
class UndefinedMacroException extends MacroException {
  /// The name of the undefined macro
  final String macroName;

  const UndefinedMacroException(this.macroName, [Location? location])
      : super('Undefined macro: $macroName', location);
}

/// Thrown when there's an error in macro arguments
class MacroArgumentException extends MacroException {
  const MacroArgumentException(String message, [Location? location])
      : super(message, location);
}

/// Thrown when there's a recursive macro definition
class RecursiveMacroException extends MacroException {
  /// The chain of macro names involved in the recursion
  final List<String> macroChain;

  RecursiveMacroException(this.macroChain, [Location? location])
      : super(
          'Recursive macro definition detected: ${macroChain.join(" -> ")}',
          location,
        );
}

/// Thrown when there's an error in conditional compilation
class ConditionalCompilationException extends MacroException {
  const ConditionalCompilationException(String message, [Location? location])
      : super(message, location);
}
