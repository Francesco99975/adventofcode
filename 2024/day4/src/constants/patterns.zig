const XMAS1: [3][3]u8 = .{ .{ 'M', 0, 'S' }, .{ 0, 'A', 0 }, .{ 'M', 0, 'S' } };

const XMAS2: [3][3]u8 = .{ .{ 'S', 0, 'S' }, .{ 0, 'A', 0 }, .{ 'M', 0, 'M' } };

const XMAS3: [3][3]u8 = .{ .{ 'S', 0, 'M' }, .{ 0, 'A', 0 }, .{ 'S', 0, 'M' } };

const XMAS4: [3][3]u8 = .{ .{ 'M', 0, 'M' }, .{ 0, 'A', 0 }, .{ 'S', 0, 'S' } };

pub const XMAS: [4][3][3]u8 = .{ XMAS1, XMAS2, XMAS3, XMAS4 };
