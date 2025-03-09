import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../core/location.dart';
import '../core/macro_processor.dart';
import '../features/predefined_macros/system_macros.dart';

/// A code generator that processes macros in annotated Dart code.
///
/// The [MacroGenerator] extends Dart's standard [Generator] class to provide
/// macro processing capabilities during code generation. It identifies elements
/// with macro annotations and processes them to expand macros in the source code.
///
/// This generator is designed to be used with the source_gen package as part of
/// the build_runner pipeline, allowing for seamless integration with existing
/// Dart build systems.
///
/// Unlike the [MacroBuilder] which processes entire files, this generator
/// focuses specifically on annotated elements (classes, methods, etc.) which
/// gives developers more fine-grained control over where macro processing occurs.
class MacroGenerator extends Generator {
  /// Core processor for handling macro expansion
  final MacroProcessor _processor;

  /// Manager for system-defined predefined macros
  final SystemMacros _systemMacros;

  /// Creates a new [MacroGenerator] instance.
  ///
  /// Initializes the macro processor and system macros components
  /// needed for macro processing.
  MacroGenerator()
      : _processor = MacroProcessor(),
        _systemMacros = SystemMacros();

  /// Generates code for a Dart library by processing macros in annotated elements.
  ///
  /// This method:
  /// 1. Identifies all elements in the library
  /// 2. Checks each element for macro annotations
  /// 3. Processes annotated elements to expand macros
  /// 4. Combines the processed code into a single output
  ///
  /// Returns a string containing the generated code if any elements were processed,
  /// or null if no elements with macro annotations were found.
  ///
  /// This method is called by the build_runner system during code generation.
  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();
    final sourceFile = library.element.source.uri.toString();

    /* Process each element in the library */
    for (var element in library.allElements) {
      final macroAnnotation = _findMacroAnnotation(element);
      if (macroAnnotation != null) {
        /* Process elements with macro annotations */
        final processed = _processElement(
          element,
          macroAnnotation,
          sourceFile,
          buildStep,
        );
        if (processed.isNotEmpty) {
          output.writeln(processed);
        }
      }
    }

    /* Return null if no elements were processed */
    return output.isEmpty ? null : output.toString();
  }

  /// Finds macro annotations on a given element.
  ///
  /// This method searches for annotations that indicate macro processing
  /// should be applied to the element. Currently, it's a placeholder that
  /// would be expanded to support various macro annotation types.
  ///
  /// Returns the first found macro annotation, or null if none are found.
  ///
  /// Note: This is currently a stub implementation that would be expanded
  /// based on the supported annotation types.
  dynamic _findMacroAnnotation(Element element) {
    /* Look for our macro annotations
       This would be expanded based on supported annotation types */
    return null;
  }

  /// Processes an element with a macro annotation.
  ///
  /// This method:
  /// 1. Creates a source location for the element
  /// 2. Sets up predefined macros based on the location
  /// 3. Gets the source code for the element
  /// 4. Processes macros in the source code
  ///
  /// Parameters:
  /// - [element]: The annotated element to process
  /// - [annotation]: The macro annotation found on the element
  /// - [sourceFile]: The source file containing the element
  /// - [buildStep]: The current build step
  ///
  /// Returns a string containing the processed source code with expanded macros.
  String _processElement(
      Element element,
      dynamic annotation,
      String sourceFile,
      BuildStep buildStep,
      ) {
    /* Create location for the element */
    final location = Location(
      file: sourceFile,
      line: element.nameOffset,
      column: 1,
    );

    /* Get predefined macros based on location */
    final predefinedMacros = _systemMacros.getPredefinedMacros(location);

    /* Add predefined macros to processor */
    predefinedMacros.forEach((name, macro) {
      _processor.define(
        name: macro.name,
        replacement: macro.replacement,
        location: macro.location,
      );
    });

    /* Get the source code for the element */
    final source = element.source?.contents.data ?? '';

    /* Process macros in the source code */
    return _processor.process(source, filePath: sourceFile);
  }
}

/// Annotation to mark code for macro processing.
///
/// The [Macro] annotation is used to indicate that a Dart element
/// (class, method, field, etc.) should have macro processing applied to it.
///
/// This annotation provides configuration options for the macro processor:
/// - [defines]: Custom macro definitions to apply during processing
/// - [processIncludes]: Whether to process #include directives
/// - [expandPredefined]: Whether to expand predefined macros
///
/// Example usage:
/// ```dart
/// @Macro(
///   defines: {'DEBUG': 'true', 'VERSION': '"1.0.0"'},
///   expandPredefined: true
/// )
/// class Config {
///   // Code with macros to be processed
/// }
/// ```
class Macro {
  /// Custom macro definitions to apply during processing
  final Map<String, String>? defines;

  /// Whether to process #include directives
  final bool processIncludes;

  /// Whether to expand predefined macros
  final bool expandPredefined;

  /// Creates a new [Macro] annotation with the specified configuration.
  const Macro({
    this.defines,
    this.processIncludes = true,
    this.expandPredefined = true,
  });
}

/// Builder factory for the macro generator.
///
/// This function creates a [SharedPartBuilder] that uses the [MacroGenerator]
/// to generate code during the build process.
///
/// The generated code will be placed in a file with the extension '.g.dart'
/// and will contain the processed macros from annotated elements.
///
/// This function is the entry point used by the build system to
/// instantiate the generator with the provided options.
Builder macroGeneratorBuilder(BuilderOptions options) =>
    SharedPartBuilder([MacroGenerator()], 'macro_generator');