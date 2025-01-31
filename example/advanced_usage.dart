// import 'package:dart_macros/builder.dart';
//
// // Token concatenation example
// #define CONCAT(a, b) a ## b
// #define MAKE_GETTER(type, name) type get##name() => _##name
//
// // Advanced stringizing
// #define LOG_CALL(func) print("Calling " #func " at " __FILE__ ":" __LINE__)
// #define DEBUG_PRINT(...) print("Debug [" __FILE__ ":" __LINE__ "]: " __VA_ARGS__)
//
// // Custom predefined macros from build.yaml will be available
// #define APP_VERSION _VERSION_STRING
// #define IS_DEBUG _DEBUG
// #define HAS_NEW_UI _FEATURE_NEW_UI
//
// @Macro(
// defines: {
// 'LOGGING': 'true',
// 'MAX_RETRY': '3',
// },
// )
// class AdvancedExample {
// final String _name;
// final int _age;
//
// AdvancedExample(this._name, this._age);
//
// // Using MAKE_GETTER to generate getters
// MAKE_GETTER(String, name)
// MAKE_GETTER(int, age)
//
// // Using CONCAT for method names
// void CONCAT(print, Details)() {
// LOG_CALL(printDetails);
// print('Name: $_name, Age: $_age');
// }
//
// void processWithRetry() {
// #ifdef LOGGING
// DEBUG_PRINT("Starting process with retry");
// #endif
//
// for (var i = 0; i < MAX_RETRY; i++) {
// try {
// _process();
// break;
// } catch (e) {
// #ifdef LOGGING
// DEBUG_PRINT("Retry $i failed: $e");
// #endif
// }
// }
// }
//
// void _process() {
// #if IS_DEBUG
// print('Processing in debug mode');
// #endif
//
// #if HAS_NEW_UI
// _processWithNewUI();
// #else
// _processWithLegacyUI();
// #endif
// }
//
// void _processWithNewUI() {
// print('Using new UI - Version: $APP_VERSION');
// }
//
// void _processWithLegacyUI() {
// print('Using legacy UI - Version: $APP_VERSION');
// }
// }
//
// void main() {
// final example = AdvancedExample('John', 30);
// example.printDetails();
// example.processWithRetry();
// }