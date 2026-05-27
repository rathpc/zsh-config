# 1Password Integration Guide

This guide shows how to set up optional 1Password integration for managing secrets in your shell configuration.

## Why Use 1Password for Secrets?

Instead of hardcoding secrets in shell files, this setup pulls secrets from 1Password on-demand using the `opload` alias. Benefits:

- **Never hardcoded** — secrets stay in 1Password, not in files
- **Easy to rotate** — update secret in 1Password, no code changes
- **Single source of truth** — all secrets in one place
- **Reusable** — share `.zsh_config` without sharing secrets
- **Selective loading** — only load secrets when you need them

## Setup

### 1. Install 1Password CLI

If you don't have it:

```bash
# macOS with Homebrew
brew install 1password-cli

# Verify installation
op --version
```

For other systems, see [1Password CLI docs](https://developer.1password.com/docs/cli/get-started/).

### 2. Enable Biometric Unlock (Recommended)

In the 1Password desktop app:

1. Settings → Developer
2. Enable "Integrate with 1Password CLI"
3. Enable biometric unlock

This gives you Touch ID prompts instead of typing your master password every time.

### 3. Create a Vault (or use existing)

You need a 1Password vault for shell secrets. You can:

- Create a new vault called "ZSH_Secrets"
- Use an existing vault (like "Personal")

### 4. Create Notes for Each Secret

In your 1Password vault, create a note for each secret:

**Note Name:** `GITHUB_TOKEN`
**Field:** `secret` = `your_actual_github_token`

Repeat for each secret you need:

- `GITHUB_TOKEN`
- `GITLAB_TOKEN`
- `DATABASE_PASSWORD`
- `AWS_ACCESS_KEY_ID`
- etc.

The key insight: each note has a single field named `secret` containing the actual value.

### 5. Update `.secrets` File

Edit `~/.zsh_config/.secrets` and add your secrets:

```bash
export GITHUB_TOKEN="op://ZSH_Secrets/GITHUB_TOKEN/secret"
export GITLAB_TOKEN="op://ZSH_Secrets/GITLAB_TOKEN/secret"
export DATABASE_PASSWORD="op://ZSH_Secrets/DATABASE_PASSWORD/secret"
```

The format is: `op://VAULT_NAME/NOTE_NAME/FIELD_NAME`

### 6. Test It

Load secrets into your shell:

```bash
opload
echo $GITHUB_TOKEN
```

You should see your token printed. If not, check:

- Vault name matches exactly
- Note name matches exactly
- Field name is `secret`
- You're authenticated with `op signin`

## Using Secrets

### Before Commands That Need Secrets

Load secrets with `opload` before running commands:

```bash
# Load secrets, then run command
opload && git push

# Load secrets once per session
opload
npm install
pnpm build
```

### Why On-Demand?

If you put `opload` (or `op inject`) in your `.zshrc`, every new shell prompts you for biometric/auth. By loading on-demand, you:

- Only authenticate when you need to
- Don't slow down shell startup
- Get explicit control over when secrets are loaded

### In Scripts

If you use shell scripts that need secrets:

```bash
#!/bin/bash
eval "$(op inject --in-file=~/.zsh_config/.secrets)"
echo "Token: $GITHUB_TOKEN"
```

## Managing Secrets

### Adding a New Secret

1. Create a note in 1Password vault:
   - Name: `NEW_SECRET_NAME`
   - Field: `secret` with the actual secret value

2. Add to `~/.zsh_config/.secrets`:

   ```bash
   export NEW_SECRET_NAME="op://ZSH_Secrets/NEW_SECRET_NAME/secret"
   ```

3. Test: `opload && echo $NEW_SECRET_NAME`

### Rotating Secrets

1. Update the secret value in 1Password
2. Load it again: `opload && your-command`

No code changes needed.

### Removing a Secret

1. Delete the line from `~/.zsh_config/.secrets`
2. Optionally delete the note from 1Password

## How `opload` Works

The alias is defined in `.aliases`:

```bash
alias opload='eval "$(op inject --in-file=$HOME/.zsh_config/.secrets)"'
```

When you run `opload`:

1. `op inject --in-file=~/.zsh_config/.secrets` reads your file
2. It replaces every `op://...` reference with the actual secret value
3. The result is `eval`'d in your current shell
4. Your environment variables are now set to the actual secrets

The secrets only exist in your current shell session. New shells need their own `opload`.

## Troubleshooting 1Password

### "op: command not found"

1Password CLI is not installed. Install it:

```bash
brew install 1password-cli
```

### "invalid vault"

Check that the vault name in `.secrets` matches exactly:

```bash
op vault list
```

Example output:

```
ID    NAME
abc   ZSH_Secrets
def   Personal
```

If your vault is called `Personal`, update `.secrets`:

```bash
export GITHUB_TOKEN="op://Personal/GITHUB_TOKEN/secret"
```

### "invalid item"

The note name doesn't match. Check:

```bash
op item list --vault=ZSH_Secrets
```

Make sure the name in `.secrets` matches exactly (case-sensitive).

### Authentication Issues

If `op` isn't authenticated:

```bash
# Sign in
op signin

# Or specify account
op signin my-account.1password.com your-email@example.com
```

You may need to enter your Master Password or use biometric.

### "session expired"

1Password CLI sessions time out. Just re-authenticate:

```bash
opload
```

The biometric/password prompt should appear.

### Slow Performance

Each `opload` call hits 1Password's servers. If you're loading secrets frequently:

- Only load when needed (per session, not per command)
- Use the alias to load all secrets at once
- Cache values manually if you need them across many commands

## Security Considerations

### Secrets in Process Memory

Once loaded, secrets exist as environment variables in your shell. They:

- Are visible to child processes
- Can be read with `env` or `printenv`
- Persist until you close the shell

If this concerns you:

- Only load secrets when needed
- Close the shell when done
- Don't run untrusted commands in shells with secrets loaded

### Secrets in Shell History

Be careful with commands like:

```bash
echo $GITHUB_TOKEN  # Don't do this — saves to history
```

Better:

```bash
# Test silently
[[ -n "$GITHUB_TOKEN" ]] && echo "Token loaded" || echo "Token missing"
```

### Don't Commit Your .secrets File

The `.gitignore` excludes `.zsh_config/.secrets`, but always double-check before committing:

```bash
git status
git diff --cached
```

## Advanced: Custom Workflows

### Auto-Load on Shell Start (Less Secure, More Convenient)

If you want secrets always available (less secure but convenient), add to `.zshrc`:

```bash
# Auto-load secrets on shell startup
eval "$(op inject --in-file=~/.zsh_config/.secrets)"
```

**Note:** This requires 1Password to be unlocked at shell startup. You'll get a biometric prompt for every new shell.

### Different Vaults for Different Tools

Store secrets in different vaults based on context:

```bash
export GITHUB_TOKEN="op://Personal/GITHUB_TOKEN/secret"
export WORK_DATABASE_PASSWORD="op://Work/DATABASE_PASSWORD/secret"
```

### Loading Only Specific Secrets

If you don't want to load all secrets at once, you can use `op read` for individual values:

```bash
github_token=$(op read "op://Personal/GITHUB_TOKEN/secret")
```

## References

- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [op inject Documentation](https://developer.1password.com/docs/cli/reference/management/inject/)
- [Secret Reference Syntax](https://developer.1password.com/docs/cli/secret-references/)
