const std = @import("std");
const Parser = @import("Parser.zig");

const example = @embedFile("EXAMPLE");
const input = @embedFile("INPUT");

const BingoNumber = u8;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const NumberPool = struct {
    numbers: ArrayList(BingoNumber),

    allocator: Allocator,

    const Self = @This();

    fn initFromParser(parser: *Parser, allocator: Allocator) !Self {
        var numbers = ArrayList(BingoNumber).init(allocator);
        errdefer numbers.deinit();

        var x = Parser.SeparatorResult.MoreItems;
        while (x == .MoreItems) {
            const number = try parser.parseUnsigned(BingoNumber);
            try numbers.append(number);

            x = try parser.parseSeparatorOrTerminator(',', '\n');
        }
        return Self{ .numbers = numbers, .allocator = allocator };
    }

    fn deinit(self: Self) void {
        self.numbers.deinit();
    }

    fn items(self: Self) []BingoNumber {
        return self.numbers.items;
    }
};

const MarkResult = enum { Bingo, NotBingo };

const RowCount = 5;
const ColumnCount = 5;

const Sum = std.math.IntFittingRange(0, std.math.maxInt(BingoNumber) * std.math.maxInt(BingoNumber) * ((ColumnCount * RowCount)));

const Board = struct {
    cells: [ColumnCount][RowCount]BingoNumber,
    marks: [ColumnCount][RowCount]bool,

    const Self = @This();

    fn initFromParser(parser: *Parser) !Board {
        const marks = [_][RowCount]bool{[_]bool{false} ** RowCount} ** ColumnCount;
        var cells = [_][RowCount]BingoNumber{[_]BingoNumber{undefined} ** RowCount} ** ColumnCount;
        for (0..RowCount) |row| {
            for (0..ColumnCount) |column| {
                try parser.parseWhitespace();
                cells[column][row] = parser.parseUnsigned(BingoNumber) catch |err| {
                    const x = Self{ .cells = cells, .marks = marks };
                    x.print();
                    return err;
                };
            }
        }

        return Self{ .cells = cells, .marks = marks };
    }

    fn print(self: Self) void {
        std.debug.print("[\n", .{});
        for (0..RowCount) |row| {
            std.debug.print("  [ ", .{});
            for (0..ColumnCount) |column| {
                std.debug.print("{d}, ", .{self.cells[column][row]});
            }
            std.debug.print(" ],\n", .{});
        }
        std.debug.print("]\n", .{});
    }

    fn sumOfUnmarkedNumbers(self: Self) Sum {
        var n: Sum = 0;
        for (0..ColumnCount) |column| {
            for (0..RowCount) |row| {
                if (!self.marks[column][row]) {
                    n += self.cells[column][row];
                }
            }
        }
        return n;
    }

    fn mark(self: *Self, number: BingoNumber) MarkResult {
        for (0..ColumnCount) |column| {
            for (0..RowCount) |row| {
                if (self.cells[column][row] == number) {
                    self.marks[column][row] = true;
                }
            }
        }
        return self._result();
    }

    fn _result(self: Self) MarkResult {
        for (0..ColumnCount) |column| {
            var marks_in_column: u8 = 0;
            for (0..RowCount) |row| {
                if (self.marks[column][row]) {
                    marks_in_column += 1;
                }
            }
            if (marks_in_column == RowCount) {
                return .Bingo;
            }
        }

        for (0..RowCount) |row| {
            var marks_in_row: u8 = 0;
            for (0..ColumnCount) |column| {
                if (self.marks[column][row]) {
                    marks_in_row += 1;
                }
            }
            if (marks_in_row == ColumnCount) {
                return .Bingo;
            }
        }

        return .NotBingo;
    }
};

fn run(parser: *Parser, allocator: Allocator) !Sum {
    var number_pool = try NumberPool.initFromParser(parser, allocator);
    defer number_pool.deinit();

    var boards = ArrayList(Board).init(allocator);
    defer boards.deinit();

    try parser.parseWhitespace();
    boards: while (true) {
        const board = try Board.initFromParser(parser);
        try boards.append(board);
        parser.parseWhitespace() catch |err| {
            switch (err) {
                error.EndOfFile => break :boards,
                else => return err,
            }
        };
    }

    var items = number_pool.items();
    for (items) |number| {
        for (boards.items) |*board| {
            if (board.mark(number) == .Bingo) {
                return number * board.sumOfUnmarkedNumbers();
            }
        }
    }
    unreachable;
}

test {
    std.testing.refAllDecls(Parser);
}

test "example" {
    var parser = Parser{ .buffer = example };
    const actual = try run(&parser, std.testing.allocator);
    try std.testing.expectEqual(@as(@TypeOf(actual), 4512), actual);
}

test "input" {
    var parser = Parser{ .buffer = input };
    const actual = try run(&parser, std.testing.allocator);
    try std.testing.expectEqual(@as(@TypeOf(actual), 10374), actual);
}
