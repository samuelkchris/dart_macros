import '../core/exceptions.dart';
import '../core/location.dart';
import '../core/macro_definition.dart';
import 'tokens.dart';

/// Transforms a sequence of tokens into macro definitions.
///
/// The [MacroParser] is responsible for the syntactic analysis phase of macro
/// processing. It takes tokens produced by the lexer and constructs meaningful
/// macro definitions that capture both the structure and the semantics of the
/// macro directives in the source code.
///
/// This parser specifically handles the #define directive, which can define
/// either object-like macros (simple replacements) or function-like macros
/// (parameterized replacements).
///
/// Example usage:
/// ```dart
/// final parser = MacroParser(tokens);
/// final definitions = parser.parseMacroDefinitions();
/// ```
class MacroParser {
  /// The list of tokens to parse.
  final List<Token> _tokens;

  /// Current position in the token list.
  int _current = 0;

  /// Creates a new parser for the specified tokens.
  ///
  /// Parameters:
  /// - [tokens]: The list of tokens to parse
  MacroParser(this._tokens);

  /// Parses all macro definitions in the token stream.
  ///
  /// This method iterates through the tokens, looking for #define directives
  /// and parsing them into macro definitions. It handles errors gracefully
  /// by synchronizing to the next potential macro definition when an error
  /// is encountered.
  ///
  /// Returns a list of all macro definitions found in the token stream.
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
        /* Error recovery - skip to next potential macro definition */
        _synchronize();
      }
    }

    return definitions;
  }

  /// Parses a single macro definition.
  ///
  /// This method handles the parsing of a #define directive, determining
  /// whether it's an object-like or function-like macro based on the presence
  /// of parentheses after the macro name.
  ///
  /// Returns a [MacroDefinition] representing the parsed macro.
  /// Throws a [MacroDefinitionException] for invalid syntax.
  MacroDefinition _parseDefinition() {
    /* Skip whitespace after #define */
    while (_match(TokenType.whitespace)) {}

    /* Get macro name */
    if (!_check(TokenType.identifier)) {
      throw MacroDefinitionException(
        'Expected macro name',
        _peek().location,
      );
    }

    final nameToken = _advance();
    final name = nameToken.lexeme;

    /* Check for function-like macro */
    if (_match(TokenType.leftParen)) {
      return _parseFunctionMacro(name, nameToken.location);
    }

    /* Object-like macro */
    return _parseObjectMacro(name, nameToken.location);
  }

  /// Parses a function-like macro definition.
  ///
  /// This method handles macros with parameters, parsing the parameter list
  /// and the replacement text. Function-like macros take the form:
  /// #define NAME(param1, param2, ...) replacement
  ///
  /// Parameters:
  /// - [name]: The name of the macro
  /// - [location]: The source location of the macro name
  ///
  /// Returns a function-like macro definition.
  /// Throws a [MacroDefinitionException] for invalid syntax.
  MacroDefinition _parseFunctionMacro(String name, Location location) {
    final parameters = <String>[];

    /* Parse parameters */
    if (!_check(TokenType.rightParen)) {
      do {
        /* Skip whitespace before parameter */
        while (_match(TokenType.whitespace)) {}

        if (!_check(TokenType.identifier)) {
          throw MacroDefinitionException(
            'Expected parameter name',
            _peek().location,
          );
        }

        parameters.add(_advance().lexeme);

        /* Skip whitespace after parameter */
        while (_match(TokenType.whitespace)) {}
      } while (_match(TokenType.comma));
    }

    /* Validate closing parenthesis */
    if (!_match(TokenType.rightParen)) {
      throw MacroDefinitionException(
        'Expected ")" after parameters',
        _peek().location,
      );
    }

    /* Skip whitespace before replacement */
    while (_match(TokenType.whitespace)) {}

    /* Parse replacement text */
    final replacement = _parseReplacement();

    return MacroDefinition.function(
      name: name,
      parameters: parameters,
      replacement: replacement,
      location: location,
    );
  }

  /// Parses an object-like macro definition.
  ///
  /// This method handles macros without parameters, parsing only the replacement
  /// text. Object-like macros take the form: #define NAME replacement
  ///
  /// Parameters:
  /// - [name]: The name of the macro
  /// - [location]: The source location of the macro name
  ///
  /// Returns an object-like macro definition.
  MacroDefinition _parseObjectMacro(String name, Location location) {
    /* Skip whitespace before replacement */
    while (_match(TokenType.whitespace)) {}

    /* Parse replacement text */
    final replacement = _parseReplacement();

    return MacroDefinition.object(
      name: name,
      replacement: replacement,
      location: location,
    );
  }

  /// Parses the replacement text of a macro.
  ///
  /// This method collects tokens until the end of the line or file, handling
  /// special tokens like parentheses, stringize (#), and concatenate (##).
  /// It also performs validation of syntax elements like balanced parentheses.
  ///
  /// Returns the parsed replacement text as a string.
  /// Throws a [MacroDefinitionException] for unmatched parentheses.
  String _parseReplacement() {
    final replacement = StringBuffer();
    var parenDepth = 0;

    /* Process tokens until newline or EOF */
    while (!_isAtEnd() && !_isAtNewline()) {
      final token = _advance();

      switch (token.type) {
        case TokenType.leftParen:
        /* Track parenthesis depth */
          parenDepth++;
          replacement.write('(');
          break;

        case TokenType.rightParen:
        /* Validate parenthesis depth */
          if (--parenDepth < 0) {
            throw MacroDefinitionException(
              'Unmatched parentheses in replacement',
              token.location,
            );
          }
          replacement.write(')');
          break;

        case TokenType.stringize:
        /* Handle # operator */
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
        /* Handle ## operator */
          replacement.write('##');
          break;

        case TokenType.whitespace:
        /* Collapse multiple whitespace into one */
          if (replacement.isNotEmpty && !replacement.toString().endsWith(' ')) {
            replacement.write(' ');
          }
          break;

        default:
        /* Add token lexeme to replacement */
          replacement.write(token.lexeme);
      }
    }

    /* Validate parenthesis balance */
    if (parenDepth > 0) {
      throw MacroDefinitionException(
        'Unclosed parentheses in replacement',
        _previous().location,
      );
    }

    return replacement.toString().trim();
  }

  /// Performs error recovery after encountering a syntax error.
  ///
  /// This method skips tokens until it finds a potential synchronization point,
  /// such as a newline or the beginning of another macro directive. This allows
  /// the parser to continue after syntax errors rather than failing completely.
  void _synchronize() {
    _advance();

    while (!_isAtEnd()) {
      /* Synchronize at newlines */
      if (_previous().type == TokenType.newline) {
        return;
      }

      /* Synchronize at macro directives */
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

  /// Checks if the current token matches the expected type and advances if it does.
  ///
  /// Parameters:
  /// - [type]: The token type to check for
  ///
  /// Returns true if the current token matches and was consumed, false otherwise.
  bool _match(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  /// Checks if the current token is of the expected type without advancing.
  ///
  /// Parameters:
  /// - [type]: The token type to check for
  ///
  /// Returns true if the current token matches the expected type.
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  /// Consumes the current token and advances to the next one.
  ///
  /// Returns the token that was consumed.
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  /// Returns the most recently consumed token.
  ///
  /// Returns the token at the position immediately before the current position.
  Token _previous() {
    return _tokens[_current - 1];
  }

  /// Returns the current token without consuming it.
  ///
  /// Returns the token at the current position.
  Token _peek() {
    return _tokens[_current];
  }

  /// Checks if the current token is a newline or end-of-file.
  ///
  /// Returns true if the current token is a newline or EOF token.
  bool _isAtNewline() {
    return _check(TokenType.newline) || _check(TokenType.eof);
  }

  /// Checks if the current position is at the end of the token stream.
  ///
  /// Returns true if the current token is an EOF token.
  bool _isAtEnd() {
    return _peek().type == TokenType.eof;
  }
}

/// Parses and evaluates expressions found in macro definitions and usages.
///
/// The [MacroExpressionParser] handles the parsing of expressions that might
/// appear in macro replacement text or in conditional directives. It implements
/// a recursive descent parser for expressions with proper precedence handling.
///
/// This parser supports binary operators, unary operators, literals, variables,
/// and parenthesized expressions, making it capable of handling complex
/// expressions in macro contexts.
class MacroExpressionParser {
  /// The list of tokens to parse.
  final List<Token> _tokens;

  /// Current position in the token list.
  int _current = 0;

  /// Creates a new expression parser for the specified tokens.
  ///
  /// Parameters:
  /// - [tokens]: The list of tokens to parse
  MacroExpressionParser(this._tokens);

  /// Parses an expression from the token stream.
  ///
  /// This is the entry point for expression parsing, which delegates to
  /// specialized methods based on the grammar's precedence rules.
  ///
  /// Returns the parsed expression in a form that can be evaluated.
  dynamic parseExpression() {
    return _expression();
  }

  /// Parses a general expression.
  ///
  /// This is the lowest precedence level in the expression grammar.
  /// It delegates to other parsing methods according to precedence rules.
  ///
  /// Returns the parsed expression.
  dynamic _expression() {
    return _equality();
  }

  /// Parses equality expressions (==, !=).
  ///
  /// This handles expressions with equality operators, which have lower
  /// precedence than comparison operators.
  ///
  /// Returns the parsed equality expression.
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

  /// Parses comparison expressions (>, >=, <, <=).
  ///
  /// This handles expressions with comparison operators, which have lower
  /// precedence than arithmetic operators.
  ///
  /// Returns the parsed comparison expression.
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

  /// Parses term expressions (+, -).
  ///
  /// This handles expressions with additive operators, which have lower
  /// precedence than multiplicative operators.
  ///
  /// Returns the parsed term expression.
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

  /// Parses factor expressions (*, /, %).
  ///
  /// This handles expressions with multiplicative operators, which have lower
  /// precedence than unary operators.
  ///
  /// Returns the parsed factor expression.
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

  /// Parses unary expressions (!, -).
  ///
  /// This handles expressions with unary operators, which have higher
  /// precedence than binary operators.
  ///
  /// Returns the parsed unary expression.
  dynamic _unary() {
    if (_match([TokenType.identifier]) &&
        (_previous().lexeme == '!' || _previous().lexeme == '-')) {
      final operator = _previous().lexeme;
      final right = _unary();
      return ['unary', operator, right];
    }

    return _primary();
  }

  /// Parses primary expressions (literals, identifiers, parenthesized expressions).
  ///
  /// This handles the highest precedence elements of the expression grammar:
  /// numbers, strings, identifiers, and parenthesized expressions.
  ///
  /// Returns the parsed primary expression.
  /// Throws a [MacroDefinitionException] for invalid syntax.
  dynamic _primary() {
    /* Handle numeric literals */
    if (_match([TokenType.number])) return _previous().literal;

    /* Handle string literals */
    if (_match([TokenType.string])) return _previous().literal;

    /* Handle identifiers (variables, constants) */
    if (_match([TokenType.identifier])) return _previous().lexeme;

    /* Handle parenthesized expressions */
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

  /// Checks if the current token matches any of the expected types and advances if it does.
  ///
  /// Parameters:
  /// - [types]: The list of token types to check for
  ///
  /// Returns true if the current token matches any of the types and was consumed.
  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  /// Consumes the current token if it matches the expected type.
  ///
  /// If the current token doesn't match, throws an exception with the provided message.
  ///
  /// Parameters:
  /// - [type]: The expected token type
  /// - [message]: The error message to use if the token doesn't match
  ///
  /// Returns the consumed token.
  /// Throws a [MacroDefinitionException] if the token doesn't match.
  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw MacroDefinitionException(message, _peek().location);
  }

  /// Checks if the current token is of the expected type without advancing.
  ///
  /// Parameters:
  /// - [type]: The token type to check for
  ///
  /// Returns true if the current token matches the expected type.
  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  /// Consumes the current token and advances to the next one.
  ///
  /// Returns the token that was consumed.
  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  /// Returns the most recently consumed token.
  Token _previous() => _tokens[_current - 1];

  /// Returns the current token without consuming it.
  Token _peek() => _tokens[_current];

  /// Checks if the current position is at the end of the token stream.
  bool _isAtEnd() => _peek().type == TokenType.eof;
}