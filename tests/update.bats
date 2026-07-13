#!/usr/bin/env bats
# omz_plus_update behavior. Uses a sandbox copy of omz-plus so the
# self-update pull never touches the real working repo.

load helpers

setup() { setup_sandbox; }

@test "update skips pinned repos and pulls unpinned repos cleanly" {
  make_omz_copy
  run_omz "mattmc3/zsh_custom@$PIN_SHA" > /dev/null
  run zsh -f -c "
    export ZSH='$ZSH' ZSH_CUSTOM='$ZSH_CUSTOM' ZSH_CACHE_DIR='$ZSH_CACHE_DIR'
    export OMZ_PLUS='$SANDBOX/omz-src' GIT_TERMINAL_PROMPT=0
    plugins=(git mattmc3/zsh_custom)
    ZSH_THEME=''; zsh_custom=()
    source \"\$OMZ_PLUS/omz-plus.sh\"
    omz_plus_update
  "
  [[ "$output" == *"Skipping pinned repo: zsh_custom@$PIN_SHORT"* ]]
  [[ "$output" == *"Updating zsh_custom..."* ]]
  [[ "$output" != *"not currently on a branch"* ]]
  [[ "$output" != *"fatal"* ]]
}

@test "restart hint prints only when omz-plus itself updates" {
  make_omz_copy
  git clone --quiet "$SANDBOX/omz-src" "$SANDBOX/omz-behind"
  git -C "$SANDBOX/omz-behind" reset --hard -q HEAD~1
  run zsh -f -c "
    export ZSH='$ZSH' ZSH_CUSTOM='$ZSH_CUSTOM' ZSH_CACHE_DIR='$ZSH_CACHE_DIR'
    export OMZ_PLUS='$SANDBOX/omz-behind' GIT_TERMINAL_PROMPT=0
    plugins=(git); ZSH_THEME=''; zsh_custom=()
    source '$SANDBOX/omz-src/omz-plus.sh'
    omz_plus_update
  "
  [[ "$output" == *"Restart your shell"* ]]
  run zsh -f -c "
    export ZSH='$ZSH' ZSH_CUSTOM='$ZSH_CUSTOM' ZSH_CACHE_DIR='$ZSH_CACHE_DIR'
    export OMZ_PLUS='$SANDBOX/omz-behind' GIT_TERMINAL_PROMPT=0
    plugins=(git); ZSH_THEME=''; zsh_custom=()
    source '$SANDBOX/omz-src/omz-plus.sh'
    omz_plus_update
  "
  [[ "$output" != *"Restart your shell"* ]]
}
