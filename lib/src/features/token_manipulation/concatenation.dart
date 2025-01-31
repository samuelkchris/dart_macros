import '../../core/exceptions.dart';
import '../../core/location.dart';

/// Handles token concatenation operations (##)
class TokenConcatenator {
  /// Concatenate tokens in a macro replacement
  String concatenate(String replacement, Location location) {
    var result = replacement;
    final pattern = RegExp(r'(\S+)\s*##\s*(\S+)');

    while (result.contains('##')) {
      result = result.replaceAllMapped(pattern, (match) {
        final left = match.group(1)!;
        final right = match.group(2)!;

        // Validate the concatenation
        _validateConcatenation(left, right, location);

        return _concatenateTokens(left, right);
      });

      // If ## still exists but pattern doesn't match, there's an error
      if (result.contains('##')) {
        throw MacroDefinitionException(
          'Invalid token concatenation',
          location,
        );
      }
    }

    return result;
  }

  /// Validate that tokens can be concatenated
  void _validateConcatenation(String left, String right, Location location) {
    // Check for empty operands
    if (left.isEmpty || right.isEmpty) {
      throw MacroDefinitionException(
        'Empty token in concatenation',
        location,
      );
    }

    // Check for invalid token combinations
    if (_isNumeric(left) && _isNumeric(right)) {
      // Allow number concatenation
      return;
    }

    if (_isIdentifierPart(left) && _isIdentifierPart(right)) {
      // Allow identifier concatenation
      return;
    }

    // Check if result would be valid
    final result = left + right;
    if (!_isValidToken(result)) {
      throw MacroDefinitionException(
        'Invalid token concatenation result: $result',
        location,
      );
    }
  }

  /// Concatenate two tokens
  String _concatenateTokens(String left, String right) {
    // Handle special cases
    if (_isNumeric(left) && _isNumeric(right)) {
      return left + right;
    }

    // Remove any extra whitespace
    return left.trim() + right.trim();
  }

  /// Check if string is numeric
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(str);
  }

  /// Check if string is part of a valid identifier
  bool _isIdentifierPart(String str) {
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(str);
  }

  /// Check if result would be a valid token
  bool _isValidToken(String str) {
    return RegExp(r'^[a-zA-Z0-9_]+$|^[0-9]+(\.[0-9]+)?$|^".*"$').hasMatch(str);
  }
}