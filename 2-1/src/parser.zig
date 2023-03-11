const std = @import("std");

pub const Parser = struct {
    const Self = @This();
    const EnumFieldString = []const u8;

    buffer: [:0]const u8,

    pub fn parseUnsigned(self: *Self, comptime T: type) !T {
        if (self.buffer.len == 0) return error.EndOfFile;

        var hasReadAtLeastOneByte = false;
        var n: T = 0;
        while (self.buffer.len > 0) : (self.buffer = self.buffer[1..]) {
            const c = self.buffer[0];
            const digit = try switch (c) {
                '0'...'9' => c - '0',
                else => blk: {
                    if (hasReadAtLeastOneByte) return n;
                    std.debug.print("Invalid character {c}", .{c});
                    break :blk error.InvalidCharacter;
                },
            };
            hasReadAtLeastOneByte = true;
            const n2 = @mulWithOverflow(n, 10);
            if (n2[1] != 0) return error.NumberOverflow;
            const n3 = @addWithOverflow(n2[0], digit);
            if (n3[1] != 0) return error.NumberOverflow;
            n = n3[0];
        }
        return n;
    }

    pub fn parseByte(self: *Self) !u8 {
        if (self.buffer.len == 0) return error.EndOfFile;

        const c = self.buffer[0];
        self.buffer = self.buffer[1..];
        return c;
    }

    pub fn parseEnum(self: *Self, comptime T: type) !T {
        var strings = comptime str: {
            var array = [_]EnumFieldString{undefined} ** @typeInfo(T).Enum.fields.len;
            inline for (@typeInfo(T).Enum.fields, 0..) |field, i| {
                array[i] = field.name;
            }
            break :str array;
        };

        const string = try self.parseAnyOfStrings(&strings);

        inline for (@typeInfo(T).Enum.fields) |field| {
            if (std.mem.eql(u8, field.name, string)) {
                return @intToEnum(T, field.value);
            }
        }
        return error.InvalidEnum;
    }

    fn parseAnyOfStrings(self: *Self, strings: []EnumFieldString) !EnumFieldString {
        if (self.buffer.len == 0) return error.EndOfFile;

        for (strings) |string| {
            if (self.buffer.len < string.len) {
                continue;
            }

            if (std.mem.eql(u8, self.buffer[0..string.len], string)) {
                self.buffer = self.buffer[string.len..];
                return string;
            }
        }
        return error.NoMatch;
    }
};

test "can parse valid enum" {
    const E = enum { north, east, south, west };
    var p = Parser{ .buffer = "souththing" };
    const e = try p.parseEnum(E);
    try std.testing.expectEqual(E.south, e);
    try std.testing.expectEqualStrings("thing", p.buffer);
}

test "cannot parse invalid enum" {
    const E = enum { north, east, south, west };
    var p = Parser{ .buffer = "bla" };
    try std.testing.expectError(error.NoMatch, p.parseEnum(E));
    try std.testing.expectEqualStrings("bla", p.buffer);
}
