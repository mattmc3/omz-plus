#!/usr/bin/env bats
# Pinning repos to shas, branches, and tags.

load helpers

setup() { setup_sandbox; }

@test "@sha pin clones to sha-named dir with a clean symlink" {
  run_omz "mattmc3/zsh_custom@$PIN_SHA" > /dev/null
  [ -d "$ZSH_CUSTOM/repos/zsh_custom@$PIN_SHORT/.git" ]
  [ "$(readlink "$ZSH_CUSTOM/plugins/zsh_custom")" = "$ZSH_CUSTOM/repos/zsh_custom@$PIN_SHORT" ]
  [ "$(git -C "$ZSH_CUSTOM/repos/zsh_custom@$PIN_SHORT" rev-parse HEAD)" = "$PIN_SHA" ]
}

@test "#sha pin maps to the same dir as @sha" {
  run_omz "mattmc3/zsh_custom#$PIN_SHA" > /dev/null
  [ -d "$ZSH_CUSTOM/repos/zsh_custom@$PIN_SHORT/.git" ]
  [ "$(ls -d "$ZSH_CUSTOM/repos"/zsh_custom* | wc -l | tr -d ' ')" = "1" ]
}

@test "#branch pin clones to a branch-named dir, checked out" {
  run_omz "mattmc3/zsh_custom#main" > /dev/null
  [ -d "$ZSH_CUSTOM/repos/zsh_custom@main/.git" ]
  git -C "$ZSH_CUSTOM/repos/zsh_custom@main" rev-parse HEAD > /dev/null
}

@test "unpinning recovers with a fresh clone on a branch" {
  run_omz "mattmc3/zsh_custom@$PIN_SHA" > /dev/null
  run_omz "mattmc3/zsh_custom" > /dev/null
  [ -d "$ZSH_CUSTOM/repos/zsh_custom/.git" ]
  git -C "$ZSH_CUSTOM/repos/zsh_custom" symbolic-ref -q HEAD > /dev/null
  [ "$(readlink "$ZSH_CUSTOM/plugins/zsh_custom")" = "$ZSH_CUSTOM/repos/zsh_custom" ]
}

@test "bad sha errors loudly, removes the clone, and skips the cache" {
  run run_omz "mattmc3/zsh_custom@deadbeefdeadbee"
  [[ "$output" == *"omz-plus: Failed to pin"* ]]
  [ ! -d "$ZSH_CUSTOM/repos/zsh_custom@deadbee" ]
  [ ! -f "$ZSH_CACHE_DIR/omz-plus/prior.zsh" ]
}

@test "ssh URLs are not misparsed as pins" {
  run run_omz "" "" "" \
    '_omz_plus_parse_repo "git@github.com:mattmc3/zsh_custom"; print -r -- "$reply[2]|$reply[3]"'
  [[ "$output" == *"|zsh_custom"* ]]
  [[ "$output" != *"github.com"* ]]
}
