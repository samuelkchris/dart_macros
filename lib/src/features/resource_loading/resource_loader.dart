import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../dart_macros.dart';
import '../../core/location.dart';

/// Handles safe loading of resources relative to macro source files
class ResourceLoader {
  /// Allowed file extensions that can be loaded
  static const _allowedExtensions = {
    '.txt',
    '.json',
    '.yaml',
    '.properties',
    '.csv',
    '.xml',
    '.html',
    '.md',
    '.env',
    '.ini',
    '.toml'
  };

  /// Maximum allowed file size (5MB)
  static const _maxFileSize = 5 * 1024 * 1024;

  /// Cache of loaded resources
  static final Map<String, String> _cache = {};

  /// Load a resource relative to the current source file
  ///
  /// [resourcePath] is the path relative to [sourceLocation]
  /// Returns the content of the resource as a string
  static Future<String> loadResource(
      String resourcePath, Location sourceLocation) async {
    final resolvedPaths = _getAllPossiblePaths(resourcePath, sourceLocation);
    String? content;

    for (final resolvedPath in resolvedPaths) {
      // Check cache first
      if (_cache.containsKey(resolvedPath)) {
        return _cache[resolvedPath]!;
      }

      // Validate file extension
      if (!_isAllowedExtension(resolvedPath)) {
        continue; // Try next path instead of throwing
      }

      // Check if file exists
      final file = File(resolvedPath);
      if (!await file.exists()) {
        continue; // Try next path
      }

      // Check file size
      final size = await file.length();
      if (size > _maxFileSize) {
        throw MacroUsageException(
          'Resource exceeds maximum allowed size of ${_maxFileSize ~/ 1024}KB: $resolvedPath',
          sourceLocation,
        );
      }

      try {
        // Read and cache the content
        content = await file.readAsString();
        _cache[resolvedPath] = content;
        return content;
      } catch (e) {
        continue; // Try next path if reading fails
      }
    }

    // If we get here, no valid file was found
    throw MacroUsageException(
      'Resource not found: $resourcePath\nTried paths:\n${resolvedPaths.join('\n')}',
      sourceLocation,
    );
  }

  /// Load a binary resource relative to the current source file
  ///
  /// [resourcePath] is the path relative to [sourceLocation]
  /// Returns the content of the resource as bytes
  static Future<List<int>> loadBinaryResource(
      String resourcePath,
      Location sourceLocation,
      ) async {
    final resolvedPaths = _getAllPossiblePaths(resourcePath, sourceLocation);

    for (final resolvedPath in resolvedPaths) {
      // Validate file extension
      if (!_isAllowedExtension(resolvedPath)) {
        continue;
      }

      // Check if file exists
      final file = File(resolvedPath);
      if (!await file.exists()) {
        continue;
      }

      // Check file size
      final size = await file.length();
      if (size > _maxFileSize) {
        throw MacroUsageException(
          'Resource exceeds maximum allowed size of ${_maxFileSize ~/ 1024}KB: $resolvedPath',
          sourceLocation,
        );
      }

      try {
        return await file.readAsBytes();
      } catch (e) {
        continue;
      }
    }

    throw MacroUsageException(
      'Resource not found: $resourcePath\nTried paths:\n${resolvedPaths.join('\n')}',
      sourceLocation,
    );
  }

  /// Get all possible paths for a resource
  static List<String> _getAllPossiblePaths(String resourcePath, Location sourceLocation) {
    final paths = <String>[];

    // 1. If absolute path, only try that
    if (path.isAbsolute(resourcePath)) {
      paths.add(path.normalize(resourcePath));
      return paths;
    }

    // 2. Relative to source file
    final sourceDir = path.dirname(path.absolute(sourceLocation.file));
    paths.add(path.normalize(path.join(sourceDir, resourcePath)));

    // 3. Relative to project root
    final projectRoot = _findProjectRoot(sourceLocation.file);
    paths.add(path.normalize(path.join(projectRoot, resourcePath)));

    // 4. Relative to current working directory
    paths.add(path.normalize(path.join(Directory.current.path, resourcePath)));

    return paths.toSet().toList(); // Remove duplicates
  }

  /// Get all possible paths for a resource getter
  /// getAllPossiblePaths
  ///
  /// [resourcePath] is the path relative to [sourceLocation]
  /// Returns a list of all possible paths
  ///
  /// [sourceLocation] is the location of the macro call
  static List<String> getAllPossiblePaths(String resourcePath, Location sourceLocation) {
    final paths = <String>[];

    // 1. If absolute path, only try that
    if (path.isAbsolute(resourcePath)) {
      paths.add(path.normalize(resourcePath));
      return paths;
    }

    // 2. Relative to source file
    final sourceDir = path.dirname(path.absolute(sourceLocation.file));
    paths.add(path.normalize(path.join(sourceDir, resourcePath)));

    // 3. Relative to project root
    final projectRoot = _findProjectRoot(sourceLocation.file);
    paths.add(path.normalize(path.join(projectRoot, resourcePath)));

    // 4. Relative to current working directory
    paths.add(path.normalize(path.join(Directory.current.path, resourcePath)));

    return paths.toSet().toList(); // Remove duplicates
  }

  /// Find the project root directory by looking for pubspec.yaml
  static String _findProjectRoot(String startPath) {
    var dir = path.normalize(path.absolute(startPath));
    while (dir.length > path.rootPrefix(dir).length) {
      if (File(path.join(dir, 'pubspec.yaml')).existsSync()) {
        return dir;
      }
      final parent = path.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
    // If we can't find project root, return the original directory
    return path.dirname(startPath);
  }

  /// Check if the file extension is allowed
  static bool _isAllowedExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _allowedExtensions.contains(ext);
  }

  /// Check if the file extension is allowed for a resource getter
  /// isAllowedExtension
  ///
  /// [filePath] is the path to the file
  /// Returns true if the extension is allowed
  ///
  static bool isAllowedExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _allowedExtensions.contains(ext);
  }

  /// Clear the resource cache
  static void clearCache() {
    _cache.clear();
  }

  /// Add a file extension to allowed types
  static void addAllowedExtension(String extension) {
    if (!extension.startsWith('.')) {
      extension = '.$extension';
    }
    _allowedExtensions.add(extension.toLowerCase());
  }
}

/// Extension methods for MacroProcessor to support resource loading
extension ResourceLoaderExtension on MacroProcessor {
  /// Define a macro from a resource file
  Future<void> defineFromResource(
      String name,
      String resourcePath,
      Location location,
      ) async {
    final content = await ResourceLoader.loadResource(resourcePath, location);
    define(
      name: name,
      replacement: content,
      location: location,
    );
  }
}