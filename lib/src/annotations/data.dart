import 'package:meta/meta.dart';

import '../../dart_macros.dart';

@immutable
class Data extends MacroAnnotation {
  /// Whether to generate toString method
  final bool generateToString;

  /// Whether to generate equality operators (== and hashCode)
  final bool generateEquality;

  /// Whether to generate copyWith method
  final bool generateCopyWith;

  /// Whether to generate JSON serialization methods
  final bool generateJson;

  /// Whether to make the generated constructor const
  final bool makeConst;

  /// Whether to generate a factory constructor from map
  final bool generateFromMap;

  /// Whether to generate a toMap method
  final bool generateToMap;

  /// Custom prefix for generated code (to avoid conflicts)
  final String? generatedPrefix;

  const Data({
    this.generateToString = true,
    this.generateEquality = true,
    this.generateCopyWith = true,
    this.generateJson = true,
    this.makeConst = true,
    this.generateFromMap = true,
    this.generateToMap = true,
    this.generatedPrefix,
  });

  /// Get the prefix to use for generated code
  String getPrefix() => generatedPrefix ?? '_\$';
}
