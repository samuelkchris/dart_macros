
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/data.dart';

class DataClassGenerator extends GeneratorForAnnotation<Data> {
  @override
  String generateForAnnotatedElement(
      Element element,
      ConstantReader annotation,
      BuildStep buildStep,
      ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Data annotation can only be used on classes.',
        element: element,
      );
    }

    final dataAnnotation = _parseAnnotation(annotation);
    final className = element.name;
    dataAnnotation.getPrefix();
    final fields = element.fields.where((f) => !f.isStatic);
    final buffer = StringBuffer();

    // Generate constructor
    if (dataAnnotation.makeConst) {
      buffer.writeln(_generateConstConstructor(className, fields));
    } else {
      buffer.writeln(_generateConstructor(className, fields));
    }

    // Generate toString
    if (dataAnnotation.generateToString) {
      buffer.writeln(_generateToString(className, fields));
    }

    // Generate equality
    if (dataAnnotation.generateEquality) {
      buffer.writeln(_generateEquality(className, fields));
    }

    // Generate copyWith
    if (dataAnnotation.generateCopyWith) {
      buffer.writeln(_generateCopyWith(className, fields));
    }

    // Generate toMap/fromMap
    if (dataAnnotation.generateToMap) {
      buffer.writeln(_generateToMap(className, fields));
    }
    if (dataAnnotation.generateFromMap) {
      buffer.writeln(_generateFromMap(className, fields));
    }

    // Generate JSON methods
    if (dataAnnotation.generateJson) {
      buffer.writeln(_generateJsonMethods(className));
    }

    return buffer.toString();
  }

  Data _parseAnnotation(ConstantReader annotation) {
    return Data(
      generateToString: annotation.read('generateToString').boolValue,
      generateEquality: annotation.read('generateEquality').boolValue,
      generateCopyWith: annotation.read('generateCopyWith').boolValue,
      generateJson: annotation.read('generateJson').boolValue,
      makeConst: annotation.read('makeConst').boolValue,
      generateFromMap: annotation.read('generateFromMap').boolValue,
      generateToMap: annotation.read('generateToMap').boolValue,
      generatedPrefix: annotation.read('generatedPrefix').stringValue,
    );
  }

  String _generateConstructor(String className, Iterable<FieldElement> fields) {
    final params = fields.map((f) => 'this.${f.name}').join(', ');
    return '''
    $className($params);
    ''';
  }

  String _generateConstConstructor(String className, Iterable<FieldElement> fields) {
    final params = fields.map((f) => 'this.${f.name}').join(', ');
    return '''
    const $className($params);
    ''';
  }

  String _generateToString(String className, Iterable<FieldElement> fields) {
    final fieldStrings = fields.map((f) => '${f.name}: \$${f.name}').join(', ');
    return '''
    @override
    String toString() {
      return '$className($fieldStrings)';
    }
    ''';
  }

  String _generateEquality(String className, Iterable<FieldElement> fields) {
    final equalsFields = fields.map((f) => 'other.${f.name} == ${f.name}').join(' && ');
    final hashFields = fields.map((f) => '${f.name}.hashCode').join(', ');

    return '''
    @override
    bool operator ==(Object other) {
      if (identical(this, other)) return true;
      return other is $className && $equalsFields;
    }

    @override
    int get hashCode {
      return Object.hash($hashFields);
    }
    ''';
  }

  String _generateCopyWith(String className, Iterable<FieldElement> fields) {
    final params = fields.map((f) {
      final type = f.type.getDisplayString(withNullability: true);
      return '$type? ${f.name}';
    }).join(', ');

    final assignments = fields.map((f) =>
    '${f.name}: ${f.name} ?? this.${f.name}').join(', ');

    return '''
    $className copyWith({$params}) {
      return $className($assignments);
    }
    ''';
  }

  String _generateToMap(String className, Iterable<FieldElement> fields) {
    final mapEntries = fields.map((f) =>
    "'${f.name}': ${f.name}").join(', ');

    return '''
    Map<String, dynamic> toMap() {
      return {$mapEntries};
    }
    ''';
  }

  String _generateFromMap(String className, Iterable<FieldElement> fields) {
    final params = fields.map((f) {
      final type = f.type.getDisplayString(withNullability: false);
      return "map['${f.name}'] as $type";
    }).join(', ');

    return '''
    factory $className.fromMap(Map<String, dynamic> map) {
      return $className($params);
    }
    ''';
  }

  String _generateJsonMethods(String className) {
    return '''
    String toJson() => json.encode(toMap());

    factory $className.fromJson(String source) => 
        $className.fromMap(json.decode(source) as Map<String, dynamic>);
    ''';
  }
}