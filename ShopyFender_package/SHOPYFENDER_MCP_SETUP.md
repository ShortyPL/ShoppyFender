# ShopyFender — MCP Setup for Cursor on macOS

> **Project:** ShopyFender  
> **Environment:** macOS + Cursor Pro  
> **Purpose:** Connect Cursor to external development tools using MCP  
> **Status:** v0.1  
> **Priority:** Low-cost hobby development

---

# 1. Goal

The goal is to keep Cursor as the main control center for ShopyFender.

Target workflow:

```text
Cursor Agent
    |
    +--> Godot MCP
    |      - inspect scene tree
    |      - create/edit nodes
    |      - run scenes
    |      - inspect project
    |
    +--> Blender MCP
    |      - create 3D objects
    |      - modify meshes
    |      - materials
    |      - export assets
    |
    +--> Context7 MCP
    |      - current programming/library documentation
    |
    +--> GitHub MCP
    |      - repository metadata
    |      - issues
    |      - pull requests
    |      - repository operations
    |
    +--> Higgsfield MCP / Skills (OPTIONAL LATER)
           - images
           - videos
           - visual concepts
           - consumes paid credits
```

The game itself must NOT depend on any MCP server at runtime.

MCP is a development tool only.

---

# 2. Recommended MCP priority

For ShopyFender:

```text
PRIORITY 1
Godot MCP

PRIORITY 2
Blender MCP

PRIORITY 3
Context7

OPTIONAL
GitHub MCP

LATER / PAID
Higgsfield
```

Do not install every MCP server available on the internet.

Every MCP adds:

- tools,
- context,
- permissions,
- possible security risk,
- possible token usage,
- maintenance.

Use only tools that provide real value.

---

# 3. Cursor MCP configuration locations

Cursor supports project-specific and global MCP configuration.

## Project-specific

Recommended for ShopyFender-specific development tools:

```text
ShopyFender/.cursor/mcp.json
```

Use this for:

- Godot MCP
- Blender MCP
- Context7

## Global

Recommended for account-level tools:

```text
~/.cursor/mcp.json
```

Use this for:

- GitHub MCP
- personal external services

Do not put secrets directly into a repository file.

---

# 4. macOS prerequisites

Open Cursor terminal and check:

```bash
uname -m
brew --version
git --version
node --version
npm --version
```

Expected architecture on newer Macs:

```text
arm64
```

If Homebrew is not installed, install it first from:

```text
https://brew.sh
```

---

# 5. Install base command-line tools

From Cursor terminal:

```bash
brew install node uv git
```

Verify:

```bash
node --version
npm --version
uv --version
uvx --version
git --version
```

For this project, Node 20+ is recommended because it also satisfies several common MCP tools.

---

# 6. Install Godot and Blender

If they are not already installed:

```bash
brew install --cask godot
brew install --cask blender
```

Verify:

```bash
godot --version
blender --version
```

If `godot` or `blender` is not available immediately:

```bash
which godot
which blender
```

Restart the terminal if necessary.

---

# 7. Create tools directory

Keep third-party MCP source outside the game repository.

Recommended:

```bash
mkdir -p ~/Developer/tools
mkdir -p ~/Developer/ShopyFender
```

Example structure:

```text
~/Developer/
├── ShopyFender/
└── tools/
    └── godot-mcp/
```

This keeps third-party MCP code separate from the game.

---

# 8. GODOT MCP

## Purpose

Godot MCP allows Cursor to communicate directly with the Godot editor.

Useful capabilities include:

- inspect scene tree,
- create nodes,
- modify scenes,
- attach scripts,
- inspect project state,
- run scenes,
- capture screenshots,
- execute editor-related operations.

Recommended community project:

```text
https://github.com/mkdevkit/godot-mcp
```

Requirements documented by the project:

```text
Godot 4.4+
Node.js 18+
MCP-capable client
```

---

# 9. Install Godot MCP server

From Cursor terminal:

```bash
cd ~/Developer/tools

git clone https://github.com/mkdevkit/godot-mcp.git

cd godot-mcp/server

npm install
npm run build
```

