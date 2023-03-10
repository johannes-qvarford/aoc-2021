const std = @import("std");
const p = @import("parser.zig");
const m = @import("math.zig");

const Direction = enum {
    forward,
    down,
    backward,
    up
};

const Command = struct {
    direction: Direction,
    amount: i32
};

fn parseCommand(parser: *p.Parser) !Command {
    const direction = try parser.parseEnum(Direction);
    _ = try parser.parseByte();
    const amount = try parser.parseUnsigned(i32);
    _ = parser.parseByte() catch '\n';
    return Command {
        .direction = direction,
        .amount = amount
    };
}

const Position = struct {
    x: i32,
    y: i32,

    const Self = @This();

    fn start() Position {
        return Self {
            .x = 0,
            .y = 0
        };
    }

    fn advance(self: Self, command: Command) !Position {
        const Vector = struct { x: i2, y: i2 };
        const vector: Vector = switch (command.direction) {
            .backward => Vector{ .x = -1, .y = 0},
            .forward => Vector{ .x = 1, .y = 0},
            .up => Vector{ .x = 0, .y = -1},
            .down => Vector{ .x = 0, .y = 1}
        };

        var x = try m.mulWithOverflow(vector.x, command.amount);
        x = try m.addWithOverflow(x, self.x);
        var y = try m.mulWithOverflow(vector.y, command.amount);
        y = try m.addWithOverflow(y, self.y);

        return Self {
            .x = x,
            .y = y
        };
    }
};

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

pub fn main() !void {
    
    _ = p.Parser { .buffer = example };

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

fn run(parser: *p.Parser) !i32 {
    var position = Position.start();
    loop: while (true) {
        const command = parseCommand(parser) catch |e| {
            switch (e) {
                error.EndOfFile => break :loop,
                else => return e
            }
        };
        position = try position.advance(command);
    }
    return position.x * position.y;
}

test {
    std.testing.refAllDecls(@This());
}

test "example" {
    var parser = p.Parser { .buffer = example };
    const actual: i32 = try run(&parser);
    try std.testing.expectEqual(@as(i32, 150), actual);
}

test "input" {
    var parser = p.Parser { .buffer = input };
    const actual: i32 = try run(&parser);
    try std.testing.expectEqual(@as(i32, 1746616), actual);
}

test "valid command" {
    var parser = p.Parser { .buffer = "forward 5\n" };
    const actual: i32 = try run(&parser);
    try std.testing.expectEqual(@as(i32, 0), actual);
}

test "valid command no line ending" {
    var parser = p.Parser { .buffer = "forward 5" };
    const actual: i32 = try run(&parser);
    try std.testing.expectEqual(@as(i32, 0), actual);
}

test "valid commands" {
    var parser = p.Parser { .buffer = "forward 5\ndown 4" };
    const actual: i32 = try run(&parser);
    try std.testing.expectEqual(@as(i32, 20), actual);
}