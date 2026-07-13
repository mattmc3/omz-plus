# OMZ Plus! task runner

# List available recipes
default:
    @just --list

# Run the full test suite (needs network)
test:
    bats tests

# Run a single test file, eg: just test-file pins
test-file name:
    bats tests/{{name}}.bats
