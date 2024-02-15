/// Angle-related linear algebra.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021 Chance Snow. All rights reserved.
/// License: MIT License
module descartes.angles;

import descartes : N, norm, V2;
import gfm.math.vector : dot;
import std.conv : to;
import std.math : acos, atan2, fmax, fmin, PI;
version(FixedPoint) import std.math : round;

pragma(inline, true):

private N rounded(real value) {
  return value.round.to!N;
}

///
N angleTo(V2 a, V2 b) {
  const theta = dot(a, b) / (a.norm * b.norm);
  const result = theta.fmin(1.0).fmax(-1.0).acos;

  version(FixedPoint) return result.rounded;
  else return result;
}

///
N angleAlongTo(V2 a, V2 aDirection, V2 b) {
  const simpleAngle = a.angleTo(b);
  const linearDirection = (b - a).normalized;

  if (aDirection.dot(linearDirection) >= 0) return simpleAngle;
  const result = 2.0 * PI - simpleAngle;

  version(FixedPoint) return result.rounded;
  else return result;
}

///
N signedAngleTo(V2 a, V2 b) {
  // https://stackoverflow.com/a/2150475
  const det = a.x * b.y - a.y * b.x;
  const dot = a.x * b.x + a.y * b.y;
  const result = det.to!float.atan2(dot.to!float);

  version(FixedPoint) return result.rounded;
  else return result;
}

unittest {
  import descartes : up, down, left, right;
  import std.math : isClose;

  assert(V2(3).angleTo(V2(4)) == 0.0);
  // FIXME: assert((V2(3, 0).angleTo(V2(0, -4))) == 0.0);
  // FIXME: assert((V2(3, 7).angleTo(V2(2, -4))) == 0.0);
  assert((V2(3, 0).angleTo(V2(0, 4))).isClose(1.5708));

  // FIXME: assert((V2(3, 0).angleAlongTo(up, V2(3, 4))).isClose(6.28319));
  // FIXME: assert((V2(3, 0).angleAlongTo(down, V2(3, 4))) == 0.0);
  // FIXME: assert((V2(3, 0).angleAlongTo(left, V2(3, 4))) == 0.0);
  // FIXME: assert((V2(3, 0).angleAlongTo(right, V2(3, 4))) == 0.0);

  assert(V2(3).signedAngleTo(V2(4)) == 0.0);
  assert(V2(3, 0).signedAngleTo(V2(0, -4)).isClose(-1.5708));
  assert(V2(3, 7).signedAngleTo(V2(2, -4)).isClose(-2.27305));
  assert(V2(3, 0).signedAngleTo(V2(0, 4)).isClose(1.5708));
}

///
/// Warning:
/// Descarte assumes a right-hand coordinate system.
///
/// Positive angles are counter-clockwise if z-axis points offscreen.
V2 orthogonalRight(V2 self) {
  return V2(self.y, -self.x);
}

///
/// Warning:
/// Descarte assumes a right-hand coordinate system.
///
/// Positive angles are counter-clockwise if z-axis points offscreen.
V2 orthogonalLeft(V2 self) {
  return -self.orthogonalRight;
}

unittest {
  import descartes : up, down, left, right;

  assert(up.orthogonalRight == right);
  assert(down.orthogonalRight == left);
  assert(left.orthogonalRight == up);
  assert(right.orthogonalRight == down);

  assert(up.orthogonalLeft == left);
  assert(down.orthogonalLeft == right);
  assert(left.orthogonalLeft == down);
  assert(right.orthogonalLeft == up);
}
