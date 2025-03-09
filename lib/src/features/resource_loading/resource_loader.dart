import 'dart:io';
import 'package:path/path.dart' as path;

import '../../../dart_macros.dart';
import '../../core/location.dart';

/// Handles safe loading of resources relative to macro source files.
///
/// The [ResourceLoader] provides secure, controlled access to resource files
/// for macro processing. It implements several safety mechanisms:
/// - Whitelist approach to file extensions
/// - File size limits
/// - Multiple resolution strategies for finding resources
/// - Caching for performance optimization
///
/// This class is essential for allowing macros to reference external resources
/// while maintaining security and performance.
///
/// Example usage:
/// ```dart
/// final content = await ResourceLoader.loadResource('config.json', location);
/// ```
class ResourceLoader {
  /// Allowed file extensions that can be loaded.
  ///
  /// This whitelist ensures that only safe file types can be accessed
  /// through the resource loader, preventing access to sensitive or
  /// executable files.
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

  /// Maximum allowed file size (5MB).
  ///
  /// This limit prevents loading excessively large files which could
  /// cause memory issues or be used for denial of service attacks.
  static const _maxFileSize = 5 * 1024 * 1024;

  /// Cache of loaded resources.
  ///
  /// This cache improves performance by storing previously loaded
  /// resources, avoiding repeated file I/O operations.
  static final Map<String, String> _cache = {};

  /// Loads a resource relative to the current source file.
  ///
  /// This method attempts to locate and load a resource using several
  /// resolution strategies. It implements safety checks for file type
  /// and size, and provides caching for performance.
  ///
  /// Parameters:
  /// - [resourcePath]: The path to the resource, relative to [sourceLocation]
  /// - [sourceLocation]: The source location for resolving relative paths
  ///
  /// Returns:
  /// The content of the resource as a string
  ///
  /// Throws:
  /// - [MacroUsageException] if the resource cannot be found or is invalid
  static Future<String> loadResource(
      String resourcePath, Location sourceLocation) async {
    final resolvedPaths = _getAllPossiblePaths(resourcePath, sourceLocation);
    String? content;

    for (final resolvedPath in resolvedPaths) {
      /* Check cache first */
      if (_cache.containsKey(resolvedPath)) {
        return _cache[resolvedPath]!;
      }

      /* Validate file extension */
      if (!_isAllowedExtension(resolvedPath)) {
        continue; // Try next path instead of throwing
      }

      /* Check if file exists */
      final file = File(resolvedPath);
      if (!await file.exists()) {
        continue; // Try next path
      }

      /* Check file size */
      final size = await file.length();
      if (size > _maxFileSize) {
        throw MacroUsageException(
          'Resource exceeds maximum allowed size of ${_maxFileSize ~/ 1024}KB: $resolvedPath',
          sourceLocation,
        );
      }

      try {
        /* Read and cache the content */
        content = await file.readAsString();
        _cache[resolvedPath] = content;
        return content;
      } catch (e) {
        continue; // Try next path if reading fails
      }
    }

    /* If we get here, no valid file was found */
    throw MacroUsageException(
      'Resource not found: $resourcePath\nTried paths:\n${resolvedPaths.join('\n')}',
      sourceLocation,
    );
  }