Verify that this exists:

```bash
ls ~/Developer/tools/godot-mcp/server/build/index.js
```

If the file exists, the MCP server build is ready.

---

# 10. Install Godot MCP plugin in ShopyFender

Assuming the game repository is:

```text
~/Developer/ShopyFender
```

Run:

```bash
mkdir -p ~/Developer/ShopyFender/addons

cp -R \
  ~/Developer/tools/godot-mcp/addons/godot_mcp \
  ~/Developer/ShopyFender/addons/
```

Verify:

```bash
ls ~/Developer/ShopyFender/addons/godot_mcp
```

---

# 11. Enable Godot MCP plugin

This is one of the few one-time actions that may require opening the Godot editor.

Open the project:

```bash
cd ~/Developer/ShopyFender
godot --editor project.godot
```

Then:

```text
Project
→ Project Settings
→ Plugins
→ Godot MCP
→ Enable
```

The plugin should connect using port:

```text
6505
```

by default.

---

# 12. Configure Godot MCP in Cursor

Create:

```text
ShopyFender/.cursor/mcp.json
```

Initial configuration:

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": [
        "${userHome}/Developer/tools/godot-mcp/server/build/index.js"
      ],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    }
  }
}
```

Save the file.

Fully restart Cursor.

---

# 13. Test Godot MCP

Open the ShopyFender project in Godot.

Then ask Cursor:

```text
Use Godot MCP.

Get the current Godot scene tree.

Do not modify anything.
```

Expected result:

Cursor should call Godot MCP tools and return information about the current scene.

Second test:

```text
Use Godot MCP.

Run the current scene and tell me whether the project starts successfully.

Do not change any project files.
```

Third test after the basic project exists:

```text
Use Godot MCP.

Capture a screenshot of the running game and inspect whether the store floor,
walls, entrance and exit are visible.

Do not change anything yet.
```

---

# 14. Godot MCP troubleshooting

Check Node:

```bash
node --version
```

Check server build:

```bash
ls ~/Developer/tools/godot-mcp/server/build/index.js
```

Check plugin:

```bash
ls ~/Developer/ShopyFender/addons/godot_mcp
```

Check whether project is open in Godot.

Then completely restart Cursor.

In Cursor:

```text
Settings
→ Tools & MCP
```

The server should appear as connected.

If port 6505 is occupied:

```bash
lsof -i :6505
```

Do not randomly kill processes before identifying them.

---

# 15. Updating Godot MCP

From Cursor terminal:

```bash
cd ~/Developer/tools/godot-mcp

git pull

cd server

npm install
npm run build
```

If the Godot addon changed, copy it again:

```bash
rm -rf ~/Developer/ShopyFender/addons/godot_mcp

cp -R \
  ~/Developer/tools/godot-mcp/addons/godot_mcp \
  ~/Developer/ShopyFender/addons/
```

Then restart Godot and Cursor.

---

# 16. BLENDER MCP

## Purpose

Blender MCP allows Cursor to control Blender.

Useful for ShopyFender:

- create gondolas,
- shelves,
- simple checkout counters,
- refrigerators,
- product package meshes,
- create materials,
- inspect scenes,
- export simple assets,
- automate repetitive modeling.

Recommended community project:

```text
https://github.com/ahujasid/blender-mcp
```

The server uses `uvx`.

---

# 17. Install Blender MCP

First verify:

```bash
uvx --version
```

Then install/update the Blender addon:

```bash
uvx blender-mcp install-addon
```

The command should copy the Blender MCP addon into a detected Blender addon directory.

To inspect possible addon paths:

```bash
uvx blender-mcp addon-paths
```

---

# 18. Enable Blender MCP addon

Open Blender:

```bash
blender
```

Then:

```text
Blender
→ Edit
→ Preferences
→ Add-ons
```

Search:

```text
Blender MCP
```

Enable:

```text
Interface: Blender MCP
```

If it does not appear:

1. restart Blender,
2. run `uvx blender-mcp install-addon` again,
3. check the addon path.

---

# 19. Start Blender MCP connection

In Blender:

```text
3D Viewport
→ press N
→ BlenderMCP panel
→ Start MCP Server
```

The Blender addon must be active when Cursor wants to control Blender.

---

# 20. Find uvx absolute path

On macOS GUI applications sometimes do not inherit the same PATH as the terminal.

Run:

```bash
which uvx
```

Possible Apple Silicon result:

```text
/opt/homebrew/bin/uvx
```

Possible alternative:

```text
/usr/local/bin/uvx
```

Use YOUR actual result in Cursor configuration.

---

# 21. Add Blender MCP to Cursor

Edit:

```text
ShopyFender/.cursor/mcp.json
```

Example:

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": [
        "${userHome}/Developer/tools/godot-mcp/server/build/index.js"
      ],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    },

    "blender": {
      "command": "/opt/homebrew/bin/uvx",
      "args": [
        "blender-mcp"
      ]
    }
  }
}
```

