/// Fuzzy equality comparators.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021 Chance Snow. All rights reserved.
/// License: MIT License
module descartes.rough;

import descartes : N, norm, P2, V2;
import std.math : abs;

/// Thickness radius
enum float thickness = 0.001;
///
enum double roughTolerance = 0.000_000_1;

// TODO: How do these compare to [std.math.approxEqual](https://dlang.org/library/std/math/approx_equal.html)?

///
bool roughlyEqualTo(N a, N b, N tolerance) {
  return (a - b).abs <= tolerance;
}

///
bool roughlyEqualTo(V2 a, V2 b, N tolerance) {
  return (a - b).norm <= tolerance;
}
