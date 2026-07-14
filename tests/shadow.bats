#!/usr/bin/env bats
# Shadow policy: collections colliding with stock OMZ names.

load helpers

setup() {
  setup_sandbox
  # Fake stock OMZ plugins/lib/themes
  mkdir -p "$ZSH/plugins/git" "$ZSH/plugins/extract" "$ZSH/lib" "$ZSH/themes"
  echo '# stock' > "$ZSH/plugins/git/git.plugin.zsh"
  echo '# stock' > "$ZSH/plugins/extract/extract.plugin.zsh"
  echo '# stock' > "$ZSH/lib/git.zsh"
  echo '# stock' > "$ZSH/themes/mytheme.zsh-theme"
  # Local collection with colliding and unique entries
  COL="$SANDBOX/col"
  mkdir -p "$COL/plugins/git" "$COL/plugins/extract" "$COL/plugins/uniq" \
    "$COL/lib" "$COL/themes"
  echo '# col' > "$COL/plugins/git/git.plugin.zsh"
  echo '# col' > "$COL/plugins/extract/extract.plugin.zsh"
  echo '# col' > "$COL/plugins/uniq/uniq.plugin.zsh"
  echo '# col' > "$COL/lib/git.zsh"
  echo '# col' > "$COL/lib/extra.zsh"
  echo '# col' > "$COL/themes/mytheme.zsh-theme"
  # Fake remote collection: pre-creating the clone dir makes the
  # 'fake/faux' spec resolve here and omz_plus_clone skip the network.
  FAUX="$ZSH_CUSTOM/repos/faux"
  mkdir -p "$FAUX/plugins/git" "$FAUX/plugins/extract" "$FAUX/plugins/uniq" \
    "$FAUX/lib" "$FAUX/themes"
  echo '# faux' > "$FAUX/plugins/git/git.plugin.zsh"
  echo '# faux' > "$FAUX/plugins/extract/extract.plugin.zsh"
  echo '# faux' > "$FAUX/plugins/uniq/uniq.plugin.zsh"
  echo '# faux' > "$FAUX/lib/git.zsh"
  echo '# faux' > "$FAUX/lib/extra.zsh"
  echo '# faux' > "$FAUX/themes/mytheme.zsh-theme"
}

@test "local collection shadows stock by default" {
  run_omz "" "$COL"
  [ "$(readlink "$ZSH_CUSTOM/plugins/git")" = "$COL/plugins/git" ]
  [ "$(readlink "$ZSH_CUSTOM/lib/git.zsh")" = "$COL/lib/git.zsh" ]
  [ "$(readlink "$ZSH_CUSTOM/themes/mytheme.zsh-theme")" = "$COL/themes/mytheme.zsh-theme" ]
  [ -L "$ZSH_CUSTOM/plugins/uniq" ]
}

@test "remote collection does not shadow stock by default" {
  run run_omz "" "fake/faux"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
  [ ! -e "$ZSH_CUSTOM/lib/git.zsh" ]
  [ ! -e "$ZSH_CUSTOM/themes/mytheme.zsh-theme" ]
  [ -L "$ZSH_CUSTOM/plugins/uniq" ]
  [[ "$output" == *"omz+ shadows"* ]]
}

@test "shadow no turns off local shadowing" {
  run_omz "" "$COL" "" "" "zstyle ':omz-plus:custom:$COL:*' shadow no"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
  [ -L "$ZSH_CUSTOM/plugins/uniq" ]
}

@test "collection-wide pattern turns on remote shadowing" {
  run_omz "" "fake/faux" "" "" "zstyle ':omz-plus:custom:fake/faux:*' shadow yes"
  [ "$(readlink "$ZSH_CUSTOM/plugins/git")" = "$FAUX/plugins/git" ]
  [ "$(readlink "$ZSH_CUSTOM/themes/mytheme.zsh-theme")" = "$FAUX/themes/mytheme.zsh-theme" ]
  [ "$(readlink "$ZSH_CUSTOM/lib/git.zsh")" = "$FAUX/lib/git.zsh" ]
}

@test "per-item shadow yes works when the default is no" {
  run_omz "" "fake/faux" "" "" "zstyle ':omz-plus:custom:fake/faux:plugins:git' shadow yes"
  [ -L "$ZSH_CUSTOM/plugins/git" ]
  [ ! -e "$ZSH_CUSTOM/plugins/extract" ]
}