IMPORTANT:

Replace:

```text
/opt/homebrew/bin/uvx
```

with the output of:

```bash
which uvx
```

Restart Cursor.

---

# 22. Test Blender MCP

Open Blender.

Start Blender MCP Server from the BlenderMCP panel.

Then ask Cursor:

```text
Use Blender MCP.

Inspect the current Blender scene and list all objects.

Do not modify anything.
```

Then:

```text
Use Blender MCP.

Create a cube named MCP_Test at the origin.

Do not modify any other object.
```

If successful:

```text
Delete MCP_Test.
```

---

# 23. First useful Blender MCP task for ShopyFender

After testing:

```text
Use Blender MCP.

Create a simple low-poly supermarket gondola fixture.

Dimensions:
- width: 1.0 m
- depth: 0.5 m
- height: 1.8 m
- 4 shelves

Style:
- simple
- low-poly
- game-ready placeholder
- no detailed textures

Name the root object:
Gondola_Basic_100

Do not add unnecessary details.
```

Do NOT generate the final art style yet.

Use Blender MCP primarily for prototyping reusable objects.

---

# 24. Blender MCP security warning

Blender MCP can execute Python inside Blender.

Treat this as powerful local code execution.

Rules:

```text
- use trusted MCP source only,
- review unusual tool calls,
- do not give random third-party MCPs Blender access,
- stop the Blender MCP server when not needed,
- keep backups / Git history.
```

---

# 25. CONTEXT7 MCP

## Purpose

Context7 provides up-to-date programming/library documentation to coding agents.

Useful for:

- Godot APIs,
- GDScript questions,
- libraries,
- configuration,
- avoiding outdated code examples.

It is optional but useful.

Official project:

```text
https://github.com/upstash/context7
```

Remote MCP:

```text
https://mcp.context7.com/mcp
```

Basic usage can work without an API key.

---

# 26. Add Context7

Edit:

```text
ShopyFender/.cursor/mcp.json
```

Add:

```json
"context7": {
  "url": "https://mcp.context7.com/mcp"
}
```

