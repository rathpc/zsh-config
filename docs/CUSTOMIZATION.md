# Customization Guide

This guide walks you through customizing each configuration file for your environment.

## Before You Start

After running the install script (or copying files manually), you have:

- `~/.zsh_config/.aliases` — your aliases
- `~/.zsh_config/.exports` — your environment variables
- `~/.zsh_config/.tools` — your tool initialization
- `~/.zsh_config/.paths` — your PATH configuration
- `~/.zsh_config/.secrets` (optional) — 1Password integration

Each file is sourced in order by your `.zshrc`. Later files can use variables set by earlier files.

## Sourcing Order

The files are sourced in this specific order:

```bash
source ~/.zsh_config/.aliases   # 1. No dependencies
source ~/.zsh_config/.exports   # 2. Sets variables for later files
source ~/.zsh_config/.paths     # 3. Uses exported variables for PATH
source ~/.zsh_config/.tools     # 4. Has access to everything above
```

If you change this order, things may break. For example, `.paths` references `$GOPATH` set in `.exports`.

## Customizing Aliases

Edit `~/.zsh_config/.aliases` to add or remove shortcuts.

**Examples:**

```bash
# Short pnpm commands
alias pn="pnpm"
alias pni="pnpm install"

# Git shortcuts
alias gs="git status"
alias gc="git commit"

# Directory shortcuts
alias cdcode="cd ~/code"
alias cdwork="cd ~/work"
```

**Tips:**

- Keep aliases short and memorable
- Avoid aliases that conflict with actual commands you use
- Check existing aliases with `alias` command
- If you need conditional logic or arguments, write a function instead

## Customizing Exports

Edit `~/.zsh_config/.exports` to set environment variables.

**When to use exports:**

- Editor preferences: `export EDITOR="vim"`
- Language paths: `export GOPATH="${HOME}/go"`
- Development settings: `export NODE_ENV="production"`
- Tool configuration: `export KUBE_EDITOR="nano"`

**Do NOT put secrets here** — use `.secrets` (with 1Password) or another secret management approach.

## Customizing Paths

Edit `~/.zsh_config/.paths` to manage your `$PATH`.

**Common additions:**

```bash
# Go binaries
export PATH="${GOPATH}/bin:${PATH}"

# Local bin
export PATH="${HOME}/.local/bin:${PATH}"

# Homebrew (macOS)
export PATH="/opt/homebrew/bin:${PATH}"

# kubectl plugins (krew)
export PATH="${HOME}/.krew/bin:${PATH}"
```

**Order matters within the file** — when you prepend with `${VAR}:${PATH}`, the later entries have higher priority. Put most important paths last (so they get prepended last and end up first in `$PATH`).

## Customizing Tools

Edit `~/.zsh_config/.tools` to initialize tools and enable completions.

**Examples:**

```bash
# Load NVM
source "${HOME}/.nvm/nvm.sh"

# Enable kubectl completion
source <(kubectl completion zsh)

# Enable docker completion
source <(docker completion zsh)

# Load fzf
source "${HOME}/.fzf.zsh"
```

**When to add:**

- Language version managers (nvm, rbenv, pyenv)
- Command completions (kubectl, docker, gcloud)
- Shell enhancements (fzf, oh-my-zsh plugins)

**Performance tip:** Tool initialization runs at every shell startup. Heavy tools can slow you down. If startup feels slow, comment things out to find the culprit.

## Adding New Files

If you need additional configuration files, create them in `~/.zsh_config/` and source them in `~/.zshrc`:

```bash
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.paths
source ~/.zsh_config/.tools
source ~/.zsh_config/.functions    # Your custom functions file
```

Add new files **after all their dependencies** in the sourcing order.

## When to Use Functions Instead of Aliases

Aliases are simple text substitution. Functions can:

- Accept arguments
- Use conditional logic
- Run multiple commands
- Return values

If your "alias" needs any of these, make it a function:

```bash
# Bad: aliases can't handle this
alias gcm="git commit -m"  # Works, but you can't add validation

# Better: function
gcm() {
  if [[ -z "$1" ]]; then
    echo "Usage: gcm <message>"
    return 1
  fi
  git commit -m "$1"
}
```

## Testing Changes

After editing a file, reload your shell:

```bash
source ~/.zshrc
```

Or close and reopen your terminal.

Test that everything loads correctly:

```bash
# Test an alias
pn --version

# Check PATH
echo $PATH

# Verify export
echo $EDITOR
```

## Common Customization Patterns

### Adding Conditional Configuration

Only load something if a tool is installed:

```bash
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi
```

### OS-Specific Configuration

Handle macOS vs Linux differently:

```bash
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS specific
  export PATH="/opt/homebrew/bin:${PATH}"
elif [[ "$(uname)" == "Linux" ]]; then
  # Linux specific
  export PATH="/usr/local/bin:${PATH}"
fi
```

### Local Overrides

Keep machine-specific config separate. Add this to your `.zshrc` after sourcing the main config:

```bash
# Load local overrides if they exist
[[ -f ~/.zsh_local ]] && source ~/.zsh_local
```

Then put machine-specific things in `~/.zsh_local` (not tracked in git).

## Troubleshooting Customization

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues like:

- Aliases not working
- PATH conflicts
- Tool initialization failures
