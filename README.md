# zsh-config

A modular, shareable zsh configuration for developers. Organize your shell config by concern (aliases, exports, paths, tools) instead of keeping everything in `.zshrc`.

## Philosophy

Shell configuration grows. Starting with a few aliases in `.zshrc`, you end up with dozens of exports, path modifications, tool initializations, and secrets scattered across the file. This repo demonstrates a cleaner approach: separate concerns into individual files, source them in order, and make your setup easier to understand and customize.

**Key benefits:**

- **Find things easily** — all aliases in one file, all paths in another
- **Understand dependencies** — see which files depend on which exports
- **Customize safely** — edit one file without worrying about breaking others
- **Share your setup** — fork this repo and customize it for your environment
- **Optional 1Password** — integrate secrets without hardcoding tokens

## Quick Start

### Automated Installation (Recommended)

```bash
git clone https://github.com/rathpc/zsh-config.git ~/dotfiles/zsh-config
~/dotfiles/zsh-config/install.sh
```

Then customize the files for your environment:

```bash
nano ~/.zsh_config/.aliases
nano ~/.zsh_config/.exports
nano ~/.zsh_config/.paths
nano ~/.zsh_config/.tools
source ~/.zshrc
```

### With 1Password Integration (Optional)

If you use 1Password and want to manage secrets with the `opload` alias:

```bash
~/dotfiles/zsh-config/install.sh --with-1password
```

See [docs/1PASSWORD.md](docs/1PASSWORD.md) for setup instructions.

### Manual Installation

If you prefer more control:

```bash
git clone https://github.com/rathpc/zsh-config.git ~/dotfiles/zsh-config
cp -r ~/dotfiles/zsh-config/.zsh_config ~/.zsh_config
```

Then add these source lines to your `.zshrc` (order matters):

```bash
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.paths
source ~/.zsh_config/.tools
```

**Why the order matters:** Later files can use variables set by earlier files. Aliases come first (no dependencies), then exports (sets vars), then paths (uses exported vars), then tools (can use everything).

> _If you do not want the 1Password integration and you manually intalled, make sure to remove the `opload` alias from the `.aliases` file._

## Files

| File | Purpose |
| ---- | ------- |
| `.aliases` | Shell shortcuts and command abbreviations |
| `.exports` | Non-secret environment variables |
| `.paths` | PATH configuration for tools and languages |
| `.tools` | Tool initialization and completions |
| `.secrets` | Optional 1Password integration for secrets |

See `.zsh_config/.examples/` for reference implementations of each file.

## Documentation

- **[CUSTOMIZATION.md](docs/CUSTOMIZATION.md)** — How to adapt this for your environment
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — Common issues and solutions
- **[1PASSWORD.md](docs/1PASSWORD.md)** — Setting up optional secrets management
- **[PHILOSOPHY.md](docs/PHILOSOPHY.md)** — Why this structure, when to extend it

## Requirements

- zsh (4.1.0+)
- Bash (for install script)
- 1Password CLI (`op`) — optional, only if using `--with-1password`

## Customization

The included files are starting points. You should:

1. **Add your own aliases** — Edit `.aliases` to include your common shortcuts
2. **Set your environment** — Update `.exports` with your tool paths and preferences
3. **Configure your tools** — Enable completions and initialization in `.tools`
4. **Manage secrets** — Either use 1Password integration or set secrets another way

Start with the `.examples/` files as reference, then customize each file for your machine.

## Contributing

Found an issue? Have an improvement? Feel free to:

- Open an issue
- Submit a PR with improvements
- Suggest documentation additions

## License

MIT
