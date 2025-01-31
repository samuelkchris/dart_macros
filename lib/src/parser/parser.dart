import '../core/exceptions.dart';
import '../core/location.dart';
import '../core/macro_definition.dart';
import 'tokens.dart';

/// Parses tokens into macro definitions and usages
class MacroParser {
  /// List of tokens to parse
  final List<Token> _tokens;

  /// Current position in token list
  int _current = 0;

  MacroParser(this._tokens);

  /// Parse all macro definitions
  List<MacroDefinition> parseMacroDefinitions() {
    final definitions = <MacroDefinition>[];

    while (!_isAtEnd()) {
      try {
        if (_match(TokenType.define)) {
          definitions.add(_parseDefinition());
        } else {
          _advance();
        }
      } on MacroException {
        _synchronize();
      }
    }

    return definitions;
  }

  /// Parse a single macro definition
  MacroDefinition _parseDefinition() {
    // Skip whitespace after #define
    while (_match(TokenType.whitespace)) {}

    // Get macro name
    if (!_check(TokenType.identifier)) {
      throw MacroDefinitionException(
        'Expected macro name',
        _peek().location,
      );
    }

    final nameToken = _advance();
    final name = nameToken.lexeme;

    // Check for function-like macro
    if (_match(TokenType.leftParen)) {
      return _parseFunctionMacro(name, nameToken.location);
    }

    // Object-like macro
    return _parseObjectMacro(name, nameToken.location);
  }

  /// Parse a function-like macro definition
  MacroDefinition _parseFunctionMacro(String name, Location location) {
    final parameters = <String>[];

    // Parse parameters
    if (!_check(TokenType.rightParen)) {
      do {
        while (_match(TokenType.whitespace)) {}

        if (!_check(TokenType.identifier)) {
          throw MacroDefinitionException(
            'Expected parameter name',
            _peek().location,
          );
        }

        parameters.add(_advance().lexeme);

        while (_match(TokenType.whitespace)) {}
      } while (_match(TokenType.comma));
    }

    if (!_match(TokenType.rightParen)) {
      throw MacroDefinitionException(
        'Expected ")" after parameters',
        _peek().location,
      );
    }

    // Skip whitespace before replacement
    while (_match(TokenType.whitespace)) {}

    // Parse replacement text
    final replacement = _parseReplacement();

    return MacroDefinition.function(
      name: name,
      parameters: parameters,
      replacement: replacement,
      location: location,
    );
  }

  /// Parse an object-like macro definition
  MacroDefinition _parseObjectMacro(String name, Location location) {
    // Skip whitespace before replacement
    while (_match(TokenType.whitespace)) {}

    // Parse replacement text
    final replacement = _parseReplacement();

    return MacroDefinition.object(
      name: name,
      replacement: replacement,
      location: location,
    );
  }

  /// Parse macro replacement text
  String _parseReplacement() {
    final replacement = StringBuffer();
    var parenDepth = 0;

    while (!_isAtEnd() && !_isAtNewline()) {
      final token = _advance();

      switch (token.type) {
        case TokenType.leftParen:
          parenDepth++;
          replacement.write('(');
          break;

        case TokenType.rightParen:
          if (--parenDepth < 0) {
            throw MacroDefinitionException(
              'Unmatched parentheses in replacement',
              token.location,
            );
          }
          replacement.write(')');
          break;

        case TokenType.stringize:
          if (_match(TokenType.identifier)) {
            replacement.write('#${_previous().lexeme}');
          } else {
            throw MacroDefinitionException(
              'Expected identifier after #',
              token.location,
            );
          }
          break;

        case TokenType.concatenate:
          replacement.write('##');
          break;

        case TokenType.whitespace:
          // Collapse multiple whitespace into one
          if (replacement.isNotEmpty && !replacement.toString().endsWith(' ')) {
            replacement.write(' ');
          }
          break;

        default:
          replacement.write(token.lexeme);
      }
    }

    if (parenDepth > 0) {
      throw MacroDefinitionException(
        'Unclosed parentheses in replacement',
        _previous().location,
      );
    }

    return replacement.toString().trim();
  }

  /// Error recovery - skip tokens until next macro definition
  void _synchronize() {
    _advance();

    while (!_isAtEnd()) {
      if (_previous().type == TokenType.newline) {
        return;
      }

      switch (_peek().type) {
        case TokenType.define:
        case TokenType.undef:
        case TokenType.ifdef:
        case TokenType.ifndef:
        case TokenType.endif:
          return;
        default:
          _advance();
      }
    }
  }

  /// Check if current token matches given type
  bool _match(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  /// Check if current token is of given type
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  /// Get current token and advance
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  /// Get previous token
  Token _previous() {
    return _tokens[_current - 1];
  }

  /// Get current token
  Token _peek() {
    return _tokens[_current];
  }

  /// Check if we're at a newline
  bool _isAtNewline() {
    return _check(TokenType.newline) || _check(TokenType.eof);
  }

  /// Check if we're at the end
  bool _isAtEnd() {
    return _peek().type == TokenType.eof;
  }
}

/// Parse a macro expression from tokens
class MacroExpressionParser {
  final List<Token> _tokens;
  int _current = 0;

  MacroExpressionParser(this._tokens);

  /// Parse an expression in a macro
  dynamic parseExpression() {
    return _expression();
  }

  dynamic _expression() {
    return _equality();
  }

  dynamic _equality() {
    var expr = _comparison();

    while (_match([TokenType.identifier]) &&
        (_previous().lexeme == '==' || _previous().lexeme == '!=')) {
      final operator = _previous().lexeme;
      final right = _comparison();
      expr = [expr, operator, right];
    }

    return expr;
  }

  dynamic _comparison() {
    var expr = _term();

    while (_match([TokenType.identifier]) &&
        (_previous().lexeme == '>' ||
            _previous().lexeme == '>=' ||
            _previous().lexeme == '<' ||
            _previous().lexeme == '<=')) {
      final operator = _previous().lexeme;
      final right = _term();
      expr = [expr, operator, right];
    }

    return expr;
  }

  dynamic _term() {
    var expr = _factor();

    while (_match([TokenType.identifier]) &&
        (_previous().lexeme == '+' || _previous().lexeme == '-')) {
      final operator = _previous().lexeme;
      final right = _factor();
      expr = [expr, operator, right];
    }

    return expr;
  }

  dynamic _factor() {
    var expr = _unary();

    while (_match([TokenType.identifier]) &&
        (_previous().lexeme == '*' ||
            _previous().lexeme == '/' ||
            _previous().lexeme == '%')) {
      final operator = _previous().lexeme;
      final right = _unary();
      expr = [expr, operator, right];
    }

    return expr;
  }

  dynamic _unary() {
    if (_match([TokenType.identifier]) &&
        (_previous().lexeme == '!' || _previous().lexeme == '-')) {
      final operator = _previous().lexeme;
      final right = _unary();
      return ['unary', operator, right];
    }

    return _primary();
  }

  dynamic _primary() {
    if (_match([TokenType.number])) return _previous().literal;
    if (_match([TokenType.string])) return _previous().literal;
    if (_match([TokenType.identifier])) return _previous().lexeme;

    if (_match([TokenType.leftParen])) {
      final expr = _expression();
      _consume(TokenType.rightParen, 'Expected ")" after expression');
      return ['group', expr];
    }

    throw MacroDefinitionException(
      'Expected expression',
      _peek().location,
    );
  }

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw MacroDefinitionException(message, _peek().location);
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  Token _previous() => _tokens[_current - 1];

  Token _peek() => _tokens[_current];

  bool _isAtEnd() => _peek().type == TokenType.eof;
}
