const std     = @import("std");
const mem     = std.mem;
const debug   = std.debug;
const process = std.process;

pub fn build(b: *std.Build) void {
    // validate compiler version
    validateZigVersion(b, "0.12.0");
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
    // add args
    if (b.args) |args| { run_cmd.addArgs(args); }
    // add test step
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "gas.zig" },
        .target           = target,
        .optimize         = optimize,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

/// Runs "zig version" and compares with given value
/// If versions are not equal it will halt the build process.
fn validateZigVersion(b: *std.Build, expected_version_prefix: []const u8) void {
    const version = mem.trimRight(u8, b.run(&[_][]const u8{ b.graph.zig_exe, "version" }), "\n\t\r");
    if (false == mem.startsWith(u8, version, expected_version_prefix)) {
        debug.print(
            "\n" ++
            "  Stop, stop, stop!\n" ++
            "  You're going to take someone's eye out.\n" ++
            "  Besides, you're executing it wrong.\n" ++
            "  It's zig version: {s}*\n" ++
            "               not: {s}\n" ++
            "\n" ++
            "  Make sure to use the zig compiler in version: {s}\n\n",
            .{ expected_version_prefix, version, expected_version_prefix } );
        process.exit(1);
    }
}
