const std = @import("std");
const zlm = @import("zlm").as(f32);

// Export zlm types for convenience
pub const Vec3 = zlm.Vec3;
pub const Mat4 = zlm.Mat4;

/// Default tolerance for floating-point comparisons
pub const DEFAULT_TOLERANCE: f32 = 1e-6;

/// Compare two Vec3 vectors with tolerance
pub fn expectVec3Equal(actual: Vec3, expected: Vec3, tolerance: f32) !void {
    try std.testing.expectApproxEqAbs(actual.x, expected.x, tolerance);
    try std.testing.expectApproxEqAbs(actual.y, expected.y, tolerance);
    try std.testing.expectApproxEqAbs(actual.z, expected.z, tolerance);
}

/// Compare two Vec3 vectors with default tolerance
pub fn expectVec3EqualDefault(actual: Vec3, expected: Vec3) !void {
    try expectVec3Equal(actual, expected, DEFAULT_TOLERANCE);
}
    
/// Check if two Vec3 vectors are close within tolerance
pub fn expectVec3Close(actual: Vec3, expected: Vec3, tolerance: f32) !void {
    const diff = actual.sub(expected);
    const distance = diff.length();
    try std.testing.expect(distance <= tolerance);
}

/// Check if two Vec3 vectors are close with default tolerance
pub fn expectVec3CloseDefault(actual: Vec3, expected: Vec3) !void {
    try expectVec3Close(actual, expected, DEFAULT_TOLERANCE);
}
    
/// Test if two vectors are orthogonal (dot product ≈ 0)
pub fn expectVec3Orthogonal(v1: Vec3, v2: Vec3, tolerance: f32) !void {
        const dot_product = v1.dot(v2);
        try std.testing.expectApproxEqAbs(@as(f32, 0.0), dot_product, tolerance);
    }
    
/// Test if two vectors are orthogonal with default tolerance
pub fn expectVec3OrthogonalDefault(v1: Vec3, v2: Vec3) !void {
        try expectVec3Orthogonal(v1, v2, DEFAULT_TOLERANCE);
    }
    
/// Test vector length
pub fn expectLength(vector: Vec3, expected_length: f32, tolerance: f32) !void {
        const actual_length = vector.length();
        try std.testing.expectApproxEqAbs(expected_length, actual_length, tolerance);
    }
    
/// Test vector length with default tolerance
pub fn expectLengthDefault(vector: Vec3, expected_length: f32) !void {
        try expectLength(vector, expected_length, DEFAULT_TOLERANCE);
    }
    
/// Test dot product
pub fn expectDotProduct(v1: Vec3, v2: Vec3, expected: f32, tolerance: f32) !void {
        const actual = v1.dot(v2);
        try std.testing.expectApproxEqAbs(expected, actual, tolerance);
    }
    
/// Test dot product with default tolerance
pub fn expectDotProductDefault(v1: Vec3, v2: Vec3, expected: f32) !void {
        try expectDotProduct(v1, v2, expected, DEFAULT_TOLERANCE);
    }
    
/// Test cross product
pub fn expectCrossProduct(v1: Vec3, v2: Vec3, expected: Vec3, tolerance: f32) !void {
        const actual = v1.cross(v2);
        try expectVec3Equal(actual, expected, tolerance);
    }
    
/// Test cross product with default tolerance
pub fn expectCrossProductDefault(v1: Vec3, v2: Vec3, expected: Vec3) !void {
        try expectCrossProduct(v1, v2, expected, DEFAULT_TOLERANCE);
    }
    
/// Compare two Mat4 matrices with tolerance
pub fn expectMat4Equal(actual: Mat4, expected: Mat4, tolerance: f32) !void {
        for (0..4) |row| {
            for (0..4) |col| {
                try std.testing.expectApproxEqAbs(actual.fields[row][col], expected.fields[row][col], tolerance);
            }
        }
    }
    
/// Compare two Mat4 matrices with default tolerance
pub fn expectMat4EqualDefault(actual: Mat4, expected: Mat4) !void {
        try expectMat4Equal(actual, expected, DEFAULT_TOLERANCE);
    }
    
