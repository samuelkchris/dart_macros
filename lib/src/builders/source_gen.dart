import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../core/location.dart';
import '../core/macro_processor.dart';
import '../features/predefined_macros/system_macros.dart';

/// Generator for processing macros in annotated code
class MacroGenerator extends Generator {
  final MacroProcessor _processor;
  final SystemMacros _systemMacros;

  MacroGenerator()
      : _processor = MacroProcessor(),
        _systemMacros = SystemMacros();

  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();
    final sourceFile = library.element.source.uri.toString();

    // Process each annotated element
    for (var element in library.allElements) {
      final macroAnnotation = _findMacroAnnotation(element);
      if (macroAnnotation != null) {
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

    return output.isEmpty ? null : output.toString();
  }

  /// Find macro annotation on an element
  dynamic _findMacroAnnotation(Element element) {
    // Look for our macro annotations
    // This would be expanded based on supported annotation types
    return null;
  }

  /// Process an annotated element
  String _processElement(
      Element element,
      dynamic annotation,
      String sourceFile,
      BuildStep buildStep,
      ) {
    final location = Location(
      file: sourceFile,
      line: element.nameOffset,
      column: 1,
    );

    // Get predefined macros
    final predefinedMacros = _systemMacros.getPredefinedMacros(location);

    // Add predefined macros to processor
    predefinedMacros.forEach((name, macro) {
      _processor.define(
        name: macro.name,
        replacement: macro.replacement,
        location: macro.location,
      );
    });

    // Get the source code for the element
    final source = element.source?.contents.data ?? '';

    // Process macros
    return _processor.process(source, filePath: sourceFile);
  }
}

/// Annotation to mark code for macro processing
class Macro {
  final Map<String, String>? defines;
  final bool processIncludes;
  final bool expandPredefined;

  const Macro({
    this.defines,
    this.processIncludes = true,
    this.expandPredefined = true,
  });
}

/// Builder factory for the macro generator
Builder macroGeneratorBuilder(BuilderOptions options) =>
    SharedPartBuilder([MacroGenerator()], 'macro_generator');