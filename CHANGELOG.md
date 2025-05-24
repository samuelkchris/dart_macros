# Changelog

All notable changes to the `dart_macros` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-04-01
### Added

## [1.0.1] - 2025-03-09

### Added
- Cross-platform support for Flutter mobile applications (iOS/Android)
- New `FlutterMacros` helper class for easier Flutter integration
- Platform detection for automatic implementation selection
- Documentation for mobile-specific usage patterns

### Fixed
- Resolved issue with macro expansion in nested function calls
- Fixed path handling for file macros on Windows platforms
- Corrected error reporting for invalid macro definitions
- Addressed performance issues with large macro expansions

### Improved
- Enhanced documentation with Flutter-specific examples
- Optimized runtime performance for mobile platforms
- Streamlined API for registering macros programmatically
- Better error messages for common configuration mistakes

## [1.0.0] - 2025-03-01

### Added
- Initial release of dart_macros package
- Object-like macros for constant definitions
- Function-like macros for code generation
- Token concatenation operations
- Stringizing operations
- Conditional compilation directives
- Predefined macros system
- Runtime macro evaluation
- Debug and platform-specific macros
- Annotations for macro definition
- Documentation and examples
- Error reporting and debugging support
- Integration with Dart build system
- Type-safe macro expansion