const std = @import("std");

pub fn renderMatrix(matrix: *std.ArrayList(std.ArrayList(u8))) void {
    const stdout = std.io.getStdOut().writer();

    for (matrix.items) |row| {
        for (row.items) |value| {
            // Render each value with padding
            stdout.print("{c} ", .{value}) catch {};
        }
        stdout.print("\n", .{}) catch {};
    }
    stdout.print("\n", .{}) catch {};
}

pub fn clearScreen() !void {
    const stdout = std.io.getStdOut().writer();

    // ANSI escape sequence to clear the screen and reset the cursor
    try stdout.print("\x1b[2J\x1b[H", .{});
}