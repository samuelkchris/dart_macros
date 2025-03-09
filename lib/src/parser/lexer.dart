import '../../dart_macros.dart';
import '../core/exceptions.dart';
import '../core/location.dart';
import 'tokens.dart';

/// Transforms source code text into a sequence of tokens for macro processing.
///
/// The [MacroLexer] is responsible for the lexical analysis phase of macro processing.
/// It takes raw source code as input and breaks it down into meaningful tokens
/// that can be processed by the parser. This class handles various token types
/// including macro directives, operators, identifiers, literals, and special tokens.
///
/// The lexer keeps track of the current position in the source code, maintaining
/// line and column information for error reporting and location tracking.
///
/// Example usage:
/// ```dart
/// final lexer = MacroLexer(
///   source: '#define VERSION "1.0.0"',
///   file: 'config.dart'
/// );
/// final tokens = lexer.scanTokens();
/// ```
class MacroLexer {
  /// The source code being analyzed.
  final String source;

  /// The name or path of the file being processed.
  ///
  /// Used for error reporting and location information in tokens.
  final String file;

  /// Current position in the source code.
  ///
  /// Represents the index of the next character to be consumed.
  int _current = 0;

  /// Starting position of the current token being scanned.
  int _start = 0;

  /// Current line number in the source code (1-based).
  int _line = 1;

  /// Current column number in the source code (1-based).
  int _column = 1;

  /// Creates a new lexer for the specified source code and file.
  ///
  /// Parameters:
  /// - [source]: The source code text to analyze
  /// - [file]: The name or path of the file being processed
  MacroLexer({
    required this.source,
    required this.file,
  });

