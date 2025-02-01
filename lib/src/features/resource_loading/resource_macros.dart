


import '../../../dart_macros.dart';
import '../../core/location.dart';

/// Extension for the MacroProcessor to support resource operations
extension ResourceProcessorExtension on MacroProcessor {
  /// Include the contents of a resource file
  Future<String> includeResource(String resourcePath, Location location) async {
    return ResourceLoader.loadResource(resourcePath, location);
  }

  /// Define macros from a properties file
  Future<void> defineFromProperties(String propertiesPath, Location location) async {
    final content = await ResourceLoader.loadResource(propertiesPath, location);

    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        define(
          name: parts[0].trim(),
          replacement: parts[1].trim(),
          location: location,
        );
      }
    }
  }
}