const std = @import("std");
const Stack = @import("structlib").Stack;

pub fn main() !void {
    std.debug.print("STARTING DAY 3 - PART 1\n\n", .{});

    if (part1("data.txt")) |joltage| {
        std.debug.print("Sum Joltage: {d}\n", .{joltage});
    } else |err| {
        std.debug.print("There was an error with day 3 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 3 - PART 2\n\n", .{});

    if (part2("data.txt")) |joltage| {
        std.debug.print("Sum Joltage: {d}\n", .{joltage});
    } else |err| {
        std.debug.print("There was an error with day 3 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8) !u32 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var total_joltage_sum: u32 = 0;

    while (try interface.takeDelimiter('\n')) |bank| {
        std.debug.print("Bank: {s}\n", .{bank});

        var max_joltage: u32 = 0;

        for (0..bank.len) |i| {
            for (0..bank.len) |j| {
                const pivot = j + 1;
                if (pivot < bank.len and i < pivot) {
                    const combined_joltage = [_]u8{ bank[i], bank[pivot] };

                    const joltage_sum = try std.fmt.parseInt(u32, &combined_joltage, 10);

                    if (joltage_sum > max_joltage) {
                        max_joltage = joltage_sum;
                    }

                    std.debug.print("{d}\n", .{joltage_sum});
                }
            }
        }

        total_joltage_sum += max_joltage;
    }

    return total_joltage_sum;
}

test "DAY 3 TEST - PART 1" {
    const expected_result: u32 = 357;
    if (part1("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 3 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 3 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 3 PART 1 -> {}\n", .{err});
    }
}

fn part2(input: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    const battery_combination_limit: usize = 12;
    var total_joltage_sum: u64 = 0;

    while (try interface.takeDelimiter('\n')) |bank| {
        std.debug.print("Bank: {s}\n", .{bank});
        std.debug.print("Bank Length: {d}\n", .{bank.len});

        var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa_allocator.allocator();
        defer _ = gpa_allocator.deinit();

        var monotonic = Stack(u8).init(&allocator);
        var remaining: usize = bank.len;

        for (bank, 0..) |battery, i| {
            const j = [_]u8{battery};
            const joltage = try std.fmt.parseInt(u64, &j, 10);
            remaining -= 1;

            std.debug.print("Scanning.. {d} Remaining: {d} / Size: {d} - Joltage {d}\n", .{ i, remaining, monotonic.size, joltage });

            if (monotonic.peek()) |peek| {
                std.debug.print("Peek: {c}\n", .{peek});
                var np = [_]u8{peek};
                var numpeek = try std.fmt.parseInt(u64, &np, 10);

                while (monotonic.size > 0 and numpeek < joltage and (monotonic.size - 1 + remaining + 1) >= battery_combination_limit) {
                    const el = monotonic.pop().?;
                    if (monotonic.peek()) |peekk| {
                        np = [_]u8{peekk};
                        numpeek = try std.fmt.parseInt(u64, &np, 10);
                    }

                    std.debug.print("Popping {c} / Size: {d} - Joltage {d}\n", .{ el, monotonic.size, joltage });
                }
            } else {
                std.debug.print("Peek: Null\n", .{});
            }

            if (monotonic.size < battery_combination_limit) {
                try monotonic.push(battery);
                std.debug.print("Pushing {c} / Size: {d} - Joltage {d}\n", .{ battery, monotonic.size, joltage });
            }
        }

        var joltage_builder: std.ArrayList(u8) = .empty;
        defer joltage_builder.deinit(allocator);

        monotonic.reverse();
        while (monotonic.pop()) |battery| {
            try joltage_builder.append(allocator, battery);
        }

        std.debug.print("Joltage Builded: {s} - Len: {d}\n", .{ joltage_builder.items, joltage_builder.items.len });

        total_joltage_sum += try std.fmt.parseInt(u64, joltage_builder.items, 10);
    }

    return total_joltage_sum;
}

test "DAY 3 TEST - PART 2" {
    const expected_result: u64 = 3121910778619;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 3 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 3 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 3 PART 2 -> {}\n", .{err});
    }
}