  /// Scans the entire source code and produces a list of tokens.
  ///
  /// This method processes the source code character by character,
  /// identifying and creating tokens until the end of the file.
  /// It adds an EOF token at the end to signify the end of input.
  ///
  /// Returns a complete list of tokens from the source code.
  List<Token> scanTokens() {
    final tokens = <Token>[];

    /* Process source until reaching the end */
    while (!_isAtEnd()) {
      _start = _current;
      final token = _scanToken();
      if (token != null) {
        tokens.add(token);
      }
    }

    /* Add EOF token to signify end of input */
    tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      location: _makeLocation(),
    ));

    return tokens;
  }

  /// Scans and returns the next token from the source code.
  ///
  /// This method identifies the type of the next token based on the
  /// current character and any following characters as needed. It handles
  /// various token types including whitespace, comments, directives,
  /// identifiers, numbers, strings, and single-character tokens.
  ///
  /// Returns the next token, or null for certain ignored elements.
  /// Throws a [MacroDefinitionException] for invalid syntax.
  Token? _scanToken() {
    final char = _advance();

    /* Handle whitespace */
    if (whitespace.contains(char)) {
      while (!_isAtEnd() && whitespace.contains(_peek())) {
        _advance();
      }
      return _makeToken(TokenType.whitespace);
    }

    /* Handle newlines */
    if (char == '\n') {
      _line++;
      _column = 1;
      return _makeToken(TokenType.newline);
    }

    /* Handle comments */
    if (char == '/') {
      if (_match('/')) {
        /* Line comment - consume until end of line */
        while (!_isAtEnd() && _peek() != '\n') {
          _advance();
        }
        return _makeToken(TokenType.comment);
      } else if (_match('*')) {
        /* Block comment - consume until closing marker */
        while (!_isAtEnd() && !(_peek() == '*' && _peekNext() == '/')) {
          if (_peek() == '\n') {
            _line++;
            _column = 1;
          }
          _advance();
        }

        if (_isAtEnd()) {
          throw MacroDefinitionException(
            'Unterminated block comment',
            Location(
              file: file,
              line: _line,
              column: _column,
            ),
          );
        }

    /* Consume the closing */
    _advance();
    _advance();
    return _makeToken(TokenType.comment);
    }
    }

    /* Handle macro directives and operators */
    if (char == '#') {
    if (_isAlpha(_peek())) {
    /* Process directive keywords (#define, #ifdef, etc.) */
    while (_isAlphaNumeric(_peek())) {
    _advance();
    }

    final text = source.substring(_start, _current);
    final type = keywords[text];

    if (type != null) {
    return _makeToken(type);
    }
    }

    /* Check for ## operator (token concatenation) */
    if (_peek() == '#') {
    _advance();
    return _makeToken(TokenType.concatenate);
    }

    /* Single # operator (stringize) */
    return _makeToken(TokenType.stringize);
    }

    /* Handle identifiers */
    if (_isAlpha(char)) {
    while (_isAlphaNumeric(_peek())) {
    _advance();
    }
    return _makeToken(TokenType.identifier);
    }

    /* Handle numbers */
    if (_isDigit(char)) {
    /* Process integer part */
    while (_isDigit(_peek())) {
    _advance();
    }

    /* Process decimal part if present */
    if (_peek() == '.' && _isDigit(_peekNext())) {
    _advance(); // Consume the '.'

    while (_isDigit(_peek())) {
    _advance();
    }
    }

    /* Create token with numeric literal value */
    return Token(
    type: TokenType.number,
    lexeme: source.substring(_start, _current),
    location: _makeLocation(),
    literal: double.parse(source.substring(_start, _current)),
    );
    }

    /* Handle string literals */
    if (char == '"') {
    while (_peek() != '"' && !_isAtEnd()) {
    if (_peek() == '\n') {
    _line++;
    _column = 1;
    }
    _advance();
    }

    if (_isAtEnd()) {
    throw MacroDefinitionException(
    'Unterminated string',
    Location(
    file: file,
    line: _line,
    column: _column,
    ),
    );
    }

    /* Consume the closing quote */
    _advance();

    /* Create token with string literal value (without quotes) */
    final value = source.substring(_start + 1, _current - 1);
    return Token(
    type: TokenType.string,
    lexeme: source.substring(_start, _current),
    location: _makeLocation(),
    literal: value,
    );
    }

    /* Handle single-character tokens */
    if (singleCharTokens.containsKey(char)) {
    return _makeToken(singleCharTokens[char]!);
    }

    /* Unrecognized character - report error */
    throw MacroDefinitionException(
    'Unexpected character: $char',
    Location(
    file: file,
    line: _line,
    column: _column,
    ),
    );
  }

  /// Creates a token of the specified type from the current lexeme.
  ///
  /// Uses the current [_start] and [_current] positions to extract
  /// the token text from the source code.
  ///
  /// Parameters:
  /// - [type]: The type of token to create
  ///
  /// Returns a new token with the specified type, current lexeme, and location.
  Token _makeToken(TokenType type) {
    final text = source.substring(_start, _current);
    return Token(
      type: type,
      lexeme: text,
      location: _makeLocation(),
    );
  }

  /// Creates a location object for the current token position.
  ///
  /// The location includes the file name, line number, column number,
  /// and character offset in the source code.
  ///
  /// Returns a new location object for the current token.
  Location _makeLocation() {
    return Location(
      file: file,
      line: _line,
      column: _column - (_current - _start),
      offset: _start,
    );
  }

  /// Advances to the next character in the source code.
  ///
  /// Increments the current position and column number, and returns
  /// the character that was just consumed.
  ///
  /// Returns the character at the current position before advancing.
  String _advance() {
    _current++;
    _column++;
    return source[_current - 1];
  }

  /// Returns the current character without advancing.
  ///
  /// This "peek" operation looks at the current character without consuming it.
  /// Returns '\0' if at the end of the source code.
  ///
  /// Returns the current character, or '\0' if at the end.
  String _peek() {
    if (_isAtEnd()) return '0';
    return source[_current];
  }

  /// Returns the next character without advancing.
  ///
  /// This looks one character ahead of the current position without consuming it.
  /// Returns '\0' if at or near the end of the source code.
  ///
  /// Returns the next character, or '\0' if at or near the end.
  String _peekNext() {
    if (_current + 1 >= source.length) return '0';
    return source[_current + 1];
  }

  /// Checks if the current character matches the expected character.
  ///
  /// If there's a match, advances to the next character and returns true.
  /// Otherwise, returns false without advancing.
  ///
  /// Parameters:
  /// - [expected]: The character to check for
  ///
  /// Returns true if the current character matches and was consumed, false otherwise.
  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (source[_current] != expected) return false;

    _current++;
    _column++;
    return true;
  }

  /// Checks if the current position is at the end of the source code.
  ///
  /// Returns true if the current position is at or beyond the end of the source.
  bool _isAtEnd() => _current >= source.length;

  /// Checks if a character is alphabetic or underscore.
  ///
  /// Used to identify the start of identifiers, which can begin with
  /// a letter or underscore.
  ///
  /// Parameters:
  /// - [c]: The character to check
  ///
  /// Returns true if the character is a letter or underscore.
  bool _isAlpha(String c) {
    return RegExp(r'[a-zA-Z_]').hasMatch(c);
  }

  /// Checks if a character is a digit.
  ///
  /// Used to identify numeric literals and the numeric parts of identifiers.
  ///
  /// Parameters:
  /// - [c]: The character to check
  ///
  /// Returns true if the character is a digit (0-9).
  bool _isDigit(String c) {
    return RegExp(r'[0-9]').hasMatch(c);
  }

  /// Checks if a character is alphanumeric or underscore.
  ///
  /// Used to identify the continuation of identifiers, which can contain
  /// letters, digits, and underscores.
  ///
  /// Parameters:
  /// - [c]: The character to check
  ///
  /// Returns true if the character is a letter, digit, or underscore.
  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }
}