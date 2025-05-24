import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../annotations/data.dart';
import 'exceptions.dart';
import 'location.dart';

class MacroInitializer implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.macro.g.dart'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(inputId)) return;

    final library = await resolver.libraryFor(inputId);
    final reader = LibraryReader(library);

    final output = StringBuffer();
    output.writeln("// Generated code - do not modify");
    output.writeln("import 'package:dart_macros/dart_macros.dart';");
    output.writeln();

    for (var annotated in reader.annotatedWith(TypeChecker.fromRuntime(Data))) {
      final annotation = annotated.annotation;
      final element = annotated.element;
      final location = Location(
        file: inputId.path,
        line: element.nameOffset ~/ element.source!.contents.data.length,
        column: 1,
      );

      try {
        _handleDataAnnotation(
          annotation,
          element.displayName,
          location,
          output,
        );
      } catch (e) {
        throw MacroDefinitionException(
          'Error processing Data annotation: $e',
          location,
        );
      }
    }

    if (output.isNotEmpty) {
      final outputId = inputId.changeExtension('.macro.g.dart');
      await buildStep.writeAsString(outputId, output.toString());
    }
  }

  void _handleDataAnnotation(
    ConstantReader annotation,
    String className,
    Location location,
    StringBuffer output,
  ) {
    final generateToString = annotation.read('generateToString').boolValue;
    final generateEquality = annotation.read('generateEquality').boolValue;
    final generateJson = annotation.read('generateJson').boolValue;

    if (generateToString) {
      _addToStringMacro(className, output);
    }
    if (generateEquality) {
      _addEqualityMacros(className, output);
    }
    if (generateJson) {
      _addJsonMacros(className, output);
    }
  }

  void _addToStringMacro(String className, StringBuffer output) {
    output.writeln('''
    Macros._define('${className}_toString', 'toString() => "$className(\${_fields})"');
    ''');
  }

  void _addEqualityMacros(String className, StringBuffer output) {
    output.writeln('''
    Macros._define('${className}_equals', 
      'operator ==(Object other) => identical(this, other) || '
      'other is $className && _fieldsEqual(other)');
    Macros._define('${className}_hash', 
      'get hashCode => Object.hash(_fields)');
    ''');
  }

  void _addJsonMacros(String className, StringBuffer output) {
    output.writeln('''
    Macros._define('${className}_toJson', 
      'Map<String, dynamic> toJson() => _toMap()');
    Macros._define('${className}_fromJson', 
      'factory $className.fromJson(Map<String, dynamic> json) => '
      '$className._fromMap(json)');
    ''');
  }
}

Builder macroInitializerBuilder(BuilderOptions options) => MacroInitializer();
