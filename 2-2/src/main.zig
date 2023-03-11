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

const State = struct {
    x: i32,
    y: i32,
    aim: i32,

    const Self = @This();

    fn start() State {
        return Self {
            .x = 0,
            .y = 0,
            .aim = 0
        };
    }

    fn advance(self: Self, command: Command) !State {
        const Change = struct { x: i2, y: i32, aim: i32 };
        const vector: Change = switch (command.direction) {
            .backward => Change{ .x = -1, .y = 0, .aim = 0 },
            .forward => Change{ .x = 1, .y = self.aim, .aim = 0 },
            .up => Change{ .x = 0, .y = 0, .aim = -1 },
            .down => Change{ .x = 0, .y = 0, .aim = 1 }
        };

        var x = try m.mulWithOverflow(vector.x, command.amount);
        x = try m.addWithOverflow(x, self.x);
        var y = try m.mulWithOverflow(vector.y, command.amount);
        y = try m.addWithOverflow(y, self.y);
        const aim = try m.addWithOverflow(self.aim, try m.mulWithOverflow(vector.aim, command.amount));

        return Self {
            .x = x,
            .y = y,
            .aim = aim
        };
    }
};

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

fn run(parser: *p.Parser) !i32 {
    var position = State.start();
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
    try std.testing.expectEqual(@as(i32, 900), actual);
}

test "input" {
    var parser = p.Parser { .buffer = input };
    const actual: i32 = try run(&parser);
    try std.testing.expectEqual(@as(i32, 1741971043), actual);
}