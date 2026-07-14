# OMZ PLUS!
# Home: https://github.com/mattmc3/omz-plus
# License: MIT

# If OMZ_PLUS is not defined, use the current script's directory.
[[ -n "$OMZ_PLUS" ]] || export OMZ_PLUS="${${(%):-%x}:a:h}"
OMZ_PLUS_VERSION=1.2.0

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

##? OMZ PLUS! command wrapper.
function omz+ {
  emulate -L zsh
  local cmd=$1
  case "$cmd" in
    update|reset|shadows)
      shift
      omz_plus_$cmd "$@"
      ;;
    version|--version|-v)
      echo "omz-plus $OMZ_PLUS_VERSION"
      ;;
    help|--help|-h|'')
      print -r -- "Usage: omz+ <command>"
      print -r -- "Commands:"
      print -r -- "  update   Update OMZ PLUS! and all unpinned repos"
      print -r -- "  reset    Remove cloned repos, symlinks, and cache"
      print -r -- "  shadows  List collection items colliding with stock OMZ"
      print -r -- "  version  Show the OMZ PLUS! version"
      ;;
    *)
      echo >&2 "omz+: Unknown command '$cmd'. Run 'omz+ help'."
      return 1
      ;;
  esac
}

##? Resolve a zsh_custom entry: reply=(name scope dir)
##? name: the entry itself, minus any pin and '.git', for zstyle lookups
##? scope: 'local' for absolute paths, 'remote' for cloned repos
function _omz_plus_resolve_custdir {
  emulate -L zsh
  local entry=$1
  if [[ "$entry" != /* && "$entry" == */* ]]; then
    _omz_plus_parse_repo "$entry"
    reply=("${reply[1]%.git}" remote "$ZSH_CUSTOM/repos/$reply[3]")
  else
    reply=("$entry" local "$entry")
  fi
}

##? Decide whether a collection item may shadow its stock OMZ counterpart.
##? Args: <colname> <local|remote> <plugins|lib|themes> <item>
##? Looks up the 'shadow' style for ':omz-plus:custom:<colname>:<kind>:<item>';
##? zstyle's most-specific-pattern-wins handles per-item exceptions.
function _omz_plus_shadow_allowed {
  emulate -L zsh
  local ctx=":omz-plus:custom:$1:$3:$4" scope=$2 setting
  if zstyle -s "$ctx" shadow setting; then
    zstyle -t "$ctx" shadow
  else
    [[ "$scope" == local ]]
  fi
}

