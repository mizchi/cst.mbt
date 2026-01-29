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
pub(all) struct ParentFrame {
  kind : SyntaxKind
  first_child_idx : Int
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
  let frame = ParentFrame::{ kind, first_child_idx: self.children.length() }
  self.parents.push(frame)
}

///| Start a node at a previous checkpoint position
pub fn GreenNodeBuilder::start_node_at(
  self : GreenNodeBuilder,
  checkpoint : Checkpoint,
  kind : SyntaxKind
) -> Unit {
  // Insert a new frame that will wrap children from checkpoint position
  let frame = ParentFrame::{ kind, first_child_idx: checkpoint.child_idx }
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
}

///| Calculate current offset within the current parent
fn GreenNodeBuilder::current_offset(self : GreenNodeBuilder) -> TextSize {
  let start_idx = if self.parents.is_empty() {
    0
  } else {
    self.parents[self.parents.length() - 1].first_child_idx
  }
  let mut offset = TextSize::zero()
  for i = start_idx; i < self.children.length(); i = i + 1 {
    offset = offset + self.children[i].text_len()
  }
  offset
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
  self.children.push(Node(rel_offset=parent_offset, node~))
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
