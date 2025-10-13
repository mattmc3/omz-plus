# OMZ PLUS!
# Home: https://github.com/mattmc3/omz-plus
# License: MIT

# If OMZ_PLUS is not defined, use the current script's directory.
[[ -n "$OMZ_PLUS" ]] || export OMZ_PLUS="${${(%):-%x}:a:h}"
OMZ_PLUS_VERSION=1.0.0

# Set variables and configure OMZ PLUS!
() {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  typeset -g ZSH{,_CUSTOM,_CACHE_DIR}

  # Set Oh-My-Zsh variables since oh-my-zsh.sh hasn't been sourced yet.
  if [[ -z "$ZSH" ]]; then
    if [[ -n "$ZDOTDIR" ]]; then
      export ZSH="$ZDOTDIR/ohmyzsh"
    else
      export ZSH="$HOME/.oh-my-zsh"
    fi
  fi

  # We use ZSH_CUSTOM set for symlinking
  : ${ZSH_CUSTOM:=$ZSH/custom}

  # Set ZSH_CACHE_DIR to the path where cache files should be created
  if [[ -n "$XDG_CACHE_HOME" ]]; then
    : "${ZSH_CACHE_DIR:=$XDG_CACHE_HOME/oh-my-zsh}"
  else
    : "${ZSH_CACHE_DIR:=$ZSH/cache}"
  fi
  mkdir -p "$ZSH_CACHE_DIR/omz-plus"

  # Warn if $ZSH_CUSTOM is in zsh_custom array
  if (( ${zsh_custom[(I)$ZSH_CUSTOM]} )); then
    echo >&2 "omz-plus: warning: \$ZSH_CUSTOM ($ZSH_CUSTOM) found in the zsh_custom array."
    echo >&2 "If setting \$zsh_custom, do not add \$ZSH_CUSTOM to it."
  fi

  # Set 'plus' variables to store the extended values.
  typeset -gU plugins_plus=($plugins)
  : ${ZSH_THEME_PLUS:=$ZSH_THEME}

  # Reset the Oh-My-Zsh variables to basic values.
  plugins=(${${plugins_plus:t}%\#*})
  ZSH_THEME=${${ZSH_THEME_PLUS:t}%\#*}
}

##? Update OMZ PLUS! and all cloned repos (except pinned ones).
function omz_plus_update {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  local repo plugin commitsha is_pinned
  local -a pinned_repos

  # Collect pinned repos (those with #commit)
  for plugin in ${plugins_plus[@]}; do
    if [[ "$plugin" == *'#'* ]]; then
      pinned_repos+=("${${plugin%\#*}:t}")
    fi
  done

  # Do the same with a pinned theme
  if [[ "$ZSH_THEME_PLUS" == *'#'* ]]; then
    pinned_repos+=("${${ZSH_THEME_PLUS%\#*}:t}")
  fi

  echo "Updating OMZ PLUS!..."
  git -C "$OMZ_PLUS" pull --quiet --ff --rebase --autostash
  for repo in $ZSH_CUSTOM/repos/*/.git(N); do
    repo="${repo:a:h}"
    # Skip update if repo is pinned to a commit
    if (( ${pinned_repos[(I)${repo:t}]} )); then
      echo "Skipping pinned repo: ${repo:t}"
      continue
    fi
    echo "Updating ${repo:t}..."
    git -C "$repo" pull --quiet --ff --rebase --autostash
  done
}

##? Cleanup OMZ PLUS! by resetting everything it downloaded, and all its symlinks.
function omz_plus_reset {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  omz_plus_reset_symlinks() {
    local dir=$1 link target
    [[ -d "$dir" ]] || return
    for link in "$dir"/*; do
      [[ -L "$link" ]] || continue
      target="${link:A}"
      for custdir in $zsh_custom $ZSH_CUSTOM/repos; do
        if [[ ! -e "$target" || "$target" == "$custdir"* ]]; then
          echo "Removing symlink: $link"
          rm -f -- "$link"
        fi
      done
    done
  }

  # Remove symlinks that point to repos
  omz_plus_reset_symlinks "$ZSH_CUSTOM/plugins"
  omz_plus_reset_symlinks "$ZSH_CUSTOM/themes"
  unfunction omz_plus_reset_symlinks

  # Remove the repos directory
  if [[ -d "$ZSH_CUSTOM/repos" ]]; then
    echo "Removing repos: $ZSH_CUSTOM/repos"
    rm -rf -- "$ZSH_CUSTOM/repos"
  fi

  # Remove the cache directory
  if [[ -d "$ZSH_CACHE_DIR/omz-plus" ]]; then
    echo "Removing cache: $ZSH_CACHE_DIR/omz-plus"
    rm -rf -- "$ZSH_CACHE_DIR/omz-plus"
  fi
}

##? Clone any Zsh plugins that are in repo form.
function omz_plus_clone {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB NO_MONITOR
  local plugin repo_dir repo repo_url commitsha initfile omz_initfile current_sha
  local -a initfiles=() clone_args=()
  local repo_type=$1; shift
  # Ensure required directories exist before cloning/symlinking
  mkdir -p "$ZSH_CUSTOM/repos" "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
  for plugin in $@; do
    [[ "$plugin" == */* ]] || continue

    # Pin repo to a specific commit sha if provided
    commitsha=""
    clone_args=(--quiet --depth 1 --recursive --shallow-submodules)
    repo="$plugin"
    if [[ "$plugin" == *'#'* ]]; then
      commitsha="${plugin##*\#}"
      repo="${plugin%\#*}"
      clone_args+=(--no-checkout)
    fi

    repo_url="https://github.com/$repo"
    if [[ $repo == (https://|git@)* ]]; then
      repo_url="$repo"
      repo="${repo:h:t}/${repo:t}"
    fi

    repo_dir=$ZSH_CUSTOM/repos/${repo:t}
    if [[ "$repo_type" == "plugins" ]]; then
      initfile=$repo_dir/${repo:t}.plugin.zsh
    elif [[ "$repo_type" == "themes" ]]; then
      initfile=$repo_dir/${repo:t}.zsh-theme
    fi
    {
      if [[ ! -d $repo_dir ]]; then
        echo "Cloning $repo..."
        git clone "${clone_args[@]}" $repo_url $repo_dir
        if [[ -n "$commitsha" ]]; then
          git -C $repo_dir fetch --quiet origin "$commitsha"
          git -C $repo_dir checkout --quiet "$commitsha"
        fi
      elif [[ -n "$commitsha" ]]; then
        # Repo exists and we want it pinned - check if we need to checkout the pinned commit
        current_sha=$(git -C $repo_dir rev-parse HEAD 2>/dev/null)
        if [[ "$current_sha" != "$commitsha"* ]]; then
          echo "Pinning $repo to $commitsha..."
          git -C $repo_dir fetch --quiet origin "$commitsha" 2>/dev/null || true
          git -C $repo_dir checkout --quiet "$commitsha" 2>/dev/null || true
        fi
      fi
      # See if there's not a proper init file.
      if [[ ! -e $initfile ]]; then
        initfiles=($repo_dir/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
        (( $#initfiles )) || { echo >&2 "No init file found '$repo'." && continue }
        ln -sf $initfiles[1] $initfile
      fi
      if [[ "$repo_type" == "plugins" && ! -e "$ZSH_CUSTOM/plugins/${repo_dir:t}" ]]; then
        ln -s "$repo_dir" "$ZSH_CUSTOM/plugins/${repo_dir:t}"
      elif [[ "$repo_type" == "themes" && ! -e "$ZSH_CUSTOM/themes/${initfile:t}" ]]; then
        ln -s "$initfile" "$ZSH_CUSTOM/themes/${initfile:t}"
      fi
    } &
  done
  wait
}

##? Symlink any Zsh plugins from other custom locations.
function omz_plus_setup_zsh_custom {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB NO_MONITOR
  local lib plugin theme custdir
  for custdir in $zsh_custom; do
    if [[ ! -e $custdir ]]; then
      echo >&2 "omz-plus: zsh_custom: Directory not found '$custdir'."
      continue
    fi
    mkdir -p $ZSH_CUSTOM/lib $ZSH_CUSTOM/plugins $ZSH_CUSTOM/themes
    for lib in $custdir/lib/*.zsh(N); do
      ln -sf $lib $ZSH_CUSTOM/lib/${lib:t}
    done
    for plugin in $custdir/plugins/*(N); do
      ln -sf $plugin $ZSH_CUSTOM/plugins/${plugin:t}
    done
    for theme in $custdir/themes/*.zsh-theme(N); do
      ln -sf $theme $ZSH_CUSTOM/themes/${theme:t}
    done
    for file in $custdir/*.zsh(N); do
      ln -sf $file $ZSH_CUSTOM/${file:t}
    done
  done
}

() {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  # Check cache to avoid expensive operations if nothing changed
  local cache_file="$ZSH_CACHE_DIR/omz-plus/prior.zsh"
  local needs_update=0
  local -a plugins_plus_prior zsh_custom_prior
  local ZSH_THEME_PLUS_PRIOR

  # If the values were the same as a prior run, then we don't need to rerun all the
  # expensive bits.
  if [[ -f "$cache_file" ]]; then
    source "$cache_file"
    if [[ "${(j: :)plugins_plus_prior}" != "${(j: :)plugins_plus}" ]] \
      || [[ "$ZSH_THEME_PLUS_PRIOR" != "$ZSH_THEME_PLUS" ]] \
      || [[ "${(j: :)zsh_custom_prior}" != "${(j: :)zsh_custom}" ]]; then
      needs_update=1
    fi
  else
    needs_update=1
  fi

  if (( needs_update )); then
    # Clone and setup $ZSH_CUSTOM for repo plugins
    omz_plus_clone plugins ${plugins_plus[@]}
    omz_plus_clone themes $ZSH_THEME_PLUS

    # Symlink plugins from multiple custom locations into $ZSH_CUSTOM
    omz_plus_setup_zsh_custom

    # Save cache
    mkdir -p "${cache_file:h}"
    cat > "$cache_file" <<EOF
plugins_plus_prior=(${(q-)plugins_plus[@]})
ZSH_THEME_PLUS_PRIOR=${(q-)ZSH_THEME_PLUS}
zsh_custom_prior=(${(q-)zsh_custom[@]})
EOF
  fi
}
