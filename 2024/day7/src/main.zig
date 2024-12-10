const std = @import("std");
const symbols = @import("constants/symbols.zig");
const generator = @import("utils/generator.zig");
const converter = @import("utils/converter.zig");
const operations = @import("utils/operations.zig");
const Calculation = @import("models/calculations.zig").Calculation;

pub fn main() !void {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit(); // Clean up at the end of `main`
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();
    var expressions = std.AutoArrayHashMap(u64, Calculation()).init(allocator);
    defer {
        var it = expressions.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.deinit(); // Deinit Calculation
        }
        expressions.deinit();
    }

    var optimalMatrix = std.ArrayList(std.ArrayList(u64)).init(allocator);
    defer {
        for (optimalMatrix.items) |process| {
            process.deinit();
        }
        optimalMatrix.deinit();
    }

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);
        // Split the line into two parts
        var tokenizer = std.mem.tokenize(u8, line, " ");
        
        var sum_buffer = tokenizer.next() orelse "";
        const sum = try std.fmt.parseInt(u64, sum_buffer[0..sum_buffer.len-1], 10);

        

        var calculation = Calculation().init(allocator);
        var process = std.ArrayList(u64).init(allocator);
        try process.append(sum);

        while (tokenizer.next()) |token| {
            const part: u64 = try std.fmt.parseInt(u64, token, 10);
            try calculation.values.enqueue(part);
            try process.append(part);
        }

        try optimalMatrix.append(process);

        const result = try expressions.getOrPut(sum);
        if(result.found_existing) std.debug.print("This Ain't it Chief", .{});
        result.value_ptr.* = calculation;
    }

    // var it = expressions.iterator();

    // var sum_of_valid_values: u64 = 0;

    // var sum_of_valid_values_with_concat: u64 = 0;


    // while (it.next()) |expression| {
    //    try generator.generatePossibleOperations(expression.value_ptr.*.values.size - 1, &expression.value_ptr.*.operations, allocator); 
    //    std.debug.print("SUM {} OPS:\n", .{expression.key_ptr.* });

    //     if(try expression.value_ptr.isSummableTo(expression.key_ptr.*)) {
    //         sum_of_valid_values += expression.key_ptr.*;
    //     }

    //     // expression.value_ptr
    // }

    // it.reset();

    // std.debug.print("\nRESETTING\n\n", .{});


    // var index: usize = 1;
    // while (it.next()) |expression| {
    //     var possible_results = std.AutoHashMap(u64, void).init(allocator);
    //     defer possible_results.deinit();

    //     try possible_results.put(expression.value_ptr.*.values.dequeue() orelse 0, {});

    //     while (expression.value_ptr.*.values.dequeue()) |value| {
    //         var new_results = std.AutoHashMap(u64, void).init(allocator);
    //         defer new_results.deinit();

    //         var res_iter = possible_results.keyIterator();
    //         while (res_iter.next()) |prev| {
    //             const prev_val = prev.*;

    //             const plus_result = prev_val +% value;
    //             std.debug.print("[{}] DOING FOR SUM({}): {} + {} = {}\n", .{ index, expression.key_ptr.*, prev_val, value, plus_result });
                
    //             const times_result = prev_val *% value;
    //             std.debug.print("[{}] DOING FOR SUM({}): {} * {} = {}\n", .{ index, expression.key_ptr.*, prev_val, value, times_result });
                
    //             const concat_result = try converter.concatenate(prev_val, value, allocator);
    //             std.debug.print("[{}] DOING FOR SUM({}): {} || {} = {}\n", .{ index, expression.key_ptr.*, prev_val, value, concat_result });


    //             try new_results.put(plus_result, {});
    //             try new_results.put(times_result, {});
    //             try new_results.put(concat_result, {});
    //         }

    //         if (new_results.contains(expression.key_ptr.*)) {
    //             sum_of_valid_values_with_concat += expression.key_ptr.*;
    //             std.debug.print("[{}] DOING FOR SUM({}): FOUND!\n", .{ index, expression.key_ptr.* });
    //         }

    //         // Transfer contents to possible_results instead of reassigning
    //         possible_results.clearRetainingCapacity();
    //         var new_res_iter = new_results.keyIterator();
    //         while (new_res_iter.next()) |key| {
    //             try possible_results.put(key.*, {});
    //         }
    //     }
    //      index += 1;
    // }

    

    // std.debug.print("<PART 1> SUM OF VALID VALUES: {}\n", .{ sum_of_valid_values });
    // std.debug.print("<PART 2> SUM OF VALID VALUES WITH CONCAT: {}\n", .{ sum_of_valid_values_with_concat });


    var optimalSum: u64 = 0;
    const ops: [3]*const fn(u64, u64)u64 = [_]*const fn(u64, u64)u64{ operations.add, operations.mul, operations.cat };

    for (optimalMatrix.items) |process| {
        optimalSum += try solve(process, ops, allocator);
    }

    std.debug.print("Result: {}\n", .{optimalSum}); 
}

fn solve(nums:  std.ArrayList(u64), ops: [3]*const fn(u64, u64) u64, allocator: std.mem.Allocator) !u64 {
    if (nums.items.len == 2) {
        // Base case: If the total equals the second number, return it
        return if (nums.items[0] == nums.items[1]) nums.items[0] else 0;
    }

    const total = nums.items[0];
    const a = nums.items[1];
    const b = nums.items[2];
    const rest: []u64 = nums.items[3..];

    // Try each operation
    for (ops) |op| {
        const new_result = op(a, b);
        var new_nums = std.ArrayList(u64).init(allocator);
        defer new_nums.deinit();
        try new_nums.append(total);
        try new_nums.append(new_result);
        try new_nums.appendSlice(rest);

        const result = try solve(new_nums, ops, allocator);  // Recurse with the new list
        if (result != 0) {
            return result;  // If result is non-zero, propagate it back
        }
    }

    // Return 0 if no valid sum was found
    return 0;
}