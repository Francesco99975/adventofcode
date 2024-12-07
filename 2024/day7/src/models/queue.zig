const std = @import("std");

pub fn Queue(comptime T: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: T,
            next: ?*Node,
        };
        allocator: *const std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,
        size: usize,

        pub fn init(allocator: *const std.mem.Allocator) This {
            return This{ .allocator = allocator, .start = null, .end = null, .size = 0 };
        }
        pub fn enqueue(this: *This, value: T) !void {
            const node = try this.allocator.create(Node);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node //
            else this.start = node;
            this.end = node;
            this.size += 1;
        }
        pub fn dequeue(this: *This) ?T {
            const start = this.start orelse return null;
            defer this.allocator.destroy(start);
            if (start.next) |next|
                this.start = next
            else {
                this.start = null;
                this.end = null;
            }

            this.size -= 1;

            return start.data;
        }

        pub fn clear(this: *This) void {
            while (dequeue(this)) |_| {}
        }

        pub fn peek(this: *This, len: usize) []const T {
            const allocator = std.heap.page_allocator;
            var op: std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
            var index: usize = 0;

            var tmp = this.start;

            while (tmp) |current| {
                if (index == len) break;
                op.append(current.data) catch break;
                index += 1;
                tmp = current.next;
            }

            return op.items;
        }

        pub fn copy(this: *This) !This {
            // Initialize a new queue with the same allocator
            var new_queue = This.init(this.allocator);

            // Traverse the current queue
            var current = this.start;
            while (current) |node| {
                // Enqueue each item from the original queue into the new queue
                try new_queue.enqueue(node.data);
                current = node.next;
            }

            return new_queue;
        }
    };
}

test "queue" {
    var int_queue = Queue(i32).init(&std.testing.allocator);

    try int_queue.enqueue(25);
    try int_queue.enqueue(50);
    try int_queue.enqueue(75);
    try int_queue.enqueue(100);

    try std.testing.expectEqual(int_queue.dequeue(), 25);
    try std.testing.expectEqual(int_queue.dequeue(), 50);
    try std.testing.expectEqual(int_queue.dequeue(), 75);
    try std.testing.expectEqual(int_queue.dequeue(), 100);
    try std.testing.expectEqual(int_queue.dequeue(), null);

    try int_queue.enqueue(5);
    try std.testing.expectEqual(int_queue.dequeue(), 5);
    try std.testing.expectEqual(int_queue.dequeue(), null);
}

test "copy queue" {
    var original_queue = Queue(i32).init(&std.testing.allocator);
    defer original_queue.clear();

    try original_queue.enqueue(10);
    try original_queue.enqueue(20);
    try original_queue.enqueue(30);

    var copied_queue = try original_queue.copy();
    defer copied_queue.clear();

    try std.testing.expectEqual(original_queue.dequeue(), 10);
    try std.testing.expectEqual(original_queue.dequeue(), 20);
    try std.testing.expectEqual(original_queue.dequeue(), 30);
    try std.testing.expectEqual(original_queue.dequeue(), null);

    try std.testing.expectEqual(copied_queue.dequeue(), 10);
    try std.testing.expectEqual(copied_queue.dequeue(), 20);
    try std.testing.expectEqual(copied_queue.dequeue(), 30);
    try std.testing.expectEqual(copied_queue.dequeue(), null);
}
