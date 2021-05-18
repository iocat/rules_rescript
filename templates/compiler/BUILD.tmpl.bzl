{{AUTO_GENERATED_NOTICE}}

load("@{{REPO_NAME}}//:rules.bzl", "rescript_compiler")

rescript_compiler(
    name = "darwin",
    bsc = ":darwin/bsc.exe",
    bsb_helper = ":darwin/bsb_helper.exe",
    visibility = ["//visibility:public"],
)
rescript_compiler(
    name = "linux",
    bsc = ":linux/bsc.exe",
    bsb_helper = ":linux/bsb_helper.exe",
    visibility = ["//visibility:public"],
)
rescript_compiler(
    name = "windows",
    bsc = ":win32/bsc.exe",
    bsb_helper = ":win32/bsb_helper.exe",
    visibility = ["//visibility:public"],
)