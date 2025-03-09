import '../core/location.dart';

/// Defines all possible token types used in macro processing.
///
/// Each token type represents a specific element in macro syntax, including
/// directives like #define and #ifdef, operators, basic elements like identifiers
/// and literals, delimiters, and special tokens like whitespace and comments.
///
/// This comprehensive enumeration enables precise identification and handling
/// of each element during the lexing and parsing phases of macro processing.
enum TokenType {
  // Directive tokens - preprocessor commands
  define,    // #define - Defines a macro
  undef,     // #undef - Undefines a previously defined macro
  ifdef,     // #ifdef - Conditional compilation if macro is defined
  ifndef,    // #ifndef - Conditional compilation if macro is not defined
  endif,     // #endif - Ends a conditional compilation block
  elif,      // #elif - Else if in conditional compilation
  else_,     // #else - Else in conditional compilation
  include,   // #include - Includes another file

  // Operator tokens - special macro operations
  stringize,     // # - Converts a macro parameter to a string literal
  concatenate,   // ## - Concatenates two tokens

  // Basic element tokens - fundamental language components
  identifier,    // Names of macros, parameters, variables, etc.
  number,        // Numeric literals (integers, decimals)
  string,        // String literals (enclosed in quotes)
  character,     // Character literals (single quotes)

  // Delimiter tokens - structural elements
  leftParen,     // ( - Start of parameter list or grouping
  rightParen,    // ) - End of parameter list or grouping
  leftBrace,     // { - Start of block
  rightBrace,    // } - End of block
  comma,         // , - Parameter separator
  semicolon,     // ; - Statement terminator

  // Special tokens - non-semantic elements
  whitespace,    // Spaces, tabs, etc.
  newline,       // Line breaks
  comment,       // Single-line (//) and multi-line (/* */) comments

  // Other tokens
  replacement,   // Macro replacement text
  eof            // End of file marker
}

/// Represents a single token in the macro processing system.
///
/// A token is the smallest unit of meaning in the macro language. Each token
/// has a type that identifies its role, a lexeme that contains the actual text,
/// a location in the source code, and optionally a literal value for tokens
/// like numbers and strings.
///
/// The [Token] class provides additional utility properties to determine if
/// a token is a directive, operator, or should be ignored during parsing.
class Token {
  /// The type of this token, defining its role in the macro language.
  final TokenType type;

  /// The actual text content of the token from the source code.
  final String lexeme;

  /// The location of this token in the source file (file, line, column).
  final Location location;

  /// Optional literal value for number and string tokens.
  ///
  /// For [TokenType.number], this is the parsed numeric value.
  /// For [TokenType.string], this is the string content without quotes.
  final Object? literal;

  /// Creates a new token with the specified type, lexeme, location, and optional literal.
  const Token({
    required this.type,
    required this.lexeme,
    required this.location,
    this.literal,
  });

  /// Returns a string representation of this token for debugging.
  @override
  String toString() => 'Token($type, "$lexeme")';

  /// Indicates whether this token is a macro directive (starts with #).
  ///
  /// This includes tokens like #define, #ifdef, #ifndef, etc.
  bool get isDirective => type.name.startsWith('#');

  /// Indicates whether this token is a macro operator (# or ##).
  ///
  /// This includes the stringize (#) and concatenate (##) operators.
  bool get isOperator => type == TokenType.stringize ||
      type == TokenType.concatenate;

  /// Indicates whether this token should be ignored during parsing.
  ///
  /// This includes whitespace and comments, which don't affect the
  /// semantic meaning of the macro definitions.
  bool get isIgnorable => type == TokenType.whitespace ||
      type == TokenType.comment;
}

/// Represents a precise location in the source code.
///
/// A [TokenLocation] stores information about where a token was found
/// in the source, including the file path, line number, column number,
/// and absolute character offset. This is essential for providing
/// meaningful error messages and debugging information.
class TokenLocation {
  /// The path or name of the source file.
  final String file;

  /// The 1-based line number in the file.
  final int line;

  /// The 1-based column number in the line.
  final int column;

  /// The 0-based character offset from the start of the file.
  final int offset;

  /// Creates a new token location with the specified file, line, column, and offset.
  const TokenLocation({
    required this.file,
    required this.line,
    required this.column,
    required this.offset,
  });

  /// Returns a string representation of this location in the format "file:line:column".
  @override
  String toString() => '$file:$line:$column';

  /// Creates a new location with an updated column position.
  ///
  /// This is useful when tracking position changes within a single line.
  ///
  /// Parameters:
  /// - [delta]: The number of columns to move (positive or negative)
  ///
  /// Returns a new location with updated column and offset values.
  TokenLocation moveColumn(int delta) {
    return TokenLocation(
      file: file,
      line: line,
      column: column + delta,
      offset: offset + delta,
    );
  }

  /// Creates a new location at the beginning of the next line.
  ///
  /// This is used when processing newline characters to move to the next line.
  ///
  /// Returns a new location with line incremented, column reset to 1,
  /// and offset incremented by 1.
  TokenLocation nextLine() {
    return TokenLocation(
      file: file,
      line: line + 1,
      column: 1,
      offset: offset + 1,
    );
  }
}

/// Maps textual directive keywords to their corresponding token types.
///
/// This map allows the lexer to efficiently identify preprocessor directives
/// like #define, #ifdef, etc., and convert them to the appropriate token types.
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

/// Maps single-character symbols to their corresponding token types.
///
/// This allows the lexer to quickly identify and categorize single-character
/// tokens like parentheses, braces, commas, and the stringize operator.
const Map<String, TokenType> singleCharTokens = {
  '(': TokenType.leftParen,
  ')': TokenType.rightParen,
  '{': TokenType.leftBrace,
  '}': TokenType.rightBrace,
  ',': TokenType.comma,
  ';': TokenType.semicolon,
  '#': TokenType.stringize,
};

/// Special character sequences used in macro syntax.
///
/// These constants define sets of characters with specific roles:
/// - [operators]: Characters used as operators in macro syntax
/// - [delimiters]: Characters used as delimiters in macro syntax
/// - [whitespace]: Characters considered as whitespace
const String operators = '#';
const String delimiters = '(){},;';
const String whitespace = ' \t\r';