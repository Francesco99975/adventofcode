const std = @import("std");
const symbols = @import("../constants/symbols.zig");
const converter = @import("../utils/converter.zig");
const Stack =  @import("stack.zig").Stack;

pub fn Calculation() type {
  return struct {
    const This = @This();

    values: Stack(u64),
    operations: std.ArrayList(std.ArrayList(u8)),

    pub fn init(allocator: *const std.mem.Allocator) This {
      return This {
        .values = Stack(u64).init(allocator),
        .operations = std.ArrayList(std.ArrayList(u8)).init(allocator.*),
      };
    }

    pub fn isSummableTo(this: *This, sum: u64, allocator: *std.mem.Allocator) !bool {
      for(this.operations.items) |operation| {
         var tmp_values = try this.values.copy();
          tmp_values.reverse();
          var compare_sum: u64 = tmp_values.pop() orelse 0;
      
         
         var symbol_index: usize = 0;
          while (tmp_values.pop()) |value| {
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
                std.debug.print("DOING FOR SUM({}): {} || {} = {}\n", .{ sum, compare_sum, value, compare_sum * value });
                compare_sum = converter.concatenate(compare_sum, value, allocator.*);
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