/// Line and arc segment primitives.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021 Chance Snow. All rights reserved.
/// License: MIT License
module descartes.segments;

import descartes : P2, Rotation2, thickness, V2, N, norm;
import descartes.angles : signedAngleTo;
import std.math : abs, isNaN, PI;
import std.typecons : Nullable, nullable;
import std.variant : Algebraic, visit;

///
enum N minLineLength = 0.01;
///
enum N minArcLength = minLineLength;

version (unittest) {
  enum float tolerance = 0.0001;
}

///
interface Segment {
  ///
  @property N length();
  ///
  @property V2 startDirection();
  ///
  @property V2 endDirection();
  ///
  P2[] subdivisionsWithoutEnd(N maxAngle);
}

///
struct LineSegment {
  ///
  P2 start;
  ///
  P2 end;

  V2 direction() @property const {
    return (end - start).normalized;
  }

  /// See_Also: `Segment`
  N length() @property const {
    return (start - end).norm;
  }

  /// See_Also: `Segment`
  V2 startDirection() @property const {
    return this.direction;
  }

  /// See_Also: `Segment`
  V2 endDirection() @property const {
    return this.direction;
  }

  /// See_Also: `Segment`
  P2[] subdivisionsWithoutEnd(N _ = 0) @property const {
    return [this.start];
  }

  ///
  P2 along(N distance) const {
    return this.start + distance * this.direction;
  }

  P2 midpoint() @property const {
    return P2((this.start + this.end) / 2.0);
  }

  ///
  struct Projection {
    ///
    N along;
    ///
    P2 projectedPoint;
  }

  ///
  Nullable!Projection rojectWithdtoleranceerance(P2 point, N toleranceerance) {
    import gfm.math : dot;

    if ((point - this.start).norm < toleranceerance) {
      return Projection(0.0, this.start).nullable;
    } else if ((point - this.end).norm < toleranceerance) {
      return Projection(this.length(), this.end).nullable;
    } else {
      const direction = this.direction;
      const lineOffset = direction.dot(point - this.start);
      if (lineOffset >= 0.0 && lineOffset <= this.length()) {
        return Projection(lineOffset, this.start + lineOffset * direction).nullable;
      } else {
        return Nullable!Projection.init;
      }
    }
  }

  ///
  Nullable!Projection projectWithMaxDistance(P2 point, N toleranceerance, N maxDistance) {
    const maybeProjection = this.rojectWithdtoleranceerance(point, toleranceerance);
    if (!maybeProjection.isNull) {
      const projection = maybeProjection.get;
      if ((projection.projectedPoint - point).norm <= maxDistance) {
        return maybeProjection;
      } else {
        return Nullable!Projection.init;
      }
    }
    return Nullable!Projection.init;
  }

  ///
  N windingAngle(P2 point) {
    return signedAngleTo(this.start - point, this.end - point);
  }

  ///
  N sideOf(P2 point) {
    import std.math : sgn;

    // TODO: Compare with https://docs.rs/num/0.1.42/num/fn.signum.html
    return this.windingAngle(point).sgn;
  }

  ///
  bool isPointLeftOf(P2 point) {
    return this.windingAngle(point) > 0.0;
  }

  ///
  bool isPointRightOf(P2 point) {
    return this.windingAngle(point) < 0.0;
  }

  ///
  N signedDistanceOf(P2 point) {
    import descartes.angles : orthogonalLeft;
    import gfm.math : dot;

    const directionOrth = this.direction.orthogonalLeft;
    return (point - this.start).dot(directionOrth);
  }

  // TODO: Add boundingBox getter (https://github.com/chances/descartes/blob/master/src/segments.rs#L124)
}

///
struct ArcSegment {
  import descartes.angles : orthogonalRight;

  ///
  P2 start;
  ///
  P2 apex;
  ///
  P2 end;

  @disable this();
  private this(P2 start, P2 apex, P2 end) {
    this.start = start;
    this.apex = apex;
    this.end = end;
  }

