const std = @import("std");
const print = std.debug.print;

const Ansi = @import("ansi.zig");
const Token = @import("token.zig").Token;

pub const Lexer = struct {
    source: []const u8,
    cursor: usize,

    pub fn init(source: []const u8) Lexer {
        return Lexer{ .source = source, .cursor = 0 };
    }

    pub fn next(self: *Lexer) Token {
        const c = self.char() orelse {
            return Token.init(.EndOfFile, self.source[self.cursor..self.cursor], null);
        };

        if (self.isSpace()) {
            self.skipSpace();
            return self.next();
        }

        if (c == '(') {
            defer self.advance();
            return Token.init(.LeftParen, self.source[self.cursor .. self.cursor + 1], null);
        }

        if (c == ')') {
            defer self.advance();
            return Token.init(.RightParen, self.source[self.cursor .. self.cursor + 1], null);
        }

        if (c == '"') {
            return self.scanString();
        }

        if (self.isSymbol()) {
            const symbol = self.scanSymbol();
            const number = std.fmt.parseFloat(f64, symbol) catch {
                return Token.init(.Symbol, symbol, null);
            };
            return Token.init(.Number, symbol, number);
        }

        defer self.advance();
        return Token.init(.ErrorCharacter, self.source[self.cursor..self.cursor], null);
    }

    fn char(self: *Lexer) ?u8 {
        if (self.cursor >= self.source.len) {
            return null;
        }
        return self.source[self.cursor];
    }

    fn advance(self: *Lexer) void {
        self.cursor += 1;
    }

    fn isSpace(self: *Lexer) bool {
        const c = self.char() orelse return false;
        return switch (c) {
            ' ', '\t', '\n', '\r' => true,
            else => false,
        };
    }

    fn skipSpace(self: *Lexer) void {
        while (self.isSpace()) {
            self.cursor += 1;
        }
    }

    fn isDigit(self: *Lexer) bool {
        return switch (self.char()) {
            '0'...'9' => true,
            _ => false,
        };
    }

    fn isSymbol(self: *Lexer) bool {
        const c = self.char() orelse return false;
        return switch (c) {
            '0'...'9', 'a'...'z', 'A'...'Z', '.', '_', '-', '+', '*', '/' => true,
            else => false,
        };
    }

    fn scanSymbol(self: *Lexer) []const u8 {
        const start = self.cursor;
        while (self.isSymbol()) {
            self.cursor += 1;
        }
        return self.source[start..self.cursor];
    }

    fn scanString(self: *Lexer) Token {
        const start = self.cursor;
        self.advance();
        while (true) {
            const c = self.char() orelse {
                return Token.init(.ErrorStringOpen, self.source[start..self.cursor], null);
            };
            if (c == '"') {
                self.advance();
                return Token.init(.String, self.source[start..self.cursor], null);
            }
            self.advance();
        }
        return Token.init(.ErrorString, self.source[start..self.cursor], null);
    }
};

const expect = std.testing.expect;
fn runTest(test_name: []const u8, source: []const u8, expected_tokens: []const Token) !void {
    var lexer = Lexer.init(source);
    for (expected_tokens, 0..) |expected, i| {
        const actual = lexer.next();
        expect(Token.compare(actual, expected)) catch |err| {
            print("in test " ++ Ansi.Cyan ++ "{s}" ++ Ansi.Reset ++ ", token: " ++ Ansi.Magenta ++ "{d}" ++ Ansi.Reset ++ ":\n", .{ test_name, i });
            print(Ansi.Green ++ "expected: {}\n" ++ Ansi.Reset, .{expected});
            print(Ansi.Red ++ "actual:   {}\n" ++ Ansi.Reset, .{actual});
            return err;
        };
    }
}

test "empty" {
    const source =
        \\
    ;
    const tokens = [_]Token{
        Token.init(.EndOfFile, source[0..0], null),
        Token.init(.EndOfFile, source[0..0], null),
        Token.init(.EndOfFile, source[0..0], null),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "empty list" {
    const source =
        \\()
    ;
    const tokens = [_]Token{
        Token.init(.LeftParen, source[0..1], null),
        Token.init(.RightParen, source[1..2], null),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "integer" {
    const source =
        \\123
    ;
    const tokens = [_]Token{
        Token.init(.Number, source[0..3], 123),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "decimal" {
    const source =
        \\123.456
    ;
    const tokens = [_]Token{
        Token.init(.Number, source[0..7], 123.456),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "scientific notation" {
    const source =
        \\123.456e3
    ;
    const tokens = [_]Token{
        Token.init(.Number, source[0..9], 123.456e3),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "symbol" {
    const source =
        \\123.456e3_
    ;
    const tokens = [_]Token{
        Token.init(.Symbol, source[0..10], null),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "string" {
    const source =
        \\"lisp"
    ;
    const tokens = [_]Token{
        Token.init(.String, source[0..6], null),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "open string" {
    const source =
        \\"lisp
    ;
    const tokens = [_]Token{
        Token.init(.ErrorStringOpen, source[0..5], null),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}

test "invalid character" {
    const source =
        \\@
    ;
    const tokens = [_]Token{
        Token.init(.ErrorCharacter, source[0..0], null),
        Token.init(.EndOfFile, source[0..0], null),
    };
    try runTest(@src().fn_name[5..], source, &tokens);
}
