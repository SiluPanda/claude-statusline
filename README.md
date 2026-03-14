# Claude Code Statusline



A custom statusline script for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that displays rich session information in your terminal.

![Line 1] Model name, context size, working directory, git branch/status, worktree, agent name, vim mode, and repo link
![Line 2] Context usage bar (color-coded), cost, session duration, API duration, and lines changed

## What it shows

**Line 1:**
- Model name and context window size (200K/1M)
- Current directory name
- Git branch with staged/modified file counts
- Worktree branch (if in a worktree)
- Agent name (if running as a subagent)
- Vim mode indicator (`[N]`/`[I]`)
- Clickable link to the GitHub remote

**Line 2:**
- Context window usage bar (green < 70%, yellow 70-90%, red > 90%)
- Warning when context exceeds 200K tokens
- Session cost in USD
- Total duration and API duration
- Lines added/removed

## Prerequisites

- [jq](https://jqlang.org/) must be installed
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) must be installed

```bash
# Install jq (if not already installed)
brew install jq        # macOS
sudo apt install jq    # Debian/Ubuntu
```

## Installation

### Quick install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/SiluPanda/claude-statusline/main/install.sh | bash
```

This downloads the script to `~/.claude/statusline.sh`, makes it executable, and configures `~/.claude/settings.json` automatically. Restart Claude Code after running.

### Manual installation

<details>
<summary>Click to expand</summary>

#### 1. Download the script

```bash
# Clone this repo
git clone https://github.com/SiluPanda/claude-statusline.git

# Or just download the script directly
curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/SiluPanda/claude-statusline/main/statusline.sh
```

#### 2. Make it executable

```bash
chmod +x statusline.sh
# or if you downloaded to ~/.claude/
chmod +x ~/.claude/statusline.sh
```

#### 3. Configure Claude Code to use it

Add the following to your Claude Code settings file at `~/.claude/settings.json`:

```json
{
  "statusline": {
    "command": "/path/to/statusline.sh"
  }
}
```

For example, if you placed the script in `~/.claude/`:

```json
{
  "statusline": {
    "command": "~/.claude/statusline.sh"
  }
}
```

If you already have a `settings.json` with other settings, just add the `"statusline"` key to the existing object.

#### 4. Restart Claude Code

The statusline will appear at the bottom of your terminal the next time you start a Claude Code session.

</details>

## Customization

The script is plain bash — feel free to modify colors, layout, or add/remove fields. The input JSON from Claude Code is piped to stdin and contains fields like:

- `model.display_name` — current model
- `workspace.current_dir` — working directory
- `cost.total_cost_usd` — session cost
- `context_window.used_percentage` — context usage
- `context_window.context_window_size` — context window size
- `vim.mode` — vim mode (if enabled)
- `agent.name` — subagent name
- `worktree.name` / `worktree.branch` — worktree info

## License

MIT
