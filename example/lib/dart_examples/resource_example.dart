import 'package:dart_macros/dart_macros.dart';

@MacroFile()
class ResourceExample {
  Future<void> loadConfigurations() async {
    // Load properties file
    await MacroFunctions.LOAD_PROPERTIES('config/app.properties');
    print('App Name: ${Macros.get<String>("app.name")}');
    print('Version: ${Macros.get<String>("app.version")}');
    print('Environment: ${Macros.get<String>("app.environment")}');
    print('Debug Mode: ${Macros.get<bool>("app.debug")}');

    // API Configuration
    print('\nAPI Configuration:');
    print('URL: ${Macros.get<String>("api.url")}');
    print('Timeout: ${Macros.get<int>("api.timeout")}ms');
    print('Retries: ${Macros.get<int>("api.retries")}');

    // Feature flags
    print('\nFeature Flags:');
    print('Dark Mode: ${Macros.get<bool>("feature.dark_mode")}');
    print('Analytics: ${Macros.get<bool>("feature.analytics")}');
    print('Cloud Sync: ${Macros.get<bool>("feature.cloud_sync")}');

    // Load JSON configuration
    await MacroFunctions.LOAD_JSON('config/features.json');
    print('\nJSON Config:');
    print('Dark Mode: ${Macros.get<bool>("FEATURE_DARK_MODE")}');
    print('Analytics: ${Macros.get<bool>("FEATURE_ANALYTICS")}');
    print('Cloud Sync: ${Macros.get<bool>("FEATURE_CLOUD_SYNC")}');
    // Access flattened UI configuration
    print('\nUI Configuration:');
    print('Theme: ${Macros.get<String>("UI.THEME")}');
    print('Animations: ${Macros.get<bool>("UI.ANIMATIONS")}');

    print('Colors:');
    print('  Primary: ${Macros.get<String>("UI.COLORS.PRIMARY")}');
    print('  Secondary: ${Macros.get<String>("UI.COLORS.SECONDARY")}');
    print('  Background: ${Macros.get<String>("UI.COLORS.BACKGROUND")}');

    // Load YAML configuration with error handling
    await MacroFunctions.LOAD_YAML('config/env.yaml');
    print('\nYAML Config:');
    print('API URL: ${Macros.get<String>('API_URL')}');
    print('Environment: ${Macros.get<String>('ENVIRONMENT')}');

    // Handle potentially missing CACHE_TTL
    try {
      print('Cache TTL: ${Macros.get<int>('CACHE_TTL')}');
    } catch (e) {
      print('Cache TTL: Not defined');
    }
  }

  Future<void> processTemplates() async {
    // Load a template file
    if (await MacroFunctions.RESOURCE_EXISTS('templates/email.txt')) {
      final template =
          await MacroFunctions.LOAD_RESOURCE('templates/email.txt');

      // Replace placeholders with macro values
      final processed = template
          .replaceAll('{APP_NAME}', Macros.get<String>('app.name'))
          .replaceAll('{VERSION}', Macros.get<String>('app.version'));

      print('\nProcessed template:\n$processed');
    } else {
      print('\nTemplate file not found');
    }
  }

  Future<void> checkResources() async {
    print('\nResource Checks:');

    // Check if resources exist
    final hasReadme = await MacroFunctions.RESOURCE_EXISTS('README.md');
    print('README exists: $hasReadme');

    // Get resource directory
    final configDir = MacroFunctions.RESOURCE_DIR('config/app.properties');
    print('Config directory: $configDir');
  }
}

void main() async {
  await initializeDartMacros();

  final example = ResourceExample();

  print('\n=== Loading Configurations ===');
  await example.loadConfigurations();

  print('\n=== Processing Templates ===');
  await example.processTemplates();

  print('\n=== Checking Resources ===');
  await example.checkResources();
}
