const std = @import("std");
const coords = @import("models/coords.zig");
const renderer = @import("helpers/renderer.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("test.txt", .{});

    const stream = file.reader();

    // Create a matrix: an ArrayList of ArrayLists
    var map = std.ArrayList(std.ArrayList(u8)).init(allocator);
    var map2 = std.ArrayList(std.ArrayList(u8)).init(allocator);

    defer {
        // Clean up all rows first
        for (map.items) |row| {
            row.deinit();
        }
        // Then clean up the outer ArrayList
        map.deinit();
    }

    defer {
        // Clean up all rows first
        for (map2.items) |row| {
            row.deinit();
        }
        // Then clean up the outer ArrayList
        map2.deinit();
    }


    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '\n', 1024)) |line| {
        defer allocator.free(line);

        var row = std.ArrayList(u8).init(allocator);
        var row2 = std.ArrayList(u8).init(allocator);

        for (line) |char| {
            try row.append(char);
            try row2.append(char);
        }

        try map.append(row);
        try map2.append(row2);
    }

    var guard = try coords.findGuard(&map, coords.GUARD_ICON);
    var guard2 = try coords.findGuard(&map, coords.GUARD_ICON);

    std.debug.print("Guard Starting Coords --> x:{} / y:{}\n", .{ guard.x, guard.y });

    try part1(&guard, &map, &allocator);

    try part2Dirty(&guard2, &map2,&allocator);
}

fn part2Dirty(guard: *coords.Guard(), map: *std.ArrayList(std.ArrayList(u8)), allocator: *const std.mem.Allocator) !void {
    var placeble_looping_obstacles: u32 = 0;
    var visited = std.StringHashMap(void).init(allocator.*);
    defer visited.deinit();

    for (map.items, 0..) |row, i| {
        for (row.items, 0..) |_, j| {
            if(map.items[i].items[j] != coords.OBSTACLE and map.items[i].items[j] != coords.GUARD_ICON and map.items[i].items[j] != coords.EXTRA_OBSTACLE) {
                
                map.items[i].items[j] = coords.OBSTACLE;
                var ghost = guard.*;

                var looper: u32 = 0;
            
                while (ghost.inBoundsOf(map)) {
                    // try renderer.clearScreen();
                    visited.clearRetainingCapacity();
                    
                    //Mutate Map with guard's new position
                    if(map.items[@intCast(ghost.y)].items[@intCast(ghost.x)] != coords.EXTRA_OBSTACLE) {
                        map.items[@intCast(ghost.y)].items[@intCast(ghost.x)] = coords.GUARD_ICON;
                    }
                    

                    renderer.renderMatrix(map);
                    // //Sleep for 500ms to simulate a delay between iterations
                    std.time.sleep(10 * std.time.ns_per_ms);

                    
                    //Mutate Map with guard's step
                    if(map.items[@intCast(ghost.y)].items[@intCast(ghost.x)] != coords.EXTRA_OBSTACLE) {
                        map.items[@intCast(ghost.y)].items[@intCast(ghost.x)] = '.';
                    }

                    // Gets string representation of coords and direction
                    // const key = try ghost.getDirectionalCoordsFingerprint(&allocator.*);

                    // const result = try visited.getOrPut(key);
                        if(looper > map.items.len * map.items[@intCast(ghost.y)].items.len) {
                            placeble_looping_obstacles += 1;
                            map.items[i].items[j] = coords.EXTRA_OBSTACLE;
                            break;   
                        }
                    

                    while(ghost.isThereObstacle(map, coords.OBSTACLE)) {
                        _ = ghost.rotateClockwise();
                    }
                    

                    ghost.goForward();
                    looper += 1;
                }

                //Mutate Map with guard's new position
                if(map.items[i].items[j] != coords.EXTRA_OBSTACLE) {
                     map.items[i].items[j] = '.';
                }
            }
        }
    }

    renderer.renderMatrix(map);

    std.debug.print("<DIRTY PART 2> Possible Looping Extra Obstacles Coords Amount: {}\n", .{ placeble_looping_obstacles });
}

