const std     = @import("std");
const mem     = std.mem;
const debug   = std.debug;
const process = std.process;

pub fn build(b: *std.Build) void {
    // validate compiler version
    const expected_version_prefix = "0.12.0";
    const version = mem.trimRight(u8, b.run(&[_][]const u8{ b.graph.zig_exe, "version" }), "\n\t\r");
    if (false == mem.eql(u8, version, expected_version_prefix)) {
        debug.print("Incorrect compiler version: {s}\nExpected: {s}\n", .{ version, expected_version_prefix } );
        return;
    }
    // add build step
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name             = "gas",
        .root_source_file = .{ .path = "gas.zig" },
        .target           = target,
        .optimize         = optimize,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
}