Combined configuration now becomes:

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": [
        "${userHome}/Developer/tools/godot-mcp/server/build/index.js"
      ],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    },

    "blender": {
      "command": "/opt/homebrew/bin/uvx",
      "args": [
        "blender-mcp"
      ]
    },

    "context7": {
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

Again:

Replace Blender's `uvx` path with the result of:

```bash
which uvx
```

---

# 27. Test Context7

Ask Cursor:

```text
Use Context7 to retrieve current documentation for Godot 4 NavigationAgent3D.

Do not write code yet.

Summarize which API methods are relevant for moving ShopyFender customers.
```

Then:

```text
Use Context7 to verify the current Godot 4 API before implementing navigation.
```

---

# 28. Recommended Cursor rule for Context7

Add a Cursor rule such as:

```text
When implementing or changing code that depends on Godot APIs,
third-party libraries, package configuration or version-specific behavior,
use Context7 first when current documentation would reduce the risk of
using outdated APIs.
```

Do not force Context7 for trivial local code.

---

# 29. GITHUB MCP

## Priority

Optional.

Cursor already has:

```text
Git
terminal
repository file access
```

Therefore GitHub MCP is NOT required just to:

- commit,
- branch,
- diff,
- push,
- pull.

GitHub MCP becomes useful for:

- GitHub Issues,
- Pull Requests,
- repository metadata,
- releases,
- remote repository operations.

Official project:

```text
https://github.com/github/github-mcp-server
```

Use the official GitHub MCP server, not the deprecated old npm GitHub MCP package.

---

# 30. Recommended GitHub MCP approach

Use GitHub's remote MCP server:

```text
https://api.githubcopilot.com/mcp/
```

Use global Cursor configuration:

```text
~/.cursor/mcp.json
```

Do not put a GitHub token into the ShopyFender repository.

---

# 31. Create GitHub token

Create a GitHub Personal Access Token.

Prefer:

```text
fine-grained token
```

Give access only to repositories and operations required.

Start with minimal permissions.

Do not grant organization-wide or account-wide write permissions unless needed.

---

# 32. Store GitHub token as environment variable

Recommended variable:

```text
GITHUB_MCP_TOKEN
```

For the current macOS login session, one option is:

```bash
read -s GITHUB_MCP_TOKEN
```

Paste the token and press Enter.

Then:

```bash
launchctl setenv GITHUB_MCP_TOKEN "$GITHUB_MCP_TOKEN"
unset GITHUB_MCP_TOKEN
```

Fully quit Cursor:

```text
Cmd + Q
```

Then reopen it.

To remove the variable later:

```bash
launchctl unsetenv GITHUB_MCP_TOKEN
```

Do not paste tokens into chat.

---

# 33. Configure GitHub MCP globally

Create or edit:

```text
~/.cursor/mcp.json
```

Example:

```json
{
  "mcpServers": {
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${env:GITHUB_MCP_TOKEN}"
      }
    }
  }
}
```

Restart Cursor.

---

# 34. Test GitHub MCP safely

First test should be read-only.

Ask:

```text
Use GitHub MCP.

List the repositories available to my account.

Do not create, edit or delete anything.
```

Then:

```text
Use GitHub MCP.

Inspect the ShopyFender repository and list its branches.

Do not make changes.
```

Only after read access works should you allow issue/PR write operations.

---

# 35. GitHub MCP safety policy

Recommended Cursor rule:

```text
For GitHub MCP:

- read operations may run automatically when useful,
- never delete branches or repositories without explicit instruction,
- never merge a pull request without explicit instruction,
- never create a release without explicit instruction,
- never change repository visibility,
- never modify secrets,
- prefer local Git for normal code commits and pushes.
```

---

# 36. HIGGSFIELD

## Status

Optional later.

NOT recommended during early prototype development due to budget.

Higgsfield currently offers an official Cursor integration/MCP.

Official MCP endpoint:

```text
https://mcp.higgsfield.ai/mcp
```

Cursor can also connect through the Cursor marketplace.

No API key is required.

Authentication uses the Higgsfield account.

However:

```text
an active paid Higgsfield subscription is required
```

and MCP generations consume credits.

Even if a Higgsfield web plan includes some unlimited/free generation,
MCP generation uses credits at standard rates.

For a low-budget hobby project:

```text
DO NOT CONNECT HIGGSFIELD YET
```

unless there is a specific visual task.

---

# 37. Later Higgsfield setup

When needed:

In Cursor:

```text
Plugins / Marketplace
→ search Higgsfield
→ Connect
→ sign in
```

Alternative MCP endpoint:

```text
https://mcp.higgsfield.ai/mcp
```

Possible uses:

- concept art,
- trailer ideas,
- promotional video,
- visual references,
- character concepts.

Do not make gameplay development depend on Higgsfield.

---

# 38. Higgsfield spending rule

Add Cursor rule before enabling:

```text
Never call Higgsfield generation tools automatically.

Before any operation that consumes Higgsfield credits,
tell me what will be generated and wait for explicit instruction.
```

This is important for hobby-budget development.

---

# 39. PLAYWRIGHT MCP

Not needed for the core Godot game.

Possible later use:

- ShopyFender website,
- landing page,
- Steam-related web workflows,
- web admin tools.

Official project:

```text
https://github.com/microsoft/playwright-mcp
```

Typical configuration:

```json
"playwright": {
  "command": "npx",
  "args": [
    "@playwright/mcp@latest"
  ]
}
```

Do not install it until ShopyFender actually has a web component.

---

# 40. FILESYSTEM MCP

Do NOT install for the ShopyFender repository.

Cursor already has project filesystem access.

A filesystem MCP would duplicate capabilities and broaden access.

Only consider it if Cursor must access files outside the repository.

If ever enabled:

- grant only explicit directories,
- never grant `/`,
- never grant the entire home directory,
- never grant sensitive folders.

---

# 41. MIXAMO

Mixamo does not need MCP for the initial workflow.

Recommended workflow:

```text
Mixamo web
↓
download FBX
↓
assets/source/characters/
↓
Blender processing
↓
GLB export
↓
Godot
```

Cursor can automate post-processing through Blender MCP.

Do not search for unofficial Mixamo MCP servers just to automate downloads.

---

# 42. POLY HAVEN

The recommended Blender MCP implementation already supports Poly Haven integration.

Therefore:

```text
do not install a separate Poly Haven MCP initially
```

Use Blender MCP when useful.

Always record external asset licensing/source information in:

```text
assets/LICENSES.md
```

---

# 43. Recommended final ShopyFender MCP configuration

Project:

```text
ShopyFender/.cursor/mcp.json
```

Recommended:

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": [
        "${userHome}/Developer/tools/godot-mcp/server/build/index.js"
      ],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    },

    "blender": {
      "command": "/opt/homebrew/bin/uvx",
      "args": [
        "blender-mcp"
      ]
    },

    "context7": {
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

IMPORTANT:

Replace:

```text
/opt/homebrew/bin/uvx
```

with:

```bash
which uvx
```

Do not add GitHub credentials to this project file.

---

# 44. Global Cursor MCP configuration

Global:

```text
~/.cursor/mcp.json
```

Optional:

```json
{
  "mcpServers": {
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${env:GITHUB_MCP_TOKEN}"
      }
    }
  }
}
```

---

# 45. Recommended MCP workflow

When working on code:

```text
Cursor
↓
Context7 if version-sensitive API knowledge is needed
↓
edit code
↓
Godot MCP
↓
run game
↓
inspect scene / screenshot
↓
fix
```

When creating a 3D asset:

```text
Cursor
↓
Blender MCP
↓
create prototype asset
↓
inspect asset
↓
export GLB
↓
Godot import
↓
Godot MCP
↓
test in game
```

When managing project tasks:

```text
Cursor
↓
GitHub MCP
↓
read issue
↓
implement locally
↓
Git
↓
optional PR through GitHub MCP
```

---

# 46. Recommended MCP permission model

Use:

```text
LEAST PRIVILEGE
```

Meaning:

```text
Godot MCP
→ ShopyFender project only

Blender MCP
→ Blender session only

GitHub MCP
→ ShopyFender repository only where possible

Filesystem
→ not installed

Higgsfield
→ disabled until needed
```

---

# 47. MCP trust rule

Never install an MCP server simply because Cursor suggests one.

Before adding an MCP:

1. identify the repository,
2. inspect maintainer,
3. inspect README,
4. inspect permissions,
5. inspect install command,
6. check whether it executes arbitrary local code,
7. verify that the capability is actually needed.

Community MCP servers are executable software.

Treat them like any other dependency.

---

# 48. Cursor operating rules for MCP

Create a project rule with:

```text
MCP POLICY — ShopyFender

1. Use Godot MCP for inspecting, running and modifying Godot scenes when it
   provides a clear advantage over direct file editing.

2. Use Blender MCP only for 3D modeling, materials, scene inspection and
   asset-generation tasks.

3. Use Context7 when implementing version-sensitive Godot APIs or external
   library APIs.

4. Prefer local Git commands for commits, diffs, branches, push and pull.

5. Use GitHub MCP for GitHub-specific remote operations such as issues,
   pull requests and repository metadata.

6. Do not install new MCP servers without explicit approval.

7. Do not call paid generation services automatically.

8. Never expose access tokens in source files, prompts or logs.

9. Never perform destructive GitHub operations without explicit approval.

10. Keep all game runtime code independent from MCP.
```

---

# 49. Connection verification checklist

After setup:

```text
[ ] brew works
[ ] node works
[ ] uvx works
[ ] Godot installed
[ ] Blender installed

[ ] Godot MCP server built
[ ] Godot addon copied
[ ] Godot addon enabled
[ ] Godot MCP visible in Cursor

[ ] Blender MCP addon installed
[ ] Blender MCP addon enabled
[ ] Blender MCP server started
[ ] Blender MCP visible in Cursor

[ ] Context7 visible in Cursor

[ ] GitHub MCP optional
[ ] Higgsfield disabled for now
```

---

# 50. Full smoke test

Run these tests one at a time.

## Godot

```text
Use Godot MCP.
Inspect the currently opened project and return the scene tree.
Do not make changes.
```

## Blender

```text
Use Blender MCP.
List all objects in the current scene.
Do not make changes.
```

## Context7

```text
Use Context7.
Retrieve current Godot 4 documentation for NavigationAgent3D.
Do not modify project files.
```

## GitHub

```text
Use GitHub MCP.
Inspect the ShopyFender repository metadata.
Do not make any changes.
```

All should work before attempting combined automated workflows.

---

# 51. First combined MCP task

Once Godot and Blender are connected:

```text
Read:
- SHOPYFENDER_MASTER_SPEC.md
- SHOPYFENDER_GAME_LOGIC.md
- SHOPYFENDER_MCP_SETUP.md

Use Blender MCP to create a very simple placeholder gondola:
- width 1m
- depth 0.5m
- height 1.8m
- 4 shelves
- low-poly
- no detailed materials

Export it as GLB into the ShopyFender assets directory.

Then use Godot MCP to verify that Godot imports the asset.

Create a temporary test scene containing the gondola.

Run the scene and inspect the result.

Do not modify gameplay logic yet.

Report:
- files created
- files changed
- tools used
- validation result
- known limitations
```

---

# 52. Important cost rule

For the current hobby project:

```text
FREE / EXISTING
Cursor Pro
Godot
Blender
Git
GitHub
Context7 basic
Godot MCP
Blender MCP

PAID / CREDIT BASED
Higgsfield
other generation APIs
```

Do not introduce a paid MCP/API unless the user explicitly approves it.

---

# 53. External references

Cursor MCP documentation:

```text
https://cursor.com/docs/mcp
```

Godot MCP:

```text
https://github.com/mkdevkit/godot-mcp
```

Blender MCP:

```text
https://github.com/ahujasid/blender-mcp
```

GitHub MCP:

```text
https://github.com/github/github-mcp-server
```

Context7:

```text
https://github.com/upstash/context7
```

Playwright MCP:

```text
https://github.com/microsoft/playwright-mcp
```

Higgsfield MCP:

```text
https://mcp.higgsfield.ai/mcp
```

---

# 54. Final recommendation

Install now:

```text
1. Godot MCP
2. Blender MCP
3. Context7
```

Optional:

```text
4. GitHub MCP
```

Do not install yet:

```text
Higgsfield
Playwright
Filesystem MCP
random community MCP servers
```

The best initial ShopyFender toolchain is:

```text
Cursor
  |
  +-- Context7
  |
  +-- Godot MCP
  |
  +-- Blender MCP
  |
  +-- Git / GitHub
```

This gives Cursor enough external control to build and test the first ShopyFender prototype while keeping cost and complexity low.
