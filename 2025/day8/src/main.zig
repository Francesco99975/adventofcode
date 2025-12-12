const std = @import("std");
const List = @import("structlib").LinkedList;
const DList = @import("structlib").DoublyLinkedList;

const Coords = struct {
    x: isize,
    y: isize,
    z: isize,

    pub fn format(
        self: Coords,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: std.Io.Writer,
    ) !void {
        _ = fmt; // unused, but required by interface
        _ = options; // unused, but required by interface

        // Your custom formatting:
        try writer.print("({d}, {d}, {d})", .{ self.x, self.y, self.z });
    }
};

// Hashable symmetric pair
const CoordPair = struct {
    first: Coords,
    second: Coords,

    pub fn init(a: Coords, b: Coords) CoordPair {
        // Canonical ordering: smallest first
        if (CoordPair.lessThan(a, b)) {
            return .{ .first = a, .second = b };
        } else {
            return .{ .first = b, .second = a };
        }
    }

    pub fn distance(self: *CoordPair) usize {
        return std.math.sqrt(std.math.pow(usize, @abs(self.first.x - self.second.x), 2) + std.math.pow(usize, @abs(self.first.y - self.second.y), 2) + std.math.pow(usize, @abs(self.first.z - self.second.z), 2));
    }

    fn lessThan(a: Coords, b: Coords) bool {
        return a.x < b.x or (a.x == b.x and (a.y < b.y or (a.y == b.y and a.z < b.z)));
    }

    pub fn hash(self: CoordPair) u64 {
        var h = std.hash.Wyhash.init(0);
        h.update(std.mem.asBytes(&self.first));
        h.update(std.mem.asBytes(&self.second));
        return h.final();
    }

    pub fn eql(self: CoordPair, other: CoordPair) bool {
        return self.first.eql(other.first) and self.second.eql(other.second);
    }
};

fn hasCircuit(circuits: *const std.ArrayList(List(Coords)), box: Coords) bool {
    for (circuits.items) |*circuit| {
        if (circuit.has(box)) {
            return true;
        }
    }

    return false;
}

fn getCircuitIndex(circuits: *const std.ArrayList(List(Coords)), box: Coords) !usize {
    for (circuits.items, 0..) |*circuit, i| {
        if (circuit.has(box)) {
            return i;
        }
    }

    return error.NotFound;
}

fn hasCircuit2(circuits: *const std.ArrayList(DList(Coords)), box: Coords) bool {
    for (circuits.items) |*circuit| {
        if (circuit.has(box)) {
            return true;
        }
    }

    return false;
}

fn getCircuitIndex2(circuits: *const std.ArrayList(DList(Coords)), box: Coords) !usize {
    for (circuits.items, 0..) |*circuit, i| {
        if (circuit.has(box)) {
            return i;
        }
    }

    return error.NotFound;
}

fn ascPairDistances(_: void, a: CoordPair, b: CoordPair) bool {
    var ax = a;
    var by = b;
    return ax.distance() < by.distance();
}

fn descByListSize(_: void, a: List(Coords), b: List(Coords)) bool {
    return a.size > b.size;
}

pub fn main() !void {
    std.debug.print("STARTING DAY 8 - PART 1\n\n", .{});

    if (part1("data.txt", 1000)) |circuits_sum| {
        std.debug.print("Circuits Sum: {d}\n", .{circuits_sum});
    } else |err| {
        std.debug.print("There was an error with DAY 8 part 1 -> {}", .{err});
    }

    std.debug.print("\n\nSTARTING DAY 8 - PART 2\n\n", .{});

    if (part2("data.txt")) |last_x_sum| {
        std.debug.print("Last Xs Sum: {d}\n", .{last_x_sum});
    } else |err| {
        std.debug.print("There was an error with DAY 8 part 2 -> {}", .{err});
    }
}

