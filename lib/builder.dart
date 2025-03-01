/// A library for Dart macros.
///
/// This library provides builders and utilities to support Dart macros
/// using `macroBuilder` and `macroGeneratorBuilder`.
library;

/// Exports the macro builder to create macros during the build process.
export 'src/builders/macro_builder.dart' show macroBuilder;

/// Exports the generators for creating and applying macros.
export 'src/builders/source_gen.dart' show macroGeneratorBuilder, Macro;
