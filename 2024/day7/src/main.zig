const std = @import("std");
const symbols = @import("constants/symbols.zig");
const generator = @import("utils/generator.zig");
const Calculation = @import("models/calculations.zig").Calculation;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("test.txt", .{});

    const stream = file.reader();

    // Create a matrix: an ArrayList of ArrayLists
    var expressions = std.AutoArrayHashMap(u64, Calculation()).init(allocator);

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);
        // Split the line into two parts
        var tokenizer = std.mem.tokenize(u8, line, " ");
        
        var sum_buffer = tokenizer.next() orelse "";
        const sum = try std.fmt.parseInt(u64, sum_buffer[0..sum_buffer.len-1], 10);

        

        var calculation = Calculation().init(&allocator);

        while (tokenizer.next()) |token| {
            const part: u64 = try std.fmt.parseInt(u64, token, 10);
            try calculation.values.enqueue(part);
        }

        const result = try expressions.getOrPut(sum);
        if(result.found_existing) std.debug.print("This Ain't it Chief", .{});
        result.value_ptr.* = calculation;
    }

    var it = expressions.iterator();

    var sum_of_valid_values: u64 = 0;

    var sum_of_valid_values_with_concat: u64 = 0;


    while (it.next()) |expression| {
       try generator.generatePossibleOperations(expression.value_ptr.*.values.size - 1, &expression.value_ptr.*.operations, &allocator); 
       std.debug.print("SUM {} OPS:\n", .{expression.key_ptr.* });

        if(try expression.value_ptr.isSummableTo(expression.key_ptr.*, &allocator)) {
            sum_of_valid_values += expression.key_ptr.*;
        }

        expression.value_ptr.operations.clearRetainingCapacity();
    }

    it.reset();

    std.debug.print("\nRESETTING\n\n", .{});

    while (it.next()) |expression| {
       try generator.generatePossibleOperationsV2(expression.value_ptr.*.values.size - 1, &expression.value_ptr.*.operations, &allocator); 
       std.debug.print("SUM {} OPS:\n", .{expression.key_ptr.* });

        if(try expression.value_ptr.isSummableTo(expression.key_ptr.*, &allocator)) {
            sum_of_valid_values_with_concat += expression.key_ptr.*;
        }

        expression.value_ptr.operations.clearAndFree();
    }
    

    std.debug.print("<PART 1> SUM OF VALID VALUES: {}\n", .{ sum_of_valid_values });
     std.debug.print("<PART 2> SUM OF VALID VALUES WITH CONCAT: {}\n", .{ sum_of_valid_values_with_concat });
}