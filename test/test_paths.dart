import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  // Get the current script's directory
  final scriptDir = path.dirname(Platform.script.toFilePath());
  print('Script directory: $scriptDir');

  // Check for config directory
  final configPath = path.normalize(path.join(scriptDir, '..', 'config'));
  print('\nChecking config directory: $configPath');
  print('Config directory exists: ${Directory(configPath).existsSync()}');

  // Check for specific files
  final files = [
    'app.properties',
    'features.json',
    'env.yaml',
  ];

  print('\nChecking config files:');
  for (final file in files) {
    final filePath = path.join(configPath, file);
    final exists = File(filePath).existsSync();
    print('$file: ${exists ? 'Found' : 'Not found'} at $filePath');

    if (exists) {
      print('Content:');
      print(File(filePath).readAsStringSync());
      print('---');
    }
  }

  // Check project structure
  print('\nProject structure:');
  _printDirectoryContents(path.normalize(path.join(scriptDir, '..')), '');
}

void _printDirectoryContents(String dir, String indent) {
  final entities = Directory(dir).listSync()
    ..sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

  for (final entity in entities) {
    final basename = path.basename(entity.path);
    if (basename.startsWith('.')) continue; // Skip hidden files/directories

    print('$indent$basename');
    if (entity is Directory) {
      _printDirectoryContents(entity.path, '$indent  ');
    }
  }
}