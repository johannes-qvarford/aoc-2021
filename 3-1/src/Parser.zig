const std = @import("std");

const Self = @This();

buffer: [:0]const u8,

pub fn parseByte(self: *Self) !u8 {
    if (self.buffer.len == 0) return error.EndOfFile;

    const c = self.buffer[0];
    self.buffer = self.buffer[1..];
    return c;
}

pub fn parseBitCharacter(self: *Self) !bool {
    const byte = try self.parseByte();
    return switch (byte) {
        '0' => false,
        '1' => true,
        else => error.InvalidBitCharacter,
    };
}

pub fn BitStringNumber(comptime length: comptime_int) type {
    return std.math.IntFittingRange(0, (1 << length) - 1);
}

pub fn ShiftAmount(comptime length: comptime_int) type {
    return std.math.IntFittingRange(0, length);
}

pub fn parseBitStringAsNumber(self: *Self, comptime length: u16) !std.StaticBitSet(length) {
    var n = std.StaticBitSet(length).initEmpty();
    for (0..length) |i| {
        const rev = (length - 1) - i;
        const bitC = try self.parseBitCharacter();
        n.setValue(rev, bitC);
    }
    return n;
}

test "can parse bit string as byte" {
    var p = Self{ .buffer = "00100" };
    const set = try p.parseBitStringAsNumber(5);
    const n = set.mask;
    try std.testing.expectEqual(@as(@TypeOf(n), 0b00100), n);
}

test "can parse bit string as byte 2" {
    var p = Self{ .buffer = "11110" };
    const set = try p.parseBitStringAsNumber(5);
    const n = set.mask;
    try std.testing.expectEqual(@as(@TypeOf(n), 0b11110), n);
}
