# MoonBit Language - Agent Instructions

> For AI coding agents working with MoonBit

## Language Overview

MoonBit is a programming language designed for efficient development and deployment. Key features:
- Expression-based language with statements and expressions
- Structural typing with traits
- Built-in error handling with `raise`, `try`, `catch`
- Multiple backends: Wasm, WasmGC, JavaScript, C, LLVM

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Variables, functions | snake_case | `let my_value`, `fn my_function` |
| Types, constants | PascalCase | `struct MyStruct`, `const MAX_SIZE` |
| Enum constructors | PascalCase | `MyEnum::CaseOne` |

## Key Syntax Notes

### Variable Declarations
```moonbit
let immutable = 1        // immutable
let mut counter = 0       // mutable
counter = counter + 1     // reassignment
```

### Control Flow
```moonbit
// Conditionals
if x > 0 { "positive" } else { "non-positive" }

// Pattern matching
match opt {
  Some(v) => v
  None => default
}

// Loop
for i in 0..<10 { ... }
while condition { ... }
```

### Functions
```moonbit
fn add(a : Int, b : Int) -> Int { a + b }

// Named parameters
fn greet(name~ : String) -> Unit { ... }
greet(name="World")

// Default parameters
fn connect(host~ : String = "localhost", port~ : Int = 8080) -> Unit { ... }
```

### Error Handling
```moonbit
suberror MyError String

fn risky() -> Int raise MyError {
  if condition { raise MyError("message") }
  42
}

// Handle errors
try risky() catch {
  MyError(msg) => println(msg)
}
```

## Common Pitfalls

| Anti-pattern | Correct |
|--------------|---------|
| `let _ = func()` | `func() |> ignore` |
| `not(condition)` | `!condition` |
| `f!(value)` | `f(value)` |
| C-style `for i=0;i<n;i++` | `for i in 0..<n` |
| `match opt { Some(v) => ... }` | `if opt is Some(v) { ... }` |
| `while arr.length() > 0 { arr.pop() }` | `arr.clear()` |

## Project Structure

```
project/
├── moon.pkg.json      # Package configuration
├── moon.mod.json      # Module configuration
└── src/               # Source code
    └── main.mbt       # Entry point
```

## Testing

```moonbit
test "my test" {
  assert_eq(1 + 1, 2)
  inspect(value, content="expected")
}
```

## Resources

- Official docs: https://moonbitlang.com/docs/
- Standard library: https://github.com/moonbitlang/core
- Package registry: https:// packages.moonbitlang.com
