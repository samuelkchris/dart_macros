// // Function-like macro examples
// #define SQUARE(x) ((x) * (x))
// #define MAX(a, b) ((a) > (b) ? (a) : (b))
// #define MIN(a, b) ((a) < (b) ? (a) : (b))
// #define CLAMP(x, low, high) (MIN(MAX((x), (low)), (high)))
// #define STRINGIFY(x) #x
// #define PRINT_VAR(var) print("Variable " #var " = " + (var).toString())
//
// void main() {
// // Using square macro
// final squared = SQUARE(5);  // Expands to ((5) * (5))
// print('5 squared is $squared');
//
// // Using max/min macros
// final a = 10, b = 20;
// final maximum = MAX(a, b);  // Expands to ((a) > (b) ? (a) : (b))
// final minimum = MIN(a, b);  // Expands to ((a) < (b) ? (a) : (b))
// print('Max of $a and $b is $maximum');
// print('Min of $a and $b is $minimum');
//
// // Using clamp macro
// final value = 15;
// final clamped = CLAMP(value, 0, 10);  // Keeps value between 0 and 10
// print('Clamped value is $clamped');
//
// // Using stringizing operator
// final name = STRINGIFY(user);  // Converts to "user"
// print('Stringized: $name');
//
// // Using print variable macro
// final count = 42;
// PRINT_VAR(count);  // Prints: Variable count = 42
// }