import '../core/location.dart';

/// Represents different types of tokens in macro processing
enum TokenType {
  // Directives
  define,    // #define
  undef,     // #undef
  ifdef,     // #ifdef
  ifndef,    // #ifndef
  endif,     // #endif
  elif,      // #elif
  else_,     // #else
  include,   // #include

  // Operators
  stringize,     // #
  concatenate,   // ##

  // Basic elements
  identifier,    // variable names, macro names
  number,        // numeric literals
  string,        // string literals
  character,     // character literals

  // Delimiters
  leftParen,     // (
  rightParen,    // )
  leftBrace,     // {
  rightBrace,    // }
  comma,         // ,
  semicolon,     // ;

  // Special
  whitespace,
  newline,
  comment,       // Both // and /* */

  // Other
  replacement,   // Macro replacement text
  eof           // End of file
}

/// Represents a token in the macro processing system
class Token {
  /// The type of token
  final TokenType type;

  /// The actual text of the token
  final String lexeme;

  /// The location of the token in source
  final Location location;

  /// Optional literal value (for numbers, strings, etc.)
  final Object? literal;

  const Token({
    required this.type,
    required this.lexeme,
    required this.location,
    this.literal,
  });

  @override
  String toString() => 'Token($type, "$lexeme")';

  /// Whether this token is a macro directive
  bool get isDirective => type.name.startsWith('#');

  /// Whether this token is an operator
  bool get isOperator => type == TokenType.stringize ||
      type == TokenType.concatenate;

  /// Whether this token should be ignored in parsing
  bool get isIgnorable => type == TokenType.whitespace ||
      type == TokenType.comment;
}

/// Represents a location in the source code
class TokenLocation {
  /// The source file
  final String file;

  /// The line number (1-based)
  final int line;

  /// The column number (1-based)
  final int column;

  /// The offset from the start of the file
  final int offset;

  const TokenLocation({
    required this.file,
    required this.line,
    required this.column,
    required this.offset,
  });

  @override
  String toString() => '$file:$line:$column';

  /// Create a new location with an updated column
  TokenLocation moveColumn(int delta) {
    return TokenLocation(
      file: file,
      line: line,
      column: column + delta,
      offset: offset + delta,
    );
  }

  /// Create a new location with an updated line
  TokenLocation nextLine() {
    return TokenLocation(
      file: file,
      line: line + 1,
      column: 1,
      offset: offset + 1,
    );
  }
}

/// Keywords and their corresponding token types
const Map<String, TokenType> keywords = {
  '#define': TokenType.define,
  '#undef': TokenType.undef,
  '#ifdef': TokenType.ifdef,
  '#ifndef': TokenType.ifndef,
  '#endif': TokenType.endif,
  '#elif': TokenType.elif,
  '#else': TokenType.else_,
  '#include': TokenType.include,
};

/// Single-character tokens and their types
const Map<String, TokenType> singleCharTokens = {
  '(': TokenType.leftParen,
  ')': TokenType.rightParen,
  '{': TokenType.leftBrace,
  '}': TokenType.rightBrace,
  ',': TokenType.comma,
  ';': TokenType.semicolon,
  '#': TokenType.stringize,
};

/// Special character sequences
const String operators = '#';
const String delimiters = '(){},;';
const String whitespace = ' \t\r';