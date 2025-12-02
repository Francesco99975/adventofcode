const std = @import("std");
const day2 = @import("day2");

fn parseRange(range: []const u8) !struct { min: u64, max: u64 } {
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

fn part1() !void {
    const file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var invalid_ids: u64 = 0;
    var invalid_ids_sum: u64 = 0;

    while (try interface.takeDelimiter(',')) |line| {
        if (parseRange(line)) |range| {
            std.debug.print("MIN: {d} - MAX: {d}\n", .{ range.min, range.max });

            for (range.min..range.max + 1) |i| {
                var buf: [20]u8 = undefined;
                const str = std.fmt.bufPrint(&buf, "{d}", .{i}) catch unreachable;
                const p1 = str[0 .. str.len / 2];
                const p2 = str[str.len / 2 ..];
                std.debug.print("P1: {s} - P2: {s}\n", .{ p1, p2 });

                if (std.mem.eql(u8, p1, p2)) {
                    std.debug.print("Found {s} -- {s}, Matches invalid ID format\n", .{ p1, p2 });
                    invalid_ids += 1;
                    invalid_ids_sum += @intCast(i);
                }
            }
        } else |err| {
            std.debug.print("Error while parsing {s} -> {}", .{ line, err });
        }
    }

    std.debug.print("Found {d} invalid IDs\n", .{invalid_ids});
    std.debug.print("invalid IDs SUM: {d}\n", .{invalid_ids_sum});
}

fn part2() !void {
    const file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var invalid_ids: u64 = 0;
    var invalid_ids_sum: u64 = 0;

    while (try interface.takeDelimiter(',')) |line| {
        if (parseRange(line)) |range| {
            std.debug.print("MIN: {d} - MAX: {d}\n", .{ range.min, range.max });

            for (range.min..range.max + 1) |i| {
                var buf: [20]u8 = undefined;
                const current_id = std.fmt.bufPrint(&buf, "{d}", .{i}) catch unreachable;

                const allocator = std.heap.page_allocator;

                var lps_array: std.ArrayList(u64) = .empty;
                defer lps_array.deinit(allocator);

                for (0..current_id.len) |_| {
                    try lps_array.append(allocator, 0);
                }

                var j: usize = 1;
                var pivot: usize = 0;

                while (j < current_id.len) {
                    if (current_id[j] == current_id[pivot]) {
                        pivot += 1;
                        lps_array.items[j] = pivot;
                        j += 1;
                    } else {
                        if (pivot != 0) {
                            pivot = lps_array.items[pivot - 1];
                        } else {
                            lps_array.items[j] = 0;
                            j += 1;
                        }
                    }
                }

                const border = lps_array.items[lps_array.items.len - 1];
                const period = current_id.len - border;

                if (border > 0 and current_id.len % period == 0 and current_id.len / period >= 2) {
                    invalid_ids += 1;
                    invalid_ids_sum += @intCast(i);
                }
            }
        } else |err| {
            std.debug.print("Error while parsing {s} -> {}", .{ line, err });
        }
    }

    std.debug.print("Found {d} invalid IDs\n", .{invalid_ids});
    std.debug.print("invalid IDs SUM: {d}\n", .{invalid_ids_sum});
}

pub fn main() !void {
    std.debug.print("STARTING DAY 2 - PART 1\n\n", .{});

    try part1();

    std.debug.print("\n\nSTARTING DAY 2 - PART 2\n\n", .{});

    try part2();
}

test "DAY 2 TEST - PART 1" {
    const file = try std.fs.cwd().openFile("test.txt", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var invalid_ids_sum: u64 = 0;
    const expected_invalid_ids_sum: u64 = 1227775554;

    while (try interface.takeDelimiter(',')) |line| {
        if (parseRange(line)) |range| {
            for (range.min..range.max + 1) |i| {
                var buf: [20]u8 = undefined;
                const str = std.fmt.bufPrint(&buf, "{d}", .{i}) catch unreachable;
                const p1 = str[0 .. str.len / 2];
                const p2 = str[str.len / 2 ..];

                if (std.mem.eql(u8, p1, p2)) {
                    invalid_ids_sum += @intCast(i);
                }
            }
        } else |err| {
            std.debug.print("Error while parsing {s} -> {}", .{ line, err });
        }
    }

    try std.testing.expectEqual(expected_invalid_ids_sum, invalid_ids_sum);
    std.debug.print("Test PASSED FOR DAY 2 PART 1\n", .{});
}

test "DAY 2 TEST - PART 2" {
    const file = try std.fs.cwd().openFile("test.txt", .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var invalid_ids_sum: u64 = 0;
    const expected_invalid_ids_sum: u64 = 4174379265;

    while (try interface.takeDelimiter(',')) |line| {
        if (parseRange(line)) |range| {
            for (range.min..range.max + 1) |i| {
                var buf: [20]u8 = undefined;
                const current_id = std.fmt.bufPrint(&buf, "{d}", .{i}) catch unreachable;

                const allocator = std.testing.allocator;

                var lps_array: std.ArrayList(u64) = .empty;
                defer lps_array.deinit(allocator);

                for (0..current_id.len) |_| {
                    try lps_array.append(allocator, 0);
                }

                var j: usize = 1;
                var pivot: usize = 0;

                while (j < current_id.len) {
                    if (current_id[j] == current_id[pivot]) {
                        pivot += 1;
                        lps_array.items[j] = pivot;
                        j += 1;
                    } else {
                        if (pivot != 0) {
                            pivot = lps_array.items[pivot - 1];
                        } else {
                            lps_array.items[j] = 0;
                            j += 1;
                        }
                    }
                }

                const border = lps_array.items[lps_array.items.len - 1];
                const period = current_id.len - border;

                if (border > 0 and current_id.len % period == 0 and current_id.len / period >= 2) {
                    invalid_ids_sum += @intCast(i);
                }
            }
        } else |err| {
            std.debug.print("Error while parsing {s} -> {}", .{ line, err });
        }
    }

    try std.testing.expectEqual(expected_invalid_ids_sum, invalid_ids_sum);
    std.debug.print("Test PASSED FOR DAY 2 PART 2\n", .{});
}
