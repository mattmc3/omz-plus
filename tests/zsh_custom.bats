#!/usr/bin/env bats
# Git-hosted custom directories in the zsh_custom array.

load helpers

setup() { setup_sandbox; }

@test "zsh_custom accepts repo specs and the array stays unmodified" {
  mkdir -p "$SANDBOX/local/plugins/myplugin"
  echo 'echo hi' > "$SANDBOX/local/plugins/myplugin/myplugin.plugin.zsh"
  run run_omz "" "$SANDBOX/local mattmc3/zsh_custom" "" 'print -r -- "arr=$zsh_custom"'
  [[ "$output" == *"arr=$SANDBOX/local mattmc3/zsh_custom"* ]]
  [ -d "$ZSH_CUSTOM/repos/zsh_custom/.git" ]
}

@test "local and repo custom dirs both symlink into ZSH_CUSTOM" {
  mkdir -p "$SANDBOX/local/plugins/myplugin" "$SANDBOX/local/lib"
  echo 'echo hi' > "$SANDBOX/local/plugins/myplugin/myplugin.plugin.zsh"
  echo '# lib' > "$SANDBOX/local/lib/mylib.zsh"
  run run_omz "" "$SANDBOX/local mattmc3/zsh_custom"
  [ -L "$ZSH_CUSTOM/plugins/myplugin" ]
  [ -L "$ZSH_CUSTOM/lib/mylib.zsh" ]
  [ -L "$ZSH_CUSTOM/plugins/utility" ]  # from the cloned repo
}

@test "cache stores raw specs and a cache hit is silent" {
  run_omz "" "mattmc3/zsh_custom" > /dev/null
  grep -q "zsh_custom_prior=(.*mattmc3/zsh_custom" "$ZSH_CACHE_DIR/omz-plus/prior.zsh"
  run run_omz "" "mattmc3/zsh_custom"
  [ -z "$output" ]
}

@test "ZSH_CUSTOM inside zsh_custom warns and is removed" {
  mkdir -p "$SANDBOX/local"
  run run_omz "" "\$ZSH_CUSTOM $SANDBOX/local" "" \
    '(( ${zsh_custom[(I)$ZSH_CUSTOM]} )) && print BAD || print CLEAN'
  [[ "$output" == *"warning"* ]]
  [[ "$output" == *"CLEAN"* ]]
}
