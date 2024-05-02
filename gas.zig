const std = @import("std");

pub fn main() !void {
    var stdout_bw = std.io.bufferedWriter(std.io.getStdOut().writer());
    const stdout = stdout_bw.writer();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var client = std.http.Client {.allocator=allocator};
    var res_buf = std.ArrayList(u8).init(allocator);
    defer res_buf.deinit();
    try stdout.print("Fetching data...\n", .{});
    const res = try client.fetch(.{
        .location = .{.url = "http://arek.gabr.pl/atom.xml"},
        .response_storage = .{.dynamic = &res_buf},
    });
    switch (res.status) {
        .ok => try writeAtomSummary(res_buf.items, stdout),
        else => {
            std.debug.print("{}\n", .{res});
            return error.FailedToFetchAtomXml;
        },
    }
    try stdout_bw.flush(); // don't forget to flush!
}

const TokenBetween = struct {
    buf:   []const u8,
    left:  []const u8,
    right: []const u8,
    pos: usize = 0,

    pub fn next(self: *TokenBetween) ?[]const u8 {
        var left_i: usize = 0; var right_i: usize = 0;
        left_i  = std.mem.indexOfPosLinear(u8, self.buf, self.pos, self.left)  orelse return null;
        right_i = std.mem.indexOfPosLinear(u8, self.buf, left_i,   self.right) orelse return null;
        const res = self.buf[(left_i+self.left.len)..right_i];
        self.pos = right_i+self.right.len;
        return res;
    }
};

fn writeAtomSummary(buf: []u8, writer: anytype) !void {
    var entries_it = TokenBetween { .buf = buf, .left = "<entry>", .right = "</entry>" };
    while (entries_it.next()) |entry| {
        var title_it   = TokenBetween { .buf = entry, .left = "<title>",   .right = "</title>"   };
        var updated_it = TokenBetween { .buf = entry, .left = "<updated>", .right = "</updated>" };
        const title   = title_it.next()   orelse return;
        const updated = updated_it.next() orelse return;
        try writer.print("{s}  {s}\n", .{updated, title});
        try writer.print("{s}\n", .{std.mem.trim(u8, entry, "\n\r\t")});
    }
}
