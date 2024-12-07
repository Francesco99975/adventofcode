const std = @import("std");
const symbols = @import("../constants/symbols.zig");
const converter = @import("../utils/converter.zig");
const Queue =  @import("queue.zig").Queue;

pub fn Calculation() type {
  return struct {
    const This = @This();

    values: Queue(u64),
    operations: std.ArrayList(std.ArrayList(u8)),

    pub fn init(allocator: *const std.mem.Allocator) This {
      return This {
        .values = Queue(u64).init(allocator),
        .operations = std.ArrayList(std.ArrayList(u8)).init(allocator.*),
      };
    }

    pub fn isSummableTo(this: *This, sum: u64, allocator: *const std.mem.Allocator) !bool {
      for(this.operations.items) |operation| {
         var tmp_values = try this.values.copy();
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
                compare_sum = try converter.concatenate(compare_sum, value, allocator);
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