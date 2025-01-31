import '../../dart_macros.dart';
import '../core/exceptions.dart';
import '../core/location.dart';
import 'tokens.dart';

/// Responsible for breaking down source code into tokens
class MacroLexer {
  /// The source code being lexed
  final String source;

  /// The current file being processed
  final String file;

  /// Current position in source
  int _current = 0;

  /// Start of current token
  int _start = 0;

  /// Current line number
  int _line = 1;

  /// Current column number
  int _column = 1;

  /// Constructor
  MacroLexer({
    required this.source,
    required this.file,
  });

  /// Scan all tokens from the source
  List<Token> scanTokens() {
    final tokens = <Token>[];

    while (!_isAtEnd()) {
      _start = _current;
      final token = _scanToken();
      if (token != null) {
        tokens.add(token);
      }
    }

    // Add EOF token
    tokens.add(Token(
      type: TokenType.eof,
      lexeme: '',
      location: _makeLocation(),
    ));

    return tokens;
  }

  /// Scan a single token
  Token? _scanToken() {
    final char = _advance();

    // Handle whitespace
    if (whitespace.contains(char)) {
      while (!_isAtEnd() && whitespace.contains(_peek())) {
        _advance();
      }
      return _makeToken(TokenType.whitespace);
    }

    // Handle newlines
    if (char == '\n') {
      _line++;
      _column = 1;
      return _makeToken(TokenType.newline);
    }

    // Handle comments
    if (char == '/') {
      if (_match('/')) {
        // Line comment
        while (!_isAtEnd() && _peek() != '\n') {
          _advance();
        }
        return _makeToken(TokenType.comment);
      } else if (_match('*')) {
        // Block comment
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

        // Consume the */
        _advance();
        _advance();
        return _makeToken(TokenType.comment);
      }
    }

    // Handle macro directives
    if (char == '#') {
      if (_isAlpha(_peek())) {
        while (_isAlphaNumeric(_peek())) {
          _advance();
        }

        final text = source.substring(_start, _current);
        final type = keywords[text];

        if (type != null) {
          return _makeToken(type);
        }
      }

      // Check for ## operator
      if (_peek() == '#') {
        _advance();
        return _makeToken(TokenType.concatenate);
      }

      return _makeToken(TokenType.stringize);
    }

    // Handle identifiers
    if (_isAlpha(char)) {
      while (_isAlphaNumeric(_peek())) {
        _advance();
      }
      return _makeToken(TokenType.identifier);
    }

    // Handle numbers
    if (_isDigit(char)) {
      while (_isDigit(_peek())) {
        _advance();
      }

      // Look for decimal point
      if (_peek() == '.' && _isDigit(_peekNext())) {
        _advance(); // Consume the '.'

        while (_isDigit(_peek())) {
          _advance();
        }
      }

      return Token(
        type: TokenType.number,
        lexeme: source.substring(_start, _current),
        location: _makeLocation(),
        literal: double.parse(source.substring(_start, _current)),
      );
    }

    // Handle strings
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

      // Consume the closing "
      _advance();

      // Trim the quotes
      final value = source.substring(_start + 1, _current - 1);
      return Token(
        type: TokenType.string,
        lexeme: source.substring(_start, _current),
        location: _makeLocation(),
        literal: value,
      );
    }

    // Handle single-character tokens
    if (singleCharTokens.containsKey(char)) {
      return _makeToken(singleCharTokens[char]!);
    }

    // Unrecognized character
    throw MacroDefinitionException(
      'Unexpected character: $char',
      Location(
        file: file,
        line: _line,
        column: _column,
      ),
    );
  }

  /// Create a token of the given type
  Token _makeToken(TokenType type) {
    final text = source.substring(_start, _current);
    return Token(
      type: type,
      lexeme: text,
      location: _makeLocation(),
    );
  }

  /// Create a location object for the current position
  Location _makeLocation() {
    return Location(
      file: file,
      line: _line,
      column: _column - (_current - _start),
      offset: _start,
    );
  }

  /// Advance to next character
  String _advance() {
    _current++;
    _column++;
    return source[_current - 1];
  }

  /// Look at current character
  String _peek() {
    if (_isAtEnd()) return '\0';
    return source[_current];
  }

  /// Look at next character
  String _peekNext() {
    if (_current + 1 >= source.length) return '\0';
    return source[_current + 1];
  }

  /// Check if current character matches expected
  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (source[_current] != expected) return false;

    _current++;
    _column++;
    return true;
  }

  /// Check if we're at the end
  bool _isAtEnd() => _current >= source.length;

  /// Check if character is alphabetic
  bool _isAlpha(String c) {
    return RegExp(r'[a-zA-Z_]').hasMatch(c);
  }

  /// Check if character is digit
  bool _isDigit(String c) {
    return RegExp(r'[0-9]').hasMatch(c);
  }

  /// Check if character is alphanumeric
  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }
}
