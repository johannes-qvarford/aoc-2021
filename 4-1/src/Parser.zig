const std = @import("std");
const m = std.math;

const Self = @This();

pub const SeparatorResult = enum { MoreItems, NoMoreItems };

buffer: [:0]const u8,

pub fn parseSeparatorOrTerminator(self: *Self, separator: u8, terminator: u8) !SeparatorResult {
    const c = try self.parseByte();

    return if (c == separator) .MoreItems else if (c == terminator) .NoMoreItems else error.InvalidCharacter;
}

pub fn parseUnsigned(self: *Self, comptime T: type) !T {
    if (self.buffer.len == 0) return error.EndOfFile;

    var hasReadAtLeastOneByte = false;
    var n: T = 0;

    while (true) {
        const current_buffer = self.buffer;
        const c = self.parseByte() catch |err| {
            switch (err) {
                error.EndOfFile => {
                    if (hasReadAtLeastOneByte) {
                        return n;
                    }
                    return err;
                },
                else => return err,
            }
        };
        const digit = try switch (c) {
            '0'...'9' => c - '0',
            else => blk: {
                self.buffer = current_buffer;
                if (hasReadAtLeastOneByte) {
                    return n;
                }
                break :blk error.InvalidCharacter;
            },
        };
        hasReadAtLeastOneByte = true;
        n = try m.add(T, try m.mul(T, n, 10), digit);
    }
    return n;
}

pub fn parseWhitespace(self: *Self) !void {
    while (true) {
        const current_buffer = self.buffer;
        self.parseSingleSpace() catch |err| {
            self.buffer = current_buffer;
            switch (err) {
                error.InvalidWhitespace => {
                    return;
                },
                else => return err,
            }
        };
    }
}

fn parseSingleSpace(self: *Self) !void {
    const c = try self.parseByte();
    if (c != ' ' and c != '\n') {
        return error.InvalidWhitespace;
    }
}

pub fn parseByte(self: *Self) !u8 {
    if (self.buffer.len == 0) return error.EndOfFile;

    const c = self.buffer[0];
    self.buffer = self.buffer[1..];
    return c;
}
