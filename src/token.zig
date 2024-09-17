const std = @import("std");
const assert = std.debug.assert;

const Ansi = @import("ansi.zig");

pub const Token = struct {
    tag: Tag,
    lexeme: []const u8,
    number: ?f64,

    pub const Tag = enum {
        Number,
        String,
        Symbol,

        LeftParen,
        RightParen,

        EndOfFile,

        ErrorStringOpen,
        ErrorCharacter,

        pub fn format(self: Tag, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{s}", .{@tagName(self)});
        }
    };

    pub fn init(tag: Tag, lexeme: []const u8, number: ?f64) Token {
        return Token{
            .tag = tag,
            .lexeme = lexeme,
            .number = number,
        };
    }

    pub fn string(self: Token) []const u8 {
        assert(self.lexeme.len >= 2);
        return self.lexeme[1 .. self.lexeme.len - 1];
    }

    pub fn compare(this: Token, that: Token) bool {
        return this.tag == that.tag and std.mem.eql(u8, this.lexeme, that.lexeme) and this.number == that.number;
    }

    pub fn format(self: Token, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("{} {s} {?}", .{ self.tag, self.lexeme, self.number });
    }

    pub fn debug(self: Token, source: []const u8, color: []const u8) void {
        var cursor: usize = 0;
        var line_start: usize = 0;
        var line: usize = 1;
        const start_index = @intFromPtr(self.lexeme.ptr) - @intFromPtr(source.ptr);
        while (cursor < start_index) {
            if (source[cursor] == '\n') {
                line += 1;
                line_start = cursor + 1;
            }
            cursor += 1;
        }
        var line_end = start_index;
        while (line_end < source.len and source[line_end] != '\n') line_end += 1;
        const before_lexeme = source[line_start..start_index];
        const after_lexeme = source[start_index + self.lexeme.len .. line_end];
        std.debug.print(Ansi.Yellow ++ "{d: >4}" ++ Ansi.Reset ++ " | {s}{s}{s}" ++ Ansi.Reset ++ "{s}\n", .{ line, before_lexeme, color, self.lexeme, after_lexeme });
        std.debug.print(Ansi.Yellow ++ "{[e]s: >4}" ++ Ansi.Reset ++ " | {[e]s: >[before]}{[color]s}{[e]s:~>[token]}" ++ Ansi.Reset ++ "{[e]s: >[after]}\n", .{ .e = "", .before = before_lexeme.len, .token = if (self.lexeme.len == 0) 1 else self.lexeme.len, .after = after_lexeme.len, .color = color });
    }
};
