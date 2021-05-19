{{AUTO_GENERATED_NOTICE}}

CompilerInfo = provider(fields = ["platform", "bsc", "bsb_helper"])

def _rescript_compiler_impl(ctx):
    return [CompilerInfo(
        platform = ctx.attr.name,
        bsc = ctx.file.bsc,
        bsb_helper = ctx.file.bsb_helper,
    )]

rescript_compiler = rule(
    implementation = _rescript_compiler_impl,
    attrs = {
        "bsc": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "bsb_helper": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

RescriptOutputArtifacts = provider(fields = [
    "cmi",
    "cmj",
    "js",
])
RescriptModuleProvider = provider(fields = [
    "module_artifacts",

    # Includes js_file and all of its transitive deps
    "js_depset",
    "data_depset",
])

def _perhaps_compile_to_iast(ctx, interface_file, iast_file):
    if interface_file == None:
        return None

    iast_args = ctx.actions.args()
    iast_args.add("-bs-v", "{{COMPILER_VERSION}}")
    iast_args.add("-bs-ast")
    iast_args.add("-o", iast_file)
    iast_args.add(interface_file)

    ctx.actions.run(
        mnemonic = "CompileToiAST",
        executable = ctx.attr.compiler[CompilerInfo].bsc,
        arguments = [iast_args],
        inputs = depset([interface_file]),
        outputs = [iast_file],
    )

def _compile_to_ast(ctx, src_file, ast_file):
    ast_args = ctx.actions.args()
    ast_args.add("-bs-v", "{{COMPILER_VERSION}}")
    ast_args.add("-bs-ast")
    ast_args.add("-o", ast_file)
    ast_args.add(src_file)

    ctx.actions.run(
        mnemonic = "CompileToAST",
        executable = ctx.attr.compiler[CompilerInfo].bsc,
        arguments = [ast_args],
        inputs = depset([src_file]),
        outputs = [ast_file],
    )

def _unique(l):
    set = {}
    for item in l:
        set[item] = True
    return set.keys()

def _join_path(is_windows, items):
    parts = [item for item in items if item != ""]

    if is_windows:
        return "\\".join(parts)

    return "/".join(parts)

def _collect_cmi_cmj_and_js_depset(deps):
    return depset([], transitive = [depset(item) for item in [[
        mod[RescriptModuleProvider].module_artifacts.cmi,
        mod[RescriptModuleProvider].module_artifacts.cmj,
        mod[RescriptModuleProvider].module_artifacts.js,
    ] for mod in deps]])

def _get_module_name(src):
    return src.basename[:-4]

def _rescript_module_impl(ctx):
    ast_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [_get_module_name(ctx.file.src) + ".ast"]))
    _compile_to_ast(ctx, ctx.file.src, ast_file)

    iast_file = None
    if ctx.file.interface != None:
        iast_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [_get_module_name(ctx.file.src) + ".iast"]))
        _perhaps_compile_to_iast(ctx, ctx.file.interface, iast_file)

    # Generate cmi, cmj, and js artifacts
    cmi_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [_get_module_name(ctx.file.src) + ".cmi"]))
    cmj_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [_get_module_name(ctx.file.src) + ".cmj"]))
    js_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [_get_module_name(ctx.file.src) + ".js"]))

    # includes dependencies's artifacts and js_file artifacts in the search paths.
    deps_artifacts = _collect_cmi_cmj_and_js_depset(ctx.attr.deps)
    dep_module_dirs = _unique([deps_artifact.dirname for deps_artifact in deps_artifacts.to_list()])

    # Module without interface
    if iast_file == None:
        # Generates all targets cmi, cmj and js all at the same time.
        cmi_cmj_js_args = ctx.actions.args()
        cmi_cmj_js_args.add("-bs-v", "{{COMPILER_VERSION}}")
        cmi_cmj_js_args.add("-I", cmi_file.dirname)  # include the cmi dir.
        for dep_module_dir in dep_module_dirs:
            cmi_cmj_js_args.add("-I", dep_module_dir)
        cmi_cmj_js_args.add("-o", cmi_file)
        cmi_cmj_js_args.add("-o", cmj_file)
        cmi_cmj_js_args.add(ast_file)

        ctx.actions.run_shell(
            mnemonic = "CompileToCmiCmjJs",
            tools = [ctx.attr.compiler[CompilerInfo].bsc],
            inputs = [ctx.file.src, ast_file] + deps_artifacts.to_list(),
            outputs = [cmi_file, cmj_file, js_file],
            command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, js_file.path),
            arguments = [cmi_cmj_js_args],
        )

    else:  # Module with interface provided.
        # Generates cmi separately.
        cmi_args = ctx.actions.args()
        cmi_args.add("-I", ctx.file.interface.dirname)
        for dep_module_dir in dep_module_dirs:
            cmi_args.add("-I", dep_module_dir)
        cmi_args.add("-o", cmi_file)
        cmi_args.add(iast_file)
        ctx.actions.run_shell(
            mnemonic = "CompileToCmi",
            tools = [ctx.attr.compiler[CompilerInfo].bsc],
            inputs = [ctx.file.interface, iast_file] + deps_artifacts.to_list(),
            outputs = [cmi_file],
            command = "{} $@".format(ctx.attr.compiler[CompilerInfo].bsc.path),
            arguments = [cmi_args],
        )

        # Generates cmj and js files
        cmi_js_args = ctx.actions.args()
        cmi_js_args.add("-bs-read-cmi")  # Read the CMI file generated from previous step (from iAST file.)
        cmi_js_args.add("-I", cmi_file.dirname)  # include the cmi dir.
        for dep_module_dir in dep_module_dirs:
            cmi_js_args.add("-I", dep_module_dir)
        cmi_js_args.add("-o", cmj_file)
        cmi_js_args.add(ast_file)
        ctx.actions.run_shell(
            mnemonic = "CompileToCmjJs",
            tools = [ctx.attr.compiler[CompilerInfo].bsc],
            inputs = [ctx.file.src, ast_file, cmi_file] + deps_artifacts.to_list(),
            outputs = [cmj_file, js_file],
            command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, js_file.path),
            arguments = [cmi_js_args],
        )

    module_artifacts = RescriptOutputArtifacts(
        cmi = cmi_file,
        cmj = cmj_file,
        js = js_file,
    )

    js_files = [js_file]
    output_files = [
        module_artifacts.js,
        module_artifacts.cmj,
        module_artifacts.cmi,
    ]
    return [
        DefaultInfo(
            files = depset(
                output_files,
                transitive = [dep[RescriptModuleProvider].js_depset for dep in ctx.attr.deps],
            ),
            runfiles = ctx.runfiles(
                files = ctx.files.data + [module_artifacts.js],
                transitive_files = depset([], transitive = [dep[RescriptModuleProvider].data_depset for dep in ctx.attr.deps]),
            ),
        ),
        RescriptModuleProvider(
            js_depset = depset(js_files, transitive = [dep[RescriptModuleProvider].js_depset for dep in ctx.attr.deps]),
            data_depset = depset(ctx.files.data, transitive = [dep[RescriptModuleProvider].data_depset for dep in ctx.attr.deps]),
            module_artifacts = module_artifacts,
        ),
    ]

