const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Ansi = @import("ansi.zig");
const Array = @import("array.zig").Array;
const Token = @import("token.zig").Token;
const Lexer = @import("lexer.zig").Lexer;
const Node = @import("node.zig").Node;

pub const Parser = struct {
    allocator: Allocator,
    lexer: Lexer,
    token: Token,

    pub const Error = error{
        SyntaxError,
    };

    pub fn init(allocator: Allocator, source: []const u8) Parser {
        var lexer = Lexer.init(source);
        const token = lexer.next();
        return Parser{
            .allocator = allocator,
            .lexer = lexer,
            .token = token,
        };
    }

    pub fn parse(self: *Parser) !*Node {
        return self.parseProgram();
    }

    pub fn parseProgram(self: *Parser) !*Node {
        const node = try Node.initProgramNode(self.allocator);
        errdefer node.deinit(self.allocator);
        while (self.token.tag != Token.Tag.EndOfFile) {
            try node.as.program.statements.push(try self.parseExpression());
        }
        return node;
    }

    pub fn parseExpression(self: *Parser) !*Node {
        return switch (self.token.tag) {
            .LeftParen => self.parseList(),
            else => self.parseAtom(),
        };
    }

    pub fn parseList(self: *Parser) anyerror!*Node {
        const node = try Node.initListNode(self.allocator);
        errdefer node.deinit(self.allocator);
        _ = try self.eat(&[_]Token.Tag{.LeftParen});
        while (self.token.tag != Token.Tag.RightParen) {
            try node.as.list.expressions.push(try self.parseExpression());
        }
        _ = try self.eat(&[_]Token.Tag{.RightParen});
        return node;
    }

    pub fn parseAtom(self: *Parser) !*Node {
        return Node.initAtomNode(self.allocator, try self.eat(&[_]Token.Tag{ .Number, .String, .Symbol }));
    }

    fn eat(self: *Parser, expected: []const Token.Tag) !Token {
        const token = self.token;
        self.token = self.lexer.next();
        for (expected) |tag| {
            if (tag == token.tag) {
                return token;
            }
        }
        std.debug.print(Ansi.Red ++ "error" ++ Ansi.Reset ++ " unexpected token: " ++ Ansi.Red ++ "{}" ++ Ansi.Reset ++ " expected " ++ Ansi.Green, .{token.tag});
        switch (expected.len) {
            0 => {
                unreachable;
            },
            1 => {
                std.debug.print("{}", .{expected[0]});
            },
            2 => {
                std.debug.print("{}" ++ Ansi.Reset ++ " or " ++ Ansi.Green ++ "{}", .{ expected[0], expected[1] });
            },
            else => {
                for (expected[0 .. expected.len - 2]) |tag_| {
                    std.debug.print("{}, ", .{tag_});
                }
                std.debug.print("{}" ++ Ansi.Reset ++ " or " ++ Ansi.Green ++ "{}", .{ expected[expected.len - 2], expected[expected.len - 1] });
            },
        }
        std.debug.print("\n" ++ Ansi.Reset, .{});
        token.debug(self.lexer.source, Ansi.Red);
        return Error.SyntaxError;
    }
};

const expect = std.testing.expect;
fn runTest(test_name: []const u8, source: []const u8, print_ast: bool) !void {
    const allocator = std.testing.allocator;
    var parser = Parser.init(allocator, source);
    var node = try parser.parse();
    defer node.deinit(allocator);
    if (print_ast) {
        print("in test " ++ Ansi.Cyan ++ "{s}" ++ Ansi.Reset ++ "\n", .{test_name});
        try node.debug(allocator);
    }
}

const PrintAst = true;

test "empty" {
    const source =
        \\
    ;
    try runTest(@src().fn_name[5..], source, PrintAst);
}

test "expressions" {
    const source =
        \\1 2 3
    ;
    try runTest(@src().fn_name[5..], source, PrintAst);
}

test "empty list" {
    const source =
        \\()
    ;
    try runTest(@src().fn_name[5..], source, PrintAst);
}

test "math expression" {
    const source =
        \\(+ 1 (+ 2 3))
    ;
    try runTest(@src().fn_name[5..], source, PrintAst);
}

test "factorial" {
    const source =
        \\(def factorial (n)
        \\    (if (== n 0)
        \\          1
        \\          (* n (factorial (- n 1)))))
        \\(factorial 5)
    ;
    try runTest(@src().fn_name[5..], source, PrintAst);
}
