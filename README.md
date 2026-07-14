# OMZ PLUS!

> Enhancements for Oh-My-Zsh

<img align="right" style="float: right;" width="250" alt="Plus!" src="https://github.com/user-attachments/assets/b834d42b-d6d9-4da9-ad7d-98d1b62e79f1" />

[Oh-My-Zsh][ohmyzsh] is an incredibly popular framework for the Zsh shell. _OMZ Plus!_
aims to make Oh-My-Zsh even better by enhancing its capabilities.

_OMZ Plus!_ is named as an homage to Microsoft Plus! which added extras to Windows in
the 90's.

The main features:

-   _OMZ Plus!_ enhances the `$plugins` array so it supports git-hosted plugins!
-   _OMZ Plus!_ enhances the `$ZSH_THEME` variable so it supports git-hosted themes!
-   _OMZ Plus!_ provides an alternative to the singular `$ZSH_CUSTOM` variable with a
    new `$zsh_custom` array, which supports git-hosted custom directories too!

## TLDR

The trick with _OMZ Plus!_ is it pre-processes the builtin Oh-My-Zsh variables
you're already using. By sourcing _OMZ Plus!_ right before you source Oh-My-Zsh, it
detects git-hosted plugins, handles cloning and symlinking, and then scrubs those
variables back to the basics so that they are ready for Oh-My-Zsh to use.

Show me the code!

```zsh
# example .zshrc

# You can now use git repo syntax in your $ZSH_THEME.
ZSH_THEME=romkatv/powerlevel10k

# You can now use git repos in your $plugins array.
plugins=(
  git
  extract
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
)

# You can use multiple custom locations by using the new zsh_custom array
# which symlinks plugins, libraries, and themes from multiple locations
# into your $ZSH_CUSTOM. Git repos work here too!
zsh_custom=(
  $ZDOTDIR/custom
  $ZDOTDIR/custom.local
  mattmc3/zsh_custom
)

# Enable OMZ Plus! by simply sourcing it immediately before Oh-My-Zsh.
source /path/to/omz-plus.sh
source /path/to/oh-my-zsh.sh
```

## Install/Update/Uninstall

Add this block to your `.zshrc` right before `source $ZSH/oh-my-zsh.sh`:

```zsh
# .zshrc
# ...initial oh-my-zsh configuration...
# plugins(...)

##### START OMZ PLUS! ##################################################################
export OMZ_PLUS=${ZDOTDIR:-$HOME}/.omz-plus
[ -d "$OMZ_PLUS" ] || git clone https://github.com/mattmc3/omz-plus $OMZ_PLUS
source $OMZ_PLUS/omz-plus.sh
##### END OMZ PLUS! ####################################################################

# Source oh-my-zsh.sh immediately after omz-plus.sh
source $ZSH/oh-my-zsh.sh

# ...remaining oh-my-zsh configuration...
```

To update, run `omz+ update`, which will get the latest version of all plugins
(unless pinned).

Run `omz+ reset` if you have any issues. This will remove any cloned repos and
symlinks, returning your config back to its pre-_OMZ Plus!_ state.

To uninstall completely, run `omz+ reset`, then `rm -rf /path/to/omz-plus` to
remove _OMZ Plus!_, and then remove the _OMZ Plus!_ block in your .zshrc config.

## Details

With _OMZ Plus!_, you can now use Zsh plugins hosted on GitHub (or another git provider)
by using URLs or "short repo" syntax in your `$plugins` array and `$ZSH_THEME` variable.

You can also 'pin' repos to a particular SHA, which ensures that your plugin sticks to
a particular commit. This is a helpful way to protect yourself from upstream
modifications that break your config, or worse — supply chain attacks.

See example:

```zsh
plugins=(
    ### standard oh-my-zsh plugins
    git
    extract

    ### enhanced OMZ PLUS! plugins
    # 'user/project' short repo syntax is supported for GitHub-hosted plugins.
    zsh-users/zsh-completions
    # You can pin a plugin to a particular SHA with repo@SHA syntax
    zsh-users/zsh-autosuggestions@85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
    # The repo#ref form pins to any ref: a SHA, branch, or tag
    # zsh-users/zsh-autosuggestions#v0.7.1
    # You can use URLs as well, which is useful for plugins not hosted on GitHub.com
    https://codeberg.org/tranzystorekk/zellij.zsh
)
```

