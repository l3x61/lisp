const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Array(comptime Type: type) type {
    return struct {
        allocator: Allocator,
        items: []Type,
        capacity: usize,

        const Self = @This();

        pub const Error = error{
            OutOfMemory,
            OutOfBounds,
        };

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
                .items = &.{},
                .capacity = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.capacity == 0) return;
            self.allocator.free(self.items.ptr[0..self.capacity]);
            self.items = &.{};
            self.capacity = 0;
        }

        pub fn push(self: *Self, item: Type) Error!void {
            if (self.items.len + 1 >= self.capacity) {
                try self.double();
            }
            self.items.ptr[self.items.len] = item;
            self.items.len += 1;
        }

        pub fn peek(self: *const Self) ?Type {
            if (self.items.len != 0) {
                return &self.items.ptr[self.items.len - 1];
            }
            return null;
        }

        pub fn pop(self: *Self) ?Type {
            if (self.items.len == 0) {
                return null;
            }
            self.items.len -= 1;
            return &self.items.ptr[self.items.len];
        }

        pub fn set(self: *Self, index: usize, item: Type) Error!void {
            if (index >= self.items.len) {
                return Error.OutOfBounds;
            }
            self.items.ptr[index] = item;
        }

        pub fn get(self: *Self, index: usize) ?Type {
            if (index >= self.items.len) {
                return null;
            }
            return &self.items.ptr[index];
        }

        fn double(self: *Self) Error!void {
            const old_length = self.items.len;
            const new_capacity = switch (self.capacity) {
                0 => 1,
                std.math.maxInt(usize) => return Error.OutOfMemory,
                else => self.capacity * 2,
            };
            self.items = self.allocator.realloc(self.items.ptr[0..self.capacity], new_capacity) catch return Error.OutOfMemory;
            self.capacity = new_capacity;
            self.items.len = old_length;
        }
    };
}
