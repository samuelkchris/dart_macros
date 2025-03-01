import 'package:dart_macros/dart_macros.dart';

@MacroFile()
// Basic definitions
@Define('LOGGING', true)
@Define('MAX_RETRY', 3)
@Define('VERSION_STRING', '1.0.0')
@Define('__DEBUG__', true)
@Define('FEATURE_NEW_UI', true)

// Function-like macro definitions
@DefineMacro(
  'CONCAT',
  'a + b',  // Simplified concatenation
  parameters: ['a', 'b'],
)
@DefineMacro(
  'MAKE_GETTER',
  'type get name() => _name',  // Fixed getter syntax
  parameters: ['type', 'name'],
)
@DefineMacro(
  'LOG_CALL',
  '"Calling " + func + " at " + __FILE__ + ":" + __LINE__',  // Removed extra parentheses
  parameters: ['func'],
)
@DefineMacro(
  'DEBUG_PRINT',
  '"Debug [" + __FILE__ + ":" + __LINE__ + "]: " + text',  // Removed extra parentheses
  parameters: ['text'],
)
class AdvancedExample {
  final String _name;
  final int _age;

  AdvancedExample(this._name, this._age);

  String get name => _name;
  int get age => _age;

  void printDetails() {
    if (MacroFunctions.IS_DEBUG()) {
      MacroFunctions.LOG_CALL('printDetails');
    }
    print('Name: $_name, Age: $_age');
  }

  Future<void> processWithRetry() async {
    if (Macros.get<bool>('LOGGING')) {
      MacroFunctions.DEBUG_PRINT('Starting process with retry');
    }

    final maxRetry = Macros.get<int>('MAX_RETRY');
    for (var i = 0; i < maxRetry; i++) {
      try {
        await process();
        break;
      } catch (e) {
        if (Macros.get<bool>('LOGGING')) {
          MacroFunctions.DEBUG_PRINT('Retry $i failed: $e');
        }
      }
    }
  }

  Future<void> process() async {
    if (MacroFunctions.IS_DEBUG()) {
      print('Processing in debug mode');
    }

    if (Macros.get<bool>('FEATURE_NEW_UI')) {
      await processWithNewUI();
    } else {
      await processWithLegacyUI();
    }
  }

  Future<void> processWithNewUI() async {
    print('Using new UI - Version: ${Macros.get<String>("VERSION_STRING")}');
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> processWithLegacyUI() async {
    print('Using legacy UI - Version: ${Macros.get<String>("VERSION_STRING")}');
    await Future.delayed(Duration(milliseconds: 100));
  }
}

void main() async {
  await initializeDartMacros();

  final example = AdvancedExample('John', 30);

  print('\n=== Running Advanced Macro Examples ===');

  // Test string concatenation
  final concatenated = MacroFunctions.CONCAT('Hello', 'World');
  print('Concatenated string: $concatenated');

  // Test method with debug logging
  example.printDetails();

  // Test retry mechanism
  await example.processWithRetry();

  print('=== Examples Complete ===\n');
}