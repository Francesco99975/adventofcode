const std = @import("std");
const validator = @import("helpers/validator.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();

    // Create a matrix: an ArrayList of ArrayLists
    var matrix = std.ArrayList(std.ArrayList(u32)).init(allocator);

    defer {
        // Clean up all rows first
        for (matrix.items) |row| {
            row.deinit();
        }
        // Then clean up the outer ArrayList
        matrix.deinit();
    }

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);
        // Split the line into two parts
        var tokenizer = std.mem.tokenize(u8, line, " ");

        var row = std.ArrayList(u32).init(allocator);

        while (tokenizer.next()) |token| {
            const value: u32 = try std.fmt.parseInt(u32, token, 10);
            try row.append(value);
        }

        try matrix.append(row);
    }

    part1(&matrix);

    part2(&matrix);
}

fn part2(matrix: *std.ArrayList(std.ArrayList(u32))) void {
    var number_of_safe_lists: u32 = 0;

    for (matrix.items) |list| {
        var mutable_list = list;
        if (validator.isListSafeV2(&mutable_list, false)) {
            number_of_safe_lists += 1;
        }
    }

    std.debug.print("Safe Lists V2: {}\n", .{number_of_safe_lists});
}

fn part1(matrix: *std.ArrayList(std.ArrayList(u32))) void {
    var number_of_safe_lists: u32 = 0;

    for (matrix.items) |list| {
        if (validator.isListSafe(&list)) {
            number_of_safe_lists += 1;
        }
    }

    std.debug.print("Safe Lists V1: {}\n", .{number_of_safe_lists});
}