fn part1(input: []const u8, max_connections: usize) !u32 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var junction_boxes: std.ArrayList(Coords) = .empty;
    defer junction_boxes.deinit(allocator);

    var distances = std.AutoHashMap(CoordPair, void).init(allocator);
    defer distances.deinit();

    var sortedDistances: std.ArrayList(CoordPair) = .empty;
    defer sortedDistances.deinit(allocator);

    var circuits: std.ArrayList(List(Coords)) = .empty;
    defer {
        for (circuits.items) |*circuit| {
            circuit.deinit();
        }
        circuits.deinit(allocator);
    }

    std.debug.print("Reading Coords\n", .{});

    while (try interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        var coords_builder: std.ArrayList([]const u8) = .empty;
        defer coords_builder.deinit(allocator);

        while (it.next()) |value| {
            try coords_builder.append(allocator, value);
        }

        if (coords_builder.items.len != 3) return error.InvalidCoords;

        const x = try std.fmt.parseInt(isize, coords_builder.items[0], 10);
        const y = try std.fmt.parseInt(isize, coords_builder.items[1], 10);
        const z = try std.fmt.parseInt(isize, coords_builder.items[2], 10);

        try junction_boxes.append(allocator, .{ .x = x, .y = y, .z = z });
    }

    std.debug.print("Collecting Sorted Unique Distances\n", .{});

    var pr = std.Progress.start(.{});
    pr.setName("Collecting..");

    for (junction_boxes.items, 0..) |box, i| {
        pr.setCompletedItems(junction_boxes.items.len - i);
        for (junction_boxes.items, 0..) |boxj, j| {
            if (i != j) {
                const pair = CoordPair.init(box, boxj);

                if (distances.contains(pair)) continue;

                try distances.put(pair, {});

                try sortedDistances.append(allocator, pair);
            }
        }

        pr.completeOne();
    }

    std.sort.pdq(CoordPair, sortedDistances.items, {}, ascPairDistances);

    pr.end();

    std.debug.print("Creating Circuits\n", .{});

    var connections: usize = 0;
    for (sortedDistances.items) |*pair| {
        if (connections == max_connections) break;
        std.debug.print("Distance between {any} and {any} is: {}\n", .{ pair.first, pair.second, pair.distance() });

        if (!hasCircuit(&circuits, pair.first) and !hasCircuit(&circuits, pair.second)) {
            var list = List(Coords).init(allocator);
            try list.prepend(pair.first);
            try list.prepend(pair.second);

            try circuits.append(allocator, list);
            std.debug.print("\nCreated new Circuit from pair\n\n", .{});
            connections += 1;
        } else if (hasCircuit(&circuits, pair.first) and !hasCircuit(&circuits, pair.second)) {
            const index = try getCircuitIndex(&circuits, pair.first);

            try circuits.items[index].prepend(pair.second);
            std.debug.print("\nConnected Second Box {any} to Box {any} in exisitng Circuit\n\n", .{ pair.second, pair.first });
            connections += 1;
        } else if (!hasCircuit(&circuits, pair.first) and hasCircuit(&circuits, pair.second)) {
            const index = try getCircuitIndex(&circuits, pair.second);

            try circuits.items[index].prepend(pair.first);
            std.debug.print("\nConnected First Box {any} to Box {any} in exisitng Circuit\n\n", .{ pair.first, pair.second });
            connections += 1;
        } else {
            var index_a = try getCircuitIndex(&circuits, pair.first);
            var index_b = try getCircuitIndex(&circuits, pair.second);
            connections += 1;
            if (index_a == index_b) {
                std.debug.print("\nBoth  are in the same Circuit\n\n", .{});
            } else {
                // ensure index_a < index_b (optional, just to make behavior predictable)
                if (index_b < index_a) std.mem.swap(usize, &index_a, &index_b);

                // pointer to destination circuit
                var dest_circuit = &circuits.items[index_a];

                // remove the other circuit
                var removed_list = circuits.swapRemove(index_b);

                // prepend nodes into the correct destination
                while (removed_list.pop()) |coords| {
                    try dest_circuit.prepend(coords);
                }

                removed_list.deinit(); // free memory
                std.debug.print("\nMerged circuits containing {any} and {any}\n\n", .{ pair.first, pair.second });
            }
        }
    }

    std.debug.print("Circuits created: {d}\n", .{circuits.items.len});

    std.sort.pdq(List(Coords), circuits.items, {}, descByListSize);

    var top_circuits_sum: u32 = 1;

    for (circuits.items) |circuit| {
        std.debug.print("Circuit Size: {d}\n", .{circuit.size});
    }

    std.debug.print("TOP Circuits Lengths\n", .{});

    for (0..3) |i| {
        const size = circuits.items[i].size;
        std.debug.print("Circuit Size: {d}\n", .{size});
        top_circuits_sum *= @intCast(size);
    }

    return top_circuits_sum;
}

test "DAY 8 TEST - PART 1" {
    const expected_result: u32 = 40;
    if (part1("test.txt", 10)) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 8 PART 1\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 8 PART 1 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 8 PART 1 -> {}\n", .{err});
    }
}

