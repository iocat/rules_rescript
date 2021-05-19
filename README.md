# rules_rescript
Bazel Rules for Rescript

### 🚧 🚧 Project is under construction. PRs are welcomed. 🚧 🚧

## How to turn your repository into a rescript repo:

In your WORKSPACE file, add the following snippet and run rescript_repository to load the neccessary rescript rules:

```bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "iocat_rules_rescript",
    sha256 = "52e24089222482f9b1646079fa375d9c8662aa104597470b6ff5fd9ebeb78ac8",
    strip_prefix = "rules_rescript-452c9d0d49ce13e8a40be8f31cc1929078b7f16c",
    urls = ["https://github.com/iocat/rules_rescript/archive/452c9d0d49ce13e8a40be8f31cc1929078b7f16c.tar.gz"],
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