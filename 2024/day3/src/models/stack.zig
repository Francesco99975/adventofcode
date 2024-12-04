const std = @import("std");

pub fn Stack(comptime T: type) type {
    return struct {
        const This = @This();

        const Node = struct { data: T, next: ?*Node };

        gpa: std.mem.Allocator,
        head: ?*Node,
        size: usize,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{ .gpa = gpa, .head = null, .size = 0 };
        }

        pub fn push(this: *This, value: T) !void {
            const node = try this.gpa.create(Node);
            node.* = .{ .data = value, .next = this.head };
            this.head = node;
            this.size += 1;
        }

        pub fn pop(this: *This) ?T {
            if (this.head) |head| {
                const data: T = head.data;

                this.head = head.next;

                this.gpa.destroy(head);

                this.size -= 1;

                return data;
            }
            return null;
        }

        pub fn clear(this: *This) void {
            while (pop(this)) |_| {}
        }
    };
}