The `$ZSH_THEME` variable also supports git hosted plugins:

```zsh
# Use git hosted themes (eg: sindresorhus/pure)
ZSH_THEME=romkatv/powerlevel10k
```

Additionally, multiple `$ZSH_CUSTOM` directories are supported by using a `$zsh_custom`
alternative array.

```zsh
# Use either $ZSH_CUSTOM for a single custom directory...
# ZSH_CUSTOM=/path/to/new-custom-folder
# ...OR... you can alternatively use $zsh_custom for multiple
zsh_custom=(
    ${ZDOTDIR:-$HOME}/.zsh_custom_for_home
    ${ZDOTDIR:-$HOME}/.zsh_custom_for_work
)
```

The `$zsh_custom` array supports git-hosted custom directories too, using the same
short repo, URL, and `repo@SHA` pinning syntax as `$plugins`. Absolute paths are
treated as local directories; anything else containing a slash is treated as a git
repo and cloned to `$ZSH_CUSTOM/repos`.

```zsh
zsh_custom=(
    # Local custom directories use absolute paths
    ${ZDOTDIR:-$HOME}/.zsh_custom
    # Git-hosted custom directories use repo syntax
    mattmc3/zsh_custom
    # Pinning to a SHA works too
    # mattmc3/zsh_custom@c093219c458e1d2f721b12da3c9bb704bfc9845a
)
```

Use _either_ `ZSH_CUSTOM` for a single custom directory or `zsh_custom` for multiple.
_OMZ Plus!_ symlinks all the `zsh_custom` customization directories into Oh-My-Zsh's
singular `ZSH_CUSTOM` directory, so you typically only want to set one or the other.

**NOTE:** If you do set both, beware not to put the `ZSH_CUSTOM` location into the
`zsh_custom` array. If you do, _OMZ Plus!_ will warn you and remove it! _OMZ Plus!_
uses `ZSH_CUSTOM` as a symlink and git clone target, so beware!

