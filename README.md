# rules_rescript
Bazel Rules for Rescript

### 🚧 🚧 Project is under construction. PRs are welcomed. 🚧 🚧

## How to turn your repository into a rescript repo:

In your WORKSPACE file, add the following snippet and run rescript_repository to loads the neccessary rescript dependency:

```bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "iocat_rules_rescript",
    sha256 = "76f00cacd089d0605a9c203bbf2d067f5804824435af870e905f0ef621d0fd57",
    strip_prefix = "rules_rescript-d6a42c2b072880338cf9a7b4a189151bfa58a85e",
    urls = ["https://github.com/iocat/rules_rescript/archive/d6a42c2b072880338cf9a7b4a189151bfa58a85e.tar.gz"],
)

load("@iocat_rules_rescript//:repositories.bzl", "rescript_repository")

rescript_repository(
    name = "rescript_rules", # Note the name "rescript_rules", as what you name here will be used everywhere in your workspace.
)
```

# Turn your module(s) into build Bazel targets
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