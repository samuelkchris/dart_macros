import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_macros/src/annotations/annotations.dart';

class MacroInitializerBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.macro.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Read the input file
    final inputId = buildStep.inputId;
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(inputId)) return;

    // Parse the library
    final library = await resolver.libraryFor(inputId);
    final reader = LibraryReader(library);

    // Build the output
    final output = StringBuffer();
    output.writeln("// Generated code - do not modify");
    output.writeln("import 'package:dart_macros/dart_macros.dart';");
    output.writeln();
    output.writeln("void initializeMacros() {");

    // Process @Define annotations
    for (var annotated in reader.annotatedWith(TypeChecker.fromRuntime(Define))) {
      final annotation = annotated.annotation;
      final name = annotation.read('name').stringValue;
      final value = annotation.read('value').literalValue;
      output.writeln("  Macros._define('$name', ${_literalToString(value)});");
    }

    // Add predefined macros
    output.writeln("  Macros._define('__FILE__', '${inputId.path}');");
    output.writeln("  Macros._define('__DATE__', '${DateTime.now().toIso8601String()}');");
    output.writeln("  Macros._define('__TIME__', '${DateTime.now().hour}:${DateTime.now().minute}');");
    output.writeln("  Macros._define('__LINE__', 0);"); // Line numbers need special handling

    output.writeln("}");

    // Write the output file
    final outputId = inputId.changeExtension('.macro.g.dart');
    await buildStep.writeAsString(outputId, output.toString());
  }

  String _literalToString(dynamic value) {
    if (value is String) return "'$value'";
    return value.toString();
  }
}

Builder macroInitializerBuilder(BuilderOptions options) => MacroInitializerBuilder();