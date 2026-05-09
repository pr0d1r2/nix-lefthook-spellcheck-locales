# shellcheck shell=bash
# Lefthook-compatible locale key spellchecker.
# Checks YAML locale file keys for spelling errors using hunspell.
# Config: LEFTHOOK_SPELLCHECK_LOCALES_DIR (default: config/locales)
#         LEFTHOOK_SPELLCHECK_ALLOWED_KEYS_FILE (default: .hunspell_allowed_keys)
#         LEFTHOOK_SPELLCHECK_KEYS_DICT (default: en_US)
# Usage: lefthook-spellcheck-locales-keys [ignored]
# NOTE: sourced by writeShellApplication — no shebang or set needed.

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
exec ruby "$SCRIPT_DIR/../lib/lefthook-spellcheck-locales-keys.rb" "$@"
