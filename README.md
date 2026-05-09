# nix-lefthook-spellcheck-locales

[![CI](https://github.com/pr0d1r2/nix-lefthook-spellcheck-locales/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-spellcheck-locales/actions/workflows/ci.yml)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible locale spellchecker (keys + values), packaged as a Nix flake.

Contains two commands:

- `lefthook-spellcheck-locales-keys` - checks YAML locale key names for English spelling errors
- `lefthook-spellcheck-locales-values` - checks YAML locale values for spelling errors in their respective language

Both use [hunspell](https://hunspell.github.io/) for spell checking.

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` - no flake input needed, just the wrapper binaries in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-spellcheck-locales
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-spellcheck-locales = {
  url = "github:pr0d1r2/nix-lefthook-spellcheck-locales";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-spellcheck-locales.packages.${pkgs.stdenv.hostPlatform.system}.default
```

### Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `LEFTHOOK_SPELLCHECK_LOCALES_DIR` | `config/locales` | Path to YAML locale files |
| `LEFTHOOK_SPELLCHECK_ALLOWED_KEYS_FILE` | `.hunspell_allowed_keys` | Allowed words file for keys |
| `LEFTHOOK_SPELLCHECK_KEYS_DICT` | `en_US` | Hunspell dictionary for keys |
| `LEFTHOOK_SPELLCHECK_ALLOWED_DIR` | `.` | Directory containing `.hunspell_allowed_values_<locale>` files |
| `LEFTHOOK_SPELLCHECK_LOCALE_DICTS` | `pl:pl_PL,en:en_US` | Locale-to-dictionary mapping |
| `LEFTHOOK_SPELLCHECK_LOCALES_TIMEOUT` | `60` | Timeout in seconds |

### Allowed words files

Create `.hunspell_allowed_keys` for key false positives and `.hunspell_allowed_values_<locale>` for value false positives (one word per line, lines starting with `#` are comments).

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) - entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-spellcheck-locales  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

## License

MIT
