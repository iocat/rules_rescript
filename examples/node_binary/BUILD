load("@rescript_rules//:rules.bzl", "rescript_binary", "rescript_module")
load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary")

package(
    default_visibility = ["//visibility:public"],
)

rescript_module(
    name = "nums",
    src = "Nums.res",
)

rescript_binary(
    name = "main_rescript",
    src = "Main.res",
    deps = [
        ":nums",
        "//streams",
    ],
)

nodejs_binary(
    name = "main",
    data = [
        "@npm//rescript",
    ],
    entry_point = ":main_rescript",
)