library dart_macros;

export 'src/core/macro_processor.dart';
export 'src/core/macro_definition.dart';
export 'src/core/exceptions.dart';
export 'src/annotations.dart';
export 'src/macros.dart';
export 'src/functions.dart';
export 'src/features/resource_loading/resource_loader.dart';
export 'src/features/resource_loading/resource_macros.dart';

// This function now returns immediately since initialization is handled internally
Future<void> initializeDartMacros() async {
  // Initialization is now handled automatically in Macros class
  return;
}