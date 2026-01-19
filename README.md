# cnc - Cat No Comments

A simple, fast command-line utility to display configuration files and code without comments or blank lines. Perfect for quickly checking which settings are actually enabled in config files.

## Features

- 🚀 **Fast and lightweight** - just a bash script, no dependencies
- 🎯 **Smart defaults** - recognizes all common comment styles automatically
- 🔧 **Flexible** - customize comment characters, keep blank lines, strip inline comments
- 📦 **Easy to install** - single file, drop it anywhere in your PATH

### Supported Comment Styles (by default)

- `#` - Shell, Python, Ruby, YAML, Perl, Make, Bash, etc.
- `//` - C, C++, Java, JavaScript, Go, Rust, Swift, etc.
- `;` - Assembly, INI files, Lisp, Scheme
- `--` - SQL, Lua, Haskell, Ada

## Installation

### Quick Install (recommended)

```bash
curl -sL https://raw.githubusercontent.com/cybercdh/cnc/main/cnc -o cnc
chmod +x cnc
sudo mv cnc /usr/local/bin/
```

### Using Make

```bash
git clone https://github.com/cybercdh/cnc.git
cd cnc
sudo make install
```

> Tip for macOS: If another `cnc` exists earlier in your `PATH`, run with the full path (`/usr/local/bin/cnc --help`) or install under a different name: `sudo make install NAME=cnc-nc`.

### Manual Install

```bash
git clone https://github.com/cybercdh/cnc.git
cd cnc
chmod +x cnc
cp cnc ~/.local/bin/cnc  # or /usr/local/bin/cnc for system-wide
```

## Usage

### Basic Usage

```bash
cnc [file]
# If file is omitted or '-', reads from stdin
```

### Examples

```bash
# View SSH config without comments
cnc /etc/ssh/sshd_config

# View nginx config, keeping blank lines for readability
cnc -b /etc/nginx/nginx.conf

# Remove inline comments from a shell script
cnc -i script.sh

# Fast mode for files with only # comments
cnc -s /etc/fstab

# Custom comment character for INI files
cnc -c ';' config.ini

# Multiple custom comment types
cnc -c '#,;' app.conf

# Use with pipelines / stdin
cat sshd_config | cnc -i -
```

### Options

```
-h, --help          Show help message
-v, --version       Show version
-b, --keep-blank    Keep blank lines (default: remove them)
-i, --inline        Also remove inline comments (after code)
-c, --char CHARS    Override comment characters (comma-separated)
-s, --simple        Only remove # comments (fastest)
```

## Examples in Action

### Before (with comments):
```bash
$ cat /etc/ssh/sshd_config
# This is the sshd server system-wide configuration file.
# See sshd_config(5) for more information.

# Network settings
Port 22
#Port 2222

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no  # Disable password auth

# Logging
SyslogFacility AUTH
LogLevel INFO
```

### After (with cnc):
```bash
$ cnc /etc/ssh/sshd_config
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no  # Disable password auth
SyslogFacility AUTH
LogLevel INFO
```

### After (with cnc -i for inline removal):
```bash
$ cnc -i /etc/ssh/sshd_config
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
SyslogFacility AUTH
LogLevel INFO
```

## Use Cases

- 🔍 **Quick config inspection** - See what's actually configured without scrolling through comments
- 📋 **Config diffing** - Compare actual settings between files
- 🐛 **Debugging** - Quickly identify active configuration directives
- 📝 **Documentation** - Extract actual settings for documentation
- 🔧 **DevOps** - Parse configs in scripts without comment noise

## Why cnc?

Ever tried to check what's actually enabled in `/etc/ssh/sshd_config` or a massive nginx config, only to scroll through hundreds of lines of comments? `cnc` solves this by showing you just the active configuration.

It's like `cat`, but smarter about config files.

## Comparison with Other Tools

| Tool | Pros | Cons |
|------|------|------|
| `grep -v '^#'` | Simple | Misses indented comments, only works for # |
| `sed '/^#/d'` | Fast | Misses indented comments, requires pattern knowledge |
| **cnc** | Handles all comment types, removes blank lines, easy to use | Bash dependency |

## Performance

`cnc` is fast enough for all practical purposes. On a typical config file:

```bash
$ time cnc /etc/nginx/nginx.conf
real    0m0.003s
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## Development

### Testing

Test files are provided in the `tests/` directory:

```bash
./cnc tests/sample.conf
./cnc tests/sample.py
./cnc tests/sample.sql
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Changelog

### v1.0.0 (2026-01-18)
- Initial release
- Support for #, //, ;, -- comment styles
- Inline comment removal with -i flag
- Custom comment character support
- Keep blank lines option

## Author

Created with ❤️ for sysadmins and developers who love clean config files.

---

**Star this repo if you find it useful!** ⭐
