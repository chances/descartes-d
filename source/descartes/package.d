/// Imprecision-tolerant computational geometry.
///
/// Authors: Chance Snow
/// Copyright: Copyright © 2021 Chance Snow. All rights reserved.
/// License: MIT License
module descartes;

// https://gfm.dpldocs.info/gfm.math.html
import gfm.math;

public:

import descartes.angles;
import descartes.bands;
import descartes.bbox;
import descartes.convert;
import descartes.embedding;
import descartes.grid;
import descartes.intersect;
import descartes.path;
import descartes.rough;

///
alias N = float;

/// A stack-allocated, 2-dimensional column vector.
alias V2 = vec2!N;
/// A statically sized 2-dimensional column point.
alias P2 = vec2!N;
/// A stack-allocated, 3-dimensional column vector.
alias V3 = vec3!N;
/// A stack-allocated, 4-dimensional column vector.
alias V4 = vec4!N;
/// A statically sized 3-dimensional column point.
alias P3 = vec3!N;
/// A stack-allocated, row-major 4x4 square matrix.
alias M4 = mat4!N;
// TODO: Add Isometry to gfm?
/// A 3-dimensional direct isometry using a unit quaternion for its rotational part.
/// Also known as a rigid-body motion, or as an element of SE(3).
// alias Iso3 = Isometry3!N;
// TODO: Ensure this is stored as a homogeneous 4x4 matrix.
/// A 3D affine transformation. Stored as a homogeneous, row-major 4x4 matrix.
alias Affine3 = mat4!N;
// TODO: Ensure this is stored as a homogeneous 4x4 matrix.
/// A 3D perspective projection stored as a homogeneous, row-major 4x4 matrix.
alias Perspective3 = mat4!N;
