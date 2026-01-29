///| TextSize - Represents a position in text (UTF-8 byte offset)
pub(all) struct TextSize {
  raw : UInt
} derive(Eq, Hash, Show)

///|
pub fn TextSize::new(raw : UInt) -> TextSize {
  TextSize::{ raw, }
}

///|
pub fn TextSize::from_int(n : Int) -> TextSize {
  TextSize::{ raw: n.reinterpret_as_uint() }
}

///|
pub fn TextSize::zero() -> TextSize {
  TextSize::{ raw: 0 }
}

///|
pub fn TextSize::raw(self : TextSize) -> UInt {
  self.raw
}

///|
pub fn TextSize::to_int(self : TextSize) -> Int {
  self.raw.reinterpret_as_int()
}

///|
pub impl Add for TextSize with add(self : TextSize, other : TextSize) -> TextSize {
  TextSize::{ raw: self.raw + other.raw }
}

///|
pub impl Sub for TextSize with sub(self : TextSize, other : TextSize) -> TextSize {
  TextSize::{ raw: self.raw - other.raw }
}

///|
pub impl Compare for TextSize with compare(self : TextSize, other : TextSize) -> Int {
  if self.raw < other.raw {
    -1
  } else if self.raw > other.raw {
    1
  } else {
    0
  }
}

///| TextRange - Represents a span in text [start, end)
pub(all) struct TextRange {
  start : TextSize
  end : TextSize
} derive(Eq, Hash, Show)

///|
pub fn TextRange::new(start : TextSize, end : TextSize) -> TextRange {
  TextRange::{ start, end }
}

///|
pub fn TextRange::at(offset : TextSize, len : TextSize) -> TextRange {
  TextRange::{ start: offset, end: offset + len }
}

///|
pub fn TextRange::empty(offset : TextSize) -> TextRange {
  TextRange::{ start: offset, end: offset }
}

///|
pub fn TextRange::start(self : TextRange) -> TextSize {
  self.start
}

///|
pub fn TextRange::end(self : TextRange) -> TextSize {
  self.end
}

///|
pub fn TextRange::len(self : TextRange) -> TextSize {
  self.end - self.start
}

///|
pub fn TextRange::is_empty(self : TextRange) -> Bool {
  self.start == self.end
}

///|
pub fn TextRange::contains(self : TextRange, offset : TextSize) -> Bool {
  self.start <= offset && offset < self.end
}

///|
pub fn TextRange::contains_range(self : TextRange, other : TextRange) -> Bool {
  self.start <= other.start && other.end <= self.end
}
