# dotfiles_clean

A keyboard-driven macOS desktop that I can rebuild in one command: AeroSpace tiling, a SketchyBar menu bar, a focus border, Ghostty + Nushell + Starship, Neovim, and a vim-mode Firefox.

This repo holds only the portable, ease-of-use layer. It has no employer-specific config, credentials, or cloud wrappers. Those belong in a private repo or in a Nushell autoload file (see [Machine-specific extras](#machine-specific-extras)).

A styled version of this file is in [`README.html`](README.html). Firefox also serves it as its shortcuts page at <http://localhost:8347/shortcuts.html>.

---

## Install (repeatable)

```sh
xcode-select --install                         # once: git + /usr/bin/python3
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"   # once: Homebrew
git clone <this repo> ~/projects/dotfiles_clean
cd ~/projects/dotfiles_clean
./install.sh --dry-run                         # see what it would change
./install.sh
```

You can run `install.sh` again at any time. It's idempotent: links and files that are already correct are reported as `ok`, and anything else in the way is moved to `<name>.bak.<timestamp>`, never deleted. It does this:

1. **`brew bundle`**: installs everything in [`Brewfile`](Brewfile) that's missing.
2. **Symlinks** each config from this repo into place (table below). Edits in the repo are live.
3. **Services**: starts (or restarts) SketchyBar and JankyBorders as brew services, and launches or reloads AeroSpace.
4. **Firefox**: copies the autoconfig into the app bundle, copies `user.js`, `userChrome.css`, and `userContent.css` into the active profile, and installs a LaunchAgent that serves `firefox/home/` on `localhost:8347`. It also installs Tridactyl's native messenger and opens the Tridactyl installer if the extension is missing.

Flags: `--dry-run` (change nothing), `--no-brew` (configs only).

**Manual steps that macOS won't let a script do:**

- System Settings → Privacy & Security → **Accessibility** → allow **AeroSpace**.
- System Settings → Control Center → *Automatically hide and show the menu bar* → **Always**, so SketchyBar takes that strip.
- Optional: `./macos/defaults.sh` applies AeroSpace-friendly macOS tweaks (group windows by app in Mission Control, one Space across displays, hidden menu bar). Log out afterwards.
- First `nvim` launch: plugins clone automatically. Then run `:CopilotSignIn` if you want Copilot.
- After a **Firefox update**, re-run `./install.sh`, because updates replace the app bundle and the autoconfig with it.

---

## Programs this setup depends on

Everything is installed by the [`Brewfile`](Brewfile).

| Program | What it does here | Brew | Config in repo | Linked / copied to | Reload after editing |
|---|---|---|---|---|---|
| **AeroSpace** | i3-style tiling window manager, all window/workspace hotkeys | `cask nikitabobko/tap/aerospace` | `aerospace/aerospace.toml` | `~/.aerospace.toml` | <kbd>ctrl</kbd><kbd>alt</kbd><kbd>cmd</kbd><kbd>R</kbd> |
| **SketchyBar** | Menu bar: workspaces 1–9, focused app, CPU, RAM, Slack badge, battery, clock | `felixkratz/formulae/sketchybar` | `sketchybar/` | `~/.config/sketchybar` | `brew services restart sketchybar` |
| **JankyBorders** | Blue border on the focused window | `felixkratz/formulae/borders` | `borders/bordersrc` | `~/.config/borders` | `brew services restart borders` |
| **Ghostty** | Terminal and drop-down quake terminal | `cask ghostty` | `ghostty/config` | `~/.config/ghostty` | <kbd>cmd</kbd><kbd>shift</kbd><kbd>,</kbd> |
| **Nushell** | Shell (vi mode, fzf/yazi keys, auto-venv, startup banner) | `nushell` | `nushell/config.nu`, `env.nu` | `~/Library/Application Support/nushell/` | new shell |
| **Starship** | Prompt (dir, git, python/venv, duration) | `starship` | `starship/starship.toml` | `~/.config/starship.toml` | next prompt |
| **Neovim** 0.12+ | Editor, native `vim.pack` plugins, native LSP | `neovim` | `nvim/` | `~/.config/nvim` | restart / `:restart` |
| **Firefox** | Browser: hidden nav bar, local start page, Tridactyl | `cask firefox` (into `~/Applications`) | `firefox/` | app bundle + profile (copied) | restart Firefox |
| **Tridactyl** (No New Tab) | Vim keys in Firefox | opened by `install.sh` | `firefox/tridactylrc` | `~/.config/tridactyl/tridactylrc` | `:source` in Tridactyl |
| **Zed** | Second editor (<kbd>alt</kbd><kbd>Z</kbd>) | `cask zed` | — | — | — |
| **Slack** | <kbd>alt</kbd><kbd>S</kbd>, unread badge in the bar | `cask slack` | — | — | — |
| **1Password** | Floats instead of tiling | `cask 1password` | — | — | — |

**Supporting tools:**

| Tool | Needed by |
|---|---|
| `fzf` | Nushell <kbd>ctrl</kbd><kbd>F</kbd> file picker |
| `yazi` | Nushell <kbd>ctrl</kbd><kbd>E</kbd> / `y` file manager |
| `uv` | Python venvs (auto-activated on `cd`) |
| `ripgrep` | Telescope grep in nvim |
| `tree-sitter-cli` | nvim-treesitter (`main` branch) parser builds |
| `node` | mason-installed `pyright` and `copilot-language-server` |
| `go` | Go LSP/tests (`gopls` and `lua-language-server` are commented out in the Brewfile; enable them if you need them) |
| `opencode` | opencode.nvim |
| `git`, `gh` | git, GitHub auth |
| `font-hack-nerd-font` | SketchyBar and Starship icons |
| `font-meslo-lg-nerd-font` | Ghostty font (MesloLGM Nerd Font) |
| `/usr/bin/python3` (Xcode CLT) | Firefox home-page server (`http.server` on 127.0.0.1:8347) |

---

## Shortcuts

### AeroSpace: windows and workspaces

<kbd>alt</kbd> is the base modifier. Everything is a held chord; there are no modes to get stuck in. Plain <kbd>ctrl</kbd> is never used, so it stays free for nvim and the shell.

| Keys | Action |
|---|---|
| <kbd>alt</kbd> <kbd>1</kbd>…<kbd>9</kbd> | Go to workspace N |
| <kbd>alt</kbd> <kbd>shift</kbd> <kbd>1</kbd>…<kbd>9</kbd> | Send window to workspace N and follow |
| <kbd>alt</kbd> <kbd>shift</kbd> <kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> | Focus left / down / up / right |
| <kbd>alt</kbd> <kbd>←</kbd>/<kbd>↓</kbd>/<kbd>↑</kbd>/<kbd>→</kbd> | Focus (arrows) |
| <kbd>alt</kbd> <kbd>h</kbd>/<kbd>j</kbd>/<kbd>k</kbd>/<kbd>l</kbd> | Move window left / down / up / right |
| <kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>h</kbd> / <kbd>l</kbd> | Narrower / wider |
| <kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>j</kbd> / <kbd>k</kbd> | Shorter / taller |
| <kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>0</kbd> | Equalize window sizes |
| <kbd>alt</kbd> <kbd>/</kbd> | Tiles: toggle horizontal / vertical |
| <kbd>alt</kbd> <kbd>,</kbd> | Accordion (stacked) layout |
| <kbd>alt</kbd> <kbd>shift</kbd> <kbd>space</kbd> | Toggle floating |
| <kbd>alt</kbd> <kbd>F</kbd> | Fullscreen (keeps the window's place in the layout, unlike the green button) |
| <kbd>alt</kbd> <kbd>Q</kbd> | Close window (quits the app if it was the last window) |
| <kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>cmd</kbd> <kbd>h</kbd> / <kbd>l</kbd> | Focus monitor left / right |
| <kbd>ctrl</kbd> <kbd>shift</kbd> <kbd>alt</kbd> <kbd>h</kbd> / <kbd>l</kbd> | Move window to monitor left / right |
| <kbd>ctrl</kbd> <kbd>alt</kbd> <kbd>cmd</kbd> <kbd>R</kbd> | Reload AeroSpace config |

### AeroSpace: launchers

| Keys | Opens |
|---|---|
| <kbd>alt</kbd> <kbd>T</kbd> | Ghostty (new window) |
| <kbd>alt</kbd> <kbd>B</kbd> | Firefox (new window) |
| <kbd>alt</kbd> <kbd>Z</kbd> | Zed |
| <kbd>alt</kbd> <kbd>E</kbd> | Finder at `~` |
| <kbd>alt</kbd> <kbd>S</kbd> | Slack |
| <kbd>alt</kbd> <kbd>N</kbd> | Quick notes: `nvim ~/Documents/notes.txt` in a new Ghostty |

Finder, System Settings, and 1Password always float.

### SketchyBar and borders

| What | Behaviour |
|---|---|
| Workspace numbers | Click to switch. Blue pill = focused, bright = has windows, dim = empty |
| Slack icon | Unread count, red when > 0, `•` for unreads without mentions. Click opens Slack |
| CPU / RAM | Turn red at ≥ 80% / ≥ 85% (RAM = Activity Monitor's "Memory Used") |
| Blue window border | The focused window (JankyBorders) |

### Ghostty

| Keys | Action |
|---|---|
| <kbd>cmd</kbd> <kbd>`</kbd> | Toggle the quake drop-down terminal (global, from any app) |

Ghostty opens Nushell in `~/projects`.

### Nushell

Vi edit mode: <kbd>esc</kbd> for normal mode, <kbd>i</kbd> to insert. The prompt shows `❯` in insert mode and `❮` in normal mode.

| Keys / command | Action |
|---|---|
| <kbd>ctrl</kbd> <kbd>F</kbd> | fzf over files below `$PWD`, inserts the pick at the cursor |
| <kbd>ctrl</kbd> <kbd>E</kbd> | yazi file manager, `cd`s to wherever you quit it |
| `y [dir]` | Same as <kbd>ctrl</kbd> <kbd>E</kbd> |
| `projects` | `cd ~/projects` |
| `brew-up` | `brew upgrade`, then restart AeroSpace (and unstick SketchyBar) if the upgrade left them mismatched |
| `applefetch` | Redraw the startup banner (system info + startup time) |
| `cd` into a project | Its nearest `.venv` activates automatically, and deactivates when you leave |

### Neovim

Leader is <kbd>space</kbd>.

**Files and navigation**

| Keys | Action |
|---|---|
| <kbd>leader</kbd> <kbd>pf</kbd> | Find files (incl. hidden, not `.git`/`.venv`) |
| <kbd>ctrl</kbd> <kbd>P</kbd> | Git files |
| <kbd>leader</kbd> <kbd>ps</kbd> | Grep (prompt) |
| <kbd>leader</kbd> <kbd>pws</kbd> / <kbd>pWs</kbd> | Grep word / WORD under cursor |
| <kbd>leader</kbd> <kbd>vh</kbd> | Help tags |
| <kbd>leader</kbd> <kbd>pv</kbd> | netrw file explorer |
| <kbd>leader</kbd> <kbd>px</kbd> | Neo-tree sidebar toggle |
| <kbd>leader</kbd> <kbd>a</kbd> | Harpoon: add file |
| <kbd>ctrl</kbd> <kbd>E</kbd> | Harpoon: quick menu |
| <kbd>leader</kbd> <kbd>1</kbd>…<kbd>5</kbd> | Harpoon: jump to slot N (slots show in the tabline) |
| <kbd>ctrl</kbd> <kbd>K</kbd> / <kbd>ctrl</kbd> <kbd>J</kbd> | Quickfix next / prev |
| <kbd>leader</kbd> <kbd>k</kbd> / <kbd>leader</kbd> <kbd>j</kbd> | Location list next / prev |

**Editing**

| Keys | Action |
|---|---|
| visual <kbd>J</kbd> / <kbd>K</kbd> | Move selection down / up |
| <kbd>J</kbd> | Join lines, cursor stays put |
| <kbd>ctrl</kbd> <kbd>D</kbd> / <kbd>ctrl</kbd> <kbd>U</kbd>, <kbd>n</kbd> / <kbd>N</kbd> | Half-page / search jumps, recentred |
| visual <kbd>leader</kbd> <kbd>p</kbd> | Paste over without losing the register |
| <kbd>leader</kbd> <kbd>y</kbd> / <kbd>Y</kbd> | Yank to system clipboard |
| <kbd>leader</kbd> <kbd>d</kbd> | Delete to black hole |
| <kbd>leader</kbd> <kbd>s</kbd> | Substitute word under cursor (file-wide) |
| <kbd>leader</kbd> <kbd>f</kbd> | LSP format |
| <kbd>leader</kbd> <kbd>w</kbd> | Toggle line wrap |
| <kbd>leader</kbd> <kbd>x</kbd> | `chmod +x` current file |
| <kbd>leader</kbd> <kbd>ee</kbd> | Insert Go `if err != nil { return err }` |
| <kbd>leader</kbd> <kbd>leader</kbd> | `:source` current file |
| insert <kbd>ctrl</kbd> <kbd>C</kbd> | Escape |
| <kbd>leader</kbd> <kbd>u</kbd> | Undotree |
| <kbd>leader</kbd> <kbd>nf</kbd> / <kbd>nt</kbd> | Neogen docstring for function / type |
| <kbd>leader</kbd> <kbd>zz</kbd> / <kbd>zZ</kbd> | Zen mode (with / without numbers) |
| <kbd>leader</kbd> <kbd>ck</kbd> | Cloak: mask / unmask `.env` values |

**Completion, Copilot, snippets**

| Keys | Action |
|---|---|
| <kbd>enter</kbd> (menu open) | Accept highlighted item, or the first one |
| <kbd>ctrl</kbd> <kbd>N</kbd> / <kbd>ctrl</kbd> <kbd>P</kbd> | Move through the completion menu |
| <kbd>tab</kbd> | Accept Copilot ghost text (plain tab when there is none) |
| <kbd>alt</kbd> <kbd>]</kbd> / <kbd>alt</kbd> <kbd>[</kbd> | Next / prev Copilot suggestion |
| <kbd>leader</kbd> <kbd>tc</kbd> | Toggle Copilot suggestions |
| <kbd>ctrl</kbd> <kbd>S</kbd> <kbd>;</kbd> / <kbd>ctrl</kbd> <kbd>S</kbd> <kbd>,</kbd> | Snippet: next / prev placeholder |

**LSP** (in buffers with a language server)

| Keys | Action |
|---|---|
| <kbd>gd</kbd> | Definition |
| <kbd>K</kbd> | Hover |
| <kbd>leader</kbd> <kbd>vrr</kbd> | References |
| <kbd>leader</kbd> <kbd>vrn</kbd> | Rename |
| <kbd>leader</kbd> <kbd>vca</kbd> | Code action |
| <kbd>leader</kbd> <kbd>vd</kbd> | Diagnostic float |
| <kbd>leader</kbd> <kbd>vws</kbd> | Workspace symbol |
| <kbd>[d</kbd> / <kbd>]d</kbd> | Next / prev diagnostic |
| insert <kbd>ctrl</kbd> <kbd>H</kbd> | Signature help |
| <kbd>leader</kbd> <kbd>tt</kbd>, <kbd>[t</kbd> / <kbd>]t</kbd> | Trouble list toggle, next / prev |

**Git, tests, AI**

| Keys | Action |
|---|---|
| <kbd>leader</kbd> <kbd>gs</kbd> | Fugitive status |
| <kbd>leader</kbd> <kbd>p</kbd> / <kbd>P</kbd> (in Fugitive) | Push / pull --rebase |
| <kbd>leader</kbd> <kbd>t</kbd> (in Fugitive) | `:Git push -u origin ` (type the branch) |
| <kbd>gu</kbd> / <kbd>gh</kbd> | Merge conflict: take left (//2) / right (//3) |
| <kbd>leader</kbd> <kbd>tn</kbd> / <kbd>tf</kbd> | Neotest: nearest test / whole file |
| <kbd>leader</kbd> <kbd>oa</kbd> | opencode: ask about this |
| <kbd>leader</kbd> <kbd>os</kbd> / <kbd>ot</kbd> | opencode: select action / toggle panel |
| <kbd>go</kbd>{motion}, <kbd>goo</kbd> | Send range / line to opencode |
| <kbd>leader</kbd> <kbd>ou</kbd> / <kbd>od</kbd> | Scroll opencode up / down |

### Firefox

New tabs and windows open the local start page (`firefox/home/index.html`) with focus on the page, not the address bar, so Tridactyl keys work at once.

| Keys | Action |
|---|---|
| <kbd>cmd</kbd> <kbd>E</kbd> | Show / hide the address bar (hidden by default; show it before installing extensions so the prompt can appear) |
| <kbd>cmd</kbd> <kbd>L</kbd> | Focus address bar |
| <kbd>cmd</kbd> <kbd>T</kbd> / <kbd>N</kbd> / <kbd>W</kbd> | New tab / window, close |
| <kbd>cmd</kbd> <kbd>shift</kbd> <kbd>T</kbd> | Reopen closed tab |
| <kbd>cmd</kbd> <kbd>1</kbd>…<kbd>9</kbd> | Tab N (9 = last) |
| <kbd>cmd</kbd> <kbd>opt</kbd> <kbd>I</kbd> | DevTools |

**Tridactyl** (vim mode; off on addons.mozilla.org so install prompts work):

| Keys | Action |
|---|---|
| <kbd>f</kbd> / <kbd>F</kbd> | Follow link hint / in background tab |
| <kbd>j</kbd> / <kbd>k</kbd>, <kbd>gg</kbd> / <kbd>G</kbd> | Scroll, top / bottom |
| <kbd>H</kbd> / <kbd>L</kbd> | Back / forward |
| <kbd>o</kbd> / <kbd>t</kbd> | Open URL here / in new tab |
| <kbd>d</kbd> / <kbd>u</kbd> | Close tab / undo close |
| <kbd>J</kbd> / <kbd>K</kbd> | Previous / next tab |
| <kbd>/</kbd> | Find in page |
| <kbd>shift</kbd> <kbd>esc</kbd> | Disable Tridactyl on this page (toggle) |
| <kbd>:</kbd> | Command line (`:help` for everything) |

---

## Repo layout

```
dotfiles_clean/
├── install.sh            idempotent installer (brew bundle + links + services + Firefox)
├── Brewfile              every package/app/font the configs need
├── macos/defaults.sh     optional AeroSpace-friendly macOS settings
├── aerospace/            ~/.aerospace.toml
├── sketchybar/           sketchybarrc + plugins/*.sh
├── borders/              bordersrc (JankyBorders)
├── ghostty/              config
├── nushell/              config.nu, env.nu
├── starship/             starship.toml
├── nvim/                 init.lua, lua/plugins/*, lsp/*, nvim-pack-lock.json
└── firefox/
    ├── autoconfig/       mozilla.cfg + local-settings.js (go in the app bundle)
    ├── user.js, userChrome.css, userContent.css   (go in the profile)
    ├── tridactylrc
    ├── firefox-home-server.plist   LaunchAgent template (path filled in by install.sh)
    └── home/             start page + shortcuts.html (→ README.html)
```

## Changing things

- **Add a package**: add a line to `Brewfile`, then run `./install.sh` (or `brew bundle`).
- **Add an nvim plugin**: add `{ src = "https://github.com/owner/repo" }` to `vim.pack.add` in `nvim/init.lua`, create `nvim/lua/plugins/<name>.lua`, and `require` it from `nvim/lua/plugins/init.lua`. Update all plugins with `:lua vim.pack.update()`. `nvim-pack-lock.json` pins plugin revisions, so commit it.
- **Add a shortcut**: edit the config, then update **both** `README.md` and `README.html`. This README is the cheatsheet.

## Machine-specific extras

Keep secrets and work-only commands out of this repo. Nushell loads every `*.nu` file in `~/Library/Application Support/nushell/autoload/` after `config.nu`. Put cloud CLI wrappers, port-forward menus, and work `PATH` additions there, or symlink them in from a private repo.
