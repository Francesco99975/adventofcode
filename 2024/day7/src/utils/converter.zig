const std = @import("std");

pub fn concatenate(n1: u64, n2: u64, allocator: std.mem.Allocator) !u64 {
  // Convert u64 to string
    const n1_str = try std.fmt.allocPrint(allocator, "{}", .{n1});
    const n2_str = try std.fmt.allocPrint(allocator, "{}", .{n2});
    defer allocator.free(n1_str);
    defer allocator.free(n2_str);

    // Concatenate the strings
    const slices = [_][]const u8{ n1_str, n2_str };
    const concatenated_str = try std.mem.concat(allocator, u8, &slices);
    defer allocator.free(concatenated_str);

    // Convert the concatenated string back to u64
    return try std.fmt.parseInt(u64, concatenated_str, 10);
}