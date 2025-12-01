const std = @import("std");

pub fn add(n1: u64, n2: u64) u64 {
  return n1 + n2;
}

pub fn mul(n1: u64, n2: u64) u64 {
  return n1 * n2;
}

pub fn cat(a: u64, b: u64) u64 {
    var b_digits: u64 = 0;
    var temp = b;
    
    // Count the number of digits in b
    while (temp != 0) : (temp /= 10) {
        b_digits += 1;
    }

    // Shift a left by the number of digits in b and add b
    return a * std.math.pow(u64, 10, b_digits) + b;
}