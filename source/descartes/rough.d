/// Fuzzy equality comparators.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021 Chance Snow. All rights reserved.
/// License: MIT License
module descartes.rough;

import descartes : N, norm, V2;
import std.math : abs;

/// Thickness radius
enum float thickness = 0.001;
///
version(FixedPoint) enum int roughTolerance = 0;
///
else enum double roughTolerance = 0.000_000_1;

// TODO: How do these compare to [std.math.isClose](https://dlang.org/library/std/math/is_close.html)?

///
bool roughlyEqualTo(N a, N b, N tolerance = roughTolerance) {
  return (a - b).abs <= tolerance;
}

///
bool roughlyEqualTo(V2 a, V2 b, N tolerance = roughTolerance) {
  return (a - b).norm <= tolerance;
}

unittest {
  import descartes : P2;

  assert( P2(10, 20).roughlyEqualTo(P2(10, 20 + roughTolerance)));
  assert(!P2(10, 21).roughlyEqualTo(P2(10, 20 + roughTolerance)));
  assert( V2(10, 20).roughlyEqualTo(V2(10, 20 + roughTolerance)));
  assert(!V2(10, 21).roughlyEqualTo(V2(10, 20 + roughTolerance)));
  assert( P2(10, 20).roughlyEqualTo(P2(10, 20 + (roughTolerance / 2))));
  assert(!P2(10, 21).roughlyEqualTo(P2(10, 20 + (roughTolerance / 2))));
  assert( V2(10, 20).roughlyEqualTo(V2(10, 20 + (roughTolerance / 2))));
  assert(!V2(10, 21).roughlyEqualTo(V2(10, 20 + (roughTolerance / 2))));
  assert( P2(10, 20).roughlyEqualTo(P2(10, 20 + (roughTolerance * 5))));
  assert(!P2(10, 21).roughlyEqualTo(P2(10, 20 + (roughTolerance * 5))));
  assert( V2(10, 20).roughlyEqualTo(V2(10, 20 + (roughTolerance * 5))));
  assert(!V2(10, 21).roughlyEqualTo(V2(10, 20 + (roughTolerance * 5))));

  version(FixedPoint) {}
  else {
    const lowerTolerance = 0.000_1;
    assert( P2(10, 20 + lowerTolerance).roughlyEqualTo(P2(10, 20.000_1), lowerTolerance));
    assert( V2(10, 20 + lowerTolerance).roughlyEqualTo(V2(10, 20.000_1), lowerTolerance));
    // FIXME: assert(!P2(10, 20.000_000_1).roughlyEqualTo(P2(10, 20.000_1), lowerTolerance));
    // FIXME: assert(!V2(10, 20.000_000_1).roughlyEqualTo(V2(10, 20.000_1), lowerTolerance));
  }
}
