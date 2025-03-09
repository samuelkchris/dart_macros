import 'package:dart_macros/dart_macros.dart';

@MacroFile()
@Define('DEBUG', true)
@Define('PLATFORM', 'android')
@Define('API_VERSION', 2)
@Define('FEATURE_NEW_UI', true)
class App {
  void initialize() {
    if (MacroFunctions.IFDEF('DEBUG')) {
      print('Debug mode initialization');
      setupDebugTools();
    }

    if (MacroFunctions.IF_PLATFORM('android')) {
      print('Initializing Android platform');
      setupAndroidSpecifics();
    }

    // Complex conditions
    if (MacroFunctions.IF('DEBUG && API_VERSION >= 2')) {
      print('Advanced debug features available');
    }

    // Feature flags with version check
    if (MacroFunctions.IF('FEATURE_NEW_UI && API_VERSION >= 2')) {
      setupNewUI();
    } else {
      setupLegacyUI();
    }
  }

  void setupDebugTools() {
    print('Setting up debug tools');
  }

  void setupAndroidSpecifics() {
    print('Setting up Android specifics');
  }

  void setupNewUI() {
    print('Setting up new UI');
  }

  void setupLegacyUI() {
    print('Setting up legacy UI');
  }

  void processData() {
    // Version-specific code
    if (MacroFunctions.IF_VERSION_GTE(2)) {
      print('Using new API');
    } else {
      print('Using legacy API');
    }

    // Platform-specific optimizations
    if (MacroFunctions.IF('PLATFORM == "android" && DEBUG')) {
      print('Android-specific debug optimizations');
    }

    // Feature gates
    if (MacroFunctions.IFNDEF('EXPERIMENTAL')) {
      print('Using stable features only');
    }
  }
}

void main() async {
  await initializeDartMacros();

  final app = App();
  app.initialize();
  app.processData();
}
