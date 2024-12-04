const std = @import("std");

pub fn Queue(comptime Child: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        gpa: std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,
        size: usize,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{ .gpa = gpa, .start = null, .end = null, .size = 0 };
        }
        pub fn enqueue(this: *This, value: Child) !void {
            const node = try this.gpa.create(Node);
            node.* = .{ .data = value, .next = null };
            if (this.end) |end| end.next = node //
            else this.start = node;
            this.end = node;
            this.size += 1;
        }
        pub fn dequeue(this: *This) ?Child {
            const start = this.start orelse return null;
            defer this.gpa.destroy(start);
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

        pub fn getView(this: *This) [3]Child {
            var op: [3]Child = [_]Child{ 0, 0, 0 };
            var index: usize = 0;

            var tmp = this.start;

            while (tmp) |current| {
                if (index == 3) break;
                op[index] = current.data;
                index += 1;
                tmp = current.next;
            }

            return op;
        }

        pub fn getViewV2(this: *This, len: usize) []const Child {
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
    };
}

test "queue" {
    var int_queue = Queue(i32).init(std.testing.allocator);

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
