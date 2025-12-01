const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();

    var left_values = std.ArrayList(u32).init(allocator);
    var right_values = std.ArrayList(u32).init(allocator);

    defer left_values.deinit();
    defer right_values.deinit();

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);
        // Split the line into two parts
        var tokenizer = std.mem.tokenize(u8, line, " ");
        const left_str = tokenizer.next() orelse break;
        const right_str = tokenizer.next() orelse break;

        // Parse the numbers
        const left = try std.fmt.parseInt(u32, left_str, 10);
        const right = try std.fmt.parseInt(u32, right_str, 10);

        // Append values to the respective arrays
        try left_values.append(left);
        try right_values.append(right);
    }

    part1(&left_values, &right_values);

    part2(&left_values, &right_values);
}

fn part1(left_values: *std.ArrayList(u32), right_values: *std.ArrayList(u32)) void {
    var sum: u32 = 0;

    std.mem.sort(u32, left_values.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, right_values.items, {}, comptime std.sort.asc(u32));

    for (left_values.items, 0..) |_, i| {
        const lv = left_values.items[i];
        const rv = right_values.items[i];

        std.debug.print("LEFT: {} and ", .{lv});
        std.debug.print("RIGHT: {} = ", .{rv});

        if (lv == rv) {
            std.debug.print("SAME NO SUMMING\n", .{});
            continue;
        }

        const max = if (lv > rv) lv else rv;
        const min = if (lv < rv) lv else rv;

        sum += max - min;

        std.debug.print("SUM: {}\n", .{max - min});
    }

    std.debug.print("Sum: {}\n", .{sum});
}

fn part2(left_values: *std.ArrayList(u32), right_values: *std.ArrayList(u32)) void {
    var total_score: u32 = 0;
    for (left_values.items) |left_value| {
        var iterations: u32 = 0;
        for (right_values.items) |right_value| {
            if (right_value == left_value) {
                iterations += 1;
            }
        }
        total_score += left_value * iterations;
    }

    std.debug.print("Total Score: {}\n", .{total_score});
}
