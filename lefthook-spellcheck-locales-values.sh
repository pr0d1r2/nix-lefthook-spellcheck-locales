# shellcheck shell=bash
# Lefthook-compatible locale value spellchecker.
# Checks YAML locale file values for spelling errors using hunspell.
# Config: LEFTHOOK_SPELLCHECK_LOCALES_DIR (default: config/locales)
#         LEFTHOOK_SPELLCHECK_ALLOWED_DIR (default: .)
#         LEFTHOOK_SPELLCHECK_LOCALE_DICTS (default: pl:pl_PL,en:en_US)
# Usage: lefthook-spellcheck-locales-values [ignored]
# NOTE: sourced by writeShellApplication - no shebang or set needed.

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
exec ruby "$SCRIPT_DIR/../lib/lefthook-spellcheck-locales-values.rb" "$@"
