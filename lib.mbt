///| cst - Concrete Syntax Tree library for MoonBit
/// Based on the Red-Green Tree pattern from rowan (rust-analyzer)
///
/// # Quick Start
/// ```moonbit
/// let builder = GreenNodeBuilder::new()
/// builder.start_node(ROOT)
/// builder.token(IDENT, "foo")
/// builder.finish_node()
/// let green = builder.finish()
/// let root = SyntaxNode::new_root(green)
/// ```
///
/// # Architecture
/// - Green Tree: Immutable, position-independent, shareable
/// - Red Tree: On-demand navigation with absolute positions