  ///
  static Nullable!ArcSegment make(P2 start, P2 apex, P2 end) {
    import std.math : isInfinity;

    if ((start - apex).norm < minLineLength || (end - apex).norm < minLineLength
        || (start - end).norm < minArcLength)
      return Nullable!ArcSegment.init;
    auto segment = ArcSegment(start, apex, end);
    const center = segment.center;
    if (center.x.isNaN || center.y.isNaN || center.x.isInfinity || center.y.isInfinity)
      return Nullable!ArcSegment.init;
    return segment.nullable;
  }

  ///
  static Nullable!ArcSegment minorArcWithCenter(P2 start, P2 center, P2 end) {
    import descartes : signedAngleTo;

    const centerToStart = start - center;
    const centerToEnd = end - center;
    const radius = centerToStart.norm;

    const sum = centerToStart + centerToEnd;

    const apex = sum.norm > 0.01
      ? center + sum.normalized * radius
      : center + Rotation2(signedAngleTo(centerToStart, centerToEnd) / 2.0) * centerToStart;

    // TODO: avoid redundant calculation of center, but still check for validity somehow
    return ArcSegment.make(start, apex, end);
  }

  ///
  static Nullable!ArcSegment minorArcWithStartDirection(P2 start, V2 startDirection, P2 end) {
    import gfm.math : dot;

    const halfChord = (end - start) / 2.0;
    const halfChordNormSquared = halfChord.norm * halfChord.norm;
    const signedRadius = halfChordNormSquared / startDirection.orthogonalRight().dot(halfChord);

    const center = start + signedRadius * startDirection.orthogonalRight();

    return ArcSegment.minorArcWithCenter(start, center, end);
  }

  /// See_Also: `Segment`
  N length() @property const {
    const simpleAngleSpan = this.signedAngleSpan.abs;
    const angleSpan = this.isMinor ? simpleAngleSpan : 2.0 * PI - simpleAngleSpan;
    return this.radius * angleSpan;
  }

  /// See_Also: `Segment`
  V2 startDirection() @property const {
    const center = this.center();
    const centerToStartOrth = (this.start - center).orthogonalRight();

    return LineSegment(this.start, this.end).isPointLeftOf(this.apex)
      ? centerToStartOrth : -centerToStartOrth;
  }

  /// See_Also: `Segment`
  V2 endDirection() @property const {
    const center = this.center();
    const centerToEndOrth = (this.end - center).orthogonalRight();

    return LineSegment(this.start, this.end).isPointLeftOf(this.apex)
      ? centerToEndOrth : -centerToEndOrth;
  }

  /// See_Also: `Segment`
  P2[] subdivisionsWithoutEnd(N maxAngle) const {
    import descartes : Rotation2, thickness;
    import std.conv : to;
    import std.math : cos, floor, fmax, sin;

    const center = this.center();
    const signedAngleSpan = signedAngleTo(this.start - center, this.end - center);

    // TODO: Log error
    // if (signedAngleSpan.isNaN) println!("KAPUTT {:?} {:?}", self, center);

    const subdivisions = (signedAngleSpan.abs / maxAngle).floor;
    const subdivisionAngle = signedAngleSpan / subdivisions.to!float;

    auto pointer = this.start - center;

    auto maybePreviousPoint = Nullable!P2.init;

    import std.algorithm : filter, map;
    import std.array : array;
    import std.range : iota;

    return iota(0, subdivisions.fmax(1)).map!(_ => {
      auto point = center + pointer;
      pointer = Rotation2(subdivisionAngle.cos, -subdivisionAngle.sin,
        subdivisionAngle.sin, subdivisionAngle.cos) * pointer;

      if (!maybePreviousPoint.isNull) {
        const previousPoint = maybePreviousPoint.get;
        if ((point - previousPoint).norm > 2.0 * thickness) {
          maybePreviousPoint = point.nullable;
          return point.nullable;
        } else {
          return Nullable!P2.init;
        }
      } else {
        maybePreviousPoint = point.nullable;
        return point.nullable;
      }
    }())
      .filter!(x => !x.isNull)
      .map!(x => x.get)
      .array;
  }

