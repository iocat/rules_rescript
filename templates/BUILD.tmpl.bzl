{{AUTO_GENERATED_NOTICE}}

load("@{{REPO_NAME}}//:rules.bzl", "rescript_compiler")

exports_files(glob(["compiler/**"]))

rescript_compiler(
    name = "darwin",
    bsc = "@{{REPO_NAME}}//:compiler/darwin/bsc.exe",
    bsb_helper = ":compiler/darwin/bsb_helper.exe",
    visibility = ["//visibility:public"],
)
rescript_compiler(
    name = "linux",
    bsc = "@{{REPO_NAME}}//:compiler/linux/bsc.exe",
    bsb_helper = ":compiler/linux/bsb_helper.exe",
    visibility = ["//visibility:public"],
)
rescript_compiler(
    name = "windows",
    bsc = "@{{REPO_NAME}}//:compiler/win32/bsc.exe",
    bsb_helper = ":compiler/win32/bsb_helper.exe",
    visibility = ["//visibility:public"],
)
