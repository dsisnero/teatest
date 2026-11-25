#!/usr/bin/env bash
# Forwarding wrapper. The canonical parity scripts live in the installed
# cross-language-crystal-parity skill; never copy its Ruby implementation here.
set -euo pipefail

SKILL_DIR="${PARITY_SKILL_DIR:-${HOME}/.agents/skills/crystal_forge/skills/cross-language-crystal-parity}"
CANONICAL="${SKILL_DIR}/scripts/$(basename "${BASH_SOURCE[0]}")"

if [[ ! -x "${CANONICAL}" ]]; then
  echo "Missing canonical parity script: ${CANONICAL}" >&2
  echo "Set PARITY_SKILL_DIR to the installed cross-language-crystal-parity skill." >&2
  exit 2
fi

exec "${CANONICAL}" "$@"
