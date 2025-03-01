/// A library for processing data annotations and generating boilerplate code.
/// This library provides functionality to automatically generate common methods
/// like toString, equality, copyWith, and data conversion methods.
library;

import '../core/macro_processor.dart';
import '../core/exceptions.dart';
import '../core/location.dart';
import '../annotations/data.dart';

/// [DataProcessor] handles the generation of boilerplate code for classes annotated with [@Data].
///
/// This processor works in conjunction with [MacroProcessor] to define various utility methods
/// for data classes, including:
/// * toString() implementation
/// * equals() and hashCode implementations
/// * copyWith() method for immutable updates
/// * toMap() and fromMap() methods for data serialization
/// * toJson() and fromJson() methods for JSON serialization
class DataProcessor {
  final MacroProcessor _macroProcessor;

  /// Creates a new [DataProcessor] instance with the given [MacroProcessor].
  ///
  /// The [MacroProcessor] is used to define the actual code replacements.
  DataProcessor(this._macroProcessor);

  /// Processes a [@Data] annotation for a specific class.
  ///
  /// This method orchestrates the generation of all requested utility methods based on
  /// the annotation's configuration.
  ///
  /// Parameters:
  /// * [annotation] - The Data annotation instance containing generation preferences
  /// * [className] - The name of the class being processed
  /// * [fields] - A map of field names to their types
  /// * [location] - The source code location for error reporting
  ///
  /// Throws [MacroDefinitionException] if any part of the processing fails.
  void processDataAnnotation(Data annotation, String className, Map<String, String> fields, Location location) {
    try {
      // Generate toString method
      if (annotation.generateToString) {
        _defineToString(className, fields, location);
      }

      // Generate equality methods
      _defineEquality(className, fields, location);

      // Generate copyWith method
      _defineCopyWith(className, fields, location);

      // Generate Map conversion methods
      if (annotation.generateToMap) {
        _defineMapMethods(className, fields, location);
      }

      // Generate JSON methods
      if (annotation.generateJson) {
        _defineJsonMethods(className, location);
      }
    } catch (e) {
      throw MacroDefinitionException(
        'Failed to process @Data annotation for $className: $e',
        location,
      );
    }
  }

  /// Generates a toString() method implementation for the class.
  ///
  /// Creates a string representation that includes the class name and all field values
  /// in the format: 'ClassName(field1: value1, field2: value2, ...)'
  void _defineToString(String className, Map<String, String> fields, Location location) {
    final fieldStrings = fields.entries.map((e) => '${e.key}: \$${e.key}').join(', ');
    _macroProcessor.define(
      name: '_${className}_toString',
      replacement: '@override String toString() => \'$className($fieldStrings)\';',
      location: location,
    );
  }

  /// Generates equality comparison methods (operator== and hashCode).
  ///
  /// The generated equals method performs a field-by-field comparison,
  /// while hashCode uses Object.hash for consistent hash code generation.
  void _defineEquality(String className, Map<String, String> fields, Location location) {
    final comparisons = fields.keys.map((k) => 'other.$k == $k').join(' && ');
    final hashFields = fields.keys.join(', ');

    _macroProcessor.define(
      name: '_${className}_equals',
      replacement: '''
        @override bool operator ==(Object other) {
          if (identical(this, other)) return true;
          return other is $className && $comparisons;
        }
        @override int get hashCode => Object.hash($hashFields);
      ''',
      location: location,
    );
  }

  /// Generates a copyWith method for creating modified instances.
  ///
  /// The generated method allows creating a new instance with selectively
  /// updated fields while keeping other fields unchanged.
  ///
  /// Example:
  /// ```dart
  /// final newInstance = instance.copyWith(field1: newValue);
  /// ```
  void _defineCopyWith(String className, Map<String, String> fields, Location location) {
    final params = fields.entries.map((e) => '${e.value}? ${e.key}').join(', ');
    final assignments = fields.keys.map((k) => '$k: $k ?? this.$k').join(', ');

    _macroProcessor.define(
      name: '_${className}_copyWith',
      replacement: '''
        $className copyWith({$params}) {
          return $className($assignments);
        }
      ''',
      location: location,
    );
  }
  /// Generates methods for converting between the class and Map<String, dynamic>.
  ///
  /// Creates two methods:
  /// * toMap() - converts the instance to a Map
  /// * fromMap() - creates a new instance from a Map
  ///
  /// These methods are useful for serialization and data transfer.
  void _defineMapMethods(String className, Map<String, String> fields, Location location) {
    final toMapFields = fields.keys.map((k) => "'$k': $k").join(', ');
    final fromMapFields = fields.entries.map((e) =>
    "${e.key}: map['${e.key}'] as ${e.value}").join(', ');

    _macroProcessor.define(
      name: '_${className}_toMap',
      replacement: '''
        Map<String, dynamic> toMap() => {$toMapFields};
        
        static $className fromMap(Map<String, dynamic> map) =>
          $className($fromMapFields);
      ''',
      location: location,
    );
  }

  /// Generates JSON serialization methods.
  ///
  /// Creates toJson() and fromJson() methods that utilize the Map conversion
  /// methods along with the MacroFunctions utility class for JSON string conversion.
  void _defineJsonMethods(String className, Location location) {
    _macroProcessor.define(
      name: '_${className}_json',
      replacement: '''
        String toJson() => MacroFunctions.TO_JSON(toMap());
        
        static $className fromJson(String json) =>
          fromMap(MacroFunctions.FROM_JSON(json));
      ''',
      location: location,
    );
  }
}

/// Extension on [MacroProcessor] to provide a convenient way to process
/// data classes with the [@Data] annotation.
extension DataProcessorExtension on MacroProcessor {
  /// Processes a class annotated with [@Data].
  ///
  /// This is the main entry point for the data class processing functionality.
  /// It creates a [DataProcessor] instance and delegates the processing to it.
  void processDataClass(Data annotation, String className, Location location) {
    final processor = DataProcessor(this);
    processor.processDataAnnotation(annotation, className, {}, location);
  }
}