const std = @import("std");

const Self = @This();

buffer: [:0]const u8,

pub fn parseByte(self: *Self) !u8 {
    if (self.buffer.len == 0) return error.EndOfFile;

    const c = self.buffer[0];
    self.buffer = self.buffer[1..];
    return c;
}

pub fn parseBitCharacter(self: *Self) !u1 {
    const byte = try self.parseByte();
    return switch (byte) {
        '0' => 0,
        '1' => 1,
        else => error.InvalidBitCharacter,
    };
}

pub fn BitStringNumber(comptime length: comptime_int) type {
    return std.math.IntFittingRange(0, (1 << length) - 1);
}

pub fn ShiftAmount(comptime length: comptime_int) type {
    return std.math.IntFittingRange(0, length);
}

pub fn parseBitStringAsNumber(self: *Self, comptime length: u32) !BitStringNumber(length) {
    var n: BitStringNumber(length) = 0;
    for (0..length) |i| {
        const rev = (length - 1) - i;
        n |= (try self.parseBitCharacter()) * (@as(BitStringNumber(length), 1) << @intCast(ShiftAmount(length), rev));
    }
    return n;
}

test "can parse bit string as byte" {
    var p = Self{ .buffer = "00100" };
    const n = try p.parseBitStringAsNumber(5);
    try std.testing.expectEqual(@as(@TypeOf(n), 0b00100), n);
}

test "can parse bit string as byte 2" {
    var p = Self{ .buffer = "11110" };
    const n = try p.parseBitStringAsNumber(5);
    try std.testing.expectEqual(@as(@TypeOf(n), 0b11110), n);
}