  P2 center() @property const {
    import std.math : pow;

    // https://en.wikipedia.org/wiki/Circumscribed_circle#Circumcenter_coordinates
    const a_abs = this.start;
    const b_abs = this.apex;
    const c_abs = this.end;
    const b = b_abs - a_abs;
    const c = c_abs - a_abs;
    const d_inv = 1.0 / (2.0 * (b.x * c.y - b.y * c.x));
    const b_norm_sq = b.norm.pow(2);
    const c_norm_sq = c.norm.pow(2);
    const center_x = d_inv * (c.y * b_norm_sq - b.y * c_norm_sq);
    const center_y = d_inv * (b.x * c_norm_sq - c.x * b_norm_sq);
    return a_abs + V2(center_x, center_y);
  }

  N radius() @property const {
    return (this.start - this.center).norm;
  }

  N signedAngleSpan() @property const {
    const center = this.center;
    return signedAngleTo(this.start - center, this.end - center);
  }

  bool isMinor() @property const {
    return this.signedAngleSpan * LineSegment(this.start, this.end).sideOf(this.apex) < 0.0;
  }
}

unittest {
  import descartes : roughlyEqualTo;
  import std.math : isClose, sqrt;

  // Minor arc test
  auto o = V2(10.0, 5.0);
  const minorArc = ArcSegment.make(P2(0.0, 1.0) + o, P2(-3.0f.sqrt / 2.0, 0.5) + o, P2(-1.0, 0.0) + o);
  assert(!minorArc.isNull);
  assert(roughlyEqualTo(minorArc.get.center, P2(0.0, 0.0) + o, tolerance));
  assert(minorArc.get.isMinor);
  assert(isClose(minorArc.get.length, PI / 2.0, tolerance));

  const minorArcRev = ArcSegment.make(P2(-1.0, 0.0) + o, P2(-3.0f.sqrt / 2.0,
      0.5) + o, P2(0.0, 1.0) + o);
  assert(!minorArcRev.isNull);
  assert(roughlyEqualTo(minorArcRev.get.center, P2(0.0, 0.0) + o, tolerance));
  assert(minorArcRev.get.isMinor);
  assert(isClose(minorArcRev.get.length, PI / 2.0, tolerance));

  const minorArcByCenter = ArcSegment.minorArcWithCenter(P2(0.0, 1.0) + o,
      P2(0.0, 0.0) + o, P2(-1.0, 0.0) + o);
  assert(!minorArcByCenter.isNull);
  assert(roughlyEqualTo(minorArcByCenter.get.apex, P2(-2.0f.sqrt / 2.0, 2.0f.sqrt / 2.0) + o, tolerance));
  assert(isClose(minorArcByCenter.get.length, PI / 2.0, tolerance));

  const minorArcByCenterRev = ArcSegment.minorArcWithCenter(P2(-1.0, 0.0) + o,
      P2(0.0, 0.0) + o, P2(0.0, 1.0) + o);
  assert(!minorArcByCenterRev.isNull);
  assert(roughlyEqualTo(minorArcByCenterRev.get.apex, P2(-2.0f.sqrt / 2.0, 2.0f.sqrt / 2.0) + o, tolerance));
  assert(isClose(minorArcByCenterRev.get.length, PI / 2.0, tolerance));

  const minorArcByDirection = ArcSegment.minorArcWithStartDirection(P2(0.0,
      1.0) + o, V2(-1.0, 0.0), P2(-1.0, 0.0) + o);
  assert(!minorArcByDirection.isNull);
  assert(roughlyEqualTo(minorArcByDirection.get.apex, P2(-2.0f.sqrt / 2.0, 2.0f.sqrt / 2.0) + o, tolerance));
  assert(isClose(minorArcByDirection.get.length, PI / 2.0, tolerance));

  const minorArcByDirectionRev = ArcSegment.minorArcWithStartDirection(P2(-1.0,
      0.0) + o, V2(0.0, 1.0), P2(0.0, 1.0) + o);
  assert(!minorArcByDirectionRev.isNull);
  assert(roughlyEqualTo(minorArcByDirectionRev.get.apex, P2(-2.0f.sqrt / 2.0,
      2.0f.sqrt / 2.0) + o, tolerance));
  assert(isClose(minorArcByDirectionRev.get.length, PI / 2.0, tolerance));

  // Colinear apex
  assert(ArcSegment.make(P2(0.0, 0.0), P2(1.0, 0.0), P2(2.0, 0.0)).isNull);

  // Major arcs
  o = V2(10.0, 5.0);
  const majorArc = ArcSegment.make(
    P2(0.0, -1.0) + o,
    P2(-3.0f.sqrt / 2.0, 0.5) + o,
    P2(1.0, 0.0) + o,
  );
  assert(!majorArc.isNull);
  assert(roughlyEqualTo(majorArc.get.center, P2(0.0, 0.0) + o, tolerance));
  assert(!majorArc.get.isMinor);
  assert(isClose(majorArc.get.length, 3.0 * PI / 2.0, tolerance));

  const majorArcRev = ArcSegment.make(
    P2(-1.0, 0.0) + o,
    P2(-3.0f.sqrt / 2.0, 0.5) + o,
    P2(0.0, -1.0) + o,
  );
  // import std.stdio : writeln;
  assert(!majorArcRev.isNull);
  assert(roughlyEqualTo(majorArcRev.get.center, P2(0.0, 0.0) + o, tolerance));
  assert(!majorArcRev.get.isMinor);
  assert(isClose(majorArcRev.get.length, 3.0 * PI / 2.0, tolerance));
}