_rescript_module = rule(
    implementation = _rescript_module_impl,
    executable = False,
    attrs = {
        "compiler": attr.label(
            default = Label("@{{REPO_NAME}}//compiler:darwin"),
            providers = [CompilerInfo],
        ),
        "is_windows": attr.bool(),
        "src": attr.label(
            doc = "Rescript source file",
            allow_single_file = [".res"],
            mandatory = True,
        ),
        "interface": attr.label(
            doc = "Rescript interface file",
            allow_single_file = [".resi"],
        ),
        "deps": attr.label_list(
            doc = "List of dependencies, must be rescript_module targets.",
            providers = [RescriptModuleProvider],
        ),
        "data": attr.label_list(
            doc = "List of data files to include at runtime (consumed by rescript_binary).",
            allow_files = True,
        ),
    },
)

def get_is_windows():
    select(
        {
            "@platforms//os:windows": True,
            "//conditions:default": False,
        },
    )

def get_compiler():
    select(
        {
            "@platforms//os:osx": "@{{REPO_NAME}}//compiler:darwin",
            "@platforms//os:windows": "@{{REPO_NAME}}//compiler:windows",
            "@platforms//os:linux": "@{{REPO_NAME}}//compiler:linux",
            "//conditions:default": None,
        },
    )

def rescript_module(
        name,
        src,
        interface = None,
        deps = [],
        data = [],
        **kwargs):
    """
    Produces a rescript module's artifacts.
    """
    _rescript_module(
        name = name,
        src = src,
        interface = interface,
        deps = deps,
        data = data,

        # Private attribute not expected to be provided
        is_windows = get_is_windows(),
        compiler = get_compiler(),
        **kwargs
    )

