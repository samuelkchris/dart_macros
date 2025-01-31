/// Base class for all macro annotations
abstract class MacroAnnotation {
  const MacroAnnotation();
}

/// Marks a file for macro processing
class MacroFile extends MacroAnnotation {
  const MacroFile();
}

/// Defines a simple constant macro
class Define extends MacroAnnotation {
  final String name;
  final dynamic value;

  const Define(this.name, this.value);
}

/// Defines a function-like macro
class DefineMacro extends MacroAnnotation {
  final String name;
  final String expression;
  final List<String> parameters;

  const DefineMacro(
    this.name,
    this.expression, {
    this.parameters = const [],
  });
}

/// Conditional compilation based on platform
class Platform extends MacroAnnotation {
  final String platform;

  const Platform(this.platform);
}

/// Defines a debug-only macro
class Debug extends MacroAnnotation {
  const Debug();
}

/// Defines a release-only macro
class Release extends MacroAnnotation {
  const Release();
}

/// Marks code to be included only if a feature flag is enabled
class Feature extends MacroAnnotation {
  final String name;
  final bool enabled;

  const Feature(this.name, {this.enabled = true});
}

/// Marks code for platform-specific implementation
class PlatformSpecific extends MacroAnnotation {
  final Set<String> platforms;

  const PlatformSpecific(this.platforms);
}

/// Marks code as configurable via build configuration
class BuildConfig extends MacroAnnotation {
  final String key;
  final dynamic defaultValue;

  const BuildConfig(this.key, {this.defaultValue});
}
