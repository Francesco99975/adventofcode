const std = @import("std");
const symbols = @import("../constants/symbols.zig");
const converter = @import("../utils/converter.zig");
const Queue =  @import("queue.zig").Queue;

pub fn Calculation() type {
  return struct {
    const This = @This();

    allocator: std.mem.Allocator,
    values: Queue(u64),
    operations: std.ArrayList(std.ArrayList(u8)),

    pub fn init(allocator: std.mem.Allocator) This {
      return This {
        .allocator = allocator,
        .values = Queue(u64).init(allocator),
        .operations = std.ArrayList(std.ArrayList(u8)).init(allocator),
      };
    }

    pub fn deinit(this: *This) void {
      for (this.operations.items) |op| {
          op.deinit();
      }
      this.operations.deinit();
      this.values.deinit(); // Ensure the queue is properly cleared
  }

    pub fn isSummableTo(this: *This, sum: u64) !bool {
      for(this.operations.items) |operation| {
         var tmp_values = try this.values.copy();
         defer tmp_values.deinit();
        var compare_sum: u64 = tmp_values.dequeue() orelse 0;
      
         
         var symbol_index: usize = 0;
          while (tmp_values.dequeue()) |value| {
              const symbol = operation.items[symbol_index];
   
              if(symbol == symbols.ADDITION) {
                std.debug.print("DOING FOR SUM({}): {} + {} = {}\n", .{ sum, compare_sum, value, compare_sum + value });
                compare_sum += value;
              }

              if(symbol == symbols.MULTIPLICATION) {
                std.debug.print("DOING FOR SUM({}): {} * {} = {}\n", .{ sum, compare_sum, value, compare_sum * value });
                compare_sum *= value;
              }

              if(symbol == symbols.CONCATENATION) {
                const ex_copmpare_sum = compare_sum; // For visual ONLY
                compare_sum = try converter.concatenate(compare_sum, value, this.allocator);
                std.debug.print("DOING FOR SUM({}): {} || {} = {}\n", .{ sum, ex_copmpare_sum, value, compare_sum });
              }
              symbol_index += 1;
          }


          std.debug.print("COMPARE_SUM({}) VS SUM({})\n", .{ compare_sum, sum });

          if(compare_sum == sum) return true;
      }

      return false;
    }
  };
}