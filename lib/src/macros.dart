/// Core interface for the dart_macros package, providing a platform-agnostic API.
///
/// This file serves as the main entry point for using the dart_macros library.
/// It provides a unified interface that works across all platforms, automatically
/// selecting the appropriate implementation (mirrors-based for VM/web or
/// non-reflection based for Flutter mobile).
///
/// The [Macros] class offers:
/// * Runtime access to macro values defined via annotations or manual registration
/// * Location-aware macros like __FILE__ and __LINE__
/// * Function-like macros that can be evaluated with parameters
///
/// Example:
/// ```dart
/// // Define macros using annotations (desktop/web)
/// @Define('VERSION', '1.0.0')
/// @Define('DEBUG', true)
/// @DefineMacro('SQUARE', 'x * x', parameters: ['x'])
/// class Config {}
///
/// // Access macro values
/// void main() {
///   print('Version: ${Macros.get<String>('VERSION')}');
///   print('Debug mode: ${Macros.get<bool>('DEBUG')}');
///   print('5 squared: ${MacroFunctions.SQUARE(5)}');
///   print('Current file: ${Macros.file}');
/// }
/// ```
library;

import 'core/macros_interface.dart';
import 'core/macros_impl.dart';

export 'annotations/annotations.dart';
// export 'flutter_macros.dart' if (dart.library.mirrors) 'src/empty_flutter_macros.dart';

/// Primary interface for defining and accessing macros at runtime.
///
/// The [Macros] class provides a unified API for:
/// * Retrieving macro values with type safety
/// * Defining new macros programmatically
/// * Accessing predefined system macros like file paths and line numbers
///
/// This class automatically selects the appropriate implementation based on
/// platform capabilities, working seamlessly on both reflection-capable
/// platforms (VM, web) and non-reflection platforms (Flutter mobile).
///
/// For Flutter mobile apps, additional setup is required using
/// [FlutterMacros.registerFromAnnotations] to manually register annotations
/// that would otherwise be automatically discovered through reflection.
class Macros {
  /// The implementation singleton for the current platform
  static final MacrosInterface _impl = MacrosImplementation();

  /// Define a new macro or override an existing one.
  ///
  /// This method allows runtime definition of macros, which is particularly
  /// useful for platform-specific configuration or test environments.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to define
  /// - [value]: The value to associate with the macro
  ///
  /// Example:
  /// ```dart
  /// // Define or override the DEBUG macro
  /// Macros.define('DEBUG', true);
  /// ```
  static void define(String name, dynamic value) {
    _impl.define(name, value);
  }

  /// Registers a simple value macro.
  ///
  /// This method defines a macro with a constant value. On platforms with
  /// reflection support, this provides an alternative to using annotations.
  /// On platforms without reflection support, this is the primary way to
  /// define macros.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to define
  /// - [value]: The value to associate with the macro (can be any type)
  ///
  /// Example:
  /// ```dart
  /// Macros.registerMacro('VERSION', '1.0.0');
  /// Macros.registerMacro('MAX_ITEMS', 100);
  /// Macros.registerMacro('DEBUG', true);
  /// ```
  static void registerMacro(String name, dynamic value) {
    _impl.define(name, value);
  }

  /// Register a function-like macro programmatically.
  ///
  /// This method is required for Flutter mobile platforms, where annotation
  /// scanning is not available. It can also be used on other platforms
  /// for dynamic function macro registration.
  ///
  /// Parameters:
  /// - [name]: The name of the function-like macro
  /// - [parameters]: List of parameter names the macro accepts
  /// - [expression]: The template expression that will be expanded
  ///
  /// Example:
  /// ```dart
  /// // Register a MAX function macro
  /// Macros.registerFunctionMacro(
  ///   'MAX',
  ///   ['a', 'b'],
  ///   'a > b ? a : b'
  /// );
  /// ```
  static void registerFunctionMacro(String name, List<String> parameters, String expression) {
    // Cast is safe because both implementations support this method
    (_impl as dynamic).registerFunctionMacro(name, parameters, expression);
  }

