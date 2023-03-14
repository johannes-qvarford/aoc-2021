const std = @import("std");
const Parser = @import("Parser.zig");

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

fn BitSetInteger2(comptime line_length: u16) type {
    return std.StaticBitSet(line_length + line_length).MaskInt;
}

fn filter(comptime length: u16, allocator: std.mem.Allocator, bitsets: []std.StaticBitSet(length), comptime prefer_common: bool) !std.StaticBitSet(length) {
    var remaining = try std.DynamicBitSet.initFull(allocator, bitsets.len);
    defer remaining.deinit();

    for (0..length) |bit_position| {
        const bit_index = (length - 1) - bit_position;
        if (remaining.count() == 1) {
            return bitsets[remaining.findFirstSet().?];
        }

        var check_it = remaining.iterator(.{});
        var set_amount: usize = 0;
        while (check_it.next()) |bitset_index| {
            const is_set = bitsets[bitset_index].isSet(bit_index);
            if (is_set) {
                set_amount += 1;
            }
        }

        const true_is_common = @as(std.math.IntFittingRange(0, std.math.maxInt(usize) * 2), set_amount) * 2 >= remaining.count();
        const remove_bitsets_with_true = prefer_common == true_is_common;
        var remove_it = remaining.iterator(.{});
        while (remove_it.next()) |bitset_index| {
            if (bitsets[bitset_index].isSet(bit_index) == remove_bitsets_with_true) {
                remaining.unset(bitset_index);
            }
        }
    }

    if (remaining.count() > 1) unreachable;
    return bitsets[remaining.findFirstSet().?];
}

fn run(parser: *Parser, allocator: std.mem.Allocator, comptime line_length: u16) !BitSetInteger2(line_length) {
    const BitSet = std.StaticBitSet(line_length);

    var bitsets = std.ArrayList(BitSet).init(allocator);
    defer bitsets.deinit();

    loop: while (true) {
        const bitset: BitSet = try parser.parseBitStringAsNumber(line_length);
        try bitsets.append(bitset);

        _ = parser.parseByte() catch |e| {
            switch (e) {
                error.EndOfFile => break :loop,
            }
        };
    }

    const oxygen_generator_rating = try filter(line_length, allocator, bitsets.items, true);
    const co2_scrubber_rating = try filter(line_length, allocator, bitsets.items, false);

    return @as(BitSetInteger2(line_length), oxygen_generator_rating.mask) * co2_scrubber_rating.mask;
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
    const actual = try run(&parser, std.testing.allocator, line_length);
    try std.testing.expectEqual(@as(@TypeOf(actual), 230), actual);
}

test "input" {
    var parser = Parser{ .buffer = input };
    const line_length = comptime length: {
        break :length first_line_length(input);
    };
    const actual = try run(&parser, std.testing.allocator, line_length);
    try std.testing.expectEqual(@as(@TypeOf(actual), 7863147), actual);
}
