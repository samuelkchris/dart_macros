# 🚀 dart_macros [![pub package](https://img.shields.io/pub/v/dart_macros.svg)](https://pub.dev/packages/dart_macros) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful Dart package that brings C-style macro preprocessing capabilities to Dart, enabling compile-time code generation and manipulation.

## 📦 Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  dart_macros: ^1.0.0
```

Install it:

```bash
dart pub get
```

## 🌟 Overview

dart_macros provides a familiar C-like macro system for Dart developers, offering features such as:

- ✅ Object-like macros for constant definitions
- ✅ Function-like macros for code generation
- ✅ Token concatenation operations
- ✅ Conditional compilation directives
- ✅ Macro expansion and evaluation
- ✅ Built-in predefined macros

## 📋 Use Cases

- **Code generation** without external build tools
- **Platform-specific code branching**
- **Debug and release mode configurations**
- **Compile-time constants** and computations
- **Code reusability** through macro templates
- **Meta-programming** capabilities

## ✨ Features

- 🔍 Clean, lightweight syntax that feels natural in Dart
- 🔒 Type-safe macro expansions
- 🔥 Detailed error reporting and debugging support
- 🔄 Integration with existing Dart tooling
- ⚡ Performance optimization through compile-time evaluation
- 🧩 Support for nested macro definitions

## 🚀 Usage

### Object-like Macros

Simple macros that define constants or expressions:

```dart
import 'package:dart_macros/dart_macros.dart';

// Definition
@MacroFile()
@Define('MAX_SIZE', 100)
@Define('PI', 3.14159)
@Define('DEBUG', true)
void main() async {
  await initializeDartMacros(); // This is optional but won't hurt

  // Usage
  var array = List<int>.filled(Macros.get<int>('MAX_SIZE'), 0);
  var circleArea = Macros.get<double>('PI') * radius * radius;
  
  if (Macros.get<bool>('DEBUG')) {
    print('Debug mode enabled');
  }
}
```

### Function-like Macros

Macros that take parameters and expand to code:

```dart
import 'package:dart_macros/dart_macros.dart';

@MacroFile()
@DefineMacro(
  'SQUARE',
  'x * x',
  parameters: ['x'],
)
@DefineMacro(
  'MIN',
  'a < b ? a : b',
  parameters: ['a', 'b'],
)
@DefineMacro(
  'VALIDATE',
  'x >= 0 && x <= max',
  parameters: ['x', 'max'],
)
void main() async {
  await initializeDartMacros();

  // Usage
  var squared = MacroFunctions.SQUARE(5);  // Evaluates to 25
  var minimum = MacroFunctions.MIN(x, y);  // Returns the smaller of x and y
  var isValid = MacroFunctions.VALIDATE(value, 100);  // Checks if value is in range
}
```

### Stringizing

Convert macro arguments to string literals:

```dart
@MacroFile()
@DefineMacro(
  'STRINGIFY',
  '"x"',
  parameters: ['x'],
)
@DefineMacro(
  'REPORT_VAR',
  '"Variable " + "var" + " = " + var.toString()',
  parameters: ['var'],
)
void main() async {
  await initializeDartMacros();

  // Usage
  var name = MacroFunctions.STRINGIFY(user);  // Evaluates to "user"
  MacroFunctions.REPORT_VAR(count);  // Prints: Variable count = 5
}
```

### Concatenation

Join tokens together:

```dart
@MacroFile()
@DefineMacro(
  'CONCAT',
  'a + b',
  parameters: ['a', 'b'],
)
void main() async {
  await initializeDartMacros();

  // Usage
  var fullName = MacroFunctions.CONCAT("John", "Doe");  // Evaluates to "JohnDoe"
}
```

### Debug Operations

Special macros for debugging:

```dart
@MacroFile()
@Define('__DEBUG__', true)
@DefineMacro(
  'DEBUG_PRINT',
  '"Debug [" + __FILE__ + ":" + __LINE__ + "]: " + text',
  parameters: ['text'],
)
void main() async {
  await initializeDartMacros();

  // Usage
  MacroFunctions.DEBUG_PRINT("Starting initialization");
  // Prints: Debug [example.dart:15]: Starting initialization
}
```

### Predefined Macros

Built-in system macros:

```dart
void main() async {
  await initializeDartMacros();

  print(Macros.file);      // Current source file name
  print(Macros.line);      // Current line number
  print(Macros.date);      // Compilation date
  print(Macros.time);      // Compilation time
}
```

### Conditional Compilation

Control compilation based on conditions:

```dart
@MacroFile()
@Define('DEBUG', true)
@Define('PLATFORM', 'android')
@Define('API_VERSION', 2)
class App {
  void initialize() {
    if (MacroFunctions.IFDEF('DEBUG')) {
      print('Debug mode initialization');
    }

    if (MacroFunctions.IF_PLATFORM('android')) {
      print('Initializing Android platform');
    }

    if (MacroFunctions.IF('DEBUG && API_VERSION >= 2')) {
      print('Advanced debug features available');
    }
  }
}
```

## 📝 Best Practices

1. 📋 Document macro behavior and expansion
2. 🔤 Use meaningful and clear macro names
3. 🚧 Avoid side effects in macro arguments
4. 🧪 Test macro expansion in different contexts
5. 🔍 Consider using `const` or `static final` instead of simple object-like macros
6. ⚠️ Be careful with token concatenation and stringizing operators

## ❌ Common Pitfalls

### Side Effects in Arguments

```dart
// Bad
@DefineMacro(
  'SQUARE',
  'x * x',
  parameters: ['x'],
)
var result = MacroFunctions.SQUARE(i++);  // i gets incremented twice

// Good
@DefineMacro(
  'SQUARE',
  '(x) * (x)',
  parameters: ['x'],
)
```

### Missing Parentheses

```dart
// Bad
@DefineMacro(
  'DOUBLE',
  'x + x',
  parameters: ['x'],
)
var result = 10 * MacroFunctions.DOUBLE(5);  // Evaluates to 10 * 5 + 5 = 55

// Good
@DefineMacro(
  'DOUBLE',
  '(x) + (x)',
  parameters: ['x'],
)
// Evaluates to 10 * (5 + 5) = 100
```

## 📚 API Reference

### Core Classes

#### Macros

The main class for accessing macro values:

```dart
// Get a macro value
var debug = Macros.get<bool>('DEBUG');

// Access predefined macros
var currentFile = Macros.file;
var currentLine = Macros.line;
```

#### MacroFunctions

For invoking function-like macros:

```dart
// Using a function-like macro
var squared = MacroFunctions.SQUARE(5);

// Using predefined function-like macros
MacroFunctions.DEBUG_PRINT("Error occurred");
```

### Annotations

```dart
// Mark a file for macro processing
@MacroFile()

// Define a simple constant macro
@Define('VERSION', '1.0.0')

// Define a function-like macro
@DefineMacro(
  'MAX',
  'a > b ? a : b',
  parameters: ['a', 'b'],
)

// Platform-specific code
@Platform('android')

// Debug-only code
@Debug()
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.