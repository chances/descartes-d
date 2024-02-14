/// 2D ⇆ 3D vector conversions.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021-2024 Chance Snow. All rights reserved.
/// License: MIT License
module descartes.convert;

import descartes : V2, V3;

pragma(inline, true):

/// Determines how vecotrs are swizzled between 2D and 3D, like in shader languages.
/// See_Also: <a href="https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)">Swizzling (computer graphics)</a> on Wikipedia
enum Swizzle {
  ///
  xy,
  ///
  xz
}

/// Swizzle the given vector from 3D to 2D.
/// Params:
/// vector=
/// swizzle=How the given `vector` should be swizzled to 2D.
/// See_Also: <a href="https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)">Swizzling (computer graphics)</a> on Wikipedia
V2 to2d(V3 vector, Swizzle swizzle = Swizzle.xy) {
  if (swizzle == Swizzle.xy) return vector.xy;
  if (swizzle == Swizzle.xz) return vector.xz;
  assert(0, "Unreachable");
}

/// Swizzle the given vector from 2D to 3D.
/// Params:
/// vector=
/// swizzle=How the given `vector` should be swizzled to 3D.
/// See_Also: <a href="https://en.wikipedia.org/wiki/Swizzling_(computer_graphics)">Swizzling (computer graphics)</a> on Wikipedia
V3 to3d(V2 vector, Swizzle swizzle = Swizzle.xy) {
  if (swizzle == Swizzle.xy) return V3(vector.xy.v ~ 0.0);
  if (swizzle == Swizzle.xz) return V3(vector.x, 0.0, vector.y);
  assert(0, "Unreachable");
}

unittest {
  import descartes : up, down, left, right;

  assert(up.to3d == V3(0, -1, 0));
  assert(down.to3d == V3(0, 1, 0));
  assert(left.to3d == V3(1, 0, 0));
  assert(right.to3d == V3(-1, 0, 0));

  assert(up.to3d(Swizzle.xz) == V3(0, 0, -1));
  assert(down.to3d(Swizzle.xz) == V3(0, 0, 1));
  assert(left.to3d(Swizzle.xz) == V3(1, 0, 0));
  assert(right.to3d(Swizzle.xz) == V3(-1, 0, 0));

  assert(up.to3d.to2d == up);
  assert(down.to3d.to2d == down);
  assert(left.to3d.to2d == left);
  assert(right.to3d.to2d == right);

  assert(up.to3d(Swizzle.xz).to2d(Swizzle.xz) == up);
  assert(down.to3d(Swizzle.xz).to2d(Swizzle.xz) == down);
  assert(left.to3d(Swizzle.xz).to2d(Swizzle.xz) == left);
  assert(right.to3d(Swizzle.xz).to2d(Swizzle.xz) == right);
}
