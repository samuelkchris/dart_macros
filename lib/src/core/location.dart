/// Represents a location in source code
class Location {
  /// The source file
  final String file;

  /// The line number (1-based)
  final int line;

  /// The column number (1-based)
  final int column;

  /// The offset from the start of the file (optional)
  final int? offset;

  const Location({
    required this.file,
    required this.line,
    required this.column,
    this.offset,
  });

  @override
  String toString() => '$file:$line:$column';

  /// Create a new location with an updated column
  Location moveColumn(int delta) {
    return Location(
      file: file,
      line: line,
      column: column + delta,
      offset: offset != null ? offset! + delta : null,
    );
  }

  /// Create a new location for the next line
  Location nextLine() {
    return Location(
      file: file,
      line: line + 1,
      column: 1,
      offset: offset != null ? offset! + 1 : null,
    );
  }
}