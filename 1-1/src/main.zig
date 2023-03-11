const std = @import("std");

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

const Parser = struct {
    const Self = @This();

    buffer: [:0]const u8,

    fn parseUnsigned(self: *Self, comptime T: type) !T {
        if (self.buffer.len == 0) return error.EndOfFile;

        var n: T = 0;
        while (self.buffer.len > 0) : (self.buffer = self.buffer[1..]) {
            const c = self.buffer[0];
            const digit = try switch (c) {
                '0'...'9' => c - '0',
                '\n' => {
                    self.buffer = self.buffer[1..];
                    return n;
                },
                else => blk: {
                    std.debug.print("Invalid character {c}", .{c});
                    break :blk error.InvalidCharacter;
                },
            };
            const n2 = @mulWithOverflow(n, 10);
            if (n2[1] != 0) return error.NumberOverflow;
            const n3 = @addWithOverflow(n2[0], digit);
            if (n3[1] != 0) return error.NumberOverflow;
            n = n3[0];
        }
        return n;
    }
};

pub fn run(parser: *Parser) !u32 {
    var m: u32 = std.math.maxInt(u32);
    var increments: u32 = 0;
    while (true) {
        const n = parser.parseUnsigned(u32) catch |e| {
            switch (e) {
                error.EndOfFile => break,
                else => return e,
            }
        };
        if (n > m) {
            increments += 1;
        }
        m = n;
    }
    return increments;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const buffer = try std.io.getStdIn().readToEndAllocOptions(arena.allocator(), 1_000_000, null, @alignOf(u8), 0);
    var parser = Parser{ .buffer = buffer };

    const increments = try run(&parser);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{increments});
}

test "example" {
    var parser = Parser{ .buffer = example };
    const actual: u32 = try run(&parser);
    try std.testing.expect(actual == 7);
}

test "input" {
    var parser = Parser{ .buffer = input };
    const actual: u32 = try run(&parser);
    try std.testing.expect(actual == 1581);
}
