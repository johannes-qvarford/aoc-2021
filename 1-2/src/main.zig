const std = @import("std");

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

const Parser = struct {
    const Self = @This();

    buffer: [:0]const u8,

    fn parseUnsigned(self: *Self, comptime T: type) !T {
        if (self.buffer.len == 0) return error.EndOfFile;

        var n: T = 0;
        while(self.buffer.len > 0) : (self.buffer = self.buffer[1..]) {
            const c = self.buffer[0];
            const digit = try switch (c) {
                '0' ... '9' => c - '0',
                '\n' => {
                    self.buffer = self.buffer[1..];
                    return n;
                },
                else => blk: {
                    std.debug.print("Invalid character {c}", .{c});
                    break :blk error.InvalidCharacter;
                }
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

const WindowError = error {
    Empty
};

fn Window(comptime T: type, comptime size: comptime_int) type {
    return struct {
        items: [size]T,
        count: std.math.IntFittingRange(0, size),

        const Self = @This();

        fn empty() Self {
            return Self {
                .items = [_]u32{undefined} ** size,
                .count = 0
            };
        }

        fn push_back(self: *Self, item: T) void {
            if (self.count < size) {
                self.items[self.count] = item;
                self.count += 1;
                return;
            }

            inline for (0..size-1) |i| {
                self.items[i] = self.items[i+1];
            }

            self.items[size-1] = item;
        }

        fn sum(self: Self) WindowError!u32 {
            if (self.count < size) {
                return WindowError.Empty;
            }
            var item_sum: u32 = 0;
            inline for (0..size) |i| {
                item_sum += self.items[i];
            }
            return item_sum;
        }
    };
}

pub fn run(parser: *Parser) !u32 {
    var previous_sum: u32 = std.math.maxInt(u32);
    var increments: u32 = 0;
    var window = Window(u32, 3).empty();
    loop: while (true) {
        const n = parser.parseUnsigned(u32) catch |e| {
            switch (e) {
                error.EndOfFile => break,
                else => return e
            }
        };
        window.push_back(n);
        const sum = window.sum() catch |e| {
            switch (e) {
                WindowError.Empty => continue :loop
            }
        };

        if (sum > previous_sum) {
            increments += 1;
        }
        previous_sum = sum;
    }
    return increments;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const buffer = try std.io.getStdIn().readToEndAllocOptions(arena.allocator(), 1_000_000, null, @alignOf(u8), 0);
    var parser = Parser { .buffer = buffer };

    const increments = try run(&parser);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}", .{increments});
}

test "example" {
    var parser = Parser { .buffer = example };
    const actual: u32 = try run(&parser);
    try std.testing.expect(actual == 5);
}

test "input" {
    var parser = Parser { .buffer = input };
    const actual: u32 = try run(&parser);
    try std.testing.expect(actual == 1618);
}