const std = @import("std");
const symbols = @import("../constants/symbols.zig");

pub fn generatePossibleOperations(len: usize, operations: *std.ArrayList(std.ArrayList(u8)), allocator: *const std.mem.Allocator) !void {
  const max: usize = std.math.pow(usize, 2, len);
  
  for (0..max) |num| {
    var op = std.ArrayList(u8).init(allocator.*);
    var index: usize = 0;

    for (0..len) |_| {
      const bit_index = len - 1 - index;
      const bit = (num >> @intCast(bit_index)) & 1;
      try op.append(if (bit == 0) symbols.ADDITION else symbols.MULTIPLICATION);
      index += 1;
    }

    try operations.append(op);
  }
}

pub fn generatePossibleOperationsV2(len: usize, operations: *std.ArrayList(std.ArrayList(u8)), allocator: *const std.mem.Allocator) !void {
  const max: usize = std.math.pow(usize, 3, len);
  
  for (0..max) |num| {
    var op = std.ArrayList(u8).init(allocator.*);
    var index: usize = 0;

    var tmp = num;
    for (0..len) |_| {
      const digit = tmp % 3;
      try op.append(if (digit == 0) symbols.ADDITION else if(digit == 1) symbols.MULTIPLICATION else symbols.CONCATENATION);
      tmp = tmp / 3;
      index += 1;
    }

    try operations.append(op);
  }
}