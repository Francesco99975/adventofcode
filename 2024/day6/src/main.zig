const std = @import("std");
const coords = @import("models/coords.zig");
const renderer = @import("helpers/renderer.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data.txt", .{});

    const stream = file.reader();

    // Create a matrix: an ArrayList of ArrayLists
    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);

    defer {
        // Clean up all rows first
        for (map.items) |row| {
            row.deinit();
        }
        // Then clean up the outer ArrayList
        map.deinit();
    }

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        var row = std.ArrayList(u8).init(allocator);

        for (line) |char| {
            try row.append(char);
        }

        try map.append(row);
    }

    var guard = try coords.findGuard(&map, coords.GUARD_ICON);

    std.debug.print("Guard Starting Coords --> x:{} / y:{}\n", .{ guard.x, guard.y });

    try part1(&guard, &map, &allocator);
}


fn part1(guard: *coords.Guard(), map: *std.ArrayList(std.ArrayList(u8)), allocator: *const std.mem.Allocator) !void {
    var set = std.StringHashMap(void).init(allocator.*);

    while (guard.inBoundsOf(map)) {
        try renderer.clearScreen();
        //Mutate Map with grard's new position
        map.items[@intCast(guard.y)].items[@intCast(guard.x)] = coords.GUARD_ICON;

        // renderer.renderMatrix(map);

        // Sleep for 500ms to simulate a delay between iterations
        // std.time.sleep(1 * std.time.ns_per_ms);

        //Mutate Map with grard's step
        map.items[@intCast(guard.y)].items[@intCast(guard.x)] = coords.GUARD_STEP;

        try set.put(try guard.getCoordsFingerprint(&allocator.*), {});
        if(guard.isThereObstacle(map, '#')) {
            guard.rotateClockwise();
        }

        guard.goForward();
    }

    renderer.renderMatrix(map);

    std.debug.print("\nGuard Stopping Coords --> x:{} / y:{}\n", .{ guard.x, guard.y });

    std.debug.print("<PART 1> Guard's Number of Visited Coords: {}\n", .{ set.count() });
}

