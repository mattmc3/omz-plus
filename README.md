# OMZ PLUS!

> Enhancements for Oh-My-Zsh

<img align="right" style="float: right;" width="250" alt="Plus!" src="https://github.com/user-attachments/assets/b834d42b-d6d9-4da9-ad7d-98d1b62e79f1" />

[Oh-My-Zsh][ohmyzsh] is an incredibly popular Zsh framework, but it lacks some important features. _OMZ Plus!_ aims to make
Oh-My-Zsh even better by adding awesome extra features.

_OMZ Plus!_ is named as an homage to Microsoft Plus! which added extras to Windows in the 90's.

The main features:

-   _OMZ Plus!_ enhances the `$plugins` array so it supports git hosted plugins!
-   _OMZ Plus!_ enhances the `$ZSH_THEME` variable so it supports git hosted themes!
-   _OMZ Plus!_ provides an alternative to the singluar `$ZSH_CUSTOM` variable with a
    new `$zsh_custom` array!

## Installation

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

## Details

With _OMZ PLUS!_ you can now use Zsh plugins hosted on GitHub (or another git provider) by
using URLs or "short repo" syntax in your `$plugins` array.

```zsh
plugins=(
    ### standard oh-my-zsh plugins
    git
    extract

    ### enhanced OMZ PLUS! plugins
    # 'user/project' short repo syntax supported for GitHub.com hosted plugins.
    zsh-users/zsh-completions
    # You can pin a plugin to a particular SHA with repo#SHA syntax
    zsh-users/zsh-autosuggestions#85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
    # You can use URLs as well, which is useful for plugins not hosted on GitHub.com
    https://codeberg.org/tranzystorekk/zellij.zsh
)
```

The `$ZSH_THEME` variable also now supports git hosted plugins:

```zsh
ZSH_THEME=romkatv/powerlevel10k
```

Multiple `$ZSH_CUSTOM` directories are supported by using a `$zsh_custom` alternative array.

```zsh
# Use either ZSH_CUSTOM for a single custom directory...
# ZSH_CUSTOM=/path/to/new-custom-folder
# ...OR... use zsh_custom for multiple
zsh_custom=(
    ${ZDOTDIR:-$HOME}/.zsh_custom
    ${ZDOTDIR:-$HOME}/.zsh_custom_work
)
```

Use _either_ `ZSH_CUSTOM` for a single custom directory or `zsh_custom` multiple. _OMZ PLUS!_
symlinks all the `zsh_custom` customization directories into the Oh-My-Zsh's singular
`ZSH_CUSTOM` directory.

Also note that the plugins and themes in `$zsh_custom` locations override each other, meaning
that if a plugin of the same name is defined in multiple places, the last one wins.

## Use XDG Base Directories

If you don't want to pollute your `$HOME` directory, it's handy to set
[XDG Base Directory variables][xdg_basedirs]. To make it easy so you don't have to set
them all yourself, you can now simply set the `USE_XDG_BASEDIRS` variable before
loading _OMZ PLUS!_ and it will set them for you:

```zsh
USE_XDG_BASEDIRS=true
```

## How it all works

_OMZ PLUS!_ will clone your plugins and themes to `$ZSH/custom/repos`, and symlink them
into `$ZSH/custom/plugins` and `$ZSH/custom/themes`. Your original `$plugins` values
will be saved to `$plugins_plus`, and likewise `$ZSH_THEME` saved to `$ZSH_THEME_PLUS`
so you have the originals if you need them. The standard Oh-My-Zsh `$plugins` array and
`$ZSH_THEME` variable will be scrubbed so that Oh-My-Zsh gets only values it expects
and not the enhancements _OMZ PLUS!_ provides.

Additionally, `$zsh_custom_plus` will symlink your plugins and themes to the singular
`$ZSH_CUSTOM` location that Oh-My-Zsh recognizes. Because of this, it is not recommended
to use both - use `$ZSH_CUSTOM` for only one location, and `$zsh_custom_plus` if you
use multiple locations.

## References

-   [#11095 - Multiple ZSH_CUSTOM directories](https://github.com/ohmyzsh/ohmyzsh/issues/11095)
-   [#13200 - Automatically Install plugins](https://github.com/ohmyzsh/ohmyzsh/issues/13200)
-   [#12156 - Allow symlinked plugins](https://github.com/ohmyzsh/ohmyzsh/issues/12156)
-   [#12865 - Please add zsh-users' zsh-autosuggestions as an in-built plugin](https://github.com/ohmyzsh/ohmyzsh/issues/12865)
-   [#12872 - Please add zsh-users' zsh-completions as an in-built plugin](https://github.com/ohmyzsh/ohmyzsh/issues/12872)

## Misc

Note: This project is not affiliated with Oh-My-Zsh. Use of Microsoft Plus! references are for
parody purposes.

[ohmyzsh]: https://github.com/ohmyzsh/ohmyzsh
[zsh-autosuggestions]: https://github.com/zsh-users/zsh-autosuggestions
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[xdg_basedirs]: https://specifications.freedesktop.org/basedir-spec/latest/
