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

pub const OBSTACLE: u8 = '#';
pub const EXTRA_OBSTACLE: u8 = 'O';

fn StepHistory() type {
  return struct {
    const This = @This();

    up: u32,
    right: u32,
    down: u32,
    left: u32,

    pub fn init(up: u32, right: u32, down: u32, left: u32) This {
      return This{ .up = up, .right = right, .down = down, .left = left };
    }

    pub fn reset(this: *This, direction: Directions) void {
        switch (direction) {
          Directions.UP => {
            this.right = 0;
            this.left = 0;
            this.down = 0;
          },
          Directions.RIGHT => {
            this.up = 0;
            this.left = 0;
            this.down = 0;
          },
          Directions.DOWN => {
            this.up = 0;
            this.right = 0;
            this.left = 0;
     
          },
          Directions.LEFT => {
            this.up = 0;
            this.right = 0;
            this.down = 0;
          },
        }
    }
  };
}

pub fn Guard() type {
  return struct {
    const This = @This();

    x: isize,
    y: isize,
    direction: Directions,
    steps: StepHistory(),
    rotations: u3,
    ss: u32,

    pub fn init(x: isize, y: isize, direction: Directions) This {
      return This {
        .x = x,
        .y = y,
        .direction = direction,
        .steps = StepHistory().init(0, 0, 0, 0),
        .rotations = 0,
        .ss = 0
      };
    }

    pub fn rotateClockwise(this: *This) ?u32 {
      switch (this.direction) {
        Directions.UP => this.direction = Directions.RIGHT,
        Directions.RIGHT => this.direction = Directions.DOWN,
        Directions.DOWN => this.direction = Directions.LEFT,
        Directions.LEFT => this.direction = Directions.UP,
      }

      this.rotations += 1;
       if(this.rotations == 3) {
          defer this.rotations = 0;
          defer this.steps.reset(this.direction);
          defer this.ss = 0;

          return 1 + this.ss;

          // std.debug.print("STEPS: {any}\n", .{ this.steps });

          // if(this.steps.right == this.steps.left) {
          //   return 1 + (if (this.steps.up > this.steps.down) this.steps.up else this.steps.down);
          // }

          // if(this.steps.up == this.steps.down) {
          //   return 1 + (if (this.steps.right > this.steps.left) this.steps.right else this.steps.left);
          // }
       }

      return null;
    }

    pub fn goForward(this: *This) void {
      if(this.rotations == 1) this.ss += 1;
       switch (this.direction) {
        Directions.UP => {
          this.steps.up += 1;
          this.y -= 1;
        },
        Directions.RIGHT => {
          this.steps.right += 1;
          this.x += 1;
        },
        Directions.DOWN => {
          this.steps.down += 1;
          this.y += 1;
        },
        Directions.LEFT => {
          this.steps.left += 1;
          this.x -= 1;
        },
      }
    }

    pub fn getCoordsFingerprint(this: *This, allocator: *const std.mem.Allocator) ![]const u8 {
      return std.fmt.allocPrint(allocator.*, "{}|{}", .{ this.x, this.y });
    }

    pub fn getDirectionalCoordsFingerprint(this: *This, allocator: *const std.mem.Allocator) ![]const u8 {
      return std.fmt.allocPrint(allocator.*, "{}|{}|{}", .{ this.x, this.y, this.direction });
    }


    pub fn inBoundsOf(this: *This, matrix: *const std.ArrayList(std.ArrayList(u8))) bool {
      return this.x >= 0 and this.y >= 0 and this.y < matrix.items.len and this.x < matrix.items[@intCast(this.y)].items.len;
    }


    pub fn isInBoundsAhead(this: *This, matrix: *const std.ArrayList(std.ArrayList(u8)), steps: u32) bool {
      var ghost = this.*;
      for (0..steps) |_| {
        ghost.goForward();
      }

      return ghost.inBoundsOf(matrix);
    }


    pub fn isThereObstacle(this: *This, matrix: *const std.ArrayList(std.ArrayList(u8)), obstacle: u8) bool {
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