  /// Processes a function-like macro by substituting arguments.
  ///
  /// This is an internal method used by [MacroFunctions] extension
  /// to evaluate function-like macros.
  ///
  /// Parameters:
  /// - [name]: The name of the function-like macro to process
  /// - [arguments]: The list of arguments to pass to the macro
  ///
  /// Returns:
  /// The expanded macro expression after substituting parameters
  ///
  /// Throws:
  /// - StateError: If the macro is not defined
  /// - ArgumentError: If the wrong number of arguments is provided
  static String processMacro(String name, List<String> arguments) =>
      _impl.processMacro(name, arguments);

  /// Retrieves a macro value with type safety.
  ///
  /// This method is the primary way to access macro values defined
  /// via annotations or manual registration.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to retrieve
  ///
  /// Returns:
  /// The value of the macro, cast to the specified type T
  ///
  /// Throws:
  /// - StateError: If the macro is not defined
  /// - TypeError: If the macro's value cannot be cast to type T
  ///
  /// Example:
  /// ```dart
  /// String version = Macros.get<String>('VERSION');
  /// bool isDebug = Macros.get<bool>('DEBUG');
  /// int maxItems = Macros.get<int>('MAX_ITEMS');
  /// ```
  static T get<T>(String name) => _impl.get<T>(name);

  /// Gets a map of all currently defined macro values.
  ///
  /// This method can be useful for debugging or for systems that need
  /// to process multiple macros.
  ///
  /// Returns:
  /// An unmodifiable map of all macro names and their values
  ///
  /// Example:
  /// ```dart
  /// // Print all defined macros
  /// Macros.getAllValues().forEach((name, value) {
  ///   print('$name = $value');
  /// });
  /// ```
  static Map<String, dynamic> getAllValues() => _impl.getAllValues();

  /// Gets the current source file path.
  ///
  /// This predefined macro provides the path of the source file from
  /// which the property is accessed. On VM/web, this will typically be
  /// a relative path. On Flutter mobile, it may be a URI.
  ///
  /// Returns:
  /// A string containing the source file path
  ///
  /// Example:
  /// ```dart
  /// print('This code is in: ${Macros.file}');
  /// ```
  static String get file => _impl.file;

  /// Gets the current line number.
  ///
  /// This predefined macro provides the line number from which
  /// the property is accessed.
  ///
  /// Returns:
  /// An integer representing the line number
  ///
  /// Example:
  /// ```dart
  /// print('This code is on line: ${Macros.line}');
  /// ```
  static int get line => _impl.line;

  /// Gets the current date.
  ///
  /// This predefined macro provides the current date in the format
  /// "MMM DD YYYY" (e.g., "Jan 01 2025").
  ///
  /// Returns:
  /// A string containing the formatted date
  ///
  /// Example:
  /// ```dart
  /// print('Today is: ${Macros.date}');
  /// ```
  static String get date => _impl.date;

  /// Gets the current time.
  ///
  /// This predefined macro provides the current time in the format
  /// "HH:MM:SS" (e.g., "12:30:45").
  ///
  /// Returns:
  /// A string containing the formatted time
  ///
  /// Example:
  /// ```dart
  /// print('Current time: ${Macros.time}');
  /// ```
  static String get time => _impl.time;

  /// Checks if the application is in debug mode.
  ///
  /// This convenience getter accesses the 'DEBUG' macro, which should
  /// be defined either via annotations or manual registration.
  ///
  /// Returns:
  /// true if the application is in debug mode, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (Macros.isDebug) {
  ///   print('Running in debug mode');
  /// }
  /// ```
  static bool get isDebug => _impl.isDebug;

  /// Gets the current platform identifier.
  ///
  /// This predefined macro provides the current platform identifier
  /// (e.g., "android", "ios", "web", "flutter").
  ///
  /// Returns:
  /// A string identifying the platform
  ///
  /// Example:
  /// ```dart
  /// print('Running on platform: ${Macros.platform}');
  /// ```
  static String get platform => _impl.platform;
}

/// Initializes the dart_macros system.
///
/// This function is provided for backward compatibility and explicit
/// initialization if desired, but it is generally unnecessary as the
/// [Macros] class automatically initializes itself on first use.
///
/// Returns a [Future] that completes when initialization is done.
Future<void> initializeDartMacros() async {
  // Initialization happens automatically on first use
  // This function is kept for backward compatibility
  return Future.value();
}