fn part2(guard: *coords.Guard(), map: *std.ArrayList(std.ArrayList(u8))) !void {
    var placeble_looping_obstacles: u32 = 0;

    while (guard.inBoundsOf(map)) {
        try renderer.clearScreen();

        //Mutate Map with guard's new position
        if(map.items[@intCast(guard.y)].items[@intCast(guard.x)] != coords.EXTRA_OBSTACLE) {
            map.items[@intCast(guard.y)].items[@intCast(guard.x)] = coords.GUARD_ICON;
        }
        

        renderer.renderMatrix(map);

        // Sleep for 500ms to simulate a delay between iterations
        std.time.sleep(500 * std.time.ns_per_ms);

        
        //Mutate Map with guard's step
        if(map.items[@intCast(guard.y)].items[@intCast(guard.x)] != coords.EXTRA_OBSTACLE) {
            map.items[@intCast(guard.y)].items[@intCast(guard.x)] = coords.GUARD_STEP;
         }
        
        
        if(guard.isThereObstacle(map, coords.OBSTACLE)) {
            const maybeLoopLen = guard.rotateClockwise();

            if(maybeLoopLen) |loopLen| {
                if(guard.isInBoundsAhead(map, loopLen)) {
                    std.debug.print("\nPossible Extra Obstacle Coords {} AHEAD OF --> x:{} / y:{}\n", .{ loopLen, guard.x, guard.y });

                    // Mutate Map with extra obstacle
                    switch (guard.direction) {
                        coords.Directions.UP => map.items[@intCast(guard.y - loopLen)].items[@intCast(guard.x)] = coords.EXTRA_OBSTACLE,
                        coords.Directions.RIGHT => map.items[@intCast(guard.y)].items[@intCast(guard.x + loopLen)] = coords.EXTRA_OBSTACLE,
                        coords.Directions.DOWN => map.items[@intCast(guard.y + loopLen)].items[@intCast(guard.x)] = coords.EXTRA_OBSTACLE,
                        coords.Directions.LEFT => map.items[@intCast(guard.y)].items[@intCast(guard.x - loopLen)] = coords.EXTRA_OBSTACLE,
                    }

                    placeble_looping_obstacles += 1;
                } else {
                    std.debug.print("\nPossible Extra Obstacle Coords {} AHEAD OF --> x:{} / y:{} NOT IN BOUNDS\n", .{ loopLen, guard.x, guard.y });
                }
            }
        }

        guard.goForward();
    }

    renderer.renderMatrix(map);

    std.debug.print("<PART 2> Possible Looping Extra Obstacles Coords Amount: {}\n", .{ placeble_looping_obstacles });
}


fn part1(guard: *coords.Guard(), map: *std.ArrayList(std.ArrayList(u8)), allocator: *const std.mem.Allocator) !void {
    var set = std.StringHashMap(void).init(allocator.*);
    defer set.deinit();

    while (guard.inBoundsOf(map)) {
        try renderer.clearScreen();

        //Mutate Map with guard's new position
        map.items[@intCast(guard.y)].items[@intCast(guard.x)] = coords.GUARD_ICON;

        renderer.renderMatrix(map);

        // Sleep for 500ms to simulate a delay between iterations
        std.time.sleep(150 * std.time.ns_per_ms);

        //Mutate Map with guard's step
        map.items[@intCast(guard.y)].items[@intCast(guard.x)] = coords.GUARD_STEP;

        try set.put(try guard.getCoordsFingerprint(&allocator.*), {});
        if(guard.isThereObstacle(map, coords.OBSTACLE)) {
            _ = guard.rotateClockwise();
        }

        guard.goForward();
    }

    renderer.renderMatrix(map);

    std.debug.print("\nGuard Stopping Coords --> x:{} / y:{}\n", .{ guard.x, guard.y });

    std.debug.print("<PART 1> Guard's Number of Visited Coords: {}\n", .{ set.count() });
}

