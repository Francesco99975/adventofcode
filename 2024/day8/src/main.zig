const std = @import("std");
const Antenna = @import("models/antenna.zig").Antenna;
const Coord = @import("models/antenna.zig").Coord;
const symbols = @import("constants/symbols.zig");
const util = @import("utils/util.zig");

pub fn main() !void {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit(); // Clean up at the end of `main`
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();

    var antennas = std.ArrayList(Antenna()).init(allocator);
    defer antennas.deinit();

    // var antinodes = std.ArrayList(Coord).init(allocator);
    // defer antinodes.deinit();

    var y: usize = 0;
    var mx: usize = 0;
    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        for (line, 0..) |char, x| {
            if(char != '.' and char != symbols.ANTINODE) {
                try antennas.append(Antenna(){ .frequency = char, .position = Coord{ .x = x, .y = y } });
            }

            // if(char == symbols.ANTINODE) {
            //     try antinodes.append(Coord{ .x = x, .y = y });
            // }
            mx += 1;
        }
        y += 1;
    }

    file.close();

    _ = try part_one(&antennas, y, mx/y);
    _  = try part_two(&antennas, y, mx/y);
}


fn part_two(antennas: *std.ArrayList(Antenna()), maxY: usize, maxX: usize) !u32 {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit(); // Clean up at the end of `main`

    var antinodes = std.AutoHashMap(isize, void).init(allocator);
    defer antinodes.deinit();

    std.debug.print("MAX X: {}\n", .{maxX});
    std.debug.print("MAX Y: {}\n", .{maxY});

    for (0..antennas.items.len) |i| {
        for (0..antennas.items.len) |j| {
            if (antennas.items[i].frequency != antennas.items[j].frequency) continue; // Frequencies must match
            if (antennas.items[i].position.x == antennas.items[j].position.x and antennas.items[i].position.y == antennas.items[j].position.y) continue; // Skip same antenna

            const ax: isize = @intCast(antennas.items[i].position.x);
            const ay: isize = @intCast(antennas.items[i].position.y);
            const bx: isize = @intCast(antennas.items[j].position.x);
            const by: isize = @intCast(antennas.items[j].position.y);

            var buffer: [32]u8 = undefined;

            // var midX_a: isize = ax;
            // var midY_a: isize = ay;    

            // while (midX_a >= 0 and midY_a >= 0 and midX_a < maxX and midY_a < maxY) {
            //     // Add midpoint A to antinodes
            //     const key_a = try std.fmt.bufPrint(&buffer, "{}|{}", .{ midX_a, midY_a });
            //     std.debug.print("FOUND ANTINODE: {s} based on Antennas {}|{} and {}|{}\n", .{ key_a, ax,ay,bx,by });
            //     try antinodes.put(util.cat(util.cat(midX_a+1,  1), midY_a+1), {});
            //     midX_a += ax + bx;
            //     midY_a += ay + by;    
            // }


            const dx = bx - ax;
            const dy = by - ay;

            
            var midX_b: isize = ax;
            var midY_b: isize = ay;    

            while (midX_b >= 0 and midY_b >= 0 and midX_b < maxX and midY_b < maxY) {
                // Add midpoint B to antinodes
                const key_b = try std.fmt.bufPrint(&buffer, "{}|{}", .{ midX_b, midY_b });
                std.debug.print("FOUND ANTINODE: {s} based on Antennas {}|{} and {}|{}\n", .{ key_b, ax,ay,bx,by });
                try antinodes.put(util.cat(util.cat(midX_b+1,  1), midY_b+1), {});
                midX_b += dx;
                midY_b += dy;    
            }
        }
    }

    std.debug.print("\n<PART 2> UNIQUE ANTINODES: {}\n", .{ antinodes.count() });

    for (0..maxY) |y| {
        for(0..maxX) |x| {
            const xx: isize = @intCast(x);
            const yy: isize = @intCast(y);
            const cmp = util.cat(util.cat(xx+1,  1), yy+1);
            const v: u8 = if (antinodes.contains(cmp)) symbols.ANTINODE else '.';
            std.debug.print("{c}", .{v});
        }
        std.debug.print("\n", .{});
    }

    return antinodes.count();
}

