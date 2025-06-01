# Getting Started with CryBot

## Installation

### Quick Install
```bash
curl -fsSL https://crybot.dev/install.sh | bash
```

### First Time Setup
1. **Configure Voice**: Run `crybot --setup-voice`
2. **Test Microphone**: Say "Hey CryBot"
3. **Install Plugins**: `crybot plugin install weather`
4. **Customize Theme**: `crybot theme set cyberpunk`

## Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `open <app>` | Launch application | "open browser" |
| `run <script>` | Execute script | "run backup.py" |
| `show <info>` | Display information | "show cpu usage" |
| `git <action>` | Git operations | "git status" |

## Voice Tips

- **Speak clearly** - Enunciate your words
- **Wait for beep** - Listen for activation sound
- **Use wake words** - "Hey CryBot" or "Crystal"
- **Keep it simple** - Short, direct commands work best

## Next Steps

- [Advanced Commands](./advanced-commands.md)
- [Plugin Development](../developer/plugin-guide.md)
- [Configuration](./configuration.md)