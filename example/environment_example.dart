import 'package:dart_macros/dart_macros.dart';

@MacroFile()
class EnvironmentExample {
  Future<void> checkEnvironment() async {
    print('=== Environment Information ===\n');

    // Platform information
    final platform = MacroFunctions.PLATFORM_INFO();
    print('Platform:');
    print('  OS: ${platform["os"]}');
    print('  Version: ${platform["version"]}');
    print('  Locale: ${platform["locale"]}');
    print('  Processors: ${platform["processors"]}');

    // Dart-related environment
    print('\nDart Environment:');
    print('  SDK Version: ${MacroFunctions.ENV("DART_SDK_VERSION")}');
    print('  Pub Cache: ${MacroFunctions.ENV("PUB_CACHE")}');

    // CI detection
    print('\nCI Environment:');
    print('  Running in CI: ${MacroFunctions.IS_CI()}');

    if (MacroFunctions.IS_CI()) {
      print('  Build Number: ${MacroFunctions.ENV("BUILD_NUMBER")}');
      print('  GitHub SHA: ${MacroFunctions.ENV("GITHUB_SHA")}');
    }

    // Build configuration
    print('\nBuild Configuration:');
    final debugMode = await MacroFunctions.BUILD_CONFIG('debug');
    print('  Debug Mode: $debugMode');

    final apiUrl = await MacroFunctions.BUILD_CONFIG('api.url');
    print('  API URL: $apiUrl');

    // Custom environment variables
    print('\nCustom Environment:');
    final appVars = MacroFunctions.ENV_WITH_PREFIX('APP_');
    appVars.forEach((key, value) {
      print('  $key: $value');
    });
  }

  void generateCode() {
    print('\n=== Generated Code Example ===\n');

    final isDebug = MacroFunctions.IS_CI() ? 'false' : 'true';
    final platformOs = MacroFunctions.PLATFORM_INFO()['os'];
    final numProcessors = MacroFunctions.PLATFORM_INFO()['processors'];
    final buildDate = DateTime.now();
    final isCiBuild = MacroFunctions.IS_CI();

    final code = '''
class Config {
  static const bool isDebug = $isDebug;
  static const String platform = '$platformOs';
  static const int processors = $numProcessors;
  
  static const String buildInfo = 
    'Build Date: $buildDate\\n'
    'Built on: \$platform\\n'
    'CI Build: $isCiBuild';
}''';

    print(code);
    print('\n');
  }
}

void main() async {
  await initializeDartMacros();

  final example = EnvironmentExample();
  await example.checkEnvironment();
  example.generateCode();
}