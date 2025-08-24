#!/usr/bin/env bash
set -euo pipefail

# Compile all .scad files to .stl if the source is newer than the target.
# Uses OpenSCAD binary path from ./.env (key: openscad_path). Falls back to `openscad`.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read openscad_path from .env without sourcing (to preserve backslashes/Windows paths)
OPENSCAD_CMD="${OPENSCAD_CMD:-}"
if [[ -z "${OPENSCAD_CMD}" && -f "${ROOT_DIR}/.env" ]]; then
  # Extract first occurrence of openscad_path=... as-is
  OPENSCAD_CMD="$(sed -n 's/^openscad_path=//p' "${ROOT_DIR}/.env" | head -n1)"
fi
OPENSCAD_CMD="${OPENSCAD_CMD:-openscad}"

echo "Using OpenSCAD: ${OPENSCAD_CMD}"

total=0
built=0
skipped=0
failed=0

# Iterate over all .scad files; ignore .git contents if present
while IFS= read -r -d '' scad; do
  (( total++ )) || true
  stl="${scad%.scad}.stl"

  if [[ ! -f "$stl" || "$scad" -nt "$stl" ]]; then
    echo "Rendering: $scad -> $stl"
    mkdir -p "$(dirname "$stl")"
    if "${OPENSCAD_CMD}" -o "$stl" "$scad"; then
      (( built++ )) || true
    else
      echo "Error: failed to render $scad" >&2
      (( failed++ )) || true
    fi
  else
    echo "Up-to-date: $stl"
    (( skipped++ )) || true
  fi
done < <(find "${ROOT_DIR}" -type f -name "*.scad" ! -path "${ROOT_DIR}/.git/*" -print0)

echo "Done. Total: $total, built: $built, skipped: $skipped, failed: $failed"

# Exit non-zero if any failures occurred
if (( failed > 0 )); then
  exit 1
fi

