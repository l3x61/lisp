const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const String = std.ArrayList(u8);

const Ansi = @import("ansi.zig");
const Array = @import("array.zig").Array;
const Token = @import("token.zig").Token;

const ProgramNode = struct {
    statements: Array(*Node),
};

const ListNode = struct {
    expressions: Array(*Node),
};

const AtomNode = struct {
    token: Token,
};

pub const Node = struct {
    tag: Tag,
    as: Union,

    pub const Tag = enum {
        Program,
        List,
        Atom,

        pub fn format(self: Tag, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            try writer.print("{s}", .{@tagName(self)});
        }
    };

    pub const Union = union {
        program: ProgramNode,
        list: ListNode,
        atom: AtomNode,
    };

    pub fn initProgramNode(allocator: Allocator) !*Node {
        var node = try allocator.create(Node);
        node.tag = Node.Tag.Program;
        node.as = Union{ .program = ProgramNode{ .statements = Array(*Node).init(allocator) } };
        return node;
    }

    pub fn initListNode(allocator: Allocator) !*Node {
        var node = try allocator.create(Node);
        node.tag = Node.Tag.List;
        node.as = Union{ .list = ListNode{ .expressions = Array(*Node).init(allocator) } };
        return node;
    }

    pub fn initAtomNode(allocator: Allocator, atom: Token) !*Node {
        var node = try allocator.create(Node);
        node.tag = Node.Tag.Atom;
        node.as = Union{ .atom = AtomNode{ .token = atom } };
        return node;
    }

    pub fn deinit(self: *Node, allocator: Allocator) void {
        switch (self.tag) {
            .Program => {
                var program = self.as.program;
                for (program.statements.items) |statement| {
                    statement.deinit(allocator);
                }
                program.statements.deinit();
                allocator.destroy(self);
            },
            .List => {
                var list = self.as.list;
                for (list.expressions.items) |expression| {
                    expression.deinit(allocator);
                }
                list.expressions.deinit();
                allocator.destroy(self);
            },
            .Atom => {
                allocator.destroy(self);
            },
        }
    }

    pub fn debug(self: *Node, allocator: Allocator) !void {
        var prefix = String.init(allocator);
        defer prefix.deinit();
        try self.debugInternal(allocator, &prefix, true);
    }

    // TODO: windows does not print unicode characters correctly
    fn debugInternal(self: *Node, allocator: Allocator, prefix: *String, is_last: bool) !void {
        std.debug.print(Ansi.Dim ++ "{s}", .{prefix.items});
        var _prefix = try prefix.clone();
        defer _prefix.deinit();
        if (!is_last) {
            std.debug.print("├── ", .{});
            try _prefix.appendSlice("│   ");
        } else {
            if (self.tag != Node.Tag.Program) {
                std.debug.print("└── ", .{});
                try _prefix.appendSlice("    ");
            }
        }
        std.debug.print(Ansi.Reset, .{});

        switch (self.tag) {
            .Program => {
                const program = self.as.program;
                std.debug.print("Program\n", .{});
                const last_statement_index = program.statements.items.len -% 1;
                for (program.statements.items, 0..) |statement, i| {
                    try statement.debugInternal(allocator, &_prefix, i == last_statement_index);
                }
            },
            .List => {
                const list = self.as.list;
                std.debug.print("List\n", .{});
                const last_statement_index = list.expressions.items.len -% 1;
                for (list.expressions.items, 0..) |expression, i| {
                    try expression.debugInternal(allocator, &_prefix, i == last_statement_index);
                }
            },
            .Atom => {
                const atom = self.as.atom;
                std.debug.print("{} " ++ Ansi.Cyan ++ "{s}\n" ++ Ansi.Reset, .{ atom.token.tag, atom.token.lexeme });
            },
        }
    }
};