fn part2(input: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(input, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;

    var reader = file.reader(&buffer);
    const interface = &reader.interface;

    var gpa_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa_allocator.allocator();
    defer _ = gpa_allocator.deinit();

    var junction_boxes: std.ArrayList(Coords) = .empty;
    defer junction_boxes.deinit(allocator);

    var distances = std.AutoHashMap(CoordPair, void).init(allocator);
    defer distances.deinit();

    var sortedDistances: std.ArrayList(CoordPair) = .empty;
    defer sortedDistances.deinit(allocator);

    var circuits: std.ArrayList(DList(Coords)) = .empty;
    defer {
        for (circuits.items) |*circuit| {
            circuit.deinit();
        }
        circuits.deinit(allocator);
    }

    std.debug.print("Reading Coords\n", .{});

    while (try interface.takeDelimiter('\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ',');
        var coords_builder: std.ArrayList([]const u8) = .empty;
        defer coords_builder.deinit(allocator);

        while (it.next()) |value| {
            try coords_builder.append(allocator, value);
        }

        if (coords_builder.items.len != 3) return error.InvalidCoords;

        const x = try std.fmt.parseInt(isize, coords_builder.items[0], 10);
        const y = try std.fmt.parseInt(isize, coords_builder.items[1], 10);
        const z = try std.fmt.parseInt(isize, coords_builder.items[2], 10);

        try junction_boxes.append(allocator, .{ .x = x, .y = y, .z = z });
    }

    std.debug.print("Collecting Sorted Unique Distances\n", .{});

    for (junction_boxes.items, 0..) |box, i| {
        for (junction_boxes.items, 0..) |boxj, j| {
            if (i != j) {
                const pair = CoordPair.init(box, boxj);

                if (distances.contains(pair)) continue;

                try distances.put(pair, {});

                try sortedDistances.append(allocator, pair);
            }
        }
    }

    std.sort.pdq(CoordPair, sortedDistances.items, {}, ascPairDistances);

    std.debug.print("Creating Circuits\n", .{});

    var latest_xs_sum: u64 = 0;

    for (sortedDistances.items) |*pair| {
        std.debug.print("Distance between {any} and {any} is: {}\n", .{ pair.first, pair.second, pair.distance() });

        if (!hasCircuit2(&circuits, pair.first) and !hasCircuit2(&circuits, pair.second)) {
            var list = DList(Coords).init(allocator);
            try list.append(pair.first);
            try list.append(pair.second);

            const x1: u64 = @intCast(pair.first.x);
            const x2: u64 = @intCast(pair.second.x);

            latest_xs_sum = x1 * x2;

            try circuits.append(allocator, list);
            std.debug.print("\nCreated new Circuit from pair\n\n", .{});
        } else if (hasCircuit2(&circuits, pair.first) and !hasCircuit2(&circuits, pair.second)) {
            const index = try getCircuitIndex2(&circuits, pair.first);

            try circuits.items[index].append(pair.second);
            const x1: u64 = @intCast(pair.first.x);
            const x2: u64 = @intCast(pair.second.x);

            latest_xs_sum = x1 * x2;
            std.debug.print("\nConnected Second Box {any} to Box {any} in exisitng Circuit\n\n", .{ pair.second, pair.first });
        } else if (!hasCircuit2(&circuits, pair.first) and hasCircuit2(&circuits, pair.second)) {
            const index = try getCircuitIndex2(&circuits, pair.second);

            try circuits.items[index].append(pair.first);
            const x1: u64 = @intCast(pair.first.x);
            const x2: u64 = @intCast(pair.second.x);

            latest_xs_sum = x1 * x2;
            std.debug.print("\nConnected First Box {any} to Box {any} in exisitng Circuit\n\n", .{ pair.first, pair.second });
        } else {
            var index_a = try getCircuitIndex2(&circuits, pair.first);
            var index_b = try getCircuitIndex2(&circuits, pair.second);

            if (index_a == index_b) {
                std.debug.print("\nBoth  are in the same Circuit\n\n", .{});
            } else {
                // ensure index_a < index_b (optional, just to make behavior predictable)
                if (index_b < index_a) std.mem.swap(usize, &index_a, &index_b);

                // pointer to destination circuit
                var dest_circuit = &circuits.items[index_a];

                // remove the other circuit
                var removed_list = circuits.swapRemove(index_b);

                // prepend nodes into the correct destination
                while (removed_list.pop()) |coords| {
                    try dest_circuit.append(coords);
                }

                const x1: u64 = @intCast(pair.first.x);
                const x2: u64 = @intCast(pair.second.x);

                latest_xs_sum = x1 * x2;

                removed_list.deinit(); // free memory
                std.debug.print("\nMerged circuits containing {any} and {any}\n\n", .{ pair.first, pair.second });
            }
        }
    }

    return latest_xs_sum;
}

test "DAY 8 TEST - PART 2" {
    const expected_result: u64 = 25272;
    if (part2("test.txt")) |result| {
        if (std.testing.expectEqual(expected_result, result)) |_| {
            std.debug.print("Test PASSED FOR DAY 8 PART 2\n", .{});
        } else |err| {
            std.debug.print("Test FAILED FOR DAY 8 PART 2 -> {}\n", .{err});
        }
    } else |err| {
        std.debug.print("Test FAILED FOR DAY 8 PART 2 -> {}\n", .{err});
    }
}
