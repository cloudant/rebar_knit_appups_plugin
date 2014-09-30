rebar\_knit\_appups\_plugin
===========================

This is a plugin to replace the builtin `generate-appups` command for
[rebar][rebar]. This works by reading a number of module attributes that
affect appup generation.


[rebar]: https://github.com/rebar/rebar


Module Attributes
-----------------

The way we pass metadata to the appup generation algorithm is through
module attributes. This way we store appup related information directly
in the affected modules which means that our upgrade logic will be less
likely to go stale with source changes.

Supported module attributes:

* `rebar_knit_priority` - Set a module priority. This is an integer which
  defaults to 0. Added and changed modules are sorted according to this
  priority. Beware that relup generation will also affect ordering if you use
  module dependencies.
* `rebar_knit_extra` - Set the value of Extra for code_change. This defaults to
  an empty list.
* `rebar_knit_depends` - Set module dependencies. This is a list of module
  names as atoms.
* `rebar_knit_timeout` - Set an time when suspending processes. This isn't 
  common option.
* `rebar_knit_purge` - Set the purge style. Purging affects how processes
  running old code are handled during an upgrade. There is a pre and post merge
  step and both can be either `soft_purge` or `brutal_purge`. `soft_purge`
  basically means to skip the purge step and just wait for Erlang to kill the
  process running old code. `brutal_purge` means that the upgrade process will
  kill any process running old code for this module. The value for this
  attribute should be of the form `soft_purge | brutal_purge | {Pre, Post}`.
  Setting it as an atom is just a shorthand for setting `Pre` and `Post` to the
  same value. Default is `{brutal_purge, brutal_purge}`. If you're uncertain
  use `brutal_purge` as it'll be immediately clear if your code is upgrading
  properly. `{brutal_purge, brutal_purge}` is the default.
* `rebar_knit_apply` - Run a function during an upgrade. This lets you run
  arbitrary code to affect how things are managed. In general the most common
  use case for this option is to change supervision trees during an upgrade.
  This can either be an MFA or a `{Phase, MFA}` tuple. There are three phases:
  `first`, `immediate`, `last` which affect when the function is invoked. First
  means before new code is loaded, immediate is just after the current module
  is loaded, and last is after all other modules have been loaded. `Phase` can
  also be `{PhaseName, Priority}` if you want to be specific on the ordering
  of invocation. N.B. that the first/immediate/last phase is on a
  per-application basis. There's no support (yet) for a global ordering. This
  will be added if/when is needed.


A Note on Module Dependencies
-----------------------------

Module dependencies are quite useful but there's a non-obvious effect of
using them buried in systools. Basically, any connected set of module
dependencies will be grouped in the relup and upgraded between the same
suspend/resume calls. Its possible that this can have unintended side effects
during an upgrade.

For instance, a common case might be if you have a `gen_server` behavior
paired with a utility module that you want to upgrade simultaneously. Adding
a `-rebar_knit_depends([my_app_util])` would be a straightforward method to
accomplish this. The part to be careful on is if you have a second
`gen_server` that you also want to have depend on `my_app_util`. If you do
this then processes running code from *both* `gen_server` modules will be
suspended simultaneously.

In general its best to try and make sure that your modules can be upgraded
independently but sometimes a simple dependency will save you lots of pain
trying to support multiple live module versions.
