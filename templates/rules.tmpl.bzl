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
    "cmiFile",
    "cmjFile",
    "astFile",
    # Optional iast.
    "iastFile",
    "jsFile",
    # Includes jsFile and all of its transitive deps
    "jsDepset",
    "srcFile",
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

# collects all interfaces and js files of the dependencies as a depset
def collectCmijAndJsDepSet(ctx):
    return depset([], transitive = [depset(item) for item in [[
        # mod[RescriptModuleProvider].astFile,
        mod[RescriptModuleProvider].cmiFile,
        mod[RescriptModuleProvider].cmjFile,
        mod[RescriptModuleProvider].jsFile,
        # mod[RescriptModuleProvider].srcFile,
    ] for mod in ctx.attr.deps]])

def _rescript_module_impl(ctx):
    moduleArtifactsDir = "_" + ctx.label.name + "/"
    astFile = _compile_to_ast(ctx, moduleArtifactsDir = moduleArtifactsDir)
    iastFile = _perhaps_compile_to_iast(ctx, moduleArtifactsDir = moduleArtifactsDir)

    # Generate cmi, cmj, and js
    cmiFile = ctx.actions.declare_file(moduleArtifactsDir + ctx.label.name + ".cmi")
    cmjFile = ctx.actions.declare_file(moduleArtifactsDir + ctx.label.name + ".cmj")
    jsFile = ctx.actions.declare_file(moduleArtifactsDir + ctx.label.name + ".js")

    depModuleDirs = [mod[RescriptModuleProvider].moduleArtifactsDir for mod in ctx.attr.deps]

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
            inputs = [astFile] + collectCmijAndJsDepSet(ctx).to_list(),
            outputs = [cmiFile, cmjFile, jsFile],
            command = "{} $@ > {}".format(ctx.attr.compiler[CompilerInfo].bsc.path, jsFile.path),
            arguments = [cmiCmjJsArgs],
        )

        # Module with interface provided.
    else:
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
            inputs = [iastFile, ctx.file.interface] + collectCmijAndJsDepSet(ctx).to_list(),
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
            inputs = [astFile, ctx.file.src, cmiFile] + collectCmijAndJsDepSet(ctx).to_list(),
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
        ),
        RescriptModuleProvider(
            srcFile = ctx.file.src,
            astFile = astFile,
            cmiFile = cmiFile,
            cmjFile = cmjFile,
            jsFile = jsFile,
            jsDepset = depset([jsFile], transitive = [dep[RescriptModuleProvider].jsDepset for dep in ctx.attr.deps]),
            iastFile = iastFile,
            moduleArtifactsDir = jsFile.dirname,
        ),
    ]

rescript_module = rule(
    implementation = _rescript_module_impl,
    executable = False,
    attrs = {
        "compiler": attr.label(
            # TODO: This needs to be a sensible default.
            default = Label("@{{REPO_NAME}}//:darwin"),
            providers = [CompilerInfo],
        ),
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
            providers = [RescriptModuleProvider],
        ),
        "data": attr.label_list(allow_files = True),
    },
)

def _rescript_binary_impl(ctx):
    pass

rescript_binary = rule(
    implementation = _rescript_binary_impl,
    executable = True,
    attrs = {
        "compiler": attr.label(
            # TODO: This needs to be a sensible default.
            default = Label("@{{REPO_NAME}}//:darwin"),
            providers = [CompilerInfo],
        ),
    },
)
