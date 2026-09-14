#!/usr/bin/env zsh
set -euo pipefail

# ShoppyFender MCP setup
# Project root is /Volumes/TimeData/Cursor/ShoppyFender (not ~/Developer/ShopyFender).

ROOT="/Volumes/TimeData/Cursor/ShoppyFender"
CLONE="${ROOT}/tools/godot-mcp"
REPO="https://github.com/mkdevkit/godot-mcp.git"

mkdir -p "${ROOT}/tools" "${ROOT}/addons"

if [[ ! -d "${CLONE}/.git" ]]; then
  git clone "${REPO}" "${CLONE}"
else
  git -C "${CLONE}" pull --ff-only
fi

cd "${CLONE}/server"
npm install
npm run build

if [[ ! -f "${CLONE}/server/build/index.js" ]]; then
  echo "error: MCP server build missing: ${CLONE}/server/build/index.js" >&2
  exit 1
fi

rm -rf "${ROOT}/addons/godot_mcp"
cp -R "${CLONE}/addons/godot_mcp" "${ROOT}/addons/godot_mcp"

echo "Godot MCP ready."
echo "  server: ${CLONE}/server/build/index.js"
echo "  addon:  ${ROOT}/addons/godot_mcp"
echo "uvx path: $(command -v uvx)"
echo
echo "Next: open this project in Godot, enable plugin if needed,"
echo "then restart Cursor so .cursor/mcp.json is picked up."