/// Check if two Mat4 matrices are close within tolerance
pub fn expectMat4Close(actual: Mat4, expected: Mat4, tolerance: f32) !void {
        var max_diff: f32 = 0.0;
        for (0..4) |row| {
            for (0..4) |col| {
                const diff = @abs(actual.fields[row][col] - expected.fields[row][col]);
                max_diff = @max(max_diff, diff);
            }
        }
        try std.testing.expect(max_diff <= tolerance);
    }
    
/// Check if two Mat4 matrices are close with default tolerance
pub fn expectMat4CloseDefault(actual: Mat4, expected: Mat4) !void {
        try expectMat4Close(actual, expected, DEFAULT_TOLERANCE);
    }
    
/// Test if matrix is identity
pub fn expectMat4Identity(matrix: Mat4, tolerance: f32) !void {
        const identity = Mat4.identity;
        try expectMat4Equal(matrix, identity, tolerance);
    }
    
/// Test if matrix is identity with default tolerance
pub fn expectMat4IdentityDefault(matrix: Mat4) !void {
        try expectMat4Identity(matrix, DEFAULT_TOLERANCE);
    }
    
/// Test matrix-vector multiplication
pub fn expectMat4MulVec3(matrix: Mat4, vector: Vec3, expected: Vec3, tolerance: f32) !void {
        const actual = vector.transformPosition(matrix);
        try expectVec3Equal(actual, expected, tolerance);
    }
    
/// Test matrix-vector multiplication with default tolerance
pub fn expectMat4MulVec3Default(matrix: Mat4, vector: Vec3, expected: Vec3) !void {
        try expectMat4MulVec3(matrix, vector, expected, DEFAULT_TOLERANCE);
    }
    
/// Test matrix multiplication
pub fn expectMat4Mul(m1: Mat4, m2: Mat4, expected: Mat4, tolerance: f32) !void {
        const actual = m1.mul(m2);
        try expectMat4Equal(actual, expected, tolerance);
    }
    
/// Test matrix multiplication with default tolerance
pub fn expectMat4MulDefault(m1: Mat4, m2: Mat4, expected: Mat4) !void {
        try expectMat4Mul(m1, m2, expected, DEFAULT_TOLERANCE);
    }
    
/// Test color equality (RGB vectors)
pub fn expectColorEqual(actual: Vec3, expected: Vec3, tolerance: f32) !void {
        try expectVec3Equal(actual, expected, tolerance);
    }
    
/// Test color equality with default tolerance
pub fn expectColorEqualDefault(actual: Vec3, expected: Vec3) !void {
        try expectColorEqual(actual, expected, DEFAULT_TOLERANCE);
    }
    
/// Test color orthogonality
pub fn expectColorOrthogonal(c1: Vec3, c2: Vec3, tolerance: f32) !void {
        try expectVec3Orthogonal(c1, c2, tolerance);
    }
    
/// Test color orthogonality with default tolerance
pub fn expectColorOrthogonalDefault(c1: Vec3, c2: Vec3) !void {
        try expectColorOrthogonal(c1, c2, DEFAULT_TOLERANCE);
    }
    
/// Test that a vector is normalized (length ≈ 1)
pub fn expectNormalized(vector: Vec3, tolerance: f32) !void {
        try expectLength(vector, 1.0, tolerance);
    }
    
/// Test that a vector is normalized with default tolerance
pub fn expectNormalizedDefault(vector: Vec3) !void {
        try expectNormalized(vector, DEFAULT_TOLERANCE);
    }
    
/// Test right-handed coordinate system (X × Y = Z, Y × Z = X, Z × X = Y)
pub fn expectRightHandedSystem(x_axis: Vec3, y_axis: Vec3, z_axis: Vec3, tolerance: f32) !void {
        try expectCrossProduct(x_axis, y_axis, z_axis, tolerance);
        try expectCrossProduct(y_axis, z_axis, x_axis, tolerance);
        try expectCrossProduct(z_axis, x_axis, y_axis, tolerance);
    }
    