@test "more specific context beats collection pattern" {
  run_omz "" "$COL" "" "" \
    "zstyle ':omz-plus:custom:$COL:*' shadow yes; zstyle ':omz-plus:custom:$COL:plugins:git' shadow no"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
  [ -L "$ZSH_CUSTOM/plugins/extract" ]
}

@test "remote lib file can be enabled by exact name" {
  run_omz "" "fake/faux"
  [ ! -e "$ZSH_CUSTOM/lib/git.zsh" ]
  run_omz "" "fake/faux" "" "" \
    "zstyle ':omz-plus:custom:fake/faux:lib:git.zsh' shadow yes"
  [ "$(readlink "$ZSH_CUSTOM/lib/git.zsh")" = "$FAUX/lib/git.zsh" ]
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
}

@test "non-colliding lib files are never symlinked" {
  run_omz "" "$COL"
  [ ! -e "$ZSH_CUSTOM/lib/extra.zsh" ]
  run_omz "" "fake/faux" "" "" "zstyle ':omz-plus:custom:fake/faux:*' shadow yes"
  [ ! -e "$ZSH_CUSTOM/lib/extra.zsh" ]
}

@test "kind-scoped pattern excludes lib from a collection-wide yes" {
  run_omz "" "fake/faux" "" "" \
    "zstyle ':omz-plus:custom:fake/faux:*' shadow yes; zstyle ':omz-plus:custom:fake/faux:lib:*' shadow no"
  [ -L "$ZSH_CUSTOM/plugins/git" ]
  [ ! -e "$ZSH_CUSTOM/lib/git.zsh" ]
}

@test "zstyle changes invalidate the cache" {
  run_omz "" "fake/faux"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
  run_omz "" "fake/faux" "" "" "zstyle ':omz-plus:custom:fake/faux:plugins:git' shadow yes"
  [ -L "$ZSH_CUSTOM/plugins/git" ]
}

@test "turning shadowing off removes the stale symlink" {
  run_omz "" "$COL"
  [ -L "$ZSH_CUSTOM/plugins/git" ]
  run_omz "" "$COL" "" "" "zstyle ':omz-plus:custom:$COL:*' shadow no"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
}

@test "same-basename collections get distinct policies" {
  mkdir -p "$SANDBOX/joe/col/plugins/git" "$SANDBOX/matt/col/plugins/extract"
  echo '# joe' > "$SANDBOX/joe/col/plugins/git/git.plugin.zsh"
  echo '# matt' > "$SANDBOX/matt/col/plugins/extract/extract.plugin.zsh"
  run_omz "" "$SANDBOX/joe/col $SANDBOX/matt/col" "" "" \
    "zstyle ':omz-plus:custom:$SANDBOX/joe/col:*' shadow no"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
  [ "$(readlink "$ZSH_CUSTOM/plugins/extract")" = "$SANDBOX/matt/col/plugins/extract" ]
}

@test "collection-vs-collection order still last-wins" {
  mkdir -p "$SANDBOX/col2/plugins/uniq"
  echo '# col2' > "$SANDBOX/col2/plugins/uniq/uniq.plugin.zsh"
  run_omz "" "$COL $SANDBOX/col2"
  [ "$(readlink "$ZSH_CUSTOM/plugins/uniq")" = "$SANDBOX/col2/plugins/uniq" ]
}

@test "omz_plus_update reapplies shadow policy from live zstyles" {
  make_omz_copy
  run_omz "" "fake/faux"
  [ ! -e "$ZSH_CUSTOM/plugins/git" ]
  zsh -f -c "
    export ZSH='$ZSH' ZSH_CUSTOM='$ZSH_CUSTOM' ZSH_CACHE_DIR='$ZSH_CACHE_DIR'
    export OMZ_PLUS='$SANDBOX/omz-src' GIT_TERMINAL_PROMPT=0
    plugins=(git); ZSH_THEME=''
    zsh_custom=(fake/faux)
    source \"\$OMZ_PLUS/omz-plus.sh\"
    zstyle ':omz-plus:custom:fake/faux:plugins:git' shadow yes
    omz_plus_update
  " > /dev/null
  [ -L "$ZSH_CUSTOM/plugins/git" ]
}

@test "omz_plus_shadows lists collisions with zstyle hints" {
  run run_omz "" "fake/faux $COL" "" "omz_plus_shadows"
  [[ "$output" == *"plugins/git: stock"*"zstyle ':omz-plus:custom:fake/faux:plugins:git' shadow yes"* ]]
  [[ "$output" == *"plugins/git: $COL (shadows stock"* ]]
}
