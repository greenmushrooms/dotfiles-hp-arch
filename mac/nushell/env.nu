# env.nu
#
# Installed by:
# version = "0.112.2"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# Stamped as early as possible so the startup banner (see config.nu) can report
# how much of nushell's startup time was spent evaluating env.nu + config.nu.
$env.NU_LOAD_START = (date now)

# The banner's "already drawn" flag is per-shell state, but env vars are exported
# to children as strings — a nu spawned from another nu (e.g. inside herdr)
# would inherit NU_BANNER_DRAWN="true" and the pre_prompt hook's `not` would fail
# on every prompt. Drop any inherited copy so each shell starts fresh.
hide-env -i NU_BANNER_DRAWN

$env.config.show_banner = false
$env.config.edit_mode = "vi"

#default is prefix
$env.config.completions.algorithm = "substring"

$env.config.datetime_format.table = "%F %T"

# Custom PATH additions
use std/util "path add"
path add "/opt/homebrew/bin"
path add "/opt/homebrew/sbin"
path add ($env.HOME | path join ".local" "bin")