/// Test right-handed coordinate system with default tolerance
pub fn expectRightHandedSystemDefault(x_axis: Vec3, y_axis: Vec3, z_axis: Vec3) !void {
        try expectRightHandedSystem(x_axis, y_axis, z_axis, DEFAULT_TOLERANCE);
    }
    
/// Test that all vectors in a set are orthogonal
pub fn expectAllOrthogonal(vectors: []const Vec3, tolerance: f32) !void {
        for (vectors, 0..) |v1, i| {
            for (vectors[i+1..]) |v2| {
                try expectVec3Orthogonal(v1, v2, tolerance);
            }
        }
    }
    
/// Test that all vectors in a set are orthogonal with default tolerance
pub fn expectAllOrthogonalDefault(vectors: []const Vec3) !void {
        try expectAllOrthogonal(vectors, DEFAULT_TOLERANCE);
    }
    
/// Test bounding box properties
pub fn expectBoundingBox(min_bounds: Vec3, max_bounds: Vec3, center: Vec3, size: Vec3, tolerance: f32) !void {
        const calculated_center = min_bounds.add(max_bounds).scale(0.5);
        const calculated_size = max_bounds.sub(min_bounds);
        
        try expectVec3Equal(calculated_center, center, tolerance);
        try expectVec3Equal(calculated_size, size, tolerance);
    }
    
/// Test bounding box properties with default tolerance
pub fn expectBoundingBoxDefault(min_bounds: Vec3, max_bounds: Vec3, center: Vec3, size: Vec3) !void {
        try expectBoundingBox(min_bounds, max_bounds, center, size, DEFAULT_TOLERANCE);
    }
    
/// Test vertex data structure with stride/slice mechanism
pub fn expectVertexData(vertices: []const f32, stride: usize, expected_vertices: []const Vec3, expected_colors: []const Vec3, tolerance: f32) !void {
        const vertex_count = vertices.len / stride;
        try std.testing.expectEqual(expected_vertices.len, vertex_count);
        try std.testing.expectEqual(expected_colors.len, vertex_count);
        
        for (0..vertex_count) |i| {
            const vertex_start = i * stride;
            const position = Vec3.new(
                vertices[vertex_start + 0],
                vertices[vertex_start + 1], 
                vertices[vertex_start + 2]
            );
            const color = Vec3.new(
                vertices[vertex_start + 3],
                vertices[vertex_start + 4],
                vertices[vertex_start + 5]
            );
            
            try expectVec3Equal(position, expected_vertices[i], tolerance);
            try expectColorEqual(color, expected_colors[i], tolerance);
        }
    }
    
/// Test vertex data structure with default tolerance
pub fn expectVertexDataDefault(vertices: []const f32, stride: usize, expected_vertices: []const Vec3, expected_colors: []const Vec3) !void {
        try expectVertexData(vertices, stride, expected_vertices, expected_colors, DEFAULT_TOLERANCE);
    }
    
/// Test vertex data for axes (3 lines: X, Y, Z axes)
pub fn expectAxesVertexData(vertices: []const f32, axes_length: f32, tolerance: f32) !void {
        const stride = 6; // [x, y, z, r, g, b]
        const expected_vertices = [_]Vec3{
            // X-axis line
            Vec3.new(0.0, 0.0, 0.0),           // Origin
            Vec3.new(axes_length, 0.0, 0.0),  // +X
            
            // Y-axis line  
            Vec3.new(0.0, 0.0, 0.0),           // Origin
            Vec3.new(0.0, axes_length, 0.0),  // +Y
            
            // Z-axis line
            Vec3.new(0.0, 0.0, 0.0),           // Origin
            Vec3.new(0.0, 0.0, axes_length),  // +Z
        };
        const expected_colors = [_]Vec3{
            // X-axis colors (red)
            Vec3.new(1.0, 0.0, 0.0),  // Red
            Vec3.new(1.0, 0.0, 0.0),  // Red
            
            // Y-axis colors (green)
            Vec3.new(0.0, 1.0, 0.0),  // Green
            Vec3.new(0.0, 1.0, 0.0),  // Green
            
            // Z-axis colors (blue)
            Vec3.new(0.0, 0.0, 1.0),  // Blue
            Vec3.new(0.0, 0.0, 1.0),  // Blue
        };
        
        try expectVertexData(vertices, stride, &expected_vertices, &expected_colors, tolerance);
    }
    
