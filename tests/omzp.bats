#!/usr/bin/env bats
# The omz+ command wrapper.

load helpers

setup() { setup_sandbox; }

@test "omz+ dispatches to omz_plus_* commands" {
  mkdir -p "$SANDBOX/local/plugins/myplugin"
  echo 'echo hi' > "$SANDBOX/local/plugins/myplugin/myplugin.plugin.zsh"
  run run_omz "" "$SANDBOX/local" "" 'omz+ shadows; omz+ reset'
  [[ "$output" == *"No stock collisions found."* ]]
  [ ! -d "$ZSH_CUSTOM/repos" ]
  [ ! -L "$ZSH_CUSTOM/plugins/myplugin" ]
}

@test "omz+ help lists commands and version prints version" {
  run run_omz "" "" "" 'omz+ help; omz+ version'
  [[ "$output" == *"update"*"reset"*"shadows"* ]]
  [[ "$output" == *"omz-plus "* ]]
}

@test "omz+ rejects unknown commands" {
  run run_omz "" "" "" 'omz+ bogus; echo "rc=$?"'
  [[ "$output" == *"Unknown command"* ]]
  [[ "$output" == *"rc=1"* ]]
}
