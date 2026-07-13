#!/usr/bin/env bats
# Symlink precedence and omz_plus_reset cleanup.

load helpers

setup() { setup_sandbox; }

@test "same-named plugin in a later custom dir wins without polluting the source" {
  for d in custA custB; do
    mkdir -p "$SANDBOX/$d/plugins/dupe"
    echo "echo $d" > "$SANDBOX/$d/plugins/dupe/dupe.plugin.zsh"
  done
  run_omz "" "$SANDBOX/custA $SANDBOX/custB" > /dev/null
  [ "$(readlink "$ZSH_CUSTOM/plugins/dupe")" = "$SANDBOX/custB/plugins/dupe" ]
  [ ! -e "$SANDBOX/custA/plugins/dupe/dupe" ]
}

@test "reset removes repos and every symlink setup created" {
  mkdir -p "$SANDBOX/local/plugins/myplugin" "$SANDBOX/local/lib"
  echo 'echo hi' > "$SANDBOX/local/plugins/myplugin/myplugin.plugin.zsh"
  echo '# lib' > "$SANDBOX/local/lib/mylib.zsh"
  echo '# root' > "$SANDBOX/local/rootfile.zsh"
  run_omz "" "$SANDBOX/local mattmc3/zsh_custom" "" 'omz_plus_reset' > /dev/null
  [ ! -d "$ZSH_CUSTOM/repos" ]
  [ ! -L "$ZSH_CUSTOM/plugins/myplugin" ]
  [ ! -L "$ZSH_CUSTOM/lib/mylib.zsh" ]
  [ ! -L "$ZSH_CUSTOM/rootfile.zsh" ]
  [ -z "$(ls "$ZSH_CUSTOM/plugins" 2>/dev/null)" ]
}

@test "no custdir or file variables leak from setup and reset" {
  mkdir -p "$SANDBOX/local/plugins/p1"
  echo x > "$SANDBOX/local/rootfile.zsh"
  echo x > "$SANDBOX/local/plugins/p1/p1.plugin.zsh"
  run run_omz "" "$SANDBOX/local" "" \
    'omz_plus_reset > /dev/null 2>&1; print "custdir=${+custdir} file=${+file}"'
  [[ "$output" == *"custdir=0 file=0"* ]]
}
