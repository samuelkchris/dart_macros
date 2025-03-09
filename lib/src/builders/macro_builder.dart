import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../core/macro_processor.dart';
import '../core/location.dart';
import '../features/predefined_macros/system_macros.dart';
import '../features/predefined_macros/custom_macros.dart';

/// A builder that processes C-style macros in Dart source files during the build process.
///
/// The [MacroBuilder] transforms `.dart` files into `.macro.dart` files where macros
/// are processed and expanded according to the defined rules. It's designed to be used
/// with Dart's build_runner system to provide compile-time macro preprocessing capabilities.
///
/// This builder supports several configuration options that can be specified in build.yaml:
/// - `defines`: A map of predefined macro definitions
/// - `useEnvironmentVariables`: Whether to load environment variables as macros
/// - `buildConfig`: Build-specific configuration values to be accessible as macros
/// - `featureFlags`: Boolean flags for feature toggles
/// - `version`: Application version to parse into version-specific macros
/// - `processTestFiles`: Whether to process test files
/// - `include`: List of glob patterns for files to include
/// - `exclude`: List of glob patterns for files to exclude
class MacroBuilder implements Builder {
  /// Configuration options passed to the builder
  final BuilderOptions options;

  /// Core processor that handles macro expansion
  final MacroProcessor _processor;

  /// Manager for system-defined predefined macros
  final SystemMacros _systemMacros;

  /// Manager for user-defined custom macros
  final CustomMacros _customMacros;

  /// Creates a new [MacroBuilder] with the provided build options.
  ///
  /// Initializes the macro processing components and loads configuration
  /// from the provided [options].
  ///
  /// Example build.yaml configuration:
  /// ```yaml
  /// targets:
  ///   $default:
  ///     builders:
  ///       dart_macros|macro_builder:
  ///         options:
  ///           defines:
  ///             VERSION: 1.0.0
  ///             DEBUG: true
  ///           useEnvironmentVariables: true
  ///           version: 1.0.0
  ///           featureFlags:
  ///             NEW_UI: true
  ///             ANALYTICS: false
  /// ```
  MacroBuilder(this.options)
      : _processor = MacroProcessor(),
        _systemMacros = SystemMacros(),
        _customMacros = CustomMacros() {
    _initializeBuilderOptions();
  }

