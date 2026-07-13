#!/usr/bin/env bats
# Cloning repo specs: URL forms, dedupe, and failure handling.

load helpers

setup() { setup_sandbox; }

@test ".git URL suffix is stripped from all names" {
  run run_omz "https://github.com/mattmc3/zsh_custom.git" "" "" 'print -r -- "plugins=$plugins"'
  [ -d "$ZSH_CUSTOM/repos/zsh_custom/.git" ]
  [ -L "$ZSH_CUSTOM/plugins/zsh_custom" ]
  [[ "$output" == *"plugins=git zsh_custom"* ]]
}

@test "duplicate specs resolving to the same repo clone once" {
  run run_omz "mattmc3/zsh_custom https://github.com/mattmc3/zsh_custom"
  [ "$(grep -c 'Cloning' <<< "$output")" = "1" ]
  [ -d "$ZSH_CUSTOM/repos/zsh_custom/.git" ]
}

@test "failed clone skips the cache so the next start retries" {
  run run_omz "mattmc3/no-such-repo-omz-plus-test"
  [ ! -f "$ZSH_CACHE_DIR/omz-plus/prior.zsh" ]
}
