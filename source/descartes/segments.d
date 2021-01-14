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

///
enum N minLineLength = 0.01;
///
enum N minArcLength = minLineLength;

interface Segment {
  @property N length();
  @property V2 startDirection();
  @property V2 endDirection();
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
  Nullable!Projection projectWithTolerance(P2 point, N tolerance) {
    import gfm.math : dot;

    if ((point - this.start).norm < tolerance) {
        return Projection(0.0, this.start).nullable;
    } else if ((point - this.end).norm < tolerance) {
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

  Nullable!Projection projectWithMaxDistance(P2 point, N tolerance, N maxDistance) {
    const maybeProjection = this.projectWithTolerance(point, tolerance);
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

  ///
  static Nullable!ArcSegment make(P2 start, P2 apex, P2 end) {
    import std.math : isInfinity;

    if ((start - apex).norm < minLineLength
        || (end - apex).norm < minLineLength
        || (start - end).norm < minArcLength) return Nullable!ArcSegment.init;
    auto segment = ArcSegment(start, apex, end);
    const center = segment.center;
    if (center.x.isNaN || center.y.isNaN || center.x.isInfinity || center.y.isInfinity)
      return Nullable!ArcSegment.init;
    return segment.nullable;
  }

  /// See_Also: `Segment`
  N length() @property const {
    const simpleAngleSpan = this.signedAngleSpan.abs;
    const angleSpan = this.isMinor
      ? simpleAngleSpan
      : 2.0 * PI - simpleAngleSpan;
    return this.radius * angleSpan;
  }

  /// See_Also: `Segment`
  V2 startDirection() @property const {
    const center = this.center();
    const centerToStartOrth = (this.start - center).orthogonalRight();

    return LineSegment(this.start, this.end).isPointLeftOf(this.apex)
      ?  centerToStartOrth
      : -centerToStartOrth;
  }

  /// See_Also: `Segment`
  V2 endDirection() @property const {
    const center = this.center();
    const centerToEndOrth = (this.end - center).orthogonalRight();

    return LineSegment(this.start, this.end).isPointLeftOf(this.apex)
      ?  centerToEndOrth
      : -centerToEndOrth;
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
      pointer =
        Rotation2(subdivisionAngle.cos, -subdivisionAngle.sin, subdivisionAngle.sin, subdivisionAngle.cos) * pointer;

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
    }()).filter!(x => !x.isNull).map!(x => x.get).array;
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

// TODO: Unit tests: https://github.com/aeplay/descartes/blob/0f31b1830f15a402089832c7a87d74aba3912005/src/segments.rs#L364
