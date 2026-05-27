# Philosophy

This document explains the thinking behind the modular structure and when to extend it.

## The Problem with `.zshrc`

Shell configuration starts simple:

```bash
alias gs="git status"
export EDITOR="nano"
export PATH="$HOME/bin:$PATH"
```

But it grows:

```bash
# 20 aliases
alias gs="git status"
alias ga="git add"
# ... more aliases ...

# 30 exports
export EDITOR="nano"
export KUBE_EDITOR="vim"
# ... more exports ...

# Complex PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.krew/bin:$PATH"
# ... many more paths ...

# Tool initialization
source ~/.nvm/nvm.sh
source ~/.rvm/scripts/rvm
# ... more tool setup ...
```

A 500-line `.zshrc` is hard to navigate, understand, and maintain.

## The Solution: Separation of Concerns

By splitting configuration into focused files, you get:

1. **Findability** — know where to look for each thing
2. **Clarity** — less context to hold when reading/editing
3. **Reusability** — export variables that other files can use
4. **Testability** — validate each file independently
5. **Shareability** — easier to understand and adapt others' configs

## File Purposes

Each file has a clear responsibility:

**`.aliases`** — Shell shortcuts. No dependencies on other files. Can be read/understood standalone.

**`.exports`** — Environment variables. Provides values that `.paths` and `.tools` might reference.

**`.paths`** — PATH management. Uses variables from `.exports`. Must run before `.tools` so tools can find their binaries.

**`.tools`** — Tool initialization and completions. Depends on PATH being set up so `command -v` checks succeed.

**`.secrets`** — Sensitive values from 1Password. Separate so you can rotate/review easily.

**Sourcing order matters:**

1. `.aliases` — no dependencies
2. `.exports` — sets variables for others
3. `.paths` — uses exports, makes tools available
4. `.tools` — can use everything above
5. `.secrets` — can use all above if needed

This order is non-negotiable: if you put `.tools` before `.paths`, tools installed via Homebrew won't be detected by `command -v` checks, and completions will silently fail to load.

## When to Add a New File

You might need additional files:

**`.functions`** — Shell functions you write (more complex than aliases). Worth a separate file if you have 5+ functions.

**`.completions`** — Custom shell completions. Separate if you maintain many custom completions.

**`.prompt`** — Custom shell prompt configuration. Separate if using starship, pure, or similar.

**`.local`** — Machine-specific overrides. Don't commit this to git; let each machine have its own.

If you add a file, source it in `.zshrc` **after all dependencies**:

```bash
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.paths
source ~/.zsh_config/.tools
source ~/.zsh_config/.functions   # New file
```

## When NOT to Add a New File

**Don't create a file for:**

- A single function or two — add to `.aliases` or `.tools`
- One or two shell options — add to `.exports`
- A single tool completion — add to `.tools`

**Use existing files first** before creating new ones. The point is organization, not maximizing the number of files.

## Design Principles

### Be Explicit

Export variables with their values visible, don't hide them behind complex logic.

Good:

```bash
export GOPATH="${HOME}/go"
```

Less good:

```bash
if [[ -x /usr/local/go ]]; then
  export GOPATH="/usr/local/go"
elif [[ -d "${HOME}/go" ]]; then
  export GOPATH="${HOME}/go"
fi
```

(Unless the complexity is necessary for your environment.)

### Keep Files Small

Aim for files small enough to read in one screen (50-100 lines). If a file is growing large, consider:

- Splitting into separate files
- Removing things you don't actually use
- Creating a specialized section file (like `.functions`)

### Order by Importance

In each file, put most-used items first. Example in `.aliases`:

```bash
# Most used — git and pnpm shortcuts first
alias gs="git status"
alias pn="pnpm"

# Less used — specialized tools
alias kubectl_context="kubectl config current-context"
```

### Document Non-Obvious Items

Add comments for items that aren't self-explanatory:

```bash
# Why: Docker completions are slow, only load if using Docker
if command -v docker &> /dev/null; then
  source <(docker completion zsh)
fi

# Why: HISTFILE location for syncing across sessions
export HISTFILE="${HOME}/.zsh_history"
```

Don't comment obvious things:

```bash
# Set EDITOR to nano  ← don't bother
export EDITOR="nano"
```

### Use Guards for Optional Tools

When initializing tools that might not be installed, guard with checks:

```bash
# Only init kubectl if installed
if command -v kubectl &> /dev/null; then
  source <(kubectl completion zsh)
fi

# Only add path if directory exists
if [[ -d "${HOME}/.krew/bin" ]]; then
  export PATH="${HOME}/.krew/bin:${PATH}"
fi
```

This makes the same config work across different machines.

## Flexibility Over Dogma

This structure is a suggestion, not a law. You might:

- Combine `.tools` and `.exports` into one file
- Keep everything in `.zshrc` (it's simpler for small configs)
- Create 10 specialized files (if you have that much config)

The goal is **maintainability for you**. If the structure doesn't serve that for your use case, change it. The pattern that works is the pattern that you actually maintain.

## Why This Works

The reason separation of concerns works for shell config is the same reason it works for code:

1. **Lower cognitive load** — You can think about one thing at a time
2. **Easier debugging** — Problems are usually isolated to one file
3. **Better diffs** — Changes are scoped, not scattered
4. **Selective sourcing** — Test changes by sourcing just the affected file
5. **Reduced bus factor** — Anyone (including future you) can understand what's where

## Evolution

This structure works well for:

- Personal shell configuration
- Sharing setups with a team
- Onboarding new developers
- Cross-machine consistency

As your configuration grows, you might evolve to:

- Versioned configs (managing multiple environments)
- Generated configs (from a higher-level config language)
- Dotfiles frameworks (like chezmoi or rcm)

Start here, evolve if needed. Don't optimize for problems you don't have yet.

## Trade-offs

Being honest about what this approach costs:

**More files to manage** — Five small files vs one big file. The trade-off is per-file simplicity for total file count.

**Sourcing overhead** — Five `source` calls instead of one parsed file. The performance difference is negligible (milliseconds), but it exists.

**Need to know where things live** — "Which file has KUBE_EDITOR?" You learn quickly, but there's a small ramp-up.

**Setup complexity** — A single `.zshrc` has zero structure to learn. This pattern has structure to learn.

For configurations beyond ~50 lines, these trade-offs are worth it. For configurations under 50 lines, just use `.zshrc`.