fn part_one(antennas: *std.ArrayList(Antenna()), maxY: usize, maxX: usize) !u32 {
    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit(); // Clean up at the end of `main`

    var antinodes = std.AutoHashMap(isize, void).init(allocator);
    defer antinodes.deinit();

    std.debug.print("MAX X: {}\n", .{maxX});
    std.debug.print("MAX Y: {}\n", .{maxY});

    for (0..antennas.items.len) |i| {
        for (i+1..antennas.items.len) |j| {
            if (antennas.items[i].frequency != antennas.items[j].frequency) continue; // Frequencies must match
            if (antennas.items[i].position.x == antennas.items[j].position.x and antennas.items[i].position.y == antennas.items[j].position.y) continue; // Skip same antenna

            const ax: isize = @intCast(antennas.items[i].position.x);
            const ay: isize = @intCast(antennas.items[i].position.y);
            const bx: isize = @intCast(antennas.items[j].position.x);
            const by: isize = @intCast(antennas.items[j].position.y);


            // Check if b is twice as far away from a
            // const distX: isize = @intCast(@abs(bx - ax));
            // const distY: isize = @intCast(@abs(by - ay));
            // // if (distX - distY >= 2 and distY - distX >= 2) continue; // Skip if not twice as far

            // if (!(distX == 2 * distY or distY == 2 * distX)) continue;

            // const la = if(antennas.items[i].position.x < antennas.items[j].position.x) antennas.items[i].position else antennas.items[j].position;
            // const ma = if(antennas.items[i].position.x > antennas.items[j].position.x) antennas.items[i].position else antennas.items[j].position;

            // const lax: isize = @intCast(la.x);
            // const lay: isize = @intCast(la.y);
            // const max: isize = @intCast(ma.x);
            // const may: isize = @intCast(ma.y);

            // Calculate a antinode position (midX, midY) that is perfectly in line with a

            const midX_a: isize = 2 * ax - bx;
            const midY_a: isize = 2 * ay - by;

            // Calculate a antinode position (midX, midY) that is perfectly in line with b but on the opposite side

            const midX_b: isize = 2 * bx - ax;
            const midY_b: isize = 2 * by - ay;


            // for(known.items) |antinode| {
            //     if(antinode.x == midX_a and antinode.y == midY_a) {
            //         std.debug.print("[*]", .{});
            //     }
            // }

            var buffer: [32]u8 = undefined;
            
            // Add midpoint A to antinodes
            if (midX_a >= 0 and midY_a >= 0 and midX_a < maxX and midY_a < maxY) {
                const key_a = try std.fmt.bufPrint(&buffer, "{}|{}", .{ midX_a, midY_a });
                std.debug.print("FOUND ANTINODE: {s} based on Antennas {}|{} and {}|{}\n", .{ key_a, ax,ay,bx,by });
            
                try antinodes.put(util.cat(util.cat(midX_a+1, 1), midY_a+1), {});
            }

            if (midX_b < 0 or midY_b < 0 or midX_b >= maxX or midY_b >= maxY) continue;

            // for(known.items) |antinode| {
            //     if(antinode.x == midX_b and antinode.y == midY_b) {
            //         std.debug.print("[*]", .{});
            //     }
            // }


            // Add midpoint B to antinodes
            const key_b = try std.fmt.bufPrint(&buffer, "{}|{}", .{ midX_b, midY_b });
            std.debug.print("FOUND ANTINODE: {s} based on Antennas {}|{} and {}|{}\n", .{ key_b, ax,ay,bx,by });
            try antinodes.put(util.cat(util.cat(midX_b+1,  1), midY_b+1), {});
        }
    }

    std.debug.print("\n<PART 1> UNIQUE ANTINODES: {}\n", .{ antinodes.count() });

    return antinodes.count();
}


test "part_one_test" {
    const file = try std.fs.cwd().openFile("test.txt", .{});

    const stream = file.reader();

    const allocator = std.testing.allocator;

    var antennas = std.ArrayList(Antenna()).init(allocator);
    defer antennas.deinit();


    var y: usize = 0;
    var mx: usize = 0;
    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        for (line, 0..) |char, x| {
            if(char != '.' and char != symbols.ANTINODE) {
                try antennas.append(Antenna(){ .frequency = char, .position = Coord{ .x = x, .y = y } });
            }

            // if(char == symbols.ANTINODE) {
            //     try antinodes.append(Coord{ .x = x, .y = y });
            // }
            mx += 1;
        }
        y += 1;
    }

    file.close();

    const antinodes_amount = try part_one(&antennas, y, mx/y);

    try std.testing.expectEqual(14, antinodes_amount);
} 

test "part_two_test" {
    const file = try std.fs.cwd().openFile("test2.txt", .{});

    const stream = file.reader();

    const allocator = std.testing.allocator;

    var antennas = std.ArrayList(Antenna()).init(allocator);
    defer antennas.deinit();


    var y: usize = 0;
    var mx: usize = 0;
    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        for (line, 0..) |char, x| {
            if(char != '.' and char != symbols.ANTINODE) {
                try antennas.append(Antenna(){ .frequency = char, .position = Coord{ .x = x, .y = y } });
            }

            // if(char == symbols.ANTINODE) {
            //     try antinodes.append(Coord{ .x = x, .y = y });
            // }
            mx += 1;
        }
        y += 1;
    }

    file.close();

    const antinodes_amount = try part_two(&antennas, y, mx/y);

    try std.testing.expectEqual(34, antinodes_amount);
} 