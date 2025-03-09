import '../../core/location.dart';
import 'concatenation.dart';
import 'stringizing.dart';

/// Facade for token manipulation operations.
///
/// The [TokenManipulator] class provides a unified interface for all token
/// manipulation operations required during macro processing, including
/// stringizing (converting to string literals) and token concatenation.
///
/// This class implements the Facade design pattern to simplify access to
/// the underlying token manipulation operations and coordinate their execution.
///
/// Example usage:
/// ```dart
/// final manipulator = TokenManipulator();
/// final result = manipulator.process(
///   'Hello #param ## "World"',
///   {'param': 'Dart'},
///   location,
/// );
/// ```
class TokenManipulator {
  /// Handler for token concatenation operations
  final TokenConcatenator _concatenator;

  /// Handler for stringizing operations
  final Stringizer _stringizer;

  /// Creates a new token manipulator.
  ///
  /// Initializes the underlying token manipulation components.
  TokenManipulator()
      : _concatenator = TokenConcatenator(),
        _stringizer = Stringizer();

  /// Processes all token manipulations in a macro replacement.
  ///
  /// This method coordinates the application of stringizing and concatenation
  /// operations in the correct order to ensure proper macro expansion.
  ///
  /// Parameters:
  /// - [replacement]: The macro replacement text to process
  /// - [parameters]: Map of parameter names to their values
  /// - [location]: The source location for error reporting
  ///
  /// Returns:
  /// The processed replacement text with all token manipulations applied
  String process(
      String replacement,
      Map<String, String> parameters,
      Location location,
      ) {
    /* First handle stringizing operations */
    var result = _stringizer.processStringizing(
      replacement,
      parameters,
      location,
    );

    /* Then handle concatenation operations */
    result = _concatenator.concatenate(result, location);

    return result;
  }

  /// Stringizes a single parameter.
  ///
  /// Convenience method to convert a parameter to a string literal.
  ///
  /// Parameters:
  /// - [param]: The parameter value to stringize
  /// - [location]: The source location for error reporting
  ///
  /// Returns:
  /// The parameter as a string literal
  String stringize(String param, Location location) {
    return _stringizer.stringize(param, location);
  }

  /// Concatenates two tokens.
  ///
  /// Convenience method to concatenate two tokens.
  ///
  /// Parameters:
  /// - [left]: The left token
  /// - [right]: The right token
  /// - [location]: The source location for error reporting
  ///
  /// Returns:
  /// The concatenated token
  String concatenate(String left, String right, Location location) {
    return _concatenator.concatenate('$left ## $right', location);
  }

  /// Handles special stringizing cases.
  ///
  /// Processes special predefined macros for stringizing.
  ///
  /// Parameters:
  /// - [input]: The input to process
  /// - [location]: The source location for error reporting
  ///
  /// Returns:
  /// The processed result
  String handleSpecialCase(String input, Location location) {
    return _stringizer.handleSpecialCases(input, location);
  }
}