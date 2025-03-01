/// Library for handling source code location information in the dart_macros package.
///
/// This library provides functionality to track and manipulate source code locations,
/// which is essential for error reporting and debugging.
library;

/// Represents a location in source code with file, line, and column information.
///
/// This class is used throughout the package to:
/// * Track where macros are defined
/// * Report error locations
/// * Track source code positions during processing
///
/// The location uses 1-based indexing for both line and column numbers,
/// matching common editor and compiler conventions.
class Location {
  /// The path to the source file.
  ///
  /// This can be either:
  /// * An absolute file system path
  /// * A relative path from the project root
  final String file;

  /// The line number in the source file (1-based).
  ///
  /// For example:
  /// * Line 1 is the first line in the file
  /// * Line 2 is the second line, and so on
  final int line;

  /// The column number in the line (1-based).
  ///
  /// For example:
  /// * Column 1 is the first character in the line
  /// * Column 2 is the second character, and so on
  final int column;

  /// The character offset from the start of the file.
  ///
  /// This is optional but useful for:
  /// * Precise position tracking
  /// * Integration with text editors
  /// * Source mapping
  final int? offset;

  /// Creates a new [Location] instance.
  ///
  /// All parameters except [offset] are required:
  /// * [file] - The source file path
  /// * [line] - The 1-based line number
  /// * [column] - The 1-based column number
  /// * [offset] - Optional character offset from file start
  const Location({
    required this.file,
    required this.line,
    required this.column,
    this.offset,
  });

  @override
  String toString() => '$file:$line:$column';

  /// Creates a new location with an updated column position.
  ///
  /// This is useful when tracking position changes within the same line.
  /// The [delta] parameter specifies how many columns to move:
  /// * Positive values move right
  /// * Negative values move left
  ///
  /// Example:
  /// ```dart
  /// final newLoc = location.moveColumn(5); // Move 5 columns right
  /// ```
  Location moveColumn(int delta) {
    return Location(
      file: file,
      line: line,
      column: column + delta,
      offset: offset != null ? offset! + delta : null,
    );
  }

  /// Creates a new location at the start of the next line.
  ///
  /// This is useful when tracking position changes across lines.
  /// The new location will:
  /// * Increment the line number by 1
  /// * Reset the column to 1
  /// * Update the offset if present
  ///
  /// Example:
  /// ```dart
  /// final nextLineLoc = location.nextLine(); // Move to start of next line
  /// ```
  Location nextLine() {
    return Location(
      file: file,
      line: line + 1,
      column: 1,
      offset: offset != null ? offset! + 1 : null,
    );
  }
}