######################################################################################################

def _rescript_binary_impl(ctx):
    srcFile = ctx.file.src

    ast_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [ctx.label.name + ".ast"]))
    _compile_to_ast(ctx, ctx.file.src, ast_file)

    cmi_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [ctx.label.name + ".cmi"]))
    cmj_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [ctx.label.name + ".cmj"]))
    js_file = ctx.actions.declare_file(_join_path(ctx.attr.is_windows, [ctx.label.name + ".js"]))

    deps_artifacts = _collect_cmi_cmj_and_js_depset(ctx.attr.deps)
    dep_module_dirs = _unique([deps_artifact.dirname for deps_artifact in deps_artifacts.to_list()])

    # Generates all targets cmi, cmj and js all at the same time.
    cmi_cmj_js_args = ctx.actions.args()
    cmi_cmj_js_args.add("-bs-v", "{{COMPILER_VERSION}}")
    cmi_cmj_js_args.add("-I", cmi_file.dirname)  # include the cmi dir.
    for dep_module_dir in dep_module_dirs:
        cmi_cmj_js_args.add("-I", dep_module_dir)
    cmi_cmj_js_args.add("-o", cmi_file)
    cmi_cmj_js_args.add("-o", cmj_file)
    cmi_cmj_js_args.add(ast_file)

    ctx.actions.run_shell(
        mnemonic = "CompileToCmiCmjJs",
        tools = [ctx.attr.compiler[CompilerInfo].bsc],
        inputs = [ctx.file.src, ast_file] + deps_artifacts.to_list(),
        outputs = [cmi_file, cmj_file, js_file],
        command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, js_file.path),
        arguments = [cmi_cmj_js_args],
    )

    return [
        DefaultInfo(
            executable = js_file,
            runfiles = ctx.runfiles(
                files = ctx.files.data,
                transitive_files = depset(
                    [],
                    transitive = [dep[RescriptModuleProvider].data_depset for dep in ctx.attr.deps] + [dep[RescriptModuleProvider].js_depset for dep in ctx.attr.deps],
                ),
            ),
        ),
    ]

_rescript_binary = rule(
    implementation = _rescript_binary_impl,
    executable = True,
    attrs = {
        "compiler": attr.label(
            default = Label("@{{REPO_NAME}}//compiler:darwin"),
            providers = [CompilerInfo],
        ),
        "is_windows": attr.bool(),
        "src": attr.label(
            doc = "Rescript source file",
            mandatory = True,
            allow_single_file = [".res"],
        ),
        "deps": attr.label_list(
            doc = "List of dependencies, must be rescript_module targets.",
            providers = [RescriptModuleProvider],
        ),
        "data": attr.label_list(
            doc = "List of data files to include at runtime.",
            allow_files = True,
        ),
    },
)

def rescript_binary(
        name,
        src,
        deps = [],
        data = [],
        **kwargs):
    """
    Produces Js binary artifacts.
    """
    _rescript_binary(
        name = name,
        src = src,
        deps = deps,
        data = data,
        is_windows = get_is_windows(),
        compiler = get_compiler(),
        **kwargs
    )
