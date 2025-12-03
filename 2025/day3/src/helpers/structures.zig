const std = @import("std");

pub fn Stack(comptime T: type) type {
    return struct {
        const This = @This();

        const Node = struct { data: T, next: ?*Node };

        allocator: *const std.mem.Allocator,
        head: ?*Node,
        size: usize,

        pub fn init(allocator: *const std.mem.Allocator) This {
            return This{ .allocator = allocator, .head = null, .size = 0 };
        }

        pub fn push(this: *This, value: T) !void {
            const node = try this.allocator.create(Node);
            node.* = .{ .data = value, .next = this.head };
            this.head = node;
            this.size += 1;
        }

        pub fn pop(this: *This) ?T {
            if (this.head) |head| {
                const data: T = head.data;

                this.head = head.next;

                this.allocator.destroy(head);

                this.size -= 1;

                return data;
            }
            return null;
        }

        pub fn peek(this: *This) ?T {
            if (this.head) |head| {
                return head.data;
            }

            return null;
        }

        pub fn clear(this: *This) void {
            while (pop(this)) |_| {}
        }

        pub fn reverse(this: *This) void {
            var prev: ?*Node = null;
            var current = this.head;
            var next: ?*Node = null;

            while (current) |node| {
                // Store the next node
                next = node.next;

                // Reverse the `next` pointer of the current node
                node.next = prev;

                // Move `prev` and `current` one step forward
                prev = current;
                current = next;
            }

            // Set the new head to the last node (which was `prev` after the loop)
            this.head = prev;
        }

        // Create a temporary copy of the stack
        pub fn copy(this: *This) !This {
            var new_stack = This.init(this.allocator);

            var current = this.head;
            while (current) |node| {
                // Push a copy of each element onto the new stack
                try new_stack.push(node.data);
                current = node.next;
            }

            return new_stack;
        }
    };
}
