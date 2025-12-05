const std = @import("std");

const Range = struct { min: u64, max: u64 };

fn parseRange(range: []const u8) !Range {
    const dash_pos = std.mem.indexOfScalar(u8, range, '-') orelse return error.NoDashFound;

    if (dash_pos == 0) return error.EmptyMin;
    if (dash_pos == range.len - 1) return error.EmptyMax;

    const min_str = range[0..dash_pos];
    const max_str = range[dash_pos + 1 ..];

    const min = try std.fmt.parseInt(u64, min_str, 10);
    const max = try std.fmt.parseInt(u64, max_str, 10);

    if (min > max) return error.MinGreaterThanMax;

    return .{ .min = min, .max = max };
}

pub fn main() !void {
    std.debug.print("STARTING DAY 5 - PART 1\n\n", .{});

    if (part1("data.txt")) |fresh| {
        std.debug.print("Fresh Ingredients: {d}\n", .{fresh});
    } else |err| {
        std.debug.print("There was an error with DAY 5 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 5 - PART 2\n\n", .{});

    if (part2("data.txt")) |fresh| {
        std.debug.print("Fresh Ingredients: {d}\n", .{fresh});
    } else |err| {
        std.debug.print("There was an error with DAY 5 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8) !u32 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var fresh_ids: u32 = 0;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var id_ranges: std.ArrayList(Range) = .empty;
    defer id_ranges.deinit(allocator);
    var ranges_mode = true;
    while (try interface.takeDelimiter('\n')) |line| {
        std.debug.print("Line: {s} / Len: {d}\n", .{ line, line.len });

        const empty_line = line.len == 0;

        if (empty_line) {
            ranges_mode = false;
        }

        if (ranges_mode) {
            if (parseRange(line)) |range| {
                try id_ranges.append(allocator, range);
            } else |err| {
                std.debug.print("Error occurred while parsing range {s} -> {}", .{ line, err });
            }
        } else if (!ranges_mode and !empty_line) {
            const id = try std.fmt.parseInt(u64, line, 10);

            for (id_ranges.items) |range| {
                if (id >= range.min and id <= range.max) {
                    fresh_ids += 1;
                    break;
                }
            }
        }
    }

    return fresh_ids;
}

test "DAY 5 TEST - PART 1" {
    const expected_result: u32 = 3;
    if (part1("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 5 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 5 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 5 PART 1 -> {}\n", .{err});
    }
}

fn part2(input: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var fresh_ids: u64 = 0;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var id_ranges: std.ArrayList(Range) = .empty;
    defer id_ranges.deinit(allocator);

    while (try interface.takeDelimiter('\n')) |line| {
        const empty_line = line.len == 0;

        if (empty_line) {
            break;
        }

        if (parseRange(line)) |range| {
            var ids = range.max - range.min + 1;

            for (id_ranges.items) |prev_range| {
                if (range.max < prev_range.min or range.min > prev_range.max) continue;

                const overlap_min = @max(range.min, prev_range.min);
                const overlap_max = @min(range.max, prev_range.max);
                const overlap = overlap_max - overlap_min + 1;

                ids -= overlap;
            }

            std.debug.print("Range: {d}-{d} / IDs: {d}\n", .{ range.min, range.max, ids });

            fresh_ids += ids;

            var new_range = range;

            var i: usize = 0;
            while (i < id_ranges.items.len) : (i += 1) {
                const prev_range = id_ranges.items[i];

                const overlap = !(new_range.max < prev_range.min or new_range.min > prev_range.max);
                if (overlap) {
                    // merge
                    new_range.min = @min(new_range.min, prev_range.min);
                    new_range.max = @max(new_range.max, prev_range.max);

                    // remove old
                    _ = id_ranges.swapRemove(i);
                    continue;
                }
            }

            // insert final merged range
            try id_ranges.append(allocator, new_range);
        } else |err| {
            std.debug.print("Error occurred while parsing range {s} -> {}", .{ line, err });
        }
    }

    return fresh_ids;
}

test "DAY 5 TEST - PART 2" {
    const expected_result: u64 = 14;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 5 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 5 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 5 PART 2 -> {}\n", .{err});
    }
}
