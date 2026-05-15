///| NodeCache - Caches interned tokens and nodes for sharing
pub(all) struct NodeCache {
  tokens : @hashmap.HashMap[(SyntaxKind, String), GreenToken]
  nodes : @hashmap.HashMap[(SyntaxKind, Int), GreenNode]
}

///|
pub fn NodeCache::new() -> NodeCache {
  NodeCache::{
    tokens: @hashmap.new(),
    nodes: @hashmap.new(),
  }
}

///|
pub fn NodeCache::token(
  self : NodeCache,
  kind : SyntaxKind,
  text : String
) -> GreenToken {
  let key = (kind, text)
  match self.tokens.get(key) {
    Some(token) => token
    None => {
      let token = GreenToken::new(kind, text)
      self.tokens.set(key, token)
      token
    }
  }
}

///| Checkpoint - Marks a position in the builder for later wrapping
pub(all) struct Checkpoint {
  parent_idx : Int
  child_idx : Int
} derive(Eq, Show)

///| Parent frame for building nested nodes
///
/// `accumulated_len` is the running sum of `text_len()` of the children
/// pushed into this frame since `start_node`. It lets `current_offset`
/// run in O(1) — the previous implementation walked all children of the
/// current frame on every `token` push, which turned the overall build
/// into O(N^2) for flat parent frames (e.g. a parser's module body that
/// holds hundreds of top-level declaration nodes plus their interleaved
/// whitespace / comment tokens).
pub(all) struct ParentFrame {
  kind : SyntaxKind
  first_child_idx : Int
  mut accumulated_len : TextSize
}

///| GreenNodeBuilder - Incrementally builds green trees
pub(all) struct GreenNodeBuilder {
  cache : NodeCache
  parents : Array[ParentFrame]
  children : Array[GreenChild]
}

///|
pub fn GreenNodeBuilder::new() -> GreenNodeBuilder {
  GreenNodeBuilder::{
    cache: NodeCache::new(),
    parents: [],
    children: [],
  }
}

///|
pub fn GreenNodeBuilder::with_cache(cache : NodeCache) -> GreenNodeBuilder {
  GreenNodeBuilder::{ cache, parents: [], children: [] }
}

///| Create a checkpoint at current position
pub fn GreenNodeBuilder::checkpoint(self : GreenNodeBuilder) -> Checkpoint {
  Checkpoint::{
    parent_idx: self.parents.length(),
    child_idx: self.children.length(),
  }
}

///| Start a new node
pub fn GreenNodeBuilder::start_node(
  self : GreenNodeBuilder,
  kind : SyntaxKind
) -> Unit {
  let frame = ParentFrame::{
    kind,
    first_child_idx: self.children.length(),
    accumulated_len: TextSize::zero(),
  }
  self.parents.push(frame)
}

///| Start a node at a previous checkpoint position
pub fn GreenNodeBuilder::start_node_at(
  self : GreenNodeBuilder,
  checkpoint : Checkpoint,
  kind : SyntaxKind
) -> Unit {
  // Re-sum the accumulated length for the children that will be
  // wrapped by this retroactive frame. This is O(K) where K is the
  // number of children between the checkpoint and the current position;
  // typically small (a single expression's worth of children), unlike
  // the unbounded walk the old current_offset performed on every token.
  let mut len = TextSize::zero()
  for i = checkpoint.child_idx; i < self.children.length(); i = i + 1 {
    len = len + self.children[i].text_len()
  }
  let frame = ParentFrame::{
    kind,
    first_child_idx: checkpoint.child_idx,
    accumulated_len: len,
  }
  // Insert at the checkpoint's parent position
  self.parents.insert(checkpoint.parent_idx, frame)
}

///| Add a token
pub fn GreenNodeBuilder::token(
  self : GreenNodeBuilder,
  kind : SyntaxKind,
  text : String
) -> Unit {
  let green_token = self.cache.token(kind, text)
  let offset = self.current_offset()
  self.children.push(Token(rel_offset=offset, token=green_token))
  // Maintain the topmost frame's running text length so the next push
  // can read `current_offset` in O(1).
  if !self.parents.is_empty() {
    let top = self.parents.length() - 1
    self.parents[top].accumulated_len = self.parents[top].accumulated_len +
      green_token.text_len()
  }
}

///| Calculate current offset within the current parent.
///
/// O(1) — the topmost frame caches its accumulated child text length and
/// `token` / `finish_node` maintain it incrementally.
fn GreenNodeBuilder::current_offset(self : GreenNodeBuilder) -> TextSize {
  if self.parents.is_empty() {
    TextSize::zero()
  } else {
    self.parents[self.parents.length() - 1].accumulated_len
  }
}

///| Finish the current node
pub fn GreenNodeBuilder::finish_node(self : GreenNodeBuilder) -> Unit {
  let frame = match self.parents.pop() {
    Some(f) => f
    None => abort("finish_node called without matching start_node")
  }
  // Collect children for this node
  let node_children : Array[GreenChild] = []
  while self.children.length() > frame.first_child_idx {
    let child = self.children.unsafe_pop()
    node_children.push(child)
  }
  // Reverse to maintain correct order
  node_children.rev_in_place()
  // Fix relative offsets after reversing
  let fixed_children : Array[GreenChild] = []
  let mut offset = TextSize::zero()
  for child in node_children {
    let fixed = match child {
      GreenChild::Node(node~, ..) => {
        let c = GreenChild::Node(rel_offset=offset, node~)
        offset = offset + node.text_len()
        c
      }
      GreenChild::Token(token~, ..) => {
        let c = GreenChild::Token(rel_offset=offset, token~)
        offset = offset + token.text_len()
        c
      }
    }
    fixed_children.push(fixed)
  }
  let node = GreenNode::new(frame.kind, @array.from_array(fixed_children[:]))
  let parent_offset = self.current_offset()
  let node_len = node.text_len()
  self.children.push(Node(rel_offset=parent_offset, node~))
  // Roll the collapsed node's text length into the parent frame so the
  // outer frame's accumulated_len stays consistent with its child list.
  if !self.parents.is_empty() {
    let top = self.parents.length() - 1
    self.parents[top].accumulated_len = self.parents[top].accumulated_len +
      node_len
  }
}

///| Finish building and return the root node
pub fn GreenNodeBuilder::finish(self : GreenNodeBuilder) -> GreenNode {
  guard self.parents.is_empty() else {
    abort("finish called with unclosed nodes")
  }
  guard self.children.length() == 1 else {
    abort("finish must have exactly one root node")
  }
  match self.children.unsafe_pop() {
    Node(node~, ..) => node
    Token(..) => abort("root must be a node, not a token")
  }
}