Also note that the plugins and themes in `zsh_custom` locations override each other,
meaning that if a plugin, library, or theme of the same name is defined in multiple
custom places, the last one wins. Overriding _stock_ Oh-My-Zsh plugins is a different
story — see [Shadowing stock Oh-My-Zsh](#shadowing-stock-oh-my-zsh).

## Shadowing stock Oh-My-Zsh

Oh-My-Zsh prefers `$ZSH_CUSTOM/plugins/<name>` over its own `$ZSH/plugins/<name>`, so
a `zsh_custom` collection containing a plugin named `git` or `extract` would silently
replace the stock plugin. _OMZ Plus!_ puts you in control of this "shadowing" with a
per-collection policy:

-   **Local collections** (absolute paths) shadow stock by default. A directory you
    authored behaves the way `$ZSH_CUSTOM` always has — your override is deliberate.
-   **Git-hosted collections** do _not_ shadow stock by default. Colliding plugins,
    libraries, and themes are skipped, and stock wins. A third-party collection can't
    swap out `git` behind your back.

Configure the policy with a single `shadow` zstyle, set before sourcing
`omz-plus.sh`. The context is `:omz-plus:custom:<repo>:<kind>:<item>`, where
`<kind>` is `plugins`, `lib`, or `themes`:

```zsh
# Allow one plugin from this collection to shadow stock
zstyle ':omz-plus:custom:mattmc3/zsh_custom:plugins:git' shadow yes

# Or allow all of the collection's plugins with a zstyle pattern...
zstyle ':omz-plus:custom:mattmc3/zsh_custom:plugins:*' shadow yes
# ...with exceptions, since more specific contexts win
zstyle ':omz-plus:custom:mattmc3/zsh_custom:plugins:extract' shadow no
```

`<repo>` is the `zsh_custom` entry itself, with any `@sha`/`#ref` pin and
`.git` suffix removed — `mattmc3/zsh_custom@c093219c458e1d2f721b12da3c9bb704bfc9845a`
and `mattmc3/zsh_custom` are the same collection, and `joe/zsh_custom` never inherits
`matt/zsh_custom`'s policy.
Local collections use their full path
(`:omz-plus:custom:/home/me/.zsh_custom:plugins:git`). `<item>` is the name as it
appears in `$ZSH_CUSTOM`: plugin directory name (`git`), library file name
(`git.zsh`), or theme file name (`agnoster.zsh-theme`). When in doubt,
`omz+ shadows` prints the exact context for every collision.

A note on library files: Oh-My-Zsh loads a custom `lib/<file>.zsh` _instead of_ the
stock file of the same name — wholesale replacement — and never loads custom lib
files with non-stock names. That makes lib shadowing the riskiest kind, so prefer
enabling lib files by exact name (`:lib:git.zsh`) over collection-wide patterns. A
bare `:*` pattern covers lib too; to allow everything else but keep lib out:

```zsh
zstyle ':omz-plus:custom:mattmc3/zsh_custom:*' shadow yes
zstyle ':omz-plus:custom:mattmc3/zsh_custom:lib:*' shadow no
```

Skipped shadows aren't silent. Setup prints a one-time notice when it skips colliding
items, and `omz+ shadows` lists every stock collision with its current winner and
the exact zstyle to flip it:

```
plugins/git: stock (mattmc3/zsh_custom skipped; enable with: zstyle ':omz-plus:custom:mattmc3/zsh_custom:plugins:git' shadow yes)
plugins/fzf: mattmc3/zsh_custom (shadows stock; disable with: zstyle ':omz-plus:custom:mattmc3/zsh_custom:plugins:fzf' shadow no)
```

Shadow zstyles belong in your `.zshrc` before `source omz-plus.sh`. Changes there
apply automatically on the next shell start. To apply zstyle edits made in a live
shell right away, run `omz+ update`, which also refreshes collection symlinks
after pulling repo updates.

Shadow policy only governs collection-vs-stock. Between collections, array order still
decides: last one wins.

**NOTE:** Prior to v1.2.0, all collections shadowed stock silently. If you relied on a
git-hosted collection overriding stock plugins, opt back in with
`zstyle ':omz-plus:custom:<repo>:*' shadow yes`.

## How it all works

_OMZ Plus!_ will clone your plugins and themes to `$ZSH/custom/repos`, and symlink them
into `$ZSH/custom/plugins` and `$ZSH/custom/themes`. Pinned repos embed the short SHA
in their directory name (eg: `zsh-autosuggestions@85919cd`), so changing or removing
a pin simply clones fresh rather than mutating an existing checkout. Repos are cloned
by name, so two repos from different owners sharing a name (eg: `alice/tool` and
`bob/tool`) collide, and only the first gets cloned. Your original `$plugins` values
will be saved to `$plugins_plus`, and likewise `$ZSH_THEME` saved to `$ZSH_THEME_PLUS`
so you have the originals if you need them. The standard Oh-My-Zsh `$plugins` array and
`$ZSH_THEME` variable will be scrubbed so that Oh-My-Zsh gets only values it expects
and not the enhancements _OMZ Plus!_ provides.

Additionally, `$zsh_custom` will symlink your plugins and themes to the singular
`$ZSH_CUSTOM` location that Oh-My-Zsh recognizes. Because of this, it is not recommended
to use both—use `$ZSH_CUSTOM` for only one location, and `$zsh_custom` if you
use multiple locations.

## References

-   [#11095 - Multiple ZSH_CUSTOM directories](https://github.com/ohmyzsh/ohmyzsh/issues/11095)
-   [#13200 - Automatically Install plugins](https://github.com/ohmyzsh/ohmyzsh/issues/13200)
-   [#12156 - Allow symlinked plugins](https://github.com/ohmyzsh/ohmyzsh/issues/12156)
-   [#12865 - Please add zsh-users' zsh-autosuggestions as an in-built plugin](https://github.com/ohmyzsh/ohmyzsh/issues/12865)
-   [#12872 - Please add zsh-users' zsh-completions as an in-built plugin](https://github.com/ohmyzsh/ohmyzsh/issues/12872)

## Testing

Tests use [bats](https://github.com/bats-core/bats-core) (`brew install bats-core`)
and clone small repos from GitHub, so they need network access:

```zsh
bats tests
# ...or with just:
just test
```

## Misc

Note: This project is not affiliated with Oh-My-Zsh. Use of Microsoft Plus! references
are for parody purposes.

[ohmyzsh]: https://github.com/ohmyzsh/ohmyzsh
[zsh-autosuggestions]: https://github.com/zsh-users/zsh-autosuggestions
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[xdg_basedirs]: https://specifications.freedesktop.org/basedir-spec/latest/
