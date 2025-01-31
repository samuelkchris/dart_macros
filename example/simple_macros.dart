import 'package:dart_macros/dart_macros.dart';

@MacroFile()
@Define('VERSION', '1.0.0')
@Define('MAX_ITEMS', 100)
@Define('PI', 3.14159)
@Define('DEBUG', true)
void main() async {
  // Initialize macros first
  await initializeDartMacros();

  print('App Version: ${Macros.get<String>("VERSION")}');

  final items = List.generate(Macros.get<int>('MAX_ITEMS'), (i) => i);
  print('Generated ${Macros.get("MAX_ITEMS")} items');

  final area = Macros.get<double>('PI') * 5 * 5;
  print('Area of circle with radius 5: $area');

  if (Macros.get<bool>('DEBUG')) {
    print('Debug mode is enabled');
  }

  // Using predefined macros
  print('Current file: ${Macros.file}');
  print('Current line: ${Macros.line}');
  print('Compilation date: ${Macros.date}');
  print('Compilation time: ${Macros.time}');
}