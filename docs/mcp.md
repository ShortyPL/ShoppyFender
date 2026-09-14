# ShoppyFender MCP notes

This project lives at `/Volumes/TimeData/Cursor/ShoppyFender`.
Ignore `~/Developer/ShopyFender` from the original spec package.

## Connected now

| Tool | How | Notes |
|---|---|---|
| Context7 | Cursor plugin | Already available. Do not add to `.cursor/mcp.json`. |
| Godot MCP | `.cursor/mcp.json` → `tools/godot-mcp/server/build/index.js` | Editor plugin on port 6505. Godot 4.4+ required. |
| Blender MCP | `.cursor/mcp.json` → `/opt/homebrew/bin/uvx blender-mcp` | Addon in Blender; start server from N-panel, port 9876. |

## Not connected

GitHub MCP, Higgsfield, Playwright, Filesystem MCP.

## Godot MCP smoke

1. Open this folder in Godot (`godot --editor --path /Volumes/TimeData/Cursor/ShoppyFender`).
2. Confirm Project → Project Settings → Plugins → **Godot MCP** is enabled.
3. Restart Cursor (Cmd+Q) after the first `mcp.json` save.
4. Ask the agent: inspect scene tree / `get_project_info`. Do not edit yet.

Without the editor open, tools return `GODOT_NOT_CONNECTED`.

## Blender MCP smoke

1. `uvx blender-mcp install-addon` (already run during setup).
2. Blender → Edit → Preferences → Add-ons → enable **Interface: MCP for Blender**.
3. 3D Viewport → `N` → MCP panel → **Start MCP Server**.
4. Leave Poly Haven / Hyper3D / Hunyuan disabled until needed.
5. Run only one MCP client against Blender at a time.

## Verified 2026-09-07

- Context7: Godot `NavigationAgent3D` docs fetched successfully.
- Godot editor: open on this project; plugin injected autoloads `MCPRuntimeBridge`, `MCPInputBridge`, `MCPScreenshotBridge`.
- Blender GUI: MCP addon enabled; server listening on `127.0.0.1:9876`; `get_scene_info` returned default Cube/Light/Camera.
- Cursor `godot-mcp` / `blender` stdio servers appear only after a full Cursor restart (Cmd+Q) so `.cursor/mcp.json` is loaded.

## Rebuild Godot MCP

```bash
zsh /Volumes/TimeData/Cursor/ShoppyFender/tools/setup_mcp.sh
```
