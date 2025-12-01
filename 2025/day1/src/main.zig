const std = @import("std");
const day1 = @import("day1");

const Direction = enum { LEFT, RIGHT };

fn rotate(counter: u32, direction: Direction, steps: u32) u32 {
    return switch (direction) {
        .LEFT => (counter +% (100 -% steps)) % 100,
        .RIGHT => (counter +% steps) % 100,
    };
}

const Move = struct {
    dir: Direction,
    amount: u32,
};

pub fn parseMove(line: []const u8) !Move {
    const clean = std.mem.trim(u8, line, " \t\r\n");

    if (clean.len < 2) return error.InvalidFormat;

    const dir_char = clean[0];
    const number_str = clean[1..];

    const dir = switch (dir_char) {
        'R', 'r' => Direction.RIGHT,
        'L', 'l' => Direction.LEFT,
        else => return error.UnknownDirection,
    };

    const amount = std.fmt.parseInt(u32, number_str, 10) catch
        return error.InvalidNumber;

    return Move{ .dir = dir, .amount = amount };
}

pub fn main() !void {
    var point: u32 = 50;

    const file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;
    var zeros: u32 = 0;

    std.debug.print("Starting Point: {d}\n", .{point});

    while (try interface.takeDelimiter('\n')) |line| {
        std.debug.print("Line: {s}\n", .{line});

        const move = try parseMove(line);

        std.debug.print("Moving: {} from {d} by {d}\n", .{ move.dir, point, move.amount });

        point = rotate(point, move.dir, move.amount);
        std.debug.print("Rotated to point: {d}\n", .{point});

        if (point == 0) {
            zeros += 1;
        }
    }

    std.debug.print("{} Zeros Found\n", .{zeros});
}

test "DAY 1 TEST - PART 1" {
    var point: u32 = 50;

    const file = try std.fs.cwd().openFile("test.txt", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var zeros: u32 = 0;

    while (try interface.takeDelimiter('\n')) |line| {
        const move = try parseMove(line);

        point = rotate(point, move.dir, move.amount);

        if (point == 0) {
            zeros += 1;
        }
    }

    try std.testing.expectEqual(3, zeros);
}
