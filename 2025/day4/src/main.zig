const std = @import("std");

const ROLL_OF_PAPER: u8 = '@';

fn isAccessible(matrix: *std.ArrayList([]u8), y: usize, x: usize) bool {
    const deltas: [8][2]isize = .{
        .{ -1, 0 },  .{ 1, 0 },  .{ 0, -1 }, .{ 0, 1 },
        .{ -1, -1 }, .{ -1, 1 }, .{ 1, -1 }, .{ 1, 1 },
    };

    const rows: isize = @intCast(matrix.items.len);
    var count: u8 = 0;

    for (deltas) |delta| {
        const syi: isize = @intCast(y);
        const sxi: isize = @intCast(x);
        const ny: isize = syi + delta[0];
        const nx: isize = sxi + delta[1];

        if (ny < 0 or nx < 0 or ny >= rows) continue;

        const nyu: usize = @intCast(ny);
        const row = matrix.items[nyu];
        const row_len: isize = @intCast(row.len);
        if (nx >= row_len) continue;

        const nxu: usize = @intCast(nx);
        if (row[nxu] == ROLL_OF_PAPER) {
            count += 1;
        }
    }

    return count < 4; // accessible if fewer than 4 adjacent rolls
}

fn processRays(
    matrix: *std.ArrayList([]u8),
    start_y: usize,
    start_x: usize,
) bool {

    // 8 directions: up, down, left, right, diagonals
    const deltas: [8][2]isize = .{
        .{ -1, 0 }, // up
        .{ 1, 0 }, // down
        .{ 0, -1 }, // left
        .{ 0, 1 }, // right
        .{ -1, -1 }, // up-left
        .{ -1, 1 }, // up-right
        .{ 1, -1 }, // down-left
        .{ 1, 1 }, // down-right
    };

    const rows: isize = @intCast(matrix.items.len);
    var checks: u16 = 0;

    for (deltas) |delta| {
        const syi: isize = @intCast(start_y);
        const sxi: isize = @intCast(start_x);
        var ny: isize = syi + delta[0];
        var nx: isize = sxi + delta[1];

        var rolls: i32 = -1;

        while (ny >= 0 and nx >= 0 and ny < rows) {
            const nyu: usize = @intCast(ny);
            const row = matrix.items[nyu];
            const row_len: isize = @intCast(row.len);

            if (nx >= row_len) break;
            const nxu: usize = @intCast(nx);
            const value = row[nxu];

            // std.debug.print("Value {c} at NY: {d} - NX: {d}\n", .{ value, ny, nx });

            if (value != ROLL_OF_PAPER) {
                break;
            }

            if (ny == syi + delta[0] and nx == sxi + delta[1]) {
                rolls = 0;
            }

            if (value == ROLL_OF_PAPER) {
                rolls += 1;
            }

            ny += delta[0];
            nx += delta[1];
        }

        std.debug.print("Adj Rolls Found for delta {d}  {d} are rolls: {d}\n", .{ delta[0], delta[1], rolls });

        if (rolls < 4)
            checks += 1;
    }

    std.debug.print("Passed Checks: {d}\n", .{checks});

    return checks == deltas.len;
}

pub fn main() !void {
    std.debug.print("STARTING DAY 4 - PART 1\n\n", .{});

    if (part1("data.txt")) |rolls| {
        std.debug.print("Accessible Rolls: {d}\n", .{rolls});
    } else |err| {
        std.debug.print("There was an error with DAY 4 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 4 - PART 2\n\n", .{});

    if (part2("data.txt")) |rolls| {
        std.debug.print("Accessible Rolls: {d}\n", .{rolls});
    } else |err| {
        std.debug.print("There was an error with DAY 4 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8) !u32 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var matrix: std.ArrayList([]u8) = .empty;
    defer {
        for (matrix.items) |row| allocator.free(row);
        matrix.deinit(allocator);
    }

    var forklist_accessible_rolls: u32 = 0;

    while (try interface.takeDelimiter('\n')) |line| {
        const row = try allocator.dupe(u8, line);
        try matrix.append(allocator, row);
    }

    for (matrix.items, 0..) |row, i| {
        for (row, 0..) |item, j| {
            if (item == ROLL_OF_PAPER) {
                std.debug.print("{c}", .{item});

                const accessible = isAccessible(&matrix, i, j);

                if (accessible) {
                    forklist_accessible_rolls += 1;
                }
            }
        }
        std.debug.print("\n", .{});
    }

    return forklist_accessible_rolls;
}

test "DAY 4 TEST - PART 1" {
    const expected_result: u32 = 13;
    if (part1("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 4 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 4 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 4 PART 1 -> {}\n", .{err});
    }
}

fn part2(input: []const u8) !u32 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var matrix: std.ArrayList([]u8) = .empty;
    defer {
        for (matrix.items) |row| allocator.free(row);
        matrix.deinit(allocator);
    }

    var forklist_accessible_rolls: u32 = 0;

    while (try interface.takeDelimiter('\n')) |line| {
        const row = try allocator.dupe(u8, line);
        try matrix.append(allocator, row);
    }

    while (true) {
        var indices_cleaner: std.ArrayList(struct { i: usize, j: usize }) = .empty;
        defer indices_cleaner.deinit(allocator);
        for (matrix.items, 0..) |row, i| {
            for (row, 0..) |item, j| {
                std.debug.print("{c}", .{item});

                if (item == ROLL_OF_PAPER) {
                    const accessible = isAccessible(&matrix, i, j);

                    if (accessible) {
                        forklist_accessible_rolls += 1;
                        try indices_cleaner.append(allocator, .{ .i = i, .j = j });
                    }
                }
            }
            std.debug.print("\n", .{});
        }

        if (indices_cleaner.items.len == 0) {
            break;
        }

        for (indices_cleaner.items) |idxes| {
            matrix.items[idxes.i][idxes.j] = 'x';
        }
    }

    return forklist_accessible_rolls;
}

test "DAY 4 TEST - PART 2" {
    const expected_result: u32 = 43;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 4 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 4 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 4 PART 2 -> {}\n", .{err});
    }
}