alias ArcOrLineSegment = Algebraic!(LineSegment, ArcSegment);

///
@property Nullable!LineSegment line(ArcOrLineSegment arcOrLine) {
  assert(arcOrLine.hasValue);
  if (LineSegment* line = arcOrLine.peek!LineSegment)
    return (*line).nullable;
  return Nullable!LineSegment.init;
}

///
@property Nullable!ArcSegment arc(ArcOrLineSegment arcOrLine) {
  assert(arcOrLine.hasValue);
  if (ArcSegment* arc = arcOrLine.peek!ArcSegment)
    return (*arc).nullable;
  return Nullable!ArcSegment.init;
}

////// See_Also: `Segment`
@property P2 start(ArcOrLineSegment arcOrLine) {
  return arcOrLine.visit!((LineSegment line) => line.start, (ArcSegment arc) => arc.start,);
}
////// See_Also: `Segment`
@property P2 end(ArcOrLineSegment arcOrLine) {
  return arcOrLine.visit!((LineSegment line) => line.end, (ArcSegment arc) => arc.end,);
}
////// See_Also: `Segment`
@property N length(ArcOrLineSegment arcOrLine) {
  return arcOrLine.visit!((LineSegment line) => line.length, (ArcSegment arc) => arc.length,);
}
////// See_Also: `Segment`
@property V2 startDirection(ArcOrLineSegment arcOrLine) {
  return arcOrLine.visit!((LineSegment line) => line.startDirection,
      (ArcSegment arc) => arc.startDirection,);
}
////// See_Also: `Segment`
@property V2 endDirection(ArcOrLineSegment arcOrLine) {
  return arcOrLine.visit!((LineSegment line) => line.endDirection,
      (ArcSegment arc) => arc.endDirection,);
}
////// See_Also: `Segment`
@property P2[] subdivisionsWithoutEnd(ArcOrLineSegment arcOrLine, N maxAngle) {
  return arcOrLine.visit!((LineSegment line) => line.subdivisionsWithoutEnd(maxAngle),
      (ArcSegment arc) => arc.subdivisionsWithoutEnd(maxAngle),);
}

///
ArcOrLineSegment lineUnchecked(P2 start, P2 end) {
  return ArcOrLineSegment(LineSegment(start, end));
}
///
ArcOrLineSegment arcUnchecked(P2 start, P2 apex, P2 end) {
  return ArcOrLineSegment(ArcSegment(start, apex, end));
}
