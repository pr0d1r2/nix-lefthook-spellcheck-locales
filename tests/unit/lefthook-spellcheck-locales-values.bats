#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"
    load "${BATS_LIB_PATH}/bats-file/load.bash"

    TMP="$BATS_TEST_TMPDIR"
    SCRIPT="$BATS_TEST_DIRNAME/../../lefthook-spellcheck-locales-values.sh"
}

@test "script file exists" {
    assert_file_exist "$SCRIPT"
}

@test "script references SCRIPT_DIR resolution" {
    run grep -c 'SCRIPT_DIR=' "$SCRIPT"
    assert_success
    assert_output "1"
}

@test "script uses readlink -f for SCRIPT_DIR" {
    run grep 'readlink -f' "$SCRIPT"
    assert_success
    assert_output --partial 'readlink -f'
}

@test "script execs ruby with the values rb file" {
    run grep 'exec ruby' "$SCRIPT"
    assert_success
    assert_output --partial "lefthook-spellcheck-locales-values.rb"
}

@test "script passes arguments to ruby" {
    run grep 'exec ruby' "$SCRIPT"
    assert_success
    assert_output --partial '"$@"'
}

@test "script has shellcheck shell directive" {
    run grep '# shellcheck shell=bash' "$SCRIPT"
    assert_success
}

@test "script does not have a shebang" {
    run head -1 "$SCRIPT"
    assert_success
    refute_output --partial "#!/"
}

@test "values: no locale files exits 0" {
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/empty" run lefthook-spellcheck-locales-values
    assert_success
    assert_output --partial "No locale files"
}

@test "values: valid English values pass" {
    mkdir -p "$TMP/config/locales"
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

@test "values: misspelled English values fail" {
    mkdir -p "$TMP/config/locales"
    cat > "$TMP/config/locales/en.yml" <<'YAML'
en:
  greeting: Helloxx worldxx
YAML
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/config/locales" \
    LEFTHOOK_SPELLCHECK_ALLOWED_DIR="$TMP" \
    LEFTHOOK_SPELLCHECK_LOCALE_DICTS="en:en_US" \
    run lefthook-spellcheck-locales-values
    assert_failure
}

@test "values: allowed words bypass spellcheck" {
    mkdir -p "$TMP/config/locales"
    cat > "$TMP/config/locales/en.yml" <<'YAML'
en:
  greeting: Helloxx worldxx
YAML
    printf 'helloxx\nworldxx\n' > "$TMP/.hunspell_allowed_values_en"
    LEFTHOOK_SPELLCHECK_LOCALES_DIR="$TMP/config/locales" \
    LEFTHOOK_SPELLCHECK_ALLOWED_DIR="$TMP" \
    LEFTHOOK_SPELLCHECK_LOCALE_DICTS="en:en_US" \
    run lefthook-spellcheck-locales-values
    assert_success
}
