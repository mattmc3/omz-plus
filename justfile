# OMZ Plus! task runner

# List available recipes
default:
    @just --list

# Run the full test suite (needs network)
test:
    bats --jobs 4 tests

# Run a single test file, eg: just test-file pins
test-file name:
    bats tests/{{name}}.bats
