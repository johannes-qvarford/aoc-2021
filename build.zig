const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const all_tests_step = b.step("test", "Run library tests");

    var iterable: std.fs.IterableDir = std.fs.cwd().openIterableDir(".", std.fs.Dir.OpenDirOptions { .access_sub_paths = true, .no_follow = true }) catch unreachable;
    defer iterable.close();

    var iterator: std.fs.IterableDir.Iterator = iterable.iterate();

    var entry = iterator.next() catch unreachable;
    while (entry != null) : (entry = iterator.next() catch unreachable) {
        const present_entry = entry.?;
        if (present_entry.kind == .Directory and present_entry.name[0] >= '0' and present_entry.name[0] <= '9' ) {
            var file_name = std.ArrayListAligned(u8, @alignOf(u8)).init(arena.allocator());
            defer file_name.deinit();
            file_name.appendSlice(present_entry.name) catch unreachable;
            file_name.appendSlice("/src/main.zig"[0..]) catch unreachable;

            const dir_tests = b.addTest(.{
                .root_source_file = .{ .path = file_name.allocatedSlice()[0..file_name.items.len] },
                .target = target,
                .optimize = optimize,
            });

            var command = std.ArrayListAligned(u8, @alignOf(u8)).init(arena.allocator());
            defer command.deinit();
            command.appendSlice("test_") catch unreachable;
            command.appendSlice(present_entry.name[0..]) catch unreachable;

            const task_tests_step = b.step(command.items, "Run library tests");

            all_tests_step.dependOn(&dir_tests.step);
            task_tests_step.dependOn(&dir_tests.step);
        }
    }
}
