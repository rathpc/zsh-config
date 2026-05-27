# Troubleshooting

## Installation Issues

### "Permission denied" when running install.sh

Make sure the script is executable:

```bash
chmod +x install.sh
./install.sh
```

### Files already exist but install.sh didn't back them up

The script tries to back up `.zsh_config` and `.zshrc` with timestamps. If you don't see the backups, check:

- Whether the files actually existed before (script only backs up what's there)
- File permissions on your home directory
- Whether the script reported errors during execution

If something seems off, do it manually:

```bash
cp -r ~/.zsh_config ~/.zsh_config.bak
cp ~/.zshrc ~/.zshrc.bak
```

### Install script doesn't add source lines to .zshrc

The script uses a marker comment `# rathpc/zsh-config` to detect if it's already configured. If your `.zshrc` already had source lines but without that marker, the script won't touch them.

If needed, manually add:

```bash
# rathpc/zsh-config
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.paths
source ~/.zsh_config/.tools
```

## Configuration Issues

### Aliases not working

Test that aliases are loaded:

```bash
source ~/.zsh_config/.aliases
alias
```

If the alias appears in the list but doesn't work, check for syntax errors:

```bash
zsh -n ~/.zsh_config/.aliases
```

Common issue: An alias name that conflicts with a real command. Check with:

```bash
which <alias_name>
```

### PATH not updated

The sourcing order matters. `.paths` must come after `.exports` because `.paths` uses exported variables like `$GOPATH`. In `.zshrc`:

```bash
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.paths    # Must come after .exports
source ~/.zsh_config/.tools
```

Test by echoing $PATH:

```bash
source ~/.zshrc
echo $PATH | tr ':' '\n'
```

### Tool completions not working

Some tools require the binary to be on $PATH for completion to load. If `.tools` runs and `command -v kubectl` returns false, completions won't load.

Make sure:

1. The tool is installed
2. The tool is on $PATH before `.tools` is sourced
3. Or check inside `.tools` to confirm it's being initialized

```bash
# Reload shell after fixing
exec zsh
```

### "command not found" for a tool

Check if the tool is installed and in your PATH:

```bash
which kubectl
echo $PATH
```

If the tool is installed but not found:

1. Make sure `.paths` is being sourced
2. Check the PATH entry in `.paths` points to the right location
3. Verify the tool's binary directory exists: `ls /opt/homebrew/bin/kubectl`

## 1Password Issues

### opload alias not found

Make sure `.aliases` is being sourced. The opload alias should be defined in the `.aliases` file.

If the alias doesn't exist, either:

- It may be commented out in the `.aliases` file, uncomment it.
- Or manually add the alias to your config:

```bash
alias opload='eval "$(op inject --in-file=$HOME/.zsh_config/.secrets)"'
```

### "op: command not found"

The 1Password CLI is not installed. Install it:

```bash
# macOS with Homebrew
brew install 1password-cli

# Linux/other
# See https://developer.1password.com/docs/cli/get-started/
```

### op inject fails with "invalid vault"

Check your 1Password vault name in `.secrets`. It must match exactly. List your vaults:

```bash
op vault list
```

Update the vault name in your `.secrets` references accordingly.

### Authentication issues with op

1Password CLI needs to be authenticated. If it prompts you constantly:

- Enable biometric unlock in 1Password desktop app
- Or sign in: `op signin`

## General Troubleshooting

### Shell not loading config at all

Make sure `.zshrc` has the source lines. Check:

```bash
grep "source ~/.zsh_config" ~/.zshrc
```

If missing, add them manually (see installation section in README).

### Slow shell startup

If your shell is slow to load, something in `.tools` might be heavy. Profile it:

```bash
# Time each source
time source ~/.zsh_config/.aliases
time source ~/.zsh_config/.exports
time source ~/.zsh_config/.paths
time source ~/.zsh_config/.tools
```

Common culprits:

- `kubectl completion zsh` — slow on every shell startup
- NVM initialization — can be slow
- Multiple `eval "$(... init -)"` calls

**Optimization:** Cache completions to file instead of running command each time:

```bash
# Slow (every shell startup):
source <(kubectl completion zsh)

# Fast (cached):
[[ -f ~/.kubectl_completion ]] || kubectl completion zsh > ~/.kubectl_completion
source ~/.kubectl_completion
```

### Syntax error in config files

Test each file:

```bash
zsh -n ~/.zsh_config/.aliases
zsh -n ~/.zsh_config/.exports
zsh -n ~/.zsh_config/.paths
zsh -n ~/.zsh_config/.tools
```

Fix any errors and reload.

### Changes not taking effect

After editing a config file:

```bash
source ~/.zshrc
```

If still not working, start a fresh shell:

```bash
exec zsh
```

If still not working, close and reopen terminal.

### Variable not set when expected

Variables in shell sessions can be tricky. Things to check:

- Is the variable in `.exports`? (Should be set there)
- Is it being overwritten somewhere else in your config?
- Is it set in a subshell only?

Debug by adding `echo` statements:

```bash
# In .exports
export FOO="bar"
echo "FOO is now: $FOO"
```

### Conflicts with oh-my-zsh

If you're using oh-my-zsh, source your config AFTER oh-my-zsh:

```bash
# oh-my-zsh setup
source $ZSH/oh-my-zsh.sh

# Then your config (overrides oh-my-zsh)
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.paths
source ~/.zsh_config/.tools
```

## Still Stuck?

Diagnostic commands:

- `echo $SHELL` — confirm you're using zsh (should be `/bin/zsh` or `/usr/local/bin/zsh`)
- `zsh --version` — check zsh version (need 4.1.0+)
- `zsh -n ~/.zsh_config/*` — check syntax of all files
- `set -x; source ~/.zshrc; set +x` — trace execution

Still not resolved? Open an issue on the repo with:

1. Your OS and zsh version
2. Output of diagnostic commands above
3. The specific error you're seeing
