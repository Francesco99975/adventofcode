const std = @import("std");

pub fn Rule() type {
  return struct {
    const This = @This();

    left: u32,
    right: u32,

    pub fn init(l: u32, r: u32) This {
      return This {
        .left = l,
        .right = r,
      };
    }

    pub fn isRuleBroken(this: *const This, l: u32, r: u32) bool {
      return this.left == r and this.right == l;
    }
  };
}