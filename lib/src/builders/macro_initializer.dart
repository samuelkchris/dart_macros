import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_macros/src/annotations/annotations.dart';

/// A builder that generates macro initialization code from annotated Dart source files.
///
/// The [MacroInitializerBuilder] reads `.dart` files and looks for `@Define` annotations
/// to generate a `.macro.g.dart` file containing initialization code for those macros.
/// This builder is a key component of the compile-time macro system, enabling developers
/// to declare macros using annotations rather than manual initialization code.
///
/// Example usage in a Dart file:
/// ```dart
/// @Define('VERSION', '1.0.0')
/// @Define('DEBUG', true)
/// class Config {}
/// ```
///
/// This would generate initialization code to define these macros at runtime.
class MacroInitializerBuilder implements Builder {
  /// Defines input and output file extensions for the builder.
  ///
  /// This builder transforms `.dart` files into `.macro.g.dart` files
  /// containing generated macro initialization code.
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.macro.g.dart'],
  };

  /// Processes a single input file to generate macro initialization code.
  ///
  /// This method:
  /// 1. Reads and parses the input Dart library
  /// 2. Finds all `@Define` annotations in the library
  /// 3. Generates initialization code for each defined macro
  /// 4. Adds predefined system macros (__FILE__, __DATE__, etc.)
  /// 5. Writes the generated code to an output file
  ///
  /// The generated file contains a single function `initializeMacros()` that,
  /// when called, will initialize all the macros defined in the input file.
  ///
  /// Returns a Future that completes when the build process is done.
  @override
  Future<void> build(BuildStep buildStep) async {
    /* Step 1: Read and validate the input file */
    final inputId = buildStep.inputId;
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(inputId)) return;

    /* Step 2: Parse the library */
    final library = await resolver.libraryFor(inputId);
    final reader = LibraryReader(library);

    /* Step 3: Begin building the output code */
    final output = StringBuffer();
    output.writeln("// Generated code - do not modify");
    output.writeln("import 'package:dart_macros/dart_macros.dart';");
    output.writeln();
    output.writeln("void initializeMacros() {");

    /* Step 4: Process @Define annotations */
    for (var annotated in reader.annotatedWith(TypeChecker.fromRuntime(Define))) {
      final annotation = annotated.annotation;
      final name = annotation.read('name').stringValue;
      final value = annotation.read('value').literalValue;
      output.writeln("  Macros._define('$name', ${_literalToString(value)});");
    }

    /* Step 5: Add predefined system macros */
    output.writeln("  Macros._define('__FILE__', '${inputId.path}');");
    output.writeln("  Macros._define('__DATE__', '${DateTime.now().toIso8601String()}');");
    output.writeln("  Macros._define('__TIME__', '${DateTime.now().hour}:${DateTime.now().minute}');");
    output.writeln("  Macros._define('__LINE__', 0);"); // Line numbers need special handling

    /* Step 6: Close the function definition */
    output.writeln("}");

    /* Step 7: Write the output file */
    final outputId = inputId.changeExtension('.macro.g.dart');
    await buildStep.writeAsString(outputId, output.toString());
  }

  /// Converts a Dart literal value to its string representation for code generation.
  ///
  /// This helper method ensures proper string escaping for different types:
  /// - Strings are wrapped in single quotes
  /// - Other types (numbers, booleans, etc.) are converted to their string representation
  ///
  /// For example:
  /// - "hello" becomes "'hello'"
  /// - 42 becomes "42"
  /// - true becomes "true"
  ///
  /// Returns a string representation of the value suitable for inclusion in generated code.
  String _literalToString(dynamic value) {
    if (value is String) return "'$value'";
    return value.toString();
  }
}

/// Factory function for creating a [MacroInitializerBuilder] instance.
///
/// This function is the entry point used by the build system to
/// instantiate the builder with the provided options.
///
/// The build_runner will call this function when setting up the build,
/// passing in the configuration options from build.yaml.
Builder macroInitializerBuilder(BuilderOptions options) => MacroInitializerBuilder();