const std = @import("std");

pub fn areSlicesEqual(a: [][]u8, b: [4][3][3]u8) bool {
    for (b) |seq| {
        if (a[0][0] == seq[0][0] and a[0][2] == seq[0][2] and a[1][1] == seq[1][1] and a[2][0] == seq[2][0] and a[2][2] == seq[2][2]) {
            return true;
        }
    }

    return false;
}
