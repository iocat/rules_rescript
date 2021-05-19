load("@rescript_rules//:rules.bzl", "rescript_binary", "rescript_module")

package(
    default_visibility = ["//visibility:public"],
)

rescript_module(
    name = "stream_util",
    src = "StreamUtil.res",
    interface = "StreamUtil.resi",
    visibility = ["//visibility:private"],
)

rescript_module(
    name = "streams",
    src = "Streams.res",
    deps = [":stream_util"]
)