/// Test vertex data for axes with default tolerance
pub fn expectAxesVertexDataDefault(vertices: []const f32, axes_length: f32) !void {
        try expectAxesVertexData(vertices, axes_length, DEFAULT_TOLERANCE);
    }
    
/// Test vertex attribute layout
pub fn expectVertexLayout(vertex_size: usize, position_offset: usize, color_offset: usize, stride: usize) !void {
        try std.testing.expectEqual(@as(usize, 0), position_offset);
        try std.testing.expectEqual(@as(usize, 12), color_offset); // 3 * 4 bytes
        try std.testing.expectEqual(@as(usize, 24), stride); // 6 * 4 bytes
        try std.testing.expectEqual(vertex_size, stride);
    }
    
/// Test that vertex data represents lines (pairs of vertices)
pub fn expectLineGeometry(vertices: []const f32, stride: usize, line_count: usize, tolerance: f32) !void {
        const vertex_count = vertices.len / stride;
        try std.testing.expectEqual(line_count * 2, vertex_count);
        
        // Test that each line starts at origin
        for (0..line_count) |line_idx| {
            const vertex_start = line_idx * 2 * stride;
            const origin = Vec3.new(
                vertices[vertex_start + 0],
                vertices[vertex_start + 1],
                vertices[vertex_start + 2]
            );
            const expected_origin = Vec3.new(0.0, 0.0, 0.0);
            try expectVec3Equal(origin, expected_origin, tolerance);
        }
}

/// Test line geometry with default tolerance
pub fn expectLineGeometryDefault(vertices: []const f32, stride: usize, line_count: usize) !void {
    try expectLineGeometry(vertices, stride, line_count, DEFAULT_TOLERANCE);
}

// ============================================================================
// IN-MODULE TESTS - Testing the testers using mathematical properties
// ============================================================================

test "vector equality with known values" {
    const v1 = Vec3.new(1.0, 2.0, 3.0);
    const v2 = Vec3.new(1.0, 2.0, 3.0);
    const v3 = Vec3.new(1.0001, 2.0001, 3.0001);
    
    // Test exact equality with small tolerance (floating point precision)
    try expectVec3Equal(v1, v2, 1e-6);
    try expectVec3EqualDefault(v1, v2);
    
    // Test approximate equality within tolerance
    try expectVec3Equal(v1, v3, 0.001);
    try expectVec3Close(v1, v3, 0.001);
}

test "vector mathematical properties" {
    const v1 = Vec3.new(3.0, 4.0, 0.0);
    const v2 = Vec3.new(0.0, 0.0, 1.0);
    
    // Test length calculation (3-4-5 triangle)
    try expectLength(v1, 5.0, 0.001);
    try expectLengthDefault(v2, 1.0);
    
    // Test dot product (orthogonal vectors = 0)
    try expectDotProduct(v1, v2, 0.0, 0.001);
    
    // Test cross product (right-hand rule)
    const x_axis = Vec3.new(1.0, 0.0, 0.0);
    const y_axis = Vec3.new(0.0, 1.0, 0.0);
    const z_axis = Vec3.new(0.0, 0.0, 1.0);
    try expectCrossProduct(x_axis, y_axis, z_axis, 0.001);
}

