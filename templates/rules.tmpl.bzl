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

RescriptModuleProvider = provider(fields = [
    "astFile",
    # Optional iast.
    "iastFile",
    "cmiFile",
    "cmjFile",
    "jsFile",
    # Includes jsFile and all of its transitive deps
    "jsDepset",
    "dataDepset",
    # For computing include paths tied to bsc.
    "moduleArtifactsDir",
])

def _perhaps_compile_to_iast(ctx, moduleArtifactsDir = ""):
    if ctx.file.interface == None:
        return None

    iastFile = ctx.actions.declare_file(moduleArtifactsDir + ctx.label.name + ".iast")

    iastArgs = ctx.actions.args()
    iastArgs.add("-bs-v", "{{COMPILER_VERSION}}")
    iastArgs.add("-bs-ast")
    iastArgs.add("-o", iastFile)
    iastArgs.add(ctx.file.interface)

    ctx.actions.run(
        mnemonic = "CompileToiAST",
        executable = ctx.attr.compiler[CompilerInfo].bsc,
        arguments = [iastArgs],
        inputs = depset([ctx.file.interface]),
        outputs = [iastFile],
    )
    return iastFile

def _compile_to_ast(ctx, moduleArtifactsDir = ""):
    astFile = ctx.actions.declare_file(moduleArtifactsDir + ctx.label.name + ".ast")

    astArgs = ctx.actions.args()
    astArgs.add("-bs-v", "{{COMPILER_VERSION}}")
    astArgs.add("-bs-ast")
    astArgs.add("-o", astFile)
    astArgs.add(ctx.file.src)

    ctx.actions.run(
        mnemonic = "CompileToAST",
        executable = ctx.attr.compiler[CompilerInfo].bsc,
        arguments = [astArgs],
        inputs = depset([ctx.file.src]),
        outputs = [astFile],
    )
    return astFile

def dropNone(l):
    return [item for item in l if item != None]

def unique(l):
    set = {}
    for item in l:
        set[item] = True
    return set.keys()

def join_path(is_windows, items):
    items = [item for item in items if item != ""]

    if is_windows:
        return "\\".join(items)
    return "/".join(items)

# collects all interfaces and js files of the dependencies as a depset
def collectCmijAndJsDepSet(deps):
    return depset([], transitive = [depset(item) for item in [[
        mod[RescriptModuleProvider].cmiFile,
        mod[RescriptModuleProvider].cmjFile,
        mod[RescriptModuleProvider].jsFile,
    ] for mod in deps]])

