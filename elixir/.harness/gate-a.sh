#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash 2>/dev/null || true)"

echo "[Gate A] Format + Lint check for symphony-elixir"

echo "  Running mix format --check-formatted..."
mix format --check-formatted 2>&1 && echo "  [PASS] format clean" || { echo "  [FAIL] format issues found"; exit 1; }

echo "  Running mix credo --strict..."
mix credo --strict 2>&1 && echo "  [PASS] credo clean" || { echo "  [FAIL] credo issues found"; exit 1; }

echo "[Gate A] PASSED"