  /// Loads a binary resource relative to the current source file.
  ///
  /// Similar to [loadResource], but returns the content as bytes instead
  /// of a string, suitable for binary file formats.
  ///
  /// Parameters:
  /// - [resourcePath]: The path to the resource, relative to [sourceLocation]
  /// - [sourceLocation]: The source location for resolving relative paths
  ///
  /// Returns:
  /// The content of the resource as a list of bytes
  ///
  /// Throws:
  /// - [MacroUsageException] if the resource cannot be found or is invalid
  static Future<List<int>> loadBinaryResource(
      String resourcePath,
      Location sourceLocation,
      ) async {
    final resolvedPaths = _getAllPossiblePaths(resourcePath, sourceLocation);

    for (final resolvedPath in resolvedPaths) {
      /* Validate file extension */
      if (!_isAllowedExtension(resolvedPath)) {
        continue;
      }

      /* Check if file exists */
      final file = File(resolvedPath);
      if (!await file.exists()) {
        continue;
      }

      /* Check file size */
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

  /// Gets all possible paths for a resource.
  ///
  /// This method implements the resolution strategy for finding resources,
  /// trying several locations in order of priority:
  /// 1. Absolute path (if provided)
  /// 2. Relative to the source file
  /// 3. Relative to the project root
  /// 4. Relative to the current working directory
  ///
  /// Parameters:
  /// - [resourcePath]: The resource path to resolve
  /// - [sourceLocation]: The source location for path resolution
  ///
  /// Returns:
  /// A list of possible absolute file paths to try
  static List<String> _getAllPossiblePaths(String resourcePath, Location sourceLocation) {
    final paths = <String>[];

    /* 1. If absolute path, only try that */
    if (path.isAbsolute(resourcePath)) {
      paths.add(path.normalize(resourcePath));
      return paths;
    }

    /* 2. Relative to source file */
    final sourceDir = path.dirname(path.absolute(sourceLocation.file));
    paths.add(path.normalize(path.join(sourceDir, resourcePath)));

    /* 3. Relative to project root */
    final projectRoot = _findProjectRoot(sourceLocation.file);
    paths.add(path.normalize(path.join(projectRoot, resourcePath)));

    /* 4. Relative to current working directory */
    paths.add(path.normalize(path.join(Directory.current.path, resourcePath)));

    return paths.toSet().toList(); // Remove duplicates
  }

  /// Gets all possible paths for a resource (public version).
  ///
  /// Similar to [_getAllPossiblePaths] but exposed for public use.
  /// This allows other components to use the same path resolution
  /// strategy without code duplication.
  ///
  /// Parameters:
  /// - [resourcePath]: The resource path to resolve
  /// - [sourceLocation]: The source location for path resolution
  ///
  /// Returns:
  /// A list of possible absolute file paths to try
  static List<String> getAllPossiblePaths(String resourcePath, Location sourceLocation) {
    final paths = <String>[];

    /* 1. If absolute path, only try that */
    if (path.isAbsolute(resourcePath)) {
      paths.add(path.normalize(resourcePath));
      return paths;
    }

    /* 2. Relative to source file */
    final sourceDir = path.dirname(path.absolute(sourceLocation.file));
    paths.add(path.normalize(path.join(sourceDir, resourcePath)));

    /* 3. Relative to project root */
    final projectRoot = _findProjectRoot(sourceLocation.file);
    paths.add(path.normalize(path.join(projectRoot, resourcePath)));

    /* 4. Relative to current working directory */
    paths.add(path.normalize(path.join(Directory.current.path, resourcePath)));

    return paths.toSet().toList(); // Remove duplicates
  }

  /// Finds the project root directory by looking for pubspec.yaml.
  ///
  /// This method walks up the directory tree from a starting path,
  /// looking for a pubspec.yaml file which indicates the project root.
  ///
  /// Parameters:
  /// - [startPath]: The path to start searching from
  ///
  /// Returns:
  /// The project root directory path, or the original directory if not found
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

  /// Finds the project root directory (public version).
  ///
  /// Similar to [_findProjectRoot] but exposed for public use.
  ///
  /// Parameters:
  /// - [startPath]: The path to start searching from
  ///
  /// Returns:
  /// The project root directory path, or the original directory if not found
  static String findProjectRoot(String startPath) {
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

  /// Checks if the file extension is allowed.
  ///
  /// This method verifies that the file has an extension in the
  /// whitelist of [_allowedExtensions].
  ///
  /// Parameters:
  /// - [filePath]: The path to check
  ///
  /// Returns:
  /// true if the extension is allowed, false otherwise
  static bool _isAllowedExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _allowedExtensions.contains(ext);
  }

  /// Checks if the file extension is allowed (public version).
  ///
  /// Similar to [_isAllowedExtension] but exposed for public use.
  ///
  /// Parameters:
  /// - [filePath]: The path to check
  ///
  /// Returns:
  /// true if the extension is allowed, false otherwise
  static bool isAllowedExtension(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _allowedExtensions.contains(ext);
  }

  /// Clears the resource cache.
  ///
  /// This method allows clearing the cache when needed, such as
  /// when resources might have changed during development.
  static void clearCache() {
    _cache.clear();
  }

  /// Adds a file extension to the allowed types.
  ///
  /// This method allows extending the whitelist of allowed file extensions.
  ///
  /// Parameters:
  /// - [extension]: The extension to add (with or without leading dot)
  static void addAllowedExtension(String extension) {
    if (!extension.startsWith('.')) {
      extension = '.$extension';
    }
    _allowedExtensions.add(extension.toLowerCase());
  }
}

/// Extension methods for MacroProcessor to support resource loading.
///
/// This extension provides integration between the MacroProcessor and
/// ResourceLoader, allowing macros to be defined from resource files.
extension ResourceLoaderExtension on MacroProcessor {
  /// Defines a macro from a resource file.
  ///
  /// This method loads a resource file and defines its content as a macro.
  ///
  /// Parameters:
  /// - [name]: The name of the macro to define
  /// - [resourcePath]: The path to the resource file
  /// - [location]: The source location for error reporting
  ///
  /// Returns:
  /// A Future that completes when the macro has been defined
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