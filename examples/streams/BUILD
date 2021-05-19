load("@rescript_rules//:rules.bzl", "rescript_binary", "rescript_module")
load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary")

package(
  default_visibility = ["//visibility:public"]
)

rescript_module(
    name = "streams",
    src = "Streams.res",
    interface = "Streams.resi",
)

rescript_binary(
    name = "main",
    src = "Main.res",
    deps = [
        "//streams",
        "//nums",
    ],
)

nodejs_binary(
    name = "main_entry",
    data = [
        "@npm//rescript"
    ],
    entry_point = ":main",
)

