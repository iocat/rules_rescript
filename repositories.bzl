load("known_SHAs.bzl", "get_sha256_if_known")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _impl(repository_ctx):
    # Describes a repository generated on-the-fly.
    template_ctx = {
        "{{AUTO_GENERATED_NOTICE}}": """# DO NOT EDIT
# Automatically generated file for repo rules @{}//.""".format(repository_ctx.name),
        "{{REPO_NAME}}": repository_ctx.name,
        "{{COMPILER_VERSION}}": repository_ctx.attr.compiler_version,
    }

    repository_ctx.template(
        "WORKSPACE",
        Label("//:templates/WORKSPACE.tmpl"),
        substitutions = template_ctx,
        executable = False,
    )
    repository_ctx.template(
        "BUILD",
        Label("//:templates/BUILD.tmpl.bzl"),
        substitutions = template_ctx,
        executable = False,
    )
    repository_ctx.template(
        "rules.bzl",
        Label("//:templates/rules.tmpl.bzl"),
        substitutions = template_ctx,
        executable = False,
    )
    repository_ctx.template(
        "compiler/BUILD",
        Label("//:templates/compiler/BUILD.tmpl.bzl"),
        substitutions = template_ctx,
        executable = False,
    )

    rescript_repo = repository_ctx.download_and_extract(
        url = "https://github.com/rescript-lang/rescript-compiler/archive/refs/tags/{}.tar.gz".format(repository_ctx.attr.compiler_version),
        output = "compiler",
        stripPrefix = "rescript-compiler-{}".format(repository_ctx.attr.compiler_version),
        sha256 = get_sha256_if_known(repository_ctx.attr.compiler_version),
    )
    

_rescript_repository = repository_rule(
    implementation = _impl,
    local = True,
    attrs = {
        "compiler_version": attr.string(),
    },
)

def rescript_repository(
        name,
        compiler_version = "9.1.2",
        **kwargs):
    _rescript_repository(
        name = name,  # Hard-code the repository name.
        compiler_version = compiler_version,
        **kwargs
    )
