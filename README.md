# rules_rescript
Bazel Rules for Rescript

### 🚧 🚧 Project is under construction. PRs are welcomed. 🚧 🚧

## How to turn your repository into a rescript repo:

In your WORKSPACE file, add the following snippet and run rescript_repository to loads the neccessary rescript dependency:

```bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "iocat_rules_rescript",
    sha256 = "734cd22aea7ca061e52b3a9ab4f62d3b992e0f83fc146fcd0dc443e28ec6b7ca",
    strip_prefix = "rules_rescript-d70deabc4bf73a66f0ad3b7b6ef7c224430b2279",
    urls = ["https://github.com/iocat/rules_rescript/archive/d70deabc4bf73a66f0ad3b7b6ef7c224430b2279.tar.gz"],
)

load("@iocat_rules_rescript//:repositories.bzl", "rescript_repository")

rescript_repository(
    name = "rescript_rules", # Note the name "rescript_rules", as what you name here will be used everywhere in your workspace.
)
```

# Turn your module(s) into Bazel build targets
Say, you have the following Rescript code:

```rescript
// example/Example.res

let map = (stream, functor) =>
  Stream.from(_ =>
    try Some(stream->Stream.next->functor) catch {
    | Stream.Failure => None
    }
  )
// ...

```

```rescript
// example/Example.resi

let map: (Stream.t<'a>, 'a => 'b) => Stream.t<'b>
// ...

```

Then, your BUILD file is: 
```bazel
# example/BUILD
load("@rescript_rules//:rules.bzl", "rescript_module")

rescript_module (
  name = "example",
  src = "Example.res",
  interface = "Example.resi",
  deps = [],
)
```