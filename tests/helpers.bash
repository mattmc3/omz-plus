# Shared helpers for OMZ Plus! bats tests.
# These tests clone small repos from GitHub, so they require network access.

# A permanently valid commit in mattmc3/zsh_custom used for pin tests.
PIN_SHA=c093219c458e1d2f721b12da3c9bb704bfc9845a
PIN_SHORT=c093219

setup_sandbox() {
  SANDBOX="$BATS_TEST_TMPDIR/sandbox"
  export ZSH="$SANDBOX/oh-my-zsh"
  export ZSH_CUSTOM="$ZSH/custom"
  export ZSH_CACHE_DIR="$SANDBOX/cache"
  export OMZ_PLUS="${OMZ_PLUS:-$BATS_TEST_DIRNAME/..}"
  export GIT_TERMINAL_PROMPT=0
  mkdir -p "$SANDBOX"
}

# Source omz-plus.sh in a fresh zsh with the given config, then run any
# extra zsh code. Args: plugins, zsh_custom, ZSH_THEME, extra zsh code.
run_omz() {
  local plugins_spec="${1:-}" custom_spec="${2:-}" theme="${3:-}" extra="${4:-}"
  zsh -f -c "
    export ZSH='$ZSH' ZSH_CUSTOM='$ZSH_CUSTOM' ZSH_CACHE_DIR='$ZSH_CACHE_DIR'
    export OMZ_PLUS='$OMZ_PLUS' GIT_TERMINAL_PROMPT=0
    plugins=(git $plugins_spec)
    ZSH_THEME='$theme'
    zsh_custom=($custom_spec)
    source \"\$OMZ_PLUS/omz-plus.sh\"
    $extra
  " 2>&1
}

# Make a committed sandbox copy of omz-plus so omz_plus_update's self-pull
# never touches the real working repo.
make_omz_copy() {
  git clone --quiet "$OMZ_PLUS" "$SANDBOX/omz-src"
  cp "$OMZ_PLUS/omz-plus.sh" "$SANDBOX/omz-src/omz-plus.sh"
  git -C "$SANDBOX/omz-src" add -A
  git -C "$SANDBOX/omz-src" -c user.email=t@t -c user.name=t commit -qm wip
}
