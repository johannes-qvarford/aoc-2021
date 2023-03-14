const std = @import("std");
const Parser = @import("Parser.zig");

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

fn BitSetInteger2(comptime line_length: u16) type {
    return std.StaticBitSet(line_length + line_length).MaskInt;
}

fn run(parser: *Parser, comptime line_length: u16) !BitSetInteger2(line_length) {
    _ = 0;
    var gamma_amount = [_]i32{0} ** line_length;

    const BitSet = std.StaticBitSet(line_length);

    var lines: u32 = 0;
    loop: while (true) {
        const bitset: BitSet = try parser.parseBitStringAsNumber(line_length);
        lines += 1;

        for (0..line_length) |i| {
            if (bitset.isSet(i)) {
                gamma_amount[i] += 1;
            } else {
                gamma_amount[i] -= 1;
            }
        }

        _ = parser.parseByte() catch |e| {
            switch (e) {
                error.EndOfFile => break :loop,
            }
        };
    }
    var final_gamma: BitSet = BitSet.initEmpty();
    for (gamma_amount, 0..) |amount, i| {
        final_gamma.setValue(i, amount > 0);
    }
    var final_epsilon = final_gamma;
    final_epsilon.toggleAll();

    return @as(BitSetInteger2(line_length), final_gamma.mask) * final_epsilon.mask;
}

fn bool_to_bit(b: bool) u1 {
    return if (b) 1 else 0;
}

fn first_line_length(str: [:0]const u8) usize {
    for (str, 0..) |byte, i| {
        if (byte == '\n') {
            return i;
        }
    }
    return str.len;
}

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(Parser);
}

test "example" {
    var parser = Parser{ .buffer = example };
    const line_length = comptime length: {
        break :length first_line_length(example);
    };
    const actual = try run(&parser, line_length);
    try std.testing.expectEqual(@as(@TypeOf(actual), 198), actual);
}

test "input" {
    var parser = Parser{ .buffer = input };
    const line_length = comptime length: {
        break :length first_line_length(input);
    };
    const actual = try run(&parser, line_length);
    try std.testing.expectEqual(@as(@TypeOf(actual), 1131506), actual);
}
