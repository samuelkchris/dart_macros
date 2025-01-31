import '../../core/exceptions.dart';
import '../../core/location.dart';

/// Handles stringizing operations (#)
class Stringizer {
  /// Convert a macro parameter to a string literal
  String stringize(String param, Location location) {
    // Handle empty parameter
    if (param.trim().isEmpty) {
      return '""';
    }

    // Remove leading/trailing whitespace
    var result = param.trim();

    // Handle quotes in the parameter
    result = result.replaceAll('"', '\\"');

    // Add quotes
    return '"$result"';
  }

  /// Process stringizing operators in a macro replacement
  String processStringizing(
      String replacement,
      Map<String, String> params,
      Location location,
      ) {
    var result = replacement;
    final pattern = RegExp(r'#(\w+)');

    result = result.replaceAllMapped(pattern, (match) {
      final param = match.group(1)!;

      // Check if it's a valid parameter
      if (!params.containsKey(param)) {
        throw MacroDefinitionException(
          'Undefined parameter in stringizing operation: $param',
          location,
        );
      }

      return stringize(params[param]!, location);
    });

    return result;
  }

  /// Convert multiple parameters to a string literal
  String stringizeAll(List<String> params, Location location) {
    if (params.isEmpty) {
      return '""';
    }

    return stringize(params.join(', '), location);
  }

  /// Handle special stringizing cases
  String handleSpecialCases(String input, Location location) {
    // Handle __FILE__ macro
    if (input == '__FILE__') {
      return stringize(location.file, location);
    }

    // Handle __LINE__ macro
    if (input == '__LINE__') {
      return stringize(location.line.toString(), location);
    }

    // Handle __FUNCTION__ macro (if available)
    if (input == '__FUNCTION__') {
      // This would need context from the parser
      return '""';
    }

    return input;
  }

  /// Validate stringizing operation
  void validateStringizing(String param, Location location) {
    // Check for nested stringizing
    if (param.contains('#')) {
      throw MacroDefinitionException(
        'Nested stringizing operations are not allowed',
        location,
      );
    }

    // Check for unmatched quotes
    var quoteCount = 0;
    for (var i = 0; i < param.length; i++) {
      if (param[i] == '"' && (i == 0 || param[i - 1] != '\\')) {
        quoteCount++;
      }
    }

    if (quoteCount % 2 != 0) {
      throw MacroDefinitionException(
        'Unmatched quotes in stringizing operation',
        location,
      );
    }
  }

  /// Format the stringized output for better readability
  String formatStringized(String input) {
    var result = input;

    // Collapse multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // Handle special characters
    result = result.replaceAll('\n', '\\n')
        .replaceAll('\t', '\\t')
        .replaceAll('\r', '\\r');

    return result;
  }
}