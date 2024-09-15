const std = @import("std");
const assert = std.debug.assert;

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
};
