const std = @import("std");
const Queue = @import("structlib").Queue;
const Stack = @import("structlib").Stack;

const Operation = enum(u8) {
    ADD = '+',
    SUB = '-',
    MUL = '*',
    DIV = '/',
    MOD = '%',
};

fn isValidOp(ch: u8) bool {
    return std.meta.intToEnum(Operation, ch) != error.InvalidEnumTag;
}

const Problem = struct {
    operation: Operation,
    operands: Queue(i64),

    pub fn init(allocator: *std.mem.Allocator, operation: Operation) Problem {
        return Problem{
            .operation = operation,
            .operands = Queue(i64).init(allocator),
        };
    }
};

const ProblemST = struct {
    operation: Operation,
    operands: Stack(i64),

    pub fn init(allocator: *std.mem.Allocator, operation: Operation) ProblemST {
        return ProblemST{
            .operation = operation,
            .operands = Stack(i64).init(allocator),
        };
    }
};

fn isNumberString(str: []const u8) bool {
    for (str) |ch| {
        if (!std.ascii.isDigit(ch)) {
            return false;
        }
    }

    return true;
}

pub fn main() !void {
    std.debug.print("STARTING DAY 6 - PART 1\n\n", .{});

    if (part1("data.txt")) |problems_sum| {
        std.debug.print("Problems Sum: {d}\n", .{problems_sum});
    } else |err| {
        std.debug.print("There was an error with DAY 6 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 6 - PART 2\n\n", .{});

    if (part2("data.txt")) |problems_sum| {
        std.debug.print("Problems Sum: {d}\n", .{problems_sum});
    } else |err| {
        std.debug.print("There was an error with DAY 6 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8) !i64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var problems: std.ArrayList(Problem) = .empty;
    defer {
        for (problems.items, 0..) |_, i| {
            var pp = &problems.items[i];
            pp.operands.clear();
        }

        problems.deinit(allocator);
    }

    while (try interface.takeDelimiter('\n')) |line| {
        var col_iterator = std.mem.splitAny(u8, line, " ");

        var i: usize = 0;
        while (col_iterator.next()) |value| {
            const clean_value = std.mem.trim(u8, value, " \n\r\t");
            if (clean_value.len == 0) continue;
            std.debug.print("Value: {s}\n", .{clean_value});

            if (problems.items.len <= i) {
                std.debug.print("Allocating Problem with stack at index {d}\n", .{i});
                try problems.append(allocator, Problem.init(&allocator, Operation.MOD));
            }

            if (isNumberString(clean_value)) {
                const number = try std.fmt.parseInt(i64, clean_value, 10);
                std.debug.print("Pushing {d} onto stack at index {d}\n", .{ number, i });
                try problems.items[i].operands.enqueue(number);
            } else {
                std.debug.print("Setting {s} as the operator for stack at index {d}\n", .{ clean_value, i });
                problems.items[i].operation = try std.meta.intToEnum(Operation, clean_value[0]);
            }
            i += 1;
        }
    }

    var problems_results_sum: i64 = 0;

    for (problems.items, 0..) |_, i| {
        var problem_result: i64 = 0;
        switch (problems.items[i].operation) {
            .ADD => {
                var pp = &problems.items[i];
                while (pp.operands.dequeue()) |operand| {
                    std.debug.print("Adding up {d}\n", .{operand});
                    problem_result += operand;
                }
            },
            .SUB => {
                var pp = &problems.items[i];
                while (pp.operands.dequeue()) |operand| {
                    problem_result -= operand;
                }
            },
            .MUL => {
                var pp = &problems.items[i];
                var j: usize = 0;
                while (pp.operands.dequeue()) |operand| : (j += 1) {
                    if (j == 0) problem_result = 1;
                    std.debug.print("Multing up {d}\n", .{operand});
                    problem_result *= operand;
                }
            },
            .DIV => {
                var pp = &problems.items[i];
                while (pp.operands.dequeue()) |operand| {
                    problem_result = @divTrunc(problems_results_sum, operand);
                }
            },
            .MOD => {
                var pp = &problems.items[i];
                while (pp.operands.dequeue()) |operand| {
                    problem_result = @mod(problems_results_sum, operand);
                }
            },
        }

        std.debug.print("Adding a Problem result of {d} to sum\n", .{problem_result});

        problems_results_sum += problem_result;
    }

    return problems_results_sum;
}

test "DAY 6 TEST - PART 1" {
    const expected_result: i64 = 4277556;
    if (part1("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 6 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 6 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 6 PART 1 -> {}\n", .{err});
    }
}

// Helper: try read 1 char at a specific offset
fn tryReadChar(file: std.fs.File, offset: usize) u8 {
    var buf: [1]u8 = undefined;
    _ = file.seekTo(offset) catch return 0;
    const n = file.read(&buf) catch return 0;
    return if (n == 1) buf[0] else 0;
}

fn part2(input: []const u8) !i64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var row_offsets: std.ArrayList(usize) = .empty;
    defer row_offsets.deinit(allocator);

    try row_offsets.append(allocator, 0);

    var buf: [1]u8 = undefined;
    var pos: usize = 0;

    while (true) {
        const n = try file.read(&buf);
        if (n == 0) break; // EOF when reading forward normally

        pos += 1;

        // Detect end-of-line
        if (buf[0] == '\n') {
            try row_offsets.append(allocator, pos);
        } else if (buf[0] == '\r') {
            // Detect CRLF
            const next = try file.read(&buf);
            if (next != 0 and buf[0] == '\n') {
                pos += 1;
            }
            try row_offsets.append(allocator, pos);
        }
    }

    const row_count = row_offsets.items.len;

    // 2. FIND longest row length dynamically
    var max_col: usize = 0;

    for (row_offsets.items, 0..) |start, i| {
        const end: usize = if (i + 1 < row_count)
            row_offsets.items[i + 1]
        else
            pos; // last row runs until EOF

        // Trim CR/LF
        var length = end - start;
        if (length > 0 and length >= 1 and tryReadChar(file, end - 1) == '\n') length -= 1;
        if (length > 0 and length >= 1 and tryReadChar(file, end - 1) == '\r') length -= 1;

        if (length > max_col) max_col = length;
    }

    var problems: std.ArrayList(ProblemST) = .empty;
    defer {
        for (problems.items, 0..) |_, i| {
            var pp = &problems.items[i];
            pp.operands.clear();
        }

        problems.deinit(allocator);
    }

    var pr_col: bool = true;
    var pi: usize = 0;

    // 3. Vertical reading
    for (0..max_col) |col| {
        if (pr_col) {
            std.debug.print("Problem\n", .{});
            pr_col = false;
            try problems.append(allocator, ProblemST
                .init(&allocator, Operation.MOD));
        }

        var buffered_chars: std.ArrayList(u8) = .empty;
        defer buffered_chars.deinit(allocator);

        for (row_offsets.items) |start_offset| {
            const seek_pos = start_offset + col;

            // Attempt seek
            if (file.seekTo(seek_pos)) |_| {} else |_| {
                // If seek fails we stop (EOF)
                break;
            }

            const n = try file.read(&buf);
            if (n == 0) continue; // past EOF

            const ch = buf[0];
            if (ch == '\n' or ch == '\r') continue; // shorter row

            if (isValidOp(ch)) {
                problems.items[pi].operation = try std.meta.intToEnum(Operation, ch);
            }

            std.debug.print("<< Character {c} >>", .{ch});
            try buffered_chars.append(allocator, ch);
        }

        if (std.mem.trim(u8, buffered_chars.items, " \n\r\t").len == 0) {
            pr_col = true;
            pi += 1;
        } else {
            const value = std.mem.trim(u8, buffered_chars.items, " \n\r\t%+-/*");

            if (isNumberString(value)) {
                const number = try std.fmt.parseInt(i64, value, 10);
                try problems.items[pi].operands.push(number);
            }
        }

        std.debug.print("\n", .{});
    }

    var problems_results_sum: i64 = 0;

    for (problems.items, 0..) |_, i| {
        var problem_result: i64 = 0;
        switch (problems.items[i].operation) {
            .ADD => {
                var pp = &problems.items[i];
                while (pp.operands.pop()) |operand| {
                    std.debug.print("Adding up {d}\n", .{operand});
                    problem_result += operand;
                }
            },
            .SUB => {
                var pp = &problems.items[i];
                while (pp.operands.pop()) |operand| {
                    problem_result -= operand;
                }
            },
            .MUL => {
                var pp = &problems.items[i];
                var j: usize = 0;
                while (pp.operands.pop()) |operand| : (j += 1) {
                    if (j == 0) problem_result = 1;
                    std.debug.print("Multing up {d}\n", .{operand});
                    problem_result *= operand;
                }
            },
            .DIV => {
                var pp = &problems.items[i];
                while (pp.operands.pop()) |operand| {
                    problem_result = @divTrunc(problems_results_sum, operand);
                }
            },
            .MOD => {
                var pp = &problems.items[i];
                while (pp.operands.pop()) |operand| {
                    problem_result = @mod(problems_results_sum, operand);
                }
            },
        }

        std.debug.print("Adding a Problem result of {d} to sum\n", .{problem_result});

        problems_results_sum += problem_result;
    }

    return problems_results_sum;
}

test "DAY 6 TEST - PART 2" {
    const expected_result: i64 = 3263827;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 6 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 6 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 6 PART 2 -> {}\n", .{err});
    }
}
