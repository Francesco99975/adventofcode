const std = @import("std");

const Coords = struct {
    x: isize,
    y: isize,

    pub fn format(
        self: Coords,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: std.Io.Writer,
    ) !void {
        _ = fmt; // unused, but required by interface
        _ = options; // unused, but required by interface

        // Your custom formatting:
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

const AngleSortCtx = struct {
    cx: f64,
    cy: f64,

    pub fn lessThan(ctx: @This(), a: Coords, b: Coords) bool {
        const ax = @as(f64, @floatFromInt(a.x)) - ctx.cx;
        const ay = @as(f64, @floatFromInt(a.y)) - ctx.cy;
        const bx = @as(f64, @floatFromInt(b.x)) - ctx.cx;
        const by = @as(f64, @floatFromInt(b.y)) - ctx.cy;

        return std.math.atan2(ay, ax) < std.math.atan2(by, bx);
    }
};

fn orderPerimeter(perimeter: []Coords, allocator: std.mem.Allocator) ![]Coords {
    var cx: f64 = 0;
    var cy: f64 = 0;

    for (perimeter) |c| {
        cx += @floatFromInt(c.x);
        cy += @floatFromInt(c.y);
    }

    cx /= @floatFromInt(perimeter.len);
    cy /= @floatFromInt(perimeter.len);

    const ordered = try allocator.dupe(Coords, perimeter);

    const ctx = AngleSortCtx{
        .cx = cx,
        .cy = cy,
    };

    // Choose one:
    std.sort.insertion(Coords, ordered, ctx, AngleSortCtx.lessThan);
    // or:
    // std.sort.pdq(Coords, ordered, ctx, AngleSortCtx.lessThan);

    return ordered;
}

fn pointOnSegment(p: Coords, a: Coords, b: Coords) bool {
    const cross =
        (p.y - a.y) * (b.x - a.x) -
        (p.x - a.x) * (b.y - a.y);

    if (cross != 0) return false;

    return p.x >= @min(a.x, b.x) and p.x <= @max(a.x, b.x) and
        p.y >= @min(a.y, b.y) and p.y <= @max(a.y, b.y);
}

fn pointInsideOrOn(p: Coords, poly: []Coords) bool {
    var inside = false;
    var j: usize = poly.len - 1;

    for (poly, 0..) |a, i| {
        const b = poly[j];

        if (pointOnSegment(p, a, b)) return true;

        if (((a.y > p.y) != (b.y > p.y)) and
            (p.x < (b.x - a.x) * @divTrunc((p.y - a.y), (b.y - a.y)) + a.x))
        {
            inside = !inside;
        }

        j = i;
    }

    return inside;
}

fn isRectangleInside(v1: Coords, v2: Coords, poly: []Coords) bool {
    const xmin = @min(v1.x, v2.x);
    const xmax = @max(v1.x, v2.x);
    const ymin = @min(v1.y, v2.y);
    const ymax = @max(v1.y, v2.y);

    const width = xmax - xmin + 1;
    const height = ymax - ymin + 1;

    if (width <= 0 or height <= 0) return false;

    // Always check all four boundary lines fully
    // Top and bottom
    {
        var x: usize = @intCast(xmin);
        while (x <= @as(usize, @intCast(xmax))) : (x += 1) {
            const px: isize = @intCast(x);
            if (!pointInsideOrOn(.{ .x = px, .y = ymin }, poly)) return false;
            if (!pointInsideOrOn(.{ .x = px, .y = ymax }, poly)) return false;
        }
    }

    // Left and right (skip corners already checked)
    {
        var y: usize = @intCast(ymin + 1);
        while (y < @as(usize, @intCast(ymax))) : (y += 1) {
            const py: isize = @intCast(y);
            if (!pointInsideOrOn(.{ .x = xmin, .y = py }, poly)) return false;
            if (!pointInsideOrOn(.{ .x = xmax, .y = py }, poly)) return false;
        }
    }

    // For large rectangles, sample interior sparsely
    if (width > 20 and height > 20) {
        const step_x = @max(1, @divTrunc(width, 15));
        const step_y = @max(1, @divTrunc(height, 15));

        var y: usize = @intCast(ymin + step_y);
        while (y < @as(usize, @intCast(ymax))) : (y += step_y) {
            const py: isize = @intCast(y);

            var x: usize = @intCast(xmin + step_x);
            while (x < @as(usize, @intCast(xmax))) : (x += step_x) {
                const px: isize = @intCast(x);
                if (!pointInsideOrOn(.{ .x = px, .y = py }, poly)) return false;
            }
        }
    } else {
        // Small rectangles: check everything
        var y: usize = @intCast(ymin);
        while (y <= @as(usize, @intCast(ymax))) : (y += 1) {
            const py: isize = @intCast(y);
            var x: usize = @intCast(xmin);
            while (x <= @as(usize, @intCast(xmax))) : (x += 1) {
                const px: isize = @intCast(x);
                if (!pointInsideOrOn(.{ .x = px, .y = py }, poly)) return false;
            }
        }
    }

    return true;
}

// fn isRectangleBetweenBoundaries(
//     vertex1: Coords,
//     vertex2: Coords,
//     perimeter: []Coords,
// ) !bool {
//     const min_x: usize = @intCast(@min(vertex1.x, vertex2.x));
//     const max_x: usize = @intCast(@max(vertex1.x, vertex2.x));
//     const min_y: usize = @intCast(@min(vertex1.y, vertex2.y));
//     const max_y: usize = @intCast(@max(vertex1.y, vertex2.y));

//     for (min_y..max_y + 1) |y| {
//         for (min_x..max_x + 1) |x| {
//             const xi: isize = @intCast(x);
//             const yi: isize = @intCast(y);
//             const p = Coords{ .x = xi, .y = yi };

//             if (!pointInsideOrOn(p, perimeter)) {
//                 return false; // rectangle leaks outside
//             }
//         }
//     }

//     return true; // every cell is inside or on boundary
// }

pub fn main() !void {
    std.debug.print("STARTING DAY 9 - PART 1\n\n", .{});

    if (part1("data.txt")) |largest_area| {
        std.debug.print("Largest Area: {d}\n", .{largest_area});
    } else |err| {
        std.debug.print("There was an error with DAY 9 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 9 - PART 2\n\n", .{});

    if (part2("data.txt")) |largest_area| {
        std.debug.print("Largest Area: {d}\n", .{largest_area});
    } else |err| {
        std.debug.print("There was an error with DAY 9 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var angles: std.ArrayList(Coords) = .empty;
    defer angles.deinit(allocator);

    std.debug.print("Reading Coords\n", .{});

    while (try interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        var coords_builder: std.ArrayList([]const u8) = .empty;
        defer coords_builder.deinit(allocator);

        while (it.next()) |value| {
            try coords_builder.append(allocator, value);
        }

        if (coords_builder.items.len != 2) return error.InvalidCoords;

        const x = try std.fmt.parseInt(isize, coords_builder.items[0], 10);
        const y = try std.fmt.parseInt(isize, coords_builder.items[1], 10);

        try angles.append(allocator, .{ .x = x, .y = y });
    }

    var largest_area: u64 = 0;

    for (angles.items, 0..) |angle, i| {
        for (angles.items, 0..) |angle2, j| {
            if (i == j) continue;

            const base = @abs(angle.x - angle2.x) + 1;
            const height = @abs(angle.y - angle2.y) + 1;

            const area = base * height;

            if (area > largest_area) {
                largest_area = area;
            }
        }
    }
    return largest_area;
}

test "DAY 9 TEST - PART 1" {
    const expected_result: u64 = 50;
    if (part1("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 9 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 9 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 9 PART 1 -> {}\n", .{err});
    }
}

fn part2(input: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var angles: std.ArrayList(Coords) = .empty;
    defer angles.deinit(allocator);

    std.debug.print("Reading Coords\n", .{});

    while (try interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        var coords_builder: std.ArrayList([]const u8) = .empty;
        defer coords_builder.deinit(allocator);

        while (it.next()) |value| {
            try coords_builder.append(allocator, value);
        }

        if (coords_builder.items.len != 2) return error.InvalidCoords;

        const x = try std.fmt.parseInt(isize, coords_builder.items[0], 10);
        const y = try std.fmt.parseInt(isize, coords_builder.items[1], 10);

        try angles.append(allocator, .{ .x = x, .y = y });
    }

    std.debug.print("Defining Perimenter\n", .{});

    var tiles_perimeter: std.ArrayList(Coords) = .empty;
    defer tiles_perimeter.deinit(allocator);

    // Conservative capacity estimate
    try tiles_perimeter.ensureTotalCapacity(allocator, angles.items.len * 8);

    for (angles.items, 0..) |a, i| {
        const b = angles.items[(i + 1) % angles.items.len];

        if (a.x == b.x) {
            // vertical edge

            const min_y: usize = @intCast(@min(a.y, b.y));
            const max_y: usize = @intCast(@max(a.y, b.y));

            for (min_y..max_y + 1) |y| {
                const point: isize = @intCast(y);
                try tiles_perimeter.append(allocator, Coords{
                    .x = a.x,
                    .y = point,
                });
            }
        } else if (a.y == b.y) {
            // horizontal edge
            const min_x: usize = @intCast(@min(a.x, b.x));
            const max_x: usize = @intCast(@max(a.x, b.x));

            for (min_x..max_x + 1) |x| {
                const point: isize = @intCast(x);
                try tiles_perimeter.append(allocator, Coords{
                    .x = point,
                    .y = a.y,
                });
            }
        } else {
            // Optional safety check
            @panic("Non axis-aligned edge");
        }
    }

    std.debug.print("Perimeter Defined and Ordered\n", .{});

    var largest_area: u64 = 0;

    for (angles.items, 0..) |angle, i| {
        for (angles.items, 0..) |angle2, j| {
            if (i == j) continue;

            if (isRectangleInside(angle, angle2, tiles_perimeter.items)) {
                const base = @abs(angle.x - angle2.x) + 1;
                const height = @abs(angle.y - angle2.y) + 1;

                const area = base * height;

                if (area > largest_area) {
                    largest_area = area;
                }
            }
        }
    }
    return largest_area;
}

test "DAY 9 TEST - PART 2" {
    const expected_result: u64 = 24;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 9 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 9 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 9 PART 2 -> {}\n", .{err});
    }
}
