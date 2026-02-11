# mizchi/cst

Concrete Syntax Tree library for [MoonBit](https://www.moonbitlang.com/), based on the [Red-Green Tree](https://ericlippert.com/2012/06/08/red-green-trees/) pattern from Rust's [rowan](https://github.com/rust-analyzer/rowan) (used in rust-analyzer).

## Features

- **Green Tree** — Immutable, position-independent, structurally shareable syntax nodes
- **Red Tree** — On-demand wrapper providing absolute positions and parent navigation
- **GreenNodeBuilder** — Incremental tree construction with checkpoint/wrap support
- **NodeCache** — Token and node interning for memory efficiency
- **Language-agnostic** — Define your own `SyntaxKind` set for any language

## Install

```bash
moon add mizchi/cst
```

## Quick Start

```moonbit nocheck
// Define syntax kinds for your language
let ROOT = @cst.SyntaxKind::new(1)
let IDENT = @cst.SyntaxKind::new(2)
let PLUS = @cst.SyntaxKind::new(3)

// Build a green tree
let builder = @cst.GreenNodeBuilder::new()
builder.start_node(ROOT)
builder.token(IDENT, "a")
builder.token(PLUS, "+")
builder.token(IDENT, "b")
builder.finish_node()
let green = builder.finish()

// Navigate with the red tree
let root = @cst.SyntaxNode::new_root(green)
let range = root.text_range() // [0, 3)
let children = root.children() // [Token("a"), Token("+"), Token("b")]
```

## Architecture

```
Green Tree (immutable, shareable)        Red Tree (on-demand, positional)
┌─────────────────────────────┐         ┌──────────────────────────────┐
│ GreenNode                   │         │ SyntaxNode                   │
│  ├─ kind: SyntaxKind        │    ──►  │  ├─ green: GreenNode         │
│  ├─ text_len: TextSize      │         │  ├─ parent: SyntaxNode?      │
│  └─ children: [GreenChild]  │         │  ├─ offset: TextSize         │
│                             │         │  └─ children() -> [Element]  │
│ GreenToken                  │         │                              │
│  ├─ kind: SyntaxKind        │         │ SyntaxToken                  │
│  └─ text: String            │         │  ├─ green: GreenToken        │
└─────────────────────────────┘         │  ├─ parent: SyntaxNode       │
                                        │  └─ text_range() -> Range    │
                                        └──────────────────────────────┘
```

The green tree stores structure without positions. The red tree wraps it to provide absolute offsets, parent references, and navigation — materialized lazily per node.

## API

### Building Trees

```moonbit nocheck
let builder = @cst.GreenNodeBuilder::new()

// Basic: start/finish nodes, add tokens
builder.start_node(kind)
builder.token(kind, "text")
builder.finish_node()
let green = builder.finish()

// Checkpoint: wrap previously added tokens into a node retroactively
let cp = builder.checkpoint()
builder.token(NUM, "1")
builder.token(PLUS, "+")
builder.token(NUM, "2")
builder.start_node_at(cp, BINARY_EXPR) // wraps all tokens since checkpoint
builder.finish_node()
```

### Navigating Trees

```moonbit nocheck
let root = @cst.SyntaxNode::new_root(green)

root.kind()              // SyntaxKind
root.text_range()        // TextRange [start, end)
root.text_len()          // TextSize
root.parent()            // SyntaxNode?
root.children()          // Array[SyntaxElement]
root.child_nodes()       // Array[SyntaxNode]
root.child_tokens()      // Array[SyntaxToken]
root.first_child()       // SyntaxElement?
root.child_at(i)         // SyntaxElement?
```

### Text Primitives

```moonbit nocheck
let size = @cst.TextSize::new(5)     // UTF-8 byte offset
let range = @cst.TextRange::new(     // [start, end) span
  @cst.TextSize::new(0),
  @cst.TextSize::new(5),
)
range.len()              // TextSize
range.contains(size)     // Bool
```

## Example: expr_lang

`examples/expr_lang/` contains a complete lexer, parser, and formatter for a small expression language, demonstrating how to build a language toolchain on top of this library.

```
let x = 1 + 2 * 3
fn add(a, b) { a + b }
add(x, 10)
```

```bash
moon run examples/expr_lang/main
```

## License

Apache-2.0
