/// Angle-related linear algebra.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021 Chance Snow. All rights reserved.
/// License: MIT License
module descartes.angles;

import descartes : N, norm, V2;
import gfm.math.vector : dot;
import std.math : acos, atan2, fmax, fmin, PI;

pragma(inline, true):

///
N angleTo(V2 a, V2 b) {
  const theta = dot(a, b) / (a.norm * b.norm);
  return theta.fmin(1.0).fmax(-1.0).acos;
}

///
N angleAlongTo(V2 a, V2 aDirection, V2 b) {
  const simpleAngle = a.angleTo(b);
  const linearDirection = (b - a).normalized;

  if (aDirection.dot(linearDirection) >= 0) return simpleAngle;
  return 2.0 * PI - simpleAngle;
}

///
N signedAngleTo(V2 a, V2 b) {
  // https://stackoverflow.com/a/2150475
  const det = a.x * b.y - a.y * b.x;
  const dot = a.x * b.x + a.y * b.y;
  return det.atan2(dot);
}

//
//  DESCARTES ASSUMES
//  A RIGHT HAND COORDINATE SYSTEM
//
//  positive angles are counter-clockwise if z axis points out of screen
//

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
