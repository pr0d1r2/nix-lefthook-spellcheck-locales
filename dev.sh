# shellcheck shell=bash
export BATS_LIB_PATH="@BATS_LIB_PATH@/share/bats"
export DICPATH="@DICPATH@${DICPATH:+:$DICPATH}"
[ -f .git/hooks/pre-commit ] || lefthook install
