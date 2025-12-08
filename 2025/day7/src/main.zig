const std = @import("std");

pub fn main() !void {
    std.debug.print("STARTING DAY 7 - PART 1\n\n", .{});

    if (part1("data.txt")) |splits| {
        std.debug.print("Beam Splits: {d}\n", .{splits});
    } else |err| {
        std.debug.print("There was an error with DAY 7 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 7 - PART 2\n\n", .{});

    if (part2("data.txt")) |timelines| {
        std.debug.print("Timelines: {d}\n", .{timelines});
    } else |err| {
        std.debug.print("There was an error with DAY 7 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8) !u32 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var splits: u32 = 0;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var trajectories = std.AutoHashMap(usize, void).init(allocator);
    defer trajectories.deinit();

    var first_line = true;
    while (try interface.takeDelimiter('\n')) |line| {
        for (line, 0..) |value, i| {
            if (!first_line) {
                if (value == '^' and trajectories.contains(i)) {
                    _ = trajectories.remove(i);
                    splits += 1;
                    const next = i + 1;

                    if (next < line.len) {
                        line[next] = '|';
                        try trajectories.put(next, {});
                    }

                    if (i > 0) {
                        const prev = i - 1;
                        if (prev >= 0) {
                            line[prev] = '|';
                            try trajectories.put(prev, {});
                        }
                    }
                } else if (trajectories.contains(i)) {
                    line[i] = '|';
                }
            } else {
                if (value == 'S') {
                    try trajectories.put(i, {});
                }
            }
        }
        std.debug.print("Line: {s}\n", .{line});
        first_line = false;
    }

    return splits;
}

test "DAY 7 TEST - PART 1" {
    const expected_result: u32 = 21;
    if (part1("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 7 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 7 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 7 PART 1 -> {}\n", .{err});
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

    var trajectories = std.AutoHashMap(usize, usize).init(allocator);
    defer trajectories.deinit();

    var first_line = true;

    while (try interface.takeDelimiter('\n')) |line| {
        for (line, 0..) |value, i| {
            if (!first_line) {
                if (value == '^' and trajectories.contains(i)) {
                    const count = trajectories.get(i).?;
                    _ = trajectories.remove(i);

                    const next = i + 1;

                    if (next < line.len) {
                        line[next] = '|';
                        const old = trajectories.get(next) orelse 0;
                        try trajectories.put(next, old + count);
                    }

                    if (i > 0) {
                        const prev = i - 1;
                        if (prev >= 0) {
                            line[prev] = '|';
                            const old = trajectories.get(prev) orelse 0;
                            try trajectories.put(prev, old + count);
                        }
                    }
                } else if (trajectories.contains(i)) {
                    line[i] = '|';
                }
            } else {
                if (value == 'S') {
                    try trajectories.put(i, 1);
                }
            }
        }
        std.debug.print("{s}\n", .{line});
        first_line = false;
    }

    var timelines: u64 = 0;

    var it = trajectories.iterator();
    while (it.next()) |trajectory| {
        timelines += @intCast(trajectory.value_ptr.*);
    }

    return timelines;
}

test "DAY 7 TEST - PART 2" {
    const expected_result: u64 = 40;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 7 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 7 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 7 PART 2 -> {}\n", .{err});
    }
}
