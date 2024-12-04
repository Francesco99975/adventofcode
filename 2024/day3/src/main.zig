const std = @import("std");
const Payload = @import("models/payload.zig").Payload;
const PayloadV2 = @import("models/payload.zig").PayloadV2;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();

    const stream = file.reader();

    var payload = Payload(u32).init();

    var payloadV2 = PayloadV2(u32).init();

    var sum: u32 = 0;

    var sumV2: u32 = 0;

    while (try stream.readUntilDelimiterOrEofAlloc(allocator, '%', 1024)) |line| {
        defer allocator.free(line);

        for (line) |token| {
            // std.debug.print("Processing token: {} \n", .{token});
            if (payload.processToken(token)) |value| {
                sum += value;
            }

            if (payloadV2.processToken(token)) |value| {
                sumV2 += value;
            }
        }
    }

    std.debug.print("\n< PART 1 > SUM OF MULTIPLICATIONS: {}\n", .{sum});
    std.debug.print("\n< PART 2 > SUM OF MULTIPLICATIONS WITH SWITCHES: {}\n", .{sumV2});
}
