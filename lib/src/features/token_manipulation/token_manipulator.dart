import '../../core/location.dart';
import 'concatenation.dart';
import 'stringizing.dart';

/// Facade for token manipulation operations
class TokenManipulator {
  final TokenConcatenator _concatenator;
  final Stringizer _stringizer;

  TokenManipulator()
      : _concatenator = TokenConcatenator(),
        _stringizer = Stringizer();

  /// Process all token manipulations in a macro replacement
  String process(
    String replacement,
    Map<String, String> parameters,
    Location location,
  ) {
    // First handle stringizing
    var result = _stringizer.processStringizing(
      replacement,
      parameters,
      location,
    );

    // Then handle concatenation
    result = _concatenator.concatenate(result, location);

    return result;
  }

  /// Stringize a single parameter
  String stringize(String param, Location location) {
    return _stringizer.stringize(param, location);
  }

  /// Concatenate two tokens
  String concatenate(String left, String right, Location location) {
    return _concatenator.concatenate('$left ## $right', location);
  }

  /// Handle special stringizing cases
  String handleSpecialCase(String input, Location location) {
    return _stringizer.handleSpecialCases(input, location);
  }
}