def _rescript_module_impl(ctx):
    # This is supposedly the directory that stores output artifacts relative to
    # the rescript_module build target.
    # Currently, set to the same dir as the target.
    moduleArtifactsDir = ""
    astFile = _compile_to_ast(ctx, moduleArtifactsDir = moduleArtifactsDir)
    iastFile = _perhaps_compile_to_iast(ctx, moduleArtifactsDir = moduleArtifactsDir)

    # Generate cmi, cmj, and js
    cmiFile = ctx.actions.declare_file(join_path(ctx.attr.is_windows, [moduleArtifactsDir, ctx.label.name + ".cmi"]))
    cmjFile = ctx.actions.declare_file(join_path(ctx.attr.is_windows, [moduleArtifactsDir, ctx.label.name + ".cmj"]))
    jsFile = ctx.actions.declare_file(join_path(ctx.attr.is_windows, [moduleArtifactsDir, ctx.label.name + ".js"]))

    # includes dependencies's artifacts and jsFile artifacts in the search paths.
    depsArtifacts = collectCmijAndJsDepSet(ctx.attr.deps)
    depModuleDirs = unique([depArtifact.dirname for depArtifact in depsArtifacts.to_list()])

    # Module without interface
    if iastFile == None:
        # Generates all targets cmi, cmj and js all at the same time.
        cmiCmjJsArgs = ctx.actions.args()
        cmiCmjJsArgs.add("-bs-v", "{{COMPILER_VERSION}}")
        cmiCmjJsArgs.add("-I", cmiFile.dirname)  # include the cmi dir.
        for depModuleDir in depModuleDirs:
            cmiCmjJsArgs.add("-I", depModuleDir)
        cmiCmjJsArgs.add("-o", cmiFile)
        cmiCmjJsArgs.add("-o", cmjFile)
        cmiCmjJsArgs.add(astFile)

        ctx.actions.run_shell(
            mnemonic = "CompileToCmiCmjJs",
            tools = [ctx.attr.compiler[CompilerInfo].bsc],
            inputs = [ctx.file.src, astFile] + depsArtifacts.to_list(),
            outputs = [cmiFile, cmjFile, jsFile],
            command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, jsFile.path),
            arguments = [cmiCmjJsArgs],
        )

    else:  # Module with interface provided.
        # Generates cmi separately.
        cmiArgs = ctx.actions.args()
        cmiArgs.add("-I", ctx.file.interface.dirname)
        for depModuleDir in depModuleDirs:
            cmiArgs.add("-I", depModuleDir)
        cmiArgs.add("-o", cmiFile)
        cmiArgs.add(iastFile)
        ctx.actions.run_shell(
            mnemonic = "CompileToCmi",
            tools = [ctx.attr.compiler[CompilerInfo].bsc],
            inputs = [ctx.file.interface, iastFile] + depsArtifacts.to_list(),
            outputs = [cmiFile],
            command = "{} $@".format(ctx.attr.compiler[CompilerInfo].bsc.path),
            arguments = [cmiArgs],
        )

        # Generates cmj and js files
        cmjJsArgs = ctx.actions.args()
        cmjJsArgs.add("-bs-read-cmi")  # Read the CMI file generated from previous step (from iAST file.)
        cmjJsArgs.add("-I", cmiFile.dirname)  # include the cmi dir.
        for depModuleDir in depModuleDirs:
            cmjJsArgs.add("-I", depModuleDir)
        cmjJsArgs.add("-o", cmjFile)
        cmjJsArgs.add(astFile)
        ctx.actions.run_shell(
            mnemonic = "CompileToCmjJs",
            tools = [ctx.attr.compiler[CompilerInfo].bsc],
            inputs = [ctx.file.src, astFile, cmiFile] + depsArtifacts.to_list(),
            outputs = [cmjFile, jsFile],
            command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, jsFile.path),
            arguments = [cmjJsArgs],
        )

    return [
        DefaultInfo(
            files = depset(
                dropNone(
                    [
                        astFile,
                        cmiFile,
                        cmjFile,
                        jsFile,
                        iastFile,
                    ],
                ),
                transitive = [dep[RescriptModuleProvider].jsDepset for dep in ctx.attr.deps],
            ),
            runfiles = ctx.runfiles(
                files = ctx.files.data,
                transitive_files = depset([], transitive = [dep[RescriptModuleProvider].dataDepset for dep in ctx.attr.deps]),
            ),
        ),
        RescriptModuleProvider(
            astFile = astFile,
            cmiFile = cmiFile,
            cmjFile = cmjFile,
            jsFile = jsFile,
            jsDepset = depset([jsFile], transitive = [dep[RescriptModuleProvider].jsDepset for dep in ctx.attr.deps]),
            dataDepset = depset(ctx.files.data, transitive = [dep[RescriptModuleProvider].dataDepset for dep in ctx.attr.deps]),
            iastFile = iastFile,
            moduleArtifactsDir = cmiFile.dirname,
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
    moduleArtifactsDir = ""

    astFile = _compile_to_ast(ctx, moduleArtifactsDir = moduleArtifactsDir)

    cmiFile = ctx.actions.declare_file(join_path(ctx.attr.is_windows, [moduleArtifactsDir, ctx.label.name + ".cmi"]))
    cmjFile = ctx.actions.declare_file(join_path(ctx.attr.is_windows, [moduleArtifactsDir, ctx.label.name + ".cmj"]))
    jsFile = ctx.actions.declare_file(join_path(ctx.attr.is_windows, [moduleArtifactsDir, ctx.label.name + ".js"]))

    depsArtifacts = collectCmijAndJsDepSet(ctx.attr.deps)
    depModuleDirs = unique([depArtifact.dirname for depArtifact in depsArtifacts.to_list()])

    # Generates all targets cmi, cmj and js all at the same time.
    cmiCmjJsArgs = ctx.actions.args()
    cmiCmjJsArgs.add("-bs-v", "{{COMPILER_VERSION}}")
    cmiCmjJsArgs.add("-I", cmiFile.dirname)  # include the cmi dir.
    for depModuleDir in depModuleDirs:
        cmiCmjJsArgs.add("-I", depModuleDir)
    cmiCmjJsArgs.add("-o", cmiFile)
    cmiCmjJsArgs.add("-o", cmjFile)
    cmiCmjJsArgs.add(astFile)

    ctx.actions.run_shell(
        mnemonic = "CompileToCmiCmjJs",
        tools = [ctx.attr.compiler[CompilerInfo].bsc],
        inputs = [ctx.file.src, astFile] + depsArtifacts.to_list(),
        outputs = [cmiFile, cmjFile, jsFile],
        command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, jsFile.path),
        arguments = [cmiCmjJsArgs],
    )

    return [
        DefaultInfo(
            executable = jsFile,
            runfiles = ctx.runfiles(
                files = ctx.files.data,
                transitive_files = depset(
                    [],
                    transitive = [dep[RescriptModuleProvider].dataDepset for dep in ctx.attr.deps] + [dep[RescriptModuleProvider].jsDepset for dep in ctx.attr.deps],
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
