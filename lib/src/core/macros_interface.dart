abstract class MacrosInterface {
  void initialize();
  T get<T>(String name);
  String processMacro(String name, List<String> arguments);
  Map<String, dynamic> getAllValues();
  void define(String name, dynamic value);
  String get file;
  int get line;
  String get date;
  String get time;
  bool get isDebug;
  String get platform;
}