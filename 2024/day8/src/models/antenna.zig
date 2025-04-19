pub const Coord = struct {
                      x: usize,
                      y: usize
                    };

pub fn Antenna() type {
  return struct {
    const This = @This();

    frequency: u8,
    position: Coord,

    fn init(frequency: u8, position: Coord) This {
      return This {
        .frequency = frequency,
        .position = position,
      };
    }
  };
}