/// A powerful macro processing system for Dart that enables compile-time code generation
/// and metaprogramming capabilities.
///
/// This package provides a comprehensive macro system that allows you to:
/// * Define and use C-style macros in Dart
/// * Generate boilerplate code using annotations
/// * Perform compile-time code transformations
/// * Handle conditional compilation
///
/// # Getting Started
///
/// Add the package to your `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   dart_macros: ^1.0.0
/// ```
///
/// # Basic Usage
///
/// ## Object-like Macros
///
/// Simple constant definitions:
/// ```dart
/// #define VERSION "1.0.0"
/// #define DEBUG true
/// ```
///
/// ## Function-like Macros
///
/// Parameterized code generation:
/// ```dart
/// #define MAX(a, b) ((a) > (b) ? (a) : (b))
/// #define ASSERT_NOT_NULL(x) if (x == null) throw ArgumentError('$x must not be null')
/// ```
///
/// ## Data Class Generation
///
/// Automatic generation of common utility methods:
/// ```dart
/// @Data()
/// class Person {
///   final String name;
///   final int age;
///
///   Person(this.name, this.age);
/// }
/// ```
///
/// This will generate:
/// * toString() implementation
/// * equals() and hashCode
/// * copyWith() method
/// * JSON serialization methods
///
/// # Features
///
/// ## Macro Processing
///
/// The package provides a robust macro processing system that supports:
/// * Object-like and function-like macros
/// * Nested macro expansion
/// * Recursion detection and prevention
/// * Error reporting with source locations
///
/// ## Code Generation
///
/// Built-in code generation capabilities include:
/// * Data class utilities
/// * Builder methods
/// * Serialization code
/// * Custom annotations
///
/// ## Error Handling
///
/// Comprehensive error handling with:
/// * Detailed error messages
/// * Source code locations
/// * Stack traces
/// * Validation checks
///
/// # Architecture
///
/// The package is organized into several core components:
///
/// ## Core Components
///
/// * [MacroProcessor] - The main engine for macro processing
/// * [MacroDefinition] - Represents macro definitions
/// * [Location] - Tracks source code positions
/// * [ExpressionEvaluator] - Evaluates compile-time expressions
///
/// ## Annotations
///
/// * [@Data] - Generates common utility methods
/// * More annotations coming soon...
///
/// ## Exception Handling
///
/// * [MacroException] - Base class for all macro-related exceptions
/// * [MacroDefinitionException] - Issues with macro definitions
/// * [MacroUsageException] - Problems with macro usage
/// * [RecursiveMacroException] - Detects recursive macro expansions
///
/// # Examples
///
/// ## Basic Macro Usage
///
/// ```dart
/// // Define a simple macro
/// #define PI 3.14159
///
/// // Use it in your code
/// double circumference(double radius) {
///   return 2 * PI * radius;
/// }
/// ```
///
/// ## Function Macro
///
/// ```dart
/// // Define a function-like macro
/// #define MIN(x, y) ((x) < (y) ? (x) : (y))
///
/// // Use it in your code
/// int minimum = MIN(a, b);
/// ```
///
/// ## Data Class
///
/// ```dart
/// @Data(
///   generateToString: true,
///   generateEquality: true,
///   generateJson: true,
/// )
/// class User {
///   final String id;
///   final String name;
///   final int age;
///
///   User(this.id, this.name, this.age);
/// }
/// ```
///
/// # Best Practices
///
/// 1. Macro Names
///    * Use UPPERCASE for object-like macros
///    * Use PascalCase for function-like macros
///    * Avoid common variable names
///
/// 2. Parentheses
///    * Always wrap macro parameters in parentheses
///    * Use extra parentheses in expressions
///
/// 3. Error Handling
///    * Always handle potential macro exceptions
///    * Provide meaningful error messages
///    * Include source locations in custom exceptions
///
/// # Contributing
///
/// Contributions are welcome! Please read our contributing guidelines before submitting PRs.
///
/// # License
///
/// This package is licensed under the MIT License. See the LICENSE file for details.
library;

/// Core functionalities for processing macros.
export 'src/core/macro_processor.dart';

/// Definitions of macros.
export 'src/core/macro_definition.dart';

/// Exception handling for the macros package.
export 'src/core/exceptions.dart';

/// Base library for macro annotations.
export 'src/annotations/annotations.dart';

/// Data structure definitions for macro annotations.
export 'src/annotations/data.dart';

/// Main macro utilities and helpers.
export 'src/macros.dart';

/// Function macros and related utilities.
export 'src/features/function_macros/functions.dart';

/// Resource loader utilities for macros.
export 'src/features/resource_loading/resource_loader.dart';

/// Resource macros and related helpers.
export 'src/features/resource_loading/resource_macros.dart';

/// Initializes the Dart macros package.
///
/// This function now returns immediately as the initialization is
/// automatically handled by the internal `Macros` class.
Future<void> initializeDartMacros() async {
  return;
}
