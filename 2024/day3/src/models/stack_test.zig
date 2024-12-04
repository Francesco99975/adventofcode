const std = @import("std");
const Stack = @import("stack.zig").Stack;

test "push and pop" {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    const gpa = general_purpose_allocator.allocator();
    var stack = Stack(u8).init(gpa);

    // Push elements onto the stack
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    // Check the size after pushing
    std.testing.expect(stack.size == 3) catch std.debug.print("Error Size not right", .{});

    // Pop elements from the stack and check them
    const val1 = stack.pop() orelse 0;
    try std.testing.expect(val1 == 3); // The last pushed element should be popped first

    const val2 = stack.pop() orelse 0;
    try std.testing.expect(val2 == 2);

    const val3 = stack.pop() orelse 0;
    try std.testing.expect(val3 == 1);

    // Check the size after popping
    std.testing.expect(stack.size == 0) catch std.debug.print("Error Size not right", .{});

    // Test that popping from an empty stack returns null
    const emptyPop = stack.pop();
    std.testing.expect(emptyPop == null) catch std.debug.print("Error POP not right", .{});
}

test "clear stack" {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    const gpa = general_purpose_allocator.allocator();
    var stack = Stack(u8).init(gpa);

    // Push elements onto the stack
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    // Clear the stack
    stack.clear();

    // Check that the stack is empty after clearing
    std.testing.expect(stack.size == 0) catch std.debug.print("Error Size not right", .{});

    // Test that popping from the cleared stack returns null
    const emptyPop = stack.pop();
    std.testing.expect(emptyPop == null) catch std.debug.print("Error POP not right", .{});
}

test "empty stack initialization" {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    const gpa = general_purpose_allocator.allocator();
    var stack = Stack(u8).init(gpa);

    // Check that the stack is empty after initialization
    std.testing.expect(stack.size == 0) catch std.debug.print("Error Size not right", .{});
    std.testing.expect(stack.pop() == null) catch std.debug.print("Error POP not right", .{});
}
