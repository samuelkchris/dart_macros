/// Base class for all macro annotations
/// 
/// Macro annotations are used to mark or configure code for macro 
/// processing. These annotations enable functionality such as defining 
/// macros, conditional compilation, and platform-specific code handling.
abstract class MacroAnnotation {
  const MacroAnnotation();
}

/// Marks a file for macro processing
/// 
/// When applied, this annotation signals that the file should be 
/// processed for macro expansion and compilation-specific transformations.
class MacroFile extends MacroAnnotation {
  const MacroFile();
}

/// Defines a simple constant macro
/// 
/// The `Define` annotation creates a named constant with a specific value. 
/// It is useful to define reusable constants in the code.
/// 
/// Example:
/// ```dart
/// @Define('PI', 3.14)
/// ```
class Define extends MacroAnnotation {
  final String name;
  final dynamic value;

  const Define(this.name, this.value);
}

/// Defines a function-like macro
/// 
/// `DefineMacro` creates a named macro that can accept parameters and use 
/// an expression to define its behavior.
/// 
/// Example:
/// ```dart
/// @DefineMacro('add', 'x + y', parameters: ['x', 'y'])
/// ```
class DefineMacro extends MacroAnnotation {
  final String name;
  final String expression;
  final List<String> parameters;

  const DefineMacro(this.name,
      this.expression, {
        this.parameters = const [],
      });
}

/// Conditional compilation based on platform
/// 
/// The `Platform` annotation allows marking specific sections of code 
/// to be included or excluded during compilation based on the target platform.
/// 
/// Example:
/// ```dart
/// @Platform('android')
/// ```
class Platform extends MacroAnnotation {
  final String platform;

  const Platform(this.platform);
}

/// Defines a debug-only macro
/// 
/// Marks sections of code to be included only in debug builds. The annotated code 
/// will be excluded in release builds.
/// 
/// Example:
/// ```dart
/// @Debug()
/// ```
class Debug extends MacroAnnotation {
  const Debug();
}

/// Defines a release-only macro
/// 
/// Marks sections of code to be included only in release builds. The annotated code 
/// will be excluded in debug builds.
/// 
/// Example:
/// ```dart
/// @Release()
/// ```
class Release extends MacroAnnotation {
  const Release();
}

/// Marks code to be included only if a feature flag is enabled
/// 
/// The `Feature` annotation allows code to be conditioned on the state of 
/// a specific feature flag, enabling or disabling it dynamically.
/// 
/// Example:
/// ```dart
/// @Feature('experimentalFeature', enabled: true)
/// ```
class Feature extends MacroAnnotation {
  final String name;
  final bool enabled;

  const Feature(this.name, {this.enabled = true});
}

/// Marks code for platform-specific implementation
/// 
/// The `PlatformSpecific` annotation allows specifying a set of platforms 
/// where the annotated code is valid. This can restrict code to certain platforms.
/// 
/// Example:
/// ```dart
/// @PlatformSpecific({'android', 'ios'})
/// ```
class PlatformSpecific extends MacroAnnotation {
  final Set<String> platforms;

  const PlatformSpecific(this.platforms);
}

/// Marks code as configurable via build configuration
/// 
/// The `BuildConfig` annotation allows linking code behavior to a build-time 
/// configuration key with an optional default value.
/// 
/// Example:
/// ```dart
/// @BuildConfig('apiUrl', defaultValue: 'https://api.example.com')
/// ```
class BuildConfig extends MacroAnnotation {
  final String key;
  final dynamic defaultValue;

  const BuildConfig(this.key, {this.defaultValue});
}
