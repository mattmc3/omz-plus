# OMZ PLUS!
# Home: https://github.com/mattmc3/omz-plus
# License: MIT

# If OMZ_PLUS is not defined, use the current script's directory.
[[ -n "$OMZ_PLUS" ]] || export OMZ_PLUS="${${(%):-%x}:a:h}"
OMZ_PLUS_VERSION=1.1.0

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

  # Warn if $ZSH_CUSTOM is in zsh_custom array, and remove it since it is
  # the symlink and clone target for everything else in the array.
  if (( ${zsh_custom[(I)$ZSH_CUSTOM]} )); then
    echo >&2 "omz-plus: warning: \$ZSH_CUSTOM ($ZSH_CUSTOM) found in the zsh_custom array."
    echo >&2 "If setting \$zsh_custom, do not add \$ZSH_CUSTOM to it. Removing it."
    zsh_custom=(${zsh_custom:#$ZSH_CUSTOM})
  fi

  # Set 'plus' variables to store the extended values.
  typeset -gU plugins_plus=($plugins)
  : ${ZSH_THEME_PLUS:=$ZSH_THEME}

  # Reset the Oh-My-Zsh variables to basic values.
  plugins=(${${${plugins_plus:t}%[#@]*}%.git})
  ZSH_THEME=${${${ZSH_THEME_PLUS:t}%[#@]*}%.git}
}

##? Parse a repo spec into its parts: reply=(repo pinref repo_dir_name)
function _omz_plus_parse_repo {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  local spec=$1 repo=$1 pinref=
  # '#ref' always pins (sha, branch, or tag). '@ref' pins only when the ref
  # is sha-like, since '@' also appears in ssh clone URLs.
  if [[ "$spec" == *'#'* ]]; then
    repo="${spec%\#*}"
    pinref="${spec##*\#}"
  elif [[ "$spec" == (#b)(*)@([[:xdigit:]](#c7,40)) ]]; then
    repo="$match[1]"
    pinref="$match[2]"
  fi
  # Pinned repos get the ref embedded in their directory name (full shas
  # shortened to 7 chars, slashes in ref names made path-safe)
  local refdir=$pinref
  [[ "$refdir" == [[:xdigit:]](#c40) ]] && refdir="${refdir[1,7]}"
  refdir="${refdir//\//-}"
  typeset -ga reply
  reply=("$repo" "$pinref" "${${repo:t}%.git}${refdir:+@$refdir}")
}

##? Update OMZ PLUS! and all cloned repos (except pinned ones).
function omz_plus_update {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  local repo prior_sha

  echo "Updating OMZ PLUS!..."
  prior_sha=$(git -C "$OMZ_PLUS" rev-parse HEAD)
  git -C "$OMZ_PLUS" pull --quiet --rebase --autostash
  if [[ "$(git -C "$OMZ_PLUS" rev-parse HEAD)" != "$prior_sha" ]]; then
    echo "OMZ PLUS! was updated. Restart your shell to use the new version."
  fi
  for repo in $ZSH_CUSTOM/repos/*/.git(N); do
    repo="${repo:a:h}"
    # Pinned repos embed '@sha' in their directory name and never update
    if [[ "${repo:t}" == *@* ]]; then
      echo "Skipping pinned repo: ${repo:t}"
      continue
    fi
    echo "Updating ${repo:t}..."
    git -C "$repo" pull --quiet --rebase --autostash
  done
}

##? Cleanup OMZ PLUS! by resetting everything it downloaded, and all its symlinks.
function omz_plus_reset {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  omz_plus_reset_symlinks() {
    local dir=$1 link target custdir
    [[ -d "$dir" ]] || return
    for link in "$dir"/*(N); do
      [[ -L "$link" ]] || continue
      target="${link:A}"
      for custdir in $zsh_custom $ZSH_CUSTOM/repos; do
        # :A both sides or symlinked paths (eg: /tmp on macOS) won't match
        if [[ ! -e "$target" || "$target" == "${custdir:A}"* ]]; then
          echo "Removing symlink: $link"
          rm -f -- "$link"
        fi
      done
    done
  }

  # Remove symlinks that point to repos
  omz_plus_reset_symlinks "$ZSH_CUSTOM/plugins"
  omz_plus_reset_symlinks "$ZSH_CUSTOM/themes"
  omz_plus_reset_symlinks "$ZSH_CUSTOM/lib"
  omz_plus_reset_symlinks "$ZSH_CUSTOM"
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
  local plugin repo_dir repo repo_url commitsha initfile
  local -a initfiles=() clone_args=() seen_dirs=()
  local repo_type=$1; shift
  # Ensure required directories exist before cloning/symlinking
  mkdir -p "$ZSH_CUSTOM/repos" "$ZSH_CUSTOM/plugins" "$ZSH_CUSTOM/themes"
  for plugin in $@; do
    [[ "$plugin" == */* ]] || continue

    # Pin repo to a specific commit sha if provided
    clone_args=(--quiet --depth 1 --recursive --shallow-submodules)
    _omz_plus_parse_repo "$plugin"
    repo="$reply[1]" commitsha="$reply[2]"
    repo_dir=$ZSH_CUSTOM/repos/$reply[3]
    [[ -z "$commitsha" ]] || clone_args+=(--no-checkout)

    repo_url="https://github.com/$repo"
    if [[ $repo == (https://|git@)* ]]; then
      repo_url="$repo"
      repo="${repo:h:t}/${repo:t}"
    fi
    repo="${repo%.git}"

    # Avoid racing clones when duplicate specs resolve to the same repo
    (( ${seen_dirs[(I)$repo_dir]} )) && continue
    seen_dirs+=("$repo_dir")

    if [[ "$repo_type" == "plugins" ]]; then
      initfile=$repo_dir/${repo:t}.plugin.zsh
    elif [[ "$repo_type" == "themes" ]]; then
      initfile=$repo_dir/${repo:t}.zsh-theme
    else
      initfile=
    fi
    {
      if [[ ! -d $repo_dir ]]; then
        echo "Cloning $repo..."
        git clone "${clone_args[@]}" $repo_url $repo_dir
        if [[ -n "$commitsha" ]]; then
          # Let git validate the pin; on failure remove the broken clone so
          # nothing gets cached and the next shell start retries.
          if ! git -C $repo_dir fetch --quiet origin "$commitsha" ||
             ! git -C $repo_dir checkout --quiet FETCH_HEAD
          then
            echo >&2 "omz-plus: Failed to pin '$repo' to '$commitsha'."
            rm -rf -- $repo_dir
            exit 1
          fi
        fi
      fi
      # See if there's not a proper init file (custom repos need none).
      if [[ -n "$initfile" && ! -e $initfile ]]; then
        initfiles=($repo_dir/*.{plugin.zsh,zsh-theme,zsh,sh}(N))
        (( $#initfiles )) || { echo >&2 "No init file found '$repo'."; exit 1 }
        ln -sf $initfiles[1] $initfile
      fi
      if [[ "$repo_type" == "plugins" ]]; then
        ln -sfn "$repo_dir" "$ZSH_CUSTOM/plugins/${repo:t}"
      elif [[ "$repo_type" == "themes" ]]; then
        ln -sfn "$initfile" "$ZSH_CUSTOM/themes/${initfile:t}"
      fi
    } &
  done
  wait
}

##? Symlink any Zsh plugins from other custom locations.
function omz_plus_setup_zsh_custom {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB NO_MONITOR
  local lib plugin theme custdir file
  for custdir in $zsh_custom; do
    # Resolve git repo entries to their clone location. Absolute paths are
    # local directories; anything else containing a slash is a repo.
    if [[ "$custdir" != /* && "$custdir" == */* ]]; then
      _omz_plus_parse_repo "$custdir"
      custdir=$ZSH_CUSTOM/repos/$reply[3]
    fi
    if [[ ! -e $custdir ]]; then
      echo >&2 "omz-plus: zsh_custom: Directory not found '$custdir'."
      continue
    fi
    mkdir -p $ZSH_CUSTOM/lib $ZSH_CUSTOM/plugins $ZSH_CUSTOM/themes
    for lib in $custdir/lib/*.zsh(N); do
      ln -sfn $lib $ZSH_CUSTOM/lib/${lib:t}
    done
    for plugin in $custdir/plugins/*(N); do
      ln -sfn $plugin $ZSH_CUSTOM/plugins/${plugin:t}
    done
    for theme in $custdir/themes/*.zsh-theme(N); do
      ln -sfn $theme $ZSH_CUSTOM/themes/${theme:t}
    done
    for file in $custdir/*.zsh(N); do
      ln -sfn $file $ZSH_CUSTOM/${file:t}
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
    omz_plus_clone custom ${(M)zsh_custom[@]:#[^/]*/*}

    # Symlink plugins from multiple custom locations into $ZSH_CUSTOM
    omz_plus_setup_zsh_custom

    # Skip caching if any repo failed to clone so the next start retries.
    local plugin cache_ok=1
    for plugin in ${plugins_plus[@]} $ZSH_THEME_PLUS ${(M)zsh_custom[@]:#[^/]*/*}; do
      [[ "$plugin" == */* ]] || continue
      _omz_plus_parse_repo "$plugin"
      [[ -d "$ZSH_CUSTOM/repos/$reply[3]" ]] || cache_ok=0
    done
    (( cache_ok )) || return

    # Save cache
    mkdir -p "${cache_file:h}"
    cat > "$cache_file" <<EOF
plugins_plus_prior=(${(q-)plugins_plus[@]})
ZSH_THEME_PLUS_PRIOR=${(q-)ZSH_THEME_PLUS}
zsh_custom_prior=(${(q-)zsh_custom[@]})
EOF
  fi
}
