#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
    mkdir -p "$TMP/config/locales"
}

@test "keys: no locale files exits 0" {
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/empty" run lefthook-spellcheck-locales-keys
    assert_success
    assert_output --partial "No locale files"
}

@test "keys: valid keys pass" {
    cat > "$TMP/config/locales/en.yml" <<'YAML'
en:
  greeting: Hello
  farewell: Goodbye
YAML
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/config/locales" \
    LEFTHOOK_SPELLCHECK_ALLOWED_KEYS_FILE="$TMP/nonexistent" \
    run lefthook-spellcheck-locales-keys
    assert_success
}

@test "values: no locale files exits 0" {
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/empty" run lefthook-spellcheck-locales-values
    assert_success
    assert_output --partial "No locale files"
}

@test "values: valid English values pass" {
    cat > "$TMP/config/locales/en.yml" <<'YAML'
en:
  greeting: Hello world
  farewell: Goodbye friend
YAML
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/config/locales" \
    LEFTHOOK_SPELLCHECK_ALLOWED_DIR="$TMP" \
    LEFTHOOK_SPELLCHECK_LOCALE_DICTS="en:en_US" \
    run lefthook-spellcheck-locales-values
    assert_success
}
