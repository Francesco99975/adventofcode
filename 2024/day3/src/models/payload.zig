const std = @import("std");
const ascii = @import("std").ascii;

const Stack = @import("stack.zig").Stack;
const Queue = @import("queue.zig").Queue;

pub fn PayloadV2(comptime T: type) type {
    return struct {
        const This = @This();

        var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

        const gpa = general_purpose_allocator.allocator();

        operation: []const u8,
        line: Queue(u8),
        enabler: Queue(u8),
        disabler: Queue(u8),
        n1: Stack(T),
        n2: Stack(T),
        pivot: usize,
        sequences: [6][]const u8,
        online: bool,

        pub fn init() This {
            return This{ .operation = "", .line = Queue(u8).init(gpa), .enabler = Queue(u8).init(gpa), .disabler = Queue(u8).init(gpa), .n1 = Stack(T).init(gpa), .n2 = Stack(T).init(gpa), .pivot = 0, .sequences = [_][]const u8{ "add", "sub", "mul", "div", "do()", "don't()" }, .online = true };
        }

        pub fn processToken(this: *This, token: u8) ?T {
            return switch (this.pivot) {
                0 => {
                    std.debug.print("Adding {c} in queue of size {}\n", .{ token, this.line.size });
                    this.line.enqueue(token) catch return null;
                    this.enabler.enqueue(token) catch return null;
                    this.disabler.enqueue(token) catch return null;

                    if(matchesSequenceOFF(this) or matchesSequenceON(this)) {
                        computeToggleOperation(this);
                    }

                    if (matchesSequence(this)) {
                        this.pivot += 1;
                    }


                    return null;
                },
                1 => {
                    if (token == '(') {
                        this.pivot += 1;
                        return null;
                    } else {
                        this.reset();
                        return null;
                    }
                },
                2 => {
                    if (ascii.isDigit(token)) {
                        std.debug.print("Pushing {c} into n1 stack\n", .{token});
                        this.n1.push(token) catch return null;
                        return null;
                    } else if (token == ',') {
                        this.pivot += 1;
                        return null;
                    } else {
                        std.debug.print("Reset for this: {}\n", .{token});
                        this.reset();
                        return null;
                    }
                },
                3 => {
                    if (ascii.isDigit(token)) {
                        std.debug.print("Pushing {c} into n2 stack\n", .{token});
                        this.n2.push(token) catch return null;
                        return null;
                    } else if (token == ')') {
                        this.pivot = 0;
                        return computeOperation(this);
                    } else {
                        this.reset();
                        return null;
                    }
                },
                else => {
                    return null;
                },
            };
        }

        fn matchesSequenceON(this: *This) bool {
            if(this.enabler.size == 4) {
                std.debug.print("Current ON view: {s}\n", .{this.enabler.getViewV2(4)});
                for (this.sequences) |seq| {
                    if (std.mem.eql(u8, this.enabler.getViewV2(4), seq)) {
                        this.operation = this.enabler.getViewV2(4);
                        std.debug.print("Matched ON operation: {s}\n", .{this.operation});
                        return true;
                    }
                    
                }

                _ = this.enabler.dequeue();
            }

            return false;
        }

        fn matchesSequenceOFF(this: *This) bool {
            if(this.disabler.size == 7) {
                std.debug.print("Current OFF view: {s}\n", .{this.disabler.getViewV2(7)});
                for (this.sequences) |seq| {
                    if (std.mem.eql(u8, this.disabler.getViewV2(7), seq)) {
                        this.operation = this.disabler.getViewV2(7);
                        std.debug.print("Matched OFF operation: {s}\n", .{this.operation});
                        return true;
                    }
                    
                }

                _ = this.disabler.dequeue();
            }

            return false;
        }

        fn matchesSequence(this: *This) bool {
            if (this.line.size == 3) {
                std.debug.print("Current view: {s}\n", .{this.line.getViewV2(3)});
                for (this.sequences) |seq| {
                    if (std.mem.eql(u8, this.line.getViewV2(3), seq)) {
                        this.operation = this.line.getViewV2(3);
                        std.debug.print("Matched operation: {s}\n", .{this.operation});
                        return true;
                    }
                    
                }

                _ = this.line.dequeue();
            }


            return false;
        }

        fn computeToggleOperation(this: *This) void {
            if (std.mem.eql(u8, this.operation, "don't()")) {
                this.online = false;
            }

            if (std.mem.eql(u8, this.operation, "do()")) {
                this.online = true;
            }


            _ = this.disabler.dequeue();
            _ = this.enabler.dequeue();
            

            std.debug.print("\n\nONLINE SET TO: {} BECAUSE OF OP: {s}\n", .{ this.online, this.operation });
        }

        fn computeOperation(this: *This) T {
            defer this.reset();
            if (this.online) {
                

                const N1 = evaluateStack(&this.n1);
                const N2 = evaluateStack(&this.n2);

                std.debug.print("Operation is: {s}\n", .{this.operation});

                std.debug.print("N1 is {}\n", .{N1});
                std.debug.print("N2 is {}\n", .{N2});

                if (std.mem.eql(u8, this.operation, "add")) {
                    return N1 + N2;
                }

                if (std.mem.eql(u8, this.operation, "sub")) {
                    return N1 - N2;
                }

                if (std.mem.eql(u8, this.operation, "mul")) {
                    return N1 * N2;
                }

                if (std.mem.eql(u8, this.operation, "div")) {
                    if (N2 == 0) {
                        return 0;
                    }
                    return N1 / N2;
                }
            }

           

            return 0;
        }

        fn evaluateStack(stack: *Stack(T)) T {
            std.debug.print("\nSTACK SIZE: {}\n", .{stack.size});

            var sum: T = 0;

            var mul: T = 1;
            while (stack.pop()) |data| {
                // std.debug.print("\nDATA: {}\n", .{data});
                sum += (data - 48) * mul;
                mul *= 10;
            }

            return sum;
        }

        fn reset(this: *This) void {
            this.pivot = 0;
            _ = this.line.dequeue();
            this.operation = "";
            this.n1.clear();
            this.n2.clear();
        }
    };
}