##? Remove a symlink left behind by a previously allowed shadow.
function _omz_plus_unlink_denied {
  emulate -L zsh
  local link=$1 custdir=$2
  # :A both sides or symlinked paths (eg: /tmp on macOS) won't match
  if [[ -L "$link" && "${link:A}" == "${custdir:A}"/* ]]; then
    rm -f -- "$link"
  fi
}

##? List collection items that collide with stock Oh-My-Zsh names.
function omz_plus_shadows {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB
  local custdir colname scope kind item name found=0
  local -a items
  for custdir in $zsh_custom; do
    _omz_plus_resolve_custdir "$custdir"
    colname=$reply[1] scope=$reply[2] custdir=$reply[3]
    [[ -e $custdir ]] || continue
    for kind in plugins lib themes; do
      case $kind in
        plugins) items=($custdir/plugins/*(N)) ;;
        lib)     items=($custdir/lib/*.zsh(N)) ;;
        themes)  items=($custdir/themes/*.zsh-theme(N)) ;;
      esac
      for item in $items; do
        name=${item:t}
        [[ -e $ZSH/$kind/$name ]] || continue
        found=1
        if _omz_plus_shadow_allowed $colname $scope $kind $name; then
          echo "$kind/$name: $colname (shadows stock; disable with: zstyle ':omz-plus:custom:$colname:$kind:$name' shadow no)"
        else
          echo "$kind/$name: stock ($colname skipped; enable with: zstyle ':omz-plus:custom:$colname:$kind:$name' shadow yes)"
        fi
      done
    done
  done
  (( found )) || echo "No stock collisions found."
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

  # Reapply collection symlinks so pulled changes and live zstyle edits
  # take effect without waiting for a new shell.
  omz_plus_setup_zsh_custom
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
  local lib plugin theme custdir file colname scope
  local -i skipped=0
  for custdir in $zsh_custom; do
    # Resolve git repo entries to their clone location. Absolute paths are
    # local directories; anything else containing a slash is a repo.
    _omz_plus_resolve_custdir "$custdir"
    colname=$reply[1] scope=$reply[2] custdir=$reply[3]
    if [[ ! -e $custdir ]]; then
      echo >&2 "omz-plus: zsh_custom: Directory not found '$custdir'."
      continue
    fi
    mkdir -p $ZSH_CUSTOM/lib $ZSH_CUSTOM/plugins $ZSH_CUSTOM/themes
    for lib in $custdir/lib/*.zsh(N); do
      # OMZ only loads a custom lib file in place of a stock one of the
      # same name, so a non-colliding lib file gets no symlink at all.
      if [[ ! -e $ZSH/lib/${lib:t} ]]; then
        _omz_plus_unlink_denied $ZSH_CUSTOM/lib/${lib:t} $custdir
        continue
      fi
      if ! _omz_plus_shadow_allowed $colname $scope lib ${lib:t}; then
        _omz_plus_unlink_denied $ZSH_CUSTOM/lib/${lib:t} $custdir
        (( skipped += 1 ))
        continue
      fi
      ln -sfn $lib $ZSH_CUSTOM/lib/${lib:t}
    done
    for plugin in $custdir/plugins/*(N); do
      if [[ -e $ZSH/plugins/${plugin:t} ]] \
        && ! _omz_plus_shadow_allowed $colname $scope plugins ${plugin:t}; then
        _omz_plus_unlink_denied $ZSH_CUSTOM/plugins/${plugin:t} $custdir
        (( skipped += 1 ))
        continue
      fi
      ln -sfn $plugin $ZSH_CUSTOM/plugins/${plugin:t}
    done
    for theme in $custdir/themes/*.zsh-theme(N); do
      if [[ -e $ZSH/themes/${theme:t} ]] \
        && ! _omz_plus_shadow_allowed $colname $scope themes ${theme:t}; then
        _omz_plus_unlink_denied $ZSH_CUSTOM/themes/${theme:t} $custdir
        (( skipped += 1 ))
        continue
      fi
      ln -sfn $theme $ZSH_CUSTOM/themes/${theme:t}
    done
    for file in $custdir/*.zsh(N); do
      ln -sfn $file $ZSH_CUSTOM/${file:t}
    done
  done
  if (( skipped )); then
    echo >&2 "omz-plus: Skipped $skipped stock-colliding item(s) from zsh_custom. Run 'omz+ shadows' to review."
  fi
}

() {
  emulate -L zsh
  setopt LOCAL_OPTIONS EXTENDED_GLOB

  # Check cache to avoid expensive operations if nothing changed
  local cache_file="$ZSH_CACHE_DIR/omz-plus/prior.zsh"
  local needs_update=0
  local -a plugins_plus_prior zsh_custom_prior omz_plus_zstyles_prior
  local ZSH_THEME_PLUS_PRIOR

  # Shadow policy zstyles must invalidate the cache too, or config
  # changes would not take effect until the arrays also change.
  local -a omz_plus_zstyles=(${(f)"$(zstyle -L ':omz-plus:*' 2>/dev/null)"})

  # If the values were the same as a prior run, then we don't need to rerun all the
  # expensive bits.
  if [[ -f "$cache_file" ]]; then
    source "$cache_file"
    if [[ "${(j: :)plugins_plus_prior}" != "${(j: :)plugins_plus}" ]] \
      || [[ "$ZSH_THEME_PLUS_PRIOR" != "$ZSH_THEME_PLUS" ]] \
      || [[ "${(j: :)zsh_custom_prior}" != "${(j: :)zsh_custom}" ]] \
      || [[ "${(F)omz_plus_zstyles_prior}" != "${(F)omz_plus_zstyles}" ]]; then
      needs_update=1
    fi
  else
    needs_update=1
  fi

  # Every update run creates these, so if any are missing, $ZSH_CUSTOM was
  # removed out from under us and must be rebuilt despite a cache hit.
  if [[ ! -d "$ZSH_CUSTOM/repos" || ! -d "$ZSH_CUSTOM/plugins" || ! -d "$ZSH_CUSTOM/themes" ]]; then
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
omz_plus_zstyles_prior=(${(q-)omz_plus_zstyles[@]})
EOF
  fi
}