test "orthogonal vector properties" {
    const x_axis = Vec3.new(1.0, 0.0, 0.0);
    const y_axis = Vec3.new(0.0, 1.0, 0.0);
    const z_axis = Vec3.new(0.0, 0.0, 1.0);
    
    // Test orthogonality
    try expectVec3Orthogonal(x_axis, y_axis, 0.001);
    try expectVec3OrthogonalDefault(y_axis, z_axis);
    
    // Test right-handed coordinate system
    try expectRightHandedSystem(x_axis, y_axis, z_axis, 0.001);
    try expectRightHandedSystemDefault(x_axis, y_axis, z_axis);
    
    // Test all orthogonal
    const axes = [_]Vec3{ x_axis, y_axis, z_axis };
    try expectAllOrthogonal(&axes, 0.001);
}

test "matrix identity properties" {
    const identity = Mat4.identity;
    const test_vec = Vec3.new(1.0, 2.0, 3.0);
    
    // Test identity matrix properties
    try expectMat4Identity(identity, 0.001);
    try expectMat4IdentityDefault(identity);
    
    // Test identity doesn't change vectors
    const transformed = test_vec.transformPosition(identity);
    try expectVec3Equal(transformed, test_vec, 0.001);
    
    // Test identity multiplication
    const result = identity.mul(identity);
    try expectMat4Equal(result, identity, 0.001);
}

test "matrix transformations" {
    // Create a simple translation matrix
    const translation = Mat4.createTranslation(Vec3.new(1.0, 2.0, 3.0));
    const test_point = Vec3.new(0.0, 0.0, 0.0);
    const expected = Vec3.new(1.0, 2.0, 3.0);
    
    // Test matrix-vector multiplication
    const result = test_point.transformPosition(translation);
    try expectMat4MulVec3(translation, test_point, expected, 0.001);
    try expectVec3Equal(result, expected, 0.001);
}

test "color space properties" {
    const red = Vec3.new(1.0, 0.0, 0.0);
    const green = Vec3.new(0.0, 1.0, 0.0);
    const blue = Vec3.new(0.0, 0.0, 1.0);
    
    // Test color normalization
    try expectNormalized(red, 0.001);
    try expectNormalizedDefault(green);
    
    // Test color orthogonality in RGB space
    try expectColorOrthogonal(red, green, 0.001);
    try expectColorOrthogonalDefault(green, blue);
    
    // Test color equality
    const red_copy = Vec3.new(1.0, 0.0, 0.0);
    try expectColorEqual(red, red_copy, 0.001);
    try expectColorEqualDefault(red, red_copy);
}

test "bounding box mathematics" {
    const min_bounds = Vec3.new(-1.0, -2.0, -3.0);
    const max_bounds = Vec3.new(1.0, 2.0, 3.0);
    const expected_center = Vec3.new(0.0, 0.0, 0.0);
    const expected_size = Vec3.new(2.0, 4.0, 6.0);
    
    // Test bounding box calculations
    try expectBoundingBox(min_bounds, max_bounds, expected_center, expected_size, 0.001);
    try expectBoundingBoxDefault(min_bounds, max_bounds, expected_center, expected_size);
}

test "vertex data structure" {
    // Test vertex data with known values
    const vertices = [_]f32{
        0.0, 0.0, 0.0,  1.0, 0.0, 0.0,  // Origin, red
        1.0, 0.0, 0.0,  0.0, 1.0, 0.0,  // +X, green
    };
    const expected_positions = [_]Vec3{
        Vec3.new(0.0, 0.0, 0.0),
        Vec3.new(1.0, 0.0, 0.0),
    };
    const expected_colors = [_]Vec3{
        Vec3.new(1.0, 0.0, 0.0),
        Vec3.new(0.0, 1.0, 0.0),
    };
    
    // Test vertex data parsing
    try expectVertexData(&vertices, 6, &expected_positions, &expected_colors, 0.001);
    try expectVertexDataDefault(&vertices, 6, &expected_positions, &expected_colors);
}