pub fn Payload(comptime T: type) type {
    return struct {
        const This = @This();

        var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

        const gpa = general_purpose_allocator.allocator();

        operation: [3]u8,
        line: Queue(u8),
        n1: Stack(T),
        n2: Stack(T),
        pivot: usize,
        sequences: [4][]const u8,

        pub fn init() This {
            return This{ .operation = [_]u8{ 0, 0, 0 }, .line = Queue(u8).init(gpa), .n1 = Stack(T).init(gpa), .n2 = Stack(T).init(gpa), .pivot = 0, .sequences = [_][]const u8{ "add", "sub", "mul", "div" } };
        }

        pub fn processToken(this: *This, token: u8) ?T {
            return switch (this.pivot) {
                0 => {
                    std.debug.print("Adding {c} in queue of size {}\n", .{ token, this.line.size });
                    this.line.enqueue(token) catch return null;

                    if (matchesSequence(this)) {
                        this.pivot += 1;
                    }

                    return null;
                },
                1 => {
                    if (token == '(') {
                        this.pivot += 1;
                        return null;
                    } else {
                        this.reset();
                        return null;
                    }
                },
                2 => {
                    if (ascii.isDigit(token)) {
                        std.debug.print("Pushing {c} into n1 stack\n", .{token});
                        this.n1.push(token) catch return null;
                        return null;
                    } else if (token == ',') {
                        this.pivot += 1;
                        return null;
                    } else {
                        std.debug.print("Reset for this: {}\n", .{token});
                        this.reset();
                        return null;
                    }
                },
                3 => {
                    if (ascii.isDigit(token)) {
                        std.debug.print("Pushing {c} into n2 stack\n", .{token});
                        this.n2.push(token) catch return null;
                        return null;
                    } else if (token == ')') {
                        this.pivot = 0;
                        return computeOperation(this);
                    } else {
                        this.reset();
                        return null;
                    }
                },
                else => {
                    return null;
                },
            };
        }

        fn matchesSequence(this: *This) bool {
            if (this.line.size == 3) {
                std.debug.print("Current view: {s}\n", .{this.line.getView()});
                for (this.sequences) |seq| {
                    if (std.mem.eql(u8, &this.line.getView(), seq)) {
                        this.operation = this.line.getView();
                        std.debug.print("Matched operation: {s}\n", .{this.operation});
                        return true;
                    }
                }

                _ = this.line.dequeue();
            }

            return false;
        }

        fn computeOperation(this: *This) T {
            defer this.reset();

            const N1 = evaluateStack(&this.n1);
            const N2 = evaluateStack(&this.n2);

            std.debug.print("Operation is: {s}\n", .{this.operation});

            std.debug.print("N1 is {}\n", .{N1});
            std.debug.print("N2 is {}\n", .{N2});

            if (std.mem.eql(u8, &this.operation, "add")) {
                return N1 + N2;
            }

            if (std.mem.eql(u8, &this.operation, "sub")) {
                return N1 - N2;
            }

            if (std.mem.eql(u8, &this.operation, "mul")) {
                return N1 * N2;
            }

            if (std.mem.eql(u8, &this.operation, "div")) {
                if (N2 == 0) {
                    return 0;
                }
                return N1 / N2;
            }

            return 0;
        }

        fn evaluateStack(stack: *Stack(T)) T {
            std.debug.print("\nSTACK SIZE: {}\n", .{stack.size});

            var sum: T = 0;

            var mul: T = 1;
            while (stack.pop()) |data| {
                // std.debug.print("\nDATA: {}\n", .{data});
                sum += (data - 48) * mul;
                mul *= 10;
            }

            return sum;
        }

        fn reset(this: *This) void {
            this.pivot = 0;
            _ = this.line.dequeue();
            this.operation = [3]u8{ 0, 0, 0 };
            this.n1.clear();
            this.n2.clear();
        }
    };
}
