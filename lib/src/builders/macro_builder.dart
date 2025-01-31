import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../core/macro_processor.dart';
import '../core/location.dart';
import '../features/predefined_macros/system_macros.dart';
import '../features/predefined_macros/custom_macros.dart';

/// Builder for processing macros during the Dart build process
class MacroBuilder implements Builder {
  final BuilderOptions options;
  final MacroProcessor _processor;
  final SystemMacros _systemMacros;
  final CustomMacros _customMacros;

  MacroBuilder(this.options)
      : _processor = MacroProcessor(),
        _systemMacros = SystemMacros(),
        _customMacros = CustomMacros() {
    _initializeBuilderOptions();
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.macro.dart']
  };

  /// Initialize builder with configuration options
  void _initializeBuilderOptions() {
    final config = options.config;

    // Load custom macros from builder options
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

    // Load environment variables if configured
    if (config['useEnvironmentVariables'] == true) {
      _customMacros.loadEnvironmentVariables(
        Location(
          file: 'build.yaml',
          line: 1,
          column: 1,
        ),
      );
    }

    // Load build configuration if provided
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

    // Load feature flags if provided
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

    // Load version if provided
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

  @override
  Future<void> build(BuildStep buildStep) async {
    // Get the input asset
    final inputId = buildStep.inputId;

    // Skip files that don't need macro processing
    if (!_shouldProcessFile(inputId)) {
      return;
    }

    // Read the input file
    final content = await buildStep.readAsString(inputId);

    // Create location for this file
    final location = Location(
      file: inputId.path,
      line: 1,
      column: 1,
    );

    // Get predefined macros for this file
    final predefinedMacros = _systemMacros.getPredefinedMacros(location);
    final customMacros = _customMacros.getCustomMacros();

    // Add all macros to processor
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

    // Process the file
    final processed = _processor.process(
      content,
      filePath: inputId.path,
    );

    // Create the output asset
    final outputId = inputId.changeExtension('.macro.dart');
    await buildStep.writeAsString(outputId, processed);
  }

  /// Determine if a file should be processed
  bool _shouldProcessFile(AssetId inputId) {
    // Skip generated files
    if (inputId.path.contains('.g.dart')) return false;
    if (inputId.path.contains('.macro.dart')) return false;

    // Skip test files unless configured otherwise
    if (inputId.path.contains('test/') &&
        !options.config['processTestFiles']) {
      return false;
    }

    // Check include/exclude patterns
    if (options.config.containsKey('include')) {
      final patterns = options.config['include'] as List;
      if (!patterns.any((pattern) =>
          Glob(pattern).matches(inputId.path))) {
        return false;
      }
    }

    if (options.config.containsKey('exclude')) {
      final patterns = options.config['exclude'] as List;
      if (patterns.any((pattern) =>
          Glob(pattern).matches(inputId.path))) {
        return false;
      }
    }

    return true;
  }
}

/// Builder factory function
Builder macroBuilder(BuilderOptions options) => MacroBuilder(options);