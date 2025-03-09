import 'package:dart_macros/dart_macros.dart';

@MacroFile()
@Define('VERSION', '1.0.0')
@Define('__DEBUG__', true)
@DefineMacro(
  'SQUARE',
  'x * x',
  parameters: ['x'],
)
@DefineMacro(
  'MAX',
  'a > b ? a : b',
  parameters: ['a', 'b'],
)
@DefineMacro(
  'MIN',
  'a < b ? a : b',
  parameters: ['a', 'b'],
)
@DefineMacro(
  'CLAMP',
  'x < low ? low : (x > high ? high : x)',
  parameters: ['x', 'low', 'high'],
)
@DefineMacro(
  'STRINGIFY',
  '"x"',
  parameters: ['x'],
)
void main() async {
  await initializeDartMacros();

  print('Version: ${Macros.get<String>('VERSION')}');

  // Test math operations
  final squared = MacroFunctions.SQUARE(5);
  print('5 squared is $squared'); // Should print 25

  // Test comparison operations
  final a = 10, b = 20, c = 30;
  final maximum = MacroFunctions.MAX(a, b);
  final minimum = MacroFunctions.MIN(b, c);
  print('Max of $a and $b is $maximum'); // Should print 20
  print('Min of $b and $c is $minimum'); // Should print 20

  // Test clamping
  final value = 15;
  final clamped = MacroFunctions.CLAMP(value, 0, 10);
  print('Clamping $value between 0 and 10: $clamped'); // Should print 10

  // Test string operations
  final name = MacroFunctions.STRINGIFY("user");
  print('Stringized: $name'); // Should print: user

  // Test debug print
  MacroFunctions.DEBUG_PRINT('This is a debug message');
}
