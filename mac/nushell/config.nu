# config.nu
#
# Installed by:
# version = "0.112.2"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R
#
$env.config.buffer_editor = 'nvim'


# Machine- or employer-specific commands (cloud CLI wrappers, port-forward menus,
# etc.) don't belong here: drop them in a .nu file under
# $nu.user-autoload-dirs (~/Library/Application Support/nushell/autoload/) and
# nushell loads them after this file.

$env.config.keybindings = ($env.config.keybindings | append {
    name: fuzzy_file
    modifier: control
    keycode: char_f
    mode: [emacs vi_normal vi_insert]
    event: {
        send: executehostcommand
        cmd: "commandline edit --insert (glob **/* --exclude [**/.*/**] | to text | fzf | str trim)"
    }
})

# Launch yazi and cd into the directory it was left in on exit.
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    ^yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp)
    if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
    }
    rm -fp $tmp
}

$env.config.keybindings = ($env.config.keybindings | append {
    name: yazi
    modifier: control
    keycode: char_e
    mode: [emacs vi_normal vi_insert]
    event: {
        send: executehostcommand
        cmd: "y"
    }
})

def --env projects [] {
    cd ($env.HOME | path join "projects")
}

# Auto-activate a Python venv when you cd into a project that has one
# (and deactivate when you leave). Walks up from $PWD to find the nearest
# .venv, then puts its bin dir on PATH and sets VIRTUAL_ENV — enough for tools
# like the pre-commit dbt-parse hook that shell out to `dbt` and need it on PATH.
# We avoid `overlay use` because it requires a parse-time-constant path and
# can't take the dynamically-discovered venv dir.
def find-venv-root [] {
    mut dir = $env.PWD
    loop {
        let candidate = ($dir | path join ".venv" "bin")
        if ($candidate | path exists) { return ($dir | path join ".venv") }
        let parent = ($dir | path dirname)
        if $parent == $dir { return null }
        $dir = $parent
    }
}

$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD? | default [] | append (
        r#'
        let want = (find-venv-root)
        let active = ($env.AUTO_VENV? | default null)
        if $want != $active {
            # Deactivate the previously auto-activated venv (if any).
            if $active != null {
                let old_bin = ($active | path join "bin")
                $env.PATH = ($env.PATH | where $it != $old_bin)
                hide-env -i VIRTUAL_ENV
                hide-env -i AUTO_VENV
            }
            # Activate the new one (if we found a venv above $PWD).
            if $want != null {
                $env.PATH = ($env.PATH | prepend ($want | path join "bin"))
                $env.VIRTUAL_ENV = $want
                $env.AUTO_VENV = $want
            }
        }
        '#
    )
)

# `brew upgrade`, then restart AeroSpace if the upgrade left the old server
# running under the new CLI ("client and server versions are incompatible").
# Only restarts on a mismatch, since restarting can regroup windows. Hung
# SketchyBar plugin runs survive the restart and keep holding the draw lock,
# freezing the workspace highlight, so those are killed and the lock cleared.
def --wrapped brew-up [...args: string] {
    ^brew upgrade ...$args
    let v = (^aerospace --version | complete)
    if not ($v.stdout + $v.stderr | str contains "incompatible") { return }

    print "AeroSpace upgraded — restarting it"
    ^osascript -e 'quit app "AeroSpace"'
    while (^pgrep -xq AeroSpace | complete).exit_code == 0 { sleep 200ms }
    ^open -a AeroSpace
    for _ in 1..50 {
        if (^aerospace list-workspaces --focused | complete).exit_code == 0 { break }
        sleep 200ms
    }

    ^pkill -f plugins/aerospace.sh | complete | ignore
    ^pkill -f 'aerospace list-workspaces' | complete | ignore
    rm -rf ($env.TMPDIR | path join "sketchybar_aerospace.lock")
    with-env { SENDER: "aerospace_workspace_change" } {
        ^bash ($env.HOME | path join ".config/sketchybar/plugins/aerospace.sh")
    }
}

# Starship prompt. Config lives in ../starship/starship.toml (symlinked to
# ~/.config/starship.toml). Committed here rather than using the generated
# vendor/autoload/starship.nu so the whole prompt is version-controlled.
$env.STARSHIP_SHELL = "nu"

def create_left_prompt [] {
    starship prompt --cmd-duration $env.CMD_DURATION_MS $'--status=($env.LAST_EXIT_CODE)'
}

$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = ""

# Prompt indicators. edit_mode is "vi" (see env.nu), so the vi insert/normal
# indicators are handled by Starship's character module and left blank here.
$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_MULTILINE_INDICATOR = "::: "

