const std = @import("std");

pub const Directions = enum {
  UP,
  RIGHT,
  DOWN,
  LEFT
};

const GuardError = error {
  GuardNotFound,
  IvalidDirection
};

pub const GUARD_ICON: u8 = '^';
pub const GUARD_STEP: u8 = 'X';

pub fn Guard() type {
  return struct {
    const This = @This();

    x: isize,
    y: isize,
    direction: Directions,

    pub fn init(x: isize, y: isize, direction: Directions) This {
      return This {
        .x = x,
        .y = y,
        .direction = direction,
      };
    }

    pub fn rotateClockwise(this: *This) void {
       switch (this.direction) {
        Directions.UP => this.direction = Directions.RIGHT,
        Directions.RIGHT => this.direction = Directions.DOWN,
        Directions.DOWN => this.direction = Directions.LEFT,
        Directions.LEFT => this.direction = Directions.UP,
      }
    }

    pub fn goForward(this: *This) void {
       switch (this.direction) {
        Directions.UP => this.y -= 1,
        Directions.RIGHT => this.x += 1,
        Directions.DOWN => this.y += 1,
        Directions.LEFT => this.x -= 1,
      }
    }

    pub fn getCoordsFingerprint(this: *This, allocator: *const std.mem.Allocator) ![]const u8 {
      return std.fmt.allocPrint(allocator.*, "{}|{}", .{ this.x, this.y });
    }


    pub fn inBoundsOf(this: *This, matrix: *std.ArrayList(std.ArrayList(u8))) bool {
      return this.x >= 0 and this.y >= 0 and this.y < matrix.items.len and this.x < matrix.items[@intCast(this.y)].items.len;
    }


    pub fn isThereObstacle(this: *This, matrix: *std.ArrayList(std.ArrayList(u8)), obstacle: u8) bool {
      return switch (this.direction) {
        Directions.UP => {
          const next_y = this.y - 1;
          if(next_y >= 0 and next_y < matrix.items.len) return matrix.items[@intCast(next_y)].items[@intCast(this.x)] == obstacle
          else return false;
        },
        Directions.RIGHT => {
          const next_x = this.x + 1;
          if(next_x >= 0 and next_x < matrix.items[@intCast(this.y)].items.len) return matrix.items[@intCast(this.y)].items[@intCast(next_x)] == obstacle
          else return false;
        },
        Directions.DOWN => {
          const next_y = this.y + 1;
          if(next_y >= 0 and next_y < matrix.items.len) return matrix.items[@intCast(next_y)].items[@intCast(this.x)] == obstacle
          else return false;
        },
        Directions.LEFT => {
          const next_x = this.x - 1;
          if(next_x >= 0 and next_x < matrix.items[@intCast(this.y)].items.len) return matrix.items[@intCast(this.y)].items[@intCast(next_x)] == obstacle
          else return false;
        },
      };
    }


  };
}

pub fn findGuard(matrix: *std.ArrayList(std.ArrayList(u8)), identificator: u8) !Guard() {
  for (matrix.items, 0..) |row, i| {
    for (row.items, 0..) |tile, j| {
      if(tile == identificator) {
        return Guard().init(@intCast(j), @intCast(i), Directions.UP);
      }
    }
  }

  return GuardError.GuardNotFound;
}