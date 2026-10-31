# Documentation in this fork

SagradaSpace's installation, migration, and fork-specific behavior are documented
in the repository's [README](../README.md). Build and architecture notes are in
[dev-docs](../dev-docs/).

The AsciiDoc command reference and guide here are inherited **AeroSpace**
documentation. Upstream names, URLs, screenshots, and attribution are deliberately
preserved. When using SagradaSpace, invoke `sagradaspace` instead of `aerospace`;
the app is `SagradaSpace.app` rather than `AeroSpace.app`.

The upstream configuration paths (`~/.aerospace.toml` and
`$XDG_CONFIG_HOME/aerospace/aerospace.toml`), `AEROSPACE_*` callback environment
variables, and `during-aerospace-startup` matcher remain supported unchanged.
The personal [bundled config](config-examples/default-config.toml) is specific to
this fork; the [upstream default](config-examples/upstream-default-config.toml)
is retained separately for reference and regression tests.
