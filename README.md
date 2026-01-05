# foxtail

A fast, cross-platform replacement for Tail that can follow **multiple log files simultaneously**, annotate each line with **timestamps**, and **color output by source file**.

## Features

- **Follow multiple files**: Behaves like `tail -f` but for multiple files at once
- **File rotation detection**: Automatically detects when files are truncated or replaced
- **Timestamp injection**: Prefixes each line with ISO-8601 timestamp and source file name
- **Color-coded output**: Each file gets a deterministic color for easy identification
- **Regex filtering**: Filter lines by pattern with `--grep`
- **JSON support**: Pretty-print structured JSON logs
- **Time filtering**: Start from a specific time with `--since`
- **Cross-platform**: Works on Linux, macOS, and Windows

## Installation

### Build from source

```bash
# Clone the repository
git clone https://github.com/myferr/foxtail
cd foxtail

# Install Crystal (if not already installed)
# Visit: https://crystal-lang.org/install/

# Build the binary
shards build

# (Optional) Install system-wide
sudo cp bin/foxtail /usr/local/bin/
```

## Usage

```bash
foxtail [options] <file...>
```

### Options

| Flag                 | Description                          |
| -------------------- | ------------------------------------ |
| `-n, --lines=N`      | Output last N lines                   |
| `-f, --follow`       | Follow file(s) (default)             |
| `--no-follow`        | Don't follow, just read once         |
| `--grep <regex>`     | Filter lines by regex pattern        |
| `--ignore-case`      | Case-insensitive grep                |
| `--json`             | Enable JSON pretty-printing          |
| `--no-color`         | Disable ANSI colors                  |
| `--since <duration>` | Start from last N seconds/m/h/d      |
| `-h, --help`         | Show help message                    |
| `-v, --version`      | Show version                        |

## Examples

### Single file (clean output, colored content)

```bash
foxtail /var/log/app.log
```

Output: Just the colored line content without timestamp or filename.

### Multiple files (with timestamps and filenames)

```bash
foxtail /var/log/app.log /var/log/error.log
```

### Use wildcards to follow multiple files

```bash
foxtail /var/log/*.log
```

### Filter lines by pattern

```bash
foxtail --grep "error" /var/log/app.log
```

### Case-insensitive search

```bash
foxtail --grep "error" --ignore-case /var/log/app.log
```

### Parse and pretty-print JSON logs

```bash
foxtail --json /var/log/app.log
```

Input:
```json
{"level":"error","msg":"db failed","requestId":"abc"}
```

Output:
```
2026-01-05T15:02:11.432Z [app.log] ERROR db failed requestId=abc
```

### Show logs from the last 5 minutes

```bash
foxtail --since 5m /var/log/app.log
```

### Disable colors for piping

```bash
foxtail --no-color /var/log/app.log | grep "error"
```

### Read file once without following

```bash
foxtail --no-follow /var/log/app.log
```

### Combine multiple options

```bash
foxtail --json --grep "error" --since 1h /var/log/*.log
```

## Output Format

### Single file
Just shows colored content (clean output, similar to `tail -f`):

```
Server started on port 8080
Connection established
Request received: GET /api/users
```

### Multiple files
Each line is prefixed with timestamp and filename:

```
<timestamp> [filename] <content>
```

Example:
```
2026-01-05T15:02:11.432Z [api.log] Server started on port 8080
2026-01-05T15:02:12.123Z [db.log] Connection established
2026-01-05T15:02:15.456Z [api.log] Request received: GET /api/users
```

## JSON Log Support

When using `--json`, foxtail attempts to parse each line as JSON and formats it nicely:

- Extracts `level` or `severity` field (uppercased)
- Extracts `msg` or `message` field
- Displays other fields as `key=value` pairs

Example:

Input:
```json
{"level":"info","msg":"Request completed","requestId":"xyz","duration":"23ms"}
```

Output:
```
2026-01-05T15:02:11.432Z [app.log] INFO Request completed requestId=xyz duration=23ms
```

Non-JSON lines are displayed as-is.

## File Rotation

foxtail automatically detects when log files are:
- Truncated (log rotation)
- Replaced (deleted and recreated)

In both cases, it continues following the file from the beginning.

## Performance

- **Low CPU usage**: Efficient polling with configurable intervals
- **Minimal overhead**: Only reads new data, doesn't re-read entire files
- **Scalable**: Can monitor dozens of files simultaneously

## Exit Codes

- `0`: Success
- `1`: Error (invalid arguments, file not found, etc.)

## Signals

- `SIGINT` (Ctrl+C): Clean shutdown
- `SIGTERM`: Clean shutdown

## Requirements

- Crystal 1.13.0 or later
- No external dependencies

## License

MIT
