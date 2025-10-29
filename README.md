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
    new `$zsh_custom` array!

## TLDR

The trick with _OMZ Plus!_ is it pre-processes the builtin Oh-My-Zsh variables
you're already using. By sourcing _OMZ Plus!_ right before you source Oh-My-Zsh, it
detects git hosted plugins, handles cloning and symlinking, and then scrubs those
variables so that they are ready for Oh-My-Zsh to use them.

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

# You can use multiple custom locations instead of a singular $ZSH_CUSTOM
# by using the new $zsh_custom array, which symlinks into your $ZSH_CUSTOM.
zsh_custom=(
  $ZDOTDIR/custom
  $ZDOTDIR/custom.local
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

To update, run `omz_plus_update`, which will get the latest version of all plugins
(unless pinned).

Run `omz_plus_reset` if you have any issues to remove any cloned repos and symlinks and return your config back to its pre-_OMZ Plus!_ state.

To uninstall completely, run `omz_plus_reset`, then `rm -rf /path/to/omz-plus` to
remove it, then remove the _OMZ Plus!_ portion of your .zshrc config.

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
    # You can pin a plugin to a particular SHA with repo#SHA syntax
    zsh-users/zsh-autosuggestions#85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
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

Use _either_ `ZSH_CUSTOM` for a single custom directory or `zsh_custom` for multiple.
_OMZ Plus!_ symlinks all the `zsh_custom` customization directories into Oh-My-Zsh's
singular `ZSH_CUSTOM` directory, so you typically only want to set one or the other.

**NOTE:** If you do set both, beware not to put the `ZSH_CUSTOM` location into the
`zsh_custom` array. If you do, _OMZ Plus!_ will warn you and remove it! _OMZ Plus!_
uses `ZSH_CUSTOM` as a symlink and git clone target, so beware!

Also note that the plugins and themes in `zsh_custom` locations override each other,
meaning that if a plugin, library, or theme of the same name is defined in multiple
custom places, the last one wins.

## How it all works

_OMZ Plus!_ will clone your plugins and themes to `$ZSH/custom/repos`, and symlink them
into `$ZSH/custom/plugins` and `$ZSH/custom/themes`. Your original `$plugins` values
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

## Misc

Note: This project is not affiliated with Oh-My-Zsh. Use of Microsoft Plus! references
are for parody purposes.

[ohmyzsh]: https://github.com/ohmyzsh/ohmyzsh
[zsh-autosuggestions]: https://github.com/zsh-users/zsh-autosuggestions
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[xdg_basedirs]: https://specifications.freedesktop.org/basedir-spec/latest/
