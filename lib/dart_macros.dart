library dart_macros;

export 'src/core/macro_processor.dart';
export 'src/core/macro_definition.dart';
export 'src/core/exceptions.dart';
export 'src/annotations.dart';
export 'src/macros.dart';

// Auto-initialize macros
import 'dart:async';

Future<void> initializeDartMacros() async {
  // This will be filled in by the build runner
  await _initializeMacrosFromGeneratedCode();
}

Future<void> _initializeMacrosFromGeneratedCode() async {
  // This function will be replaced by the generated code
  print('Warning: Macro initialization not yet generated. Run "dart run build_runner build" first.');
}