test "axes vertex data" {
    const axes_length: f32 = 2.0;
    const vertices = [_]f32{
        // X-axis (red)
        0.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        2.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        // Y-axis (green)
        0.0, 0.0, 0.0,  0.0, 1.0, 0.0,
        0.0, 2.0, 0.0,  0.0, 1.0, 0.0,
        // Z-axis (blue)
        0.0, 0.0, 0.0,  0.0, 0.0, 1.0,
        0.0, 0.0, 2.0,  0.0, 0.0, 1.0,
    };
    
    // Test axes vertex data
    try expectAxesVertexData(&vertices, axes_length, 0.001);
    try expectAxesVertexDataDefault(&vertices, axes_length);
}

test "vertex layout mathematics" {
    const vertex_size = 6 * @sizeOf(f32);
    const position_offset = 0;
    const color_offset = 3 * @sizeOf(f32);
    const stride = 6 * @sizeOf(f32);
    
    // Test vertex layout
    try expectVertexLayout(vertex_size, position_offset, color_offset, stride);
}

test "line geometry properties" {
    const vertices = [_]f32{
        // Line 1: origin to +X
        0.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        1.0, 0.0, 0.0,  1.0, 0.0, 0.0,
        // Line 2: origin to +Y
        0.0, 0.0, 0.0,  0.0, 1.0, 0.0,
        0.0, 1.0, 0.0,  0.0, 1.0, 0.0,
    };
    
    // Test line geometry
    try expectLineGeometry(&vertices, 6, 2, 0.001);
    try expectLineGeometryDefault(&vertices, 6, 2);
}

test "tolerance edge cases" {
    const v1 = Vec3.new(1.0, 0.0, 0.0);
    const v2 = Vec3.new(1.0, 0.0, 0.0);
    
    // Test with very small tolerance (should pass)
    try expectVec3Equal(v1, v2, 0.0);
    
    // Test with large tolerance (should pass)
    const v3 = Vec3.new(1.1, 0.1, 0.1);
    try expectVec3Close(v1, v3, 0.2);
}

test "mathematical consistency" {
    // Test that our utilities are mathematically consistent
    const a = Vec3.new(1.0, 2.0, 3.0);
    const b = Vec3.new(4.0, 5.0, 6.0);
    
    // Test dot product consistency
    const dot_ab = a.dot(b);
    const dot_ba = b.dot(a);
    try std.testing.expectApproxEqAbs(dot_ab, dot_ba, 0.001);
    
    // Test cross product anti-commutativity
    const cross_ab = a.cross(b);
    const cross_ba = b.cross(a);
    const neg_cross_ba = cross_ba.scale(-1.0);
    try expectVec3Equal(cross_ab, neg_cross_ba, 0.001);
}

test "matrix multiplication properties" {
    const m1 = Mat4.identity;
    const m2 = Mat4.identity;
    
    // Test identity multiplication
    const result = m1.mul(m2);
    try expectMat4Mul(m1, m2, Mat4.identity, 0.001);
    try expectMat4MulDefault(m1, m2, Mat4.identity);
    
    // Test matrix equality
    try expectMat4Equal(result, Mat4.identity, 0.001);
    try expectMat4EqualDefault(result, Mat4.identity);
}

test "vector normalization edge cases" {
    const unit_x = Vec3.new(1.0, 0.0, 0.0);
    const unit_y = Vec3.new(0.0, 1.0, 0.0);
    
    // Test normalized vectors
    try expectNormalized(unit_x, 0.001);
    try expectNormalizedDefault(unit_y);
    
    // Test non-normalized vector
    const non_unit = Vec3.new(2.0, 0.0, 0.0);
    try expectLength(non_unit, 2.0, 0.001);
}

test "coordinate system validation" {
    // Test standard coordinate system
    const x = Vec3.new(1.0, 0.0, 0.0);
    const y = Vec3.new(0.0, 1.0, 0.0);
    const z = Vec3.new(0.0, 0.0, 1.0);
    
    // Test right-handed system
    try expectRightHandedSystem(x, y, z, 0.001);
    try expectRightHandedSystemDefault(x, y, z);
    
    // Test all vectors are orthogonal
    const axes = [_]Vec3{ x, y, z };
    try expectAllOrthogonal(&axes, 0.001);
    try expectAllOrthogonalDefault(&axes);
}



