const std = @import("std");

pub fn cat(a: isize, b: isize) isize {
    var b_digits: isize = 0;
    var temp = b;
    
    // Count the number of digits in b
    while (temp != 0) : (temp = @divFloor(temp, 10)) {
        b_digits += 1;
    }

    // Shift a left by the number of digits in b and add b
    return a * std.math.pow(isize, 10, b_digits) + b;
}