# Startup banner: Apple logo on the left, system info + startup timing on the
# right (fastfetch-ish, but built in so it costs ~1ms instead of spawning a
# process — `sys` is native). Nushell's own banner is off (see env.nu); this
# replaces it. Named `applefetch` rather than `banner` because `banner` is a
# nushell builtin (the stock welcome message) and shadowing it resolves
# inconsistently.
#
# The info column is sized to fill the logo's height: OS/kernel/shell block,
# then live CPU / memory / battery / network, then startup timing.
#
# `sys disks` and `sys temp` are deliberately absent: they cost ~50ms each,
# versus ~1ms for host/cpu/mem/net. Battery is the one shell-out (`pmset`,
# ~55ms) because macOS exposes it nowhere cheaper — drop the `Battery` row if
# you want the banner back under a millisecond.
#
# "Startup" is nushell's total startup time plus how much of it went into
# evaluating env.nu + config.nu — i.e. the cost of all the custom commands,
# hooks and keybindings defined in here.
def applefetch [] {
    let logo = [
        [color art];
        ["#61BB46" "                    'c."]
        ["#61BB46" "                 ,xNMM."]
        ["#61BB46" "               .OMMMMo"]
        ["#61BB46" "               OMMM0,"]
        ["#FDB827" "     .;loddo:' loolloddol;."]
        ["#FDB827" "   cKMMMMMMMMMMNWMMMMMMMMMM0:"]
        ["#FDB827" " .KMMMMMMMMMMMMMMMMMMMMMMMWd."]
        ["#F5821F" " XMMMMMMMMMMMMMMMMMMMMMMMX."]
        ["#F5821F" ";MMMMMMMMMMMMMMMMMMMMMMMM:"]
        ["#F5821F" ":MMMMMMMMMMMMMMMMMMMMMMMM:"]
        ["#E03A3E" ".MMMMMMMMMMMMMMMMMMMMMMMMX."]
        ["#E03A3E" " kMMMMMMMMMMMMMMMMMMMMMMMMWd."]
        ["#963D97" " .XMMMMMMMMMMMMMMMMMMMMMMMMMMk"]
        ["#963D97" "  .XMMMMMMMMMMMMMMMMMMMMMMMMK."]
        ["#009DDC" "    kMMMMMMMMMMMMMMMMMMMMMMd"]
        ["#009DDC" "     ;KMMMMMMMWXXWMMMMMMMk."]
        ["#009DDC" "       .cooc,.    .,coo:."]
    ]

    let host = (sys host)
    let cpu = (sys cpu)
    let mem = (sys mem)
    # $nu.startup-time is still -1ns while config.nu is being evaluated, hence
    # the n/a fallback when `applefetch` is run outside an interactive session.
    let ms = {|d| if $d == null or $d < 0ns { "n/a" } else { $"(($d / 1ms) | math round -p 1)ms" } }
    let mins = (($host.uptime / 1min) | math floor)
    let uptime = (
        [[v u]; [($mins // 1440) "d"] [(($mins mod 1440) // 60) "h"] [($mins mod 60) "m"]]
        | where v > 0
        | each {|r| $"($r.v)($r.u)" }
        | str join " "
        | default "just now"
    )

    # 10-cell gauge, green → yellow → red as it fills. `invert` flips the
    # colouring for things where empty is the bad end (battery charge).
    let gauge = {|frac, invert|
        let n = ([([0 (($frac * 10) | math round)] | math max) 10] | math min)
        let bad = (if $invert { 1 - $frac } else { $frac })
        let color = (if $bad > 0.85 { "#E03A3E" } else if $bad > 0.6 { "#FDB827" } else { "#61BB46" })
        $"(ansi dark_gray)[(ansi { fg: $color })('' | fill -w $n -c '█')(ansi dark_gray)('' | fill -w (10 - $n) -c '─')](ansi reset)"
    }

    # The busiest non-virtual interface with an IPv4 address — i.e. whichever of
    # wifi/ethernet/tethering is actually carrying traffic, without shelling out
    # to `route get default`. `sent`/`recv` are totals since boot.
    let nic = (
        sys net
        | where {|i| ($i.name !~ '^(lo|awdl|llw|utun|gif|stf|bridge|anpi|ap)') and ($i.ip | where protocol == "ipv4" | is-not-empty) }
        | sort-by recv --reverse
        | get --optional 0
    )

    # pmset's summary line, e.g. " -InternalBattery-0 (id=123)\t82%; discharging; 4:12 remaining".
    let batt = (
        try {
            pmset -g batt
            | parse --regex '(?<pct>[0-9]+)%; (?<state>[^;]+); (?<rem>[0-9]+:[0-9]+)'
            | get --optional 0
        } catch { null }
    )

    let row = {|k, v| $"(ansi { fg: '#F5821F' attr: b })($k | fill -w 10)(ansi reset)($v)" }
    let rule = "\u{1}"  # placeholder: becomes a horizontal rule once the column width is known
    let info = (
        [
            $"(ansi { fg: '#61BB46' attr: b })($env.USER | split row '@' | first)(ansi reset)@(ansi { fg: '#009DDC' attr: b })($host.hostname)(ansi reset)"
            $rule
            (do $row "OS" $"($host.long_os_version) \(($nu.os-info.arch)\)")
            (do $row "Kernel" $"($host.name) ($host.kernel_version)")
            (do $row "Shell" $"nu (version | get version)")
            (do $row "Terminal" ($env.TERM_PROGRAM? | default $env.TERM? | default "unknown"))
            (do $row "Uptime" $uptime)
            $rule
            (do $row "CPU" $"($cpu | get brand.0) \(($cpu | length) cores\) @ (($cpu | get freq.0) / 1000 | math round -p 2) GHz")
            (do $row "Load" $"($cpu | get load_average.0)   (do $gauge (($cpu | get load_average.0 | split row ', ' | first | into float) / ($cpu | length)) false)")
            # Same figure as Activity Monitor's "Memory Used": macOS counts
            # anonymous + wired + compressed pages, so 60%+ is normal and not
            # pressure (`memory_pressure` is the real check).
            (do $row "Memory" $"($mem.used) / ($mem.total)   (do $gauge ($mem.used / $mem.total) false) (($mem.used / $mem.total * 100) | math round)%")
        ]
        | append (
            if $batt != null {
                let pct = ($batt.pct | into int)
                let left = (if $batt.state == "discharging" and $batt.rem != "0:00" { $" \((($batt.rem)) left\)" } else { "" })
                [(do $row "Battery" $"($pct)% ($batt.state)($left)   (do $gauge ($pct / 100) true)")]
            } else { [] }
        )
        | append (
            if $nic != null {
                [
                    (do $row "Network" $"($nic.name)  ($nic.ip | where protocol == 'ipv4' | get address.0)")
                    (do $row "Traffic" $"↑ ($nic.sent)  ↓ ($nic.recv)")
                ]
            } else { [] }
        )
        | append [
            $rule
            (do $row "Startup" $"(do $ms $nu.startup-time) total, (do $ms $env.NU_CONFIG_LOAD_TIME?) env.nu + config.nu")
            ($logo | get color | uniq | each {|c| $"(ansi { fg: $c })███(ansi reset)" } | str join "")
        ]
    )

    # Rules span the widest info row, so the column reads as one block however
    # long the OS/startup strings turn out to be. `--grapheme-clusters` matters:
    # plain `str length` counts bytes, so the gauge/arrow rows (█ ─ ↑ ↓ are 3
    # bytes each) would measure ~3x too wide and blow the rules out.
    let text_width = ($info | where {|l| $l != $rule } | each {|l| $l | ansi strip | str length --grapheme-clusters } | math max)
    let info = ($info | each {|l| if $l == $rule { $"(ansi dark_gray)('' | fill -w $text_width -c '─')(ansi reset)" } else { $l } })

    # Pad the logo to a fixed width and vertically centre the shorter of the two
    # columns against the taller one.
    let width = ($logo | get art | each { str length } | math max)
    let height = ([($logo | length) ($info | length)] | math max)
    let logo_pad = (($height - ($logo | length)) // 2)
    let info_pad = (($height - ($info | length)) // 2)

    # One `print` for the whole banner: each `print` call costs tens of ms when
    # stdout isn't a fast tty, so one per line would dominate the render.
    print (
        0..<$height
        | each {|i|
            let li = ($i - $logo_pad)
            let l = (if $li >= 0 { $logo | get --optional $li } else { null })
            let art = if $l == null { "" | fill -w $width } else { $"(ansi { fg: $l.color })($l.art | fill -w $width)(ansi reset)" }
            let ii = ($i - $info_pad)
            let text = (if $ii >= 0 { $info | get --optional $ii | default "" } else { "" })
            if $text == "" { $art } else { $"($art)   ($text)" }
        }
        | prepend ""
        | append ""
        | str join (char nl)
    )
}

# Draw the banner at the first prompt rather than here: $nu.startup-time isn't
# populated until config.nu has finished evaluating. String-form hook (not a
# closure) so it can set the "already drawn" flag in the caller's environment.
$env.config.hooks.pre_prompt = (
    $env.config.hooks.pre_prompt? | default [] | append (
        r#'
        if not ($env.NU_BANNER_DRAWN? | default false) {
            $env.NU_BANNER_DRAWN = true
            applefetch
        }
        '#
    )
)

# Keep this last: everything above is what it measures. Guarded in case env.nu
# (where NU_LOAD_START is stamped) wasn't loaded — the banner then shows "n/a".
if $env.NU_LOAD_START? != null {
    $env.NU_CONFIG_LOAD_TIME = ((date now) - $env.NU_LOAD_START)
}
