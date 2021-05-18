load("@rescript_rules//:rules.bzl", "rescript_binary", "rescript_module")
load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary")

rescript_module(
    name = "streams",
    src = "Streams.res",
    interface = "Streams.resi",
)

rescript_module(
    name = "nums",
    src = "Nums.res",
)

rescript_binary(
    name = "main",
    src = "Main.res",
    deps = [
        ":nums",
        ":streams",
    ],
)

nodejs_binary(
    name = "main_entry",
    data = [
        "@npm//rescript"
    ],
    entry_point = ":main",
)