  /// Defines the file extensions this builder will process and produce.
  ///
  /// This builder transforms `.dart` files into `.macro.dart` files where
  /// the macro definitions and usages have been processed.
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.macro.dart']
  };

  /// Initializes the builder with configuration options from build.yaml.
  ///
  /// This method processes the builder options and configures the macro
  /// system accordingly. It handles:
  /// 1. Custom macro definitions from 'defines'
  /// 2. Environment variables (optional)
  /// 3. Build configuration parameters
  /// 4. Feature flags for conditional compilation
  /// 5. Version information for version-specific macros
  void _initializeBuilderOptions() {
    final config = options.config;

    /* Step 1: Process custom macro definitions */
    if (config.containsKey('defines')) {
      final defines = config['defines'] as Map<String, dynamic>;
      defines.forEach((key, value) {
        _customMacros.define(
          name: key,
          value: value.toString(),
          location: Location(
            file: 'build.yaml',
            line: 1,
            column: 1,
          ),
        );
      });
    }

    /* Step 2: Load environment variables if configured */
    if (config['useEnvironmentVariables'] == true) {
      _customMacros.loadEnvironmentVariables(
        Location(
          file: 'build.yaml',
          line: 1,
          column: 1,
        ),
      );
    }

    /* Step 3: Process build configuration */
    if (config.containsKey('buildConfig')) {
      _customMacros.loadBuildConfig(
        config['buildConfig'] as Map<String, dynamic>,
        Location(
          file: 'build.yaml',
          line: 1,
          column: 1,
        ),
      );
    }

    /* Step 4: Process feature flags */
    if (config.containsKey('featureFlags')) {
      final flags = config['featureFlags'] as Map<String, dynamic>;
      _customMacros.loadFeatureFlags(
        flags.map((key, value) => MapEntry(key, value as bool)),
        Location(
          file: 'build.yaml',
          line: 1,
          column: 1,
        ),
      );
    }

    /* Step 5: Parse version information */
    if (config.containsKey('version')) {
      _customMacros.defineVersion(
        config['version'] as String,
        Location(
          file: 'build.yaml',
          line: 1,
          column: 1,
        ),
      );
    }
  }

  /// Processes a single asset file, expanding macros and generating the output.
  ///
  /// This is the main build method called by the build_runner for each input file.
  /// It performs the following steps:
  /// 1. Checks if the file should be processed
  /// 2. Reads the input file content
  /// 3. Sets up predefined and custom macros
  /// 4. Processes macros in the file content
  /// 5. Writes the processed content to the output file
  ///
  /// The result is a new file with the same name but with a `.macro.dart` extension,
  /// containing the processed content with expanded macros.
  ///
  /// Returns a Future that completes when the build process is done.
  @override
  Future<void> build(BuildStep buildStep) async {
    /* Step 1: Get the input asset and check if it should be processed */
    final inputId = buildStep.inputId;
    if (!_shouldProcessFile(inputId)) {
      return;
    }

    /* Step 2: Read the input file content */
    final content = await buildStep.readAsString(inputId);

    /* Step 3: Create source location and load macros */
    final location = Location(
      file: inputId.path,
      line: 1,
      column: 1,
    );

    /* Step 4: Get predefined and custom macros */
    final predefinedMacros = _systemMacros.getPredefinedMacros(location);
    final customMacros = _customMacros.getCustomMacros();

    /* Step 5: Register all macros with the processor */
    predefinedMacros.forEach((name, macro) {
      _processor.define(
        name: macro.name,
        replacement: macro.replacement,
        location: macro.location,
      );
    });

    customMacros.forEach((name, macro) {
      _processor.define(
        name: macro.name,
        replacement: macro.replacement,
        location: macro.location,
      );
    });

    /* Step 6: Process macros in the file content */
    final processed = _processor.process(
      content,
      filePath: inputId.path,
    );

    /* Step 7: Write processed content to output file */
    final outputId = inputId.changeExtension('.macro.dart');
    await buildStep.writeAsString(outputId, processed);
  }

  /// Determines whether a file should be processed by this builder.
  ///
  /// Files are filtered based on several criteria:
  /// 1. Skip already generated files (*.g.dart, *.macro.dart)
  /// 2. Skip test files unless explicitly configured to process them
  /// 3. Apply include/exclude patterns from configuration
  ///
  /// Returns true if the file should be processed, false otherwise.
  ///
  /// This filtering mechanism helps optimize the build process by only
  /// processing files that need macro expansion.
  bool _shouldProcessFile(AssetId inputId) {
    /* Skip already generated files */
    if (inputId.path.contains('.g.dart')) return false;
    if (inputId.path.contains('.macro.dart')) return false;

    /* Skip test files unless configured otherwise */
    if (inputId.path.contains('test/') &&
        !options.config['processTestFiles']) {
      return false;
    }

    /* Apply include patterns - file must match at least one include pattern */
    if (options.config.containsKey('include')) {
      final patterns = options.config['include'] as List;
      if (!patterns.any((pattern) =>
          Glob(pattern).matches(inputId.path))) {
        return false;
      }
    }

    /* Apply exclude patterns - file must not match any exclude pattern */
    if (options.config.containsKey('exclude')) {
      final patterns = options.config['exclude'] as List;
      if (patterns.any((pattern) =>
          Glob(pattern).matches(inputId.path))) {
        return false;
      }
    }

    /* If all filters pass, the file should be processed */
    return true;
  }
}

/// Factory function for creating a [MacroBuilder] instance.
///
/// This function is the entry point used by the build system to
/// instantiate the builder with the provided options.
///
/// The build_runner will call this function when setting up the build,
/// passing in the configuration options from build.yaml.
Builder macroBuilder(BuilderOptions options) => MacroBuilder(options);