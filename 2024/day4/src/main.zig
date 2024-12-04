const std = @import("std");
const Queue = @import("models/queue.zig").Queue;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();

    // Create a matrix: an ArrayList of ArrayLists
    var matrix = std.ArrayList(std.ArrayList(u8)).init(allocator);

    defer {
        // Clean up all rows first
        for (matrix.items) |row| {
            row.deinit();
        }
        // Then clean up the outer ArrayList
        matrix.deinit();
    }

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        var row = std.ArrayList(u8).init(allocator);

        for (line) |char| {
            try row.append(char);
        }

        try matrix.append(row);
    }

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};

    const gpa = general_purpose_allocator.allocator();

    var processer = Queue(u8).init(gpa);

    var xmas_counter: u32 = 0;
    var counter_snapshot: u32 = 0;


    //Horizontal Traversal

    for (matrix.items) |row| {
        for (row.items) |value| {
            std.debug.print(" {c} ", .{value});
            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }
        }
        processer.clear();
        std.debug.print("\n", .{});
    }
    
    std.debug.print("Horizonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot });
    counter_snapshot = xmas_counter;
    processer.clear();

    //Diagonal Traversal

     // Get dimensions of the matrix
    const rows = matrix.items.len;
    const cols: usize = if (rows > 0) matrix.items[0].items.len else 0;

    // 1. Traverse diagonals starting from the first column of each row
    for (0..rows) |start_row| {
        var r = start_row;
        var c: usize = 0;
        while (r < rows and c < cols) {
            const value = matrix.items[r].items[c];

            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

            
            r += 1;
            c +=1;
        }
        processer.clear();
    }

    std.debug.print("Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot });
    counter_snapshot = xmas_counter;

    processer.clear();

    // Diagonals starting from the top row
    for (1..cols) |start_col| { // Exclude the first column since it was handled
        var r: usize = 0;
        var c = start_col;
        while (r < rows and c < cols) {
            const value = matrix.items[r].items[c];

            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                        xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

            r += 1;
            c += 1;
        }
        processer.clear();
    }

    std.debug.print("Additional Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot });
    counter_snapshot = xmas_counter;

    processer.clear();

    //Anti Diagonal 

    // Diagonals starting from the first column
    for (0..rows) |start_row| {
        var r: isize = @intCast(start_row);
        var c: usize = 0;
        while (r >= 0 and c < cols) {
            const value = matrix.items[@intCast(r)].items[c];

            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                        xmas_counter += 1;
                }

                _ = processer.dequeue();
            }
            r -= 1;
            c += 1;
        }
        processer.clear();
    }

    std.debug.print("Anti Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot });
    counter_snapshot = xmas_counter;

    processer.clear();

    // Diagonals starting from the bottom row
    for (1..cols) |start_col| { // Exclude the first column since it was handled
        var r: usize = rows - 1;
        var c = start_col;
        while (r >= 0 and c < cols) {
            const value = matrix.items[r].items[c];

            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                        xmas_counter += 1;
                }

                _ = processer.dequeue();
            }
            r -= 1;
            c += 1;
        }
        processer.clear();
    }

    std.debug.print("Additional Anti Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot });
    counter_snapshot = xmas_counter;

    processer.clear();


    //Horizontal Reversed Traversal + Reversed Matrix Creation
    var reversedMatrix = std.ArrayList(std.ArrayList(u8)).init(allocator);

    var clonedMatrix = try matrix.clone();

    while (clonedMatrix.popOrNull()) |row| {
        var mutable_row = row;
        var rr = std.ArrayList(u8).init(allocator);
        while (mutable_row.popOrNull()) |value| {
            try rr.append(value);
            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }
        }
        try reversedMatrix.append(rr);
        processer.clear();
    }

     std.debug.print("Reversed Horizonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot});
     counter_snapshot = xmas_counter;

    processer.clear();

    //Reversed Diagonal Traversal

    // Diagonals starting from the last column
    for (0..rows) |start_row| {
        var r = start_row;
        var c: isize = @intCast(cols - 1);
        while (r < rows and c >= 0) {
            const value = matrix.items[r].items[@intCast(c)];
            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }
            r += 1;
            c -= 1;
        }
        processer.clear();
    }

    std.debug.print("Reversed Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot});
    processer.clear();
    counter_snapshot = xmas_counter;

    // Diagonals starting from the top row
    for (0..cols - 1) |start_col| { // Exclude the last column since it was handled
        var r: usize = 0;
        var c: isize = @intCast(start_col);
        while (r < rows and c >= 0) {
            const value = matrix.items[r].items[@intCast(c)];
            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

            r += 1;
            c -= 1;
        }
        processer.clear();
    }

    std.debug.print("Additional Reversed Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot});
    processer.clear();
    counter_snapshot = xmas_counter;

    // Diagonals starting from the last column
    for (0..rows) |start_row| {
        var r: isize = @intCast(start_row);
        var c: isize = @intCast(cols - 1);
        while (r >= 0 and c >= 0) {
            const value = matrix.items[@intCast(r)].items[@intCast(c)];
            
             try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

            r -= 1;
            c -= 1;
        }
        processer.clear();
    }

    std.debug.print("Anti Reversed Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot});
    processer.clear();
    counter_snapshot = xmas_counter;

    // Diagonals starting from the bottom row
    for (0..cols - 1) |start_col| { // Exclude the last column since it was handled
        var r: isize = @intCast(rows - 1);
        var c: isize = @intCast(start_col);
        while (r >= 0 and c >= 0) {
            const value = matrix.items[@intCast(r)].items[@intCast(c)];
           
             try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

            r -= 1;
            c -= 1;
        }
        processer.clear();
    }

    std.debug.print("Additional Anti Reversed Diagonal Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot});
    processer.clear();
    counter_snapshot = xmas_counter;

    //Vertical Traversal
    for (0..cols) |col| { // For each column
        for (0..rows) |row| { // For each row in the column
            const value = matrix.items[row].items[col];
            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

        }
        processer.clear();
    }


    std.debug.print("Vertical Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot });
    counter_snapshot = xmas_counter;
    processer.clear();

    //Reverse Vertical Traersal
    for (0..cols) |col| { // For each column
        for (0..rows) |row| { // For each row in the column
            const value = reversedMatrix.items[row].items[col];
            try processer.enqueue(value);


            if(processer.size == 4) {
                if (std.mem.eql(u8, processer.getViewV2(4), "XMAS")) {         
                    xmas_counter += 1;
                }

                _ = processer.dequeue();
            }

        }
        processer.clear();
    }

     std.debug.print("Reverse Vertical Traversal Counter: {}\n", .{ xmas_counter - counter_snapshot});
     counter_snapshot = xmas_counter;
     processer.clear();

    std.debug.print("XMAS COUNTER = {}\n", .{ xmas_counter });

}
