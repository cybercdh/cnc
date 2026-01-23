#!/usr/bin/env bash

set -euo pipefail

# cnc - cat no comments
# A utility to display files without comment lines
# https://github.com/cybercdh/cnc

VERSION="1.0.0"

show_help() {
    cat << EOF
Usage: cnc [OPTIONS] [FILE]

Display file contents without comment lines.

By default, cnc recognizes common comment styles:
  #   (Shell, Python, Ruby, YAML, Perl, Make, etc.)
  //  (C, C++, Java, JavaScript, Go, Rust, etc.)
  ;   (Assembly, INI files, Lisp)
  --  (SQL, Lua, Haskell)

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version
    -b, --keep-blank    Keep blank lines (default: remove them)
    -i, --inline        Also remove inline comments (after code)
    -c, --char CHARS    Override comment characters (comma-separated)
                        Example: -c '#,//'
    -s, --simple        Only remove # comments (fastest)

INPUT:
    If FILE is omitted or '-', read from stdin

EXAMPLES:
    cnc /etc/ssh/sshd_config     # SSH config
    cnc -b nginx.conf            # Keep blank lines
    cnc -i script.sh             # Remove inline comments too
    cnc -s Makefile              # Fast mode, # only
    cnc -c ';' config.ini        # Only ; comments
    cnc -c '#,;' app.conf        # Only # and ; comments

NOTES:
    - Lines that start with comments (after whitespace) are removed
    - With -i, everything after a comment character is removed
    - String literals are not parsed; use carefully with -i

EOF
}

# Default options
KEEP_BLANK=false
INLINE=false
SIMPLE_MODE=false
CUSTOM_CHARS=""

# Parse arguments
# Accept 0 or 1 positional FILE argument. If omitted, default to '-'
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "cnc version $VERSION"
            exit 0
            ;;
        -b|--keep-blank)
            KEEP_BLANK=true
            shift
            ;;
        -i|--inline)
            INLINE=true
            shift
            ;;
        -s|--simple)
            SIMPLE_MODE=true
            shift
            ;;
        -)
            FILE="-"
            shift
            ;;
        -c|--char)
            if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                echo "Error: -c requires an argument" >&2
                exit 1
            fi
            CUSTOM_CHARS="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            echo "Try 'cnc --help' for more information." >&2
            exit 1
            ;;
        *)
            FILE="${FILE:-$1}"
            shift
            ;;
    esac
done

# Default to stdin when no file specified
: "${FILE:=-}"

# If using a real file (not stdin), validate existence and readability
if [[ "$FILE" != "-" ]]; then
    if [[ ! -f "$FILE" ]]; then
        echo "Error: File '$FILE' not found" >&2
        exit 1
    fi
    if [[ ! -r "$FILE" ]]; then
        echo "Error: File '$FILE' is not readable" >&2
        exit 1
    fi
fi

# Build comment patterns
if [[ -n "$CUSTOM_CHARS" ]]; then
    # Use custom characters
    IFS=',' read -ra CHARS <<< "$CUSTOM_CHARS"
    PATTERNS=("${CHARS[@]}")
elif [[ "$SIMPLE_MODE" == true ]]; then
    # Simple mode: only #
    PATTERNS=("#")
else
    # Default: all common comment styles
    PATTERNS=("--" "//" ";" "#")
fi

# Function to remove lines starting with comments
remove_comment_lines() {
    local input="$1"

    if [[ "$input" == "-" ]]; then
        input="/dev/stdin"
    fi

    # Build grep pattern for all comment types
    local grep_pattern=""
    for pattern in "${PATTERNS[@]}"; do
        # Escape special regex characters for grep ERE
        local escaped=$(printf '%s\n' "$pattern" | sed 's/[]\/$*.^[]/\\&/g')
        if [[ -z "$grep_pattern" ]]; then
            grep_pattern="^[[:space:]]*${escaped}"
        else
            grep_pattern="${grep_pattern}|^[[:space:]]*${escaped}"
        fi
    done

    # Use grep to filter out comment lines, then optionally filter blank lines
    if [[ "$KEEP_BLANK" == true ]]; then
        grep -Ev "$grep_pattern" "$input"
    else
        grep -Ev "$grep_pattern" "$input" | grep -v '^[[:space:]]*$'
    fi
}

# Function to remove inline comments
remove_inline_comments() {
    local input="$1"

    if [[ "$input" == "-" ]]; then
        input="/dev/stdin"
    fi

    # For single pattern, use fast sed
    if [[ ${#PATTERNS[@]} -eq 1 ]]; then
        local pattern="${PATTERNS[0]}"
        local escaped=$(printf '%s\n' "$pattern" | sed 's/[&/\]/\\&/g')
        if [[ "$KEEP_BLANK" == true ]]; then
            sed "s/${escaped}.*$//" "$input"
        else
            sed "s/${escaped}.*$//" "$input" | grep -v '^[[:space:]]*$'
        fi
    else
        # For multiple patterns, use awk to find earliest occurrence
        local awk_patterns=""
        for pattern in "${PATTERNS[@]}"; do
            # Escape pattern for awk (escape backslashes and quotes)
            local escaped=$(printf '%s\n' "$pattern" | sed 's/\\/\\\\/g; s/"/\\"/g')
            awk_patterns="${awk_patterns}\"${escaped}\","
        done
        awk_patterns="${awk_patterns%,}"  # Remove trailing comma

        local keep_blank_var="$KEEP_BLANK"
        awk -v patterns="$awk_patterns" -v keep_blank="$keep_blank_var" '
        BEGIN {
            split(patterns, pats, /","/)
            for (i in pats) {
                gsub(/^"/, "", pats[i])
                gsub(/"$/, "", pats[i])
            }
        }
        {
            min_pos = length($0) + 1
            for (i in pats) {
                pos = index($0, pats[i])
                if (pos > 0 && pos < min_pos) {
                    min_pos = pos
                }
            }
            if (min_pos <= length($0)) {
                line = substr($0, 1, min_pos - 1)
            } else {
                line = $0
            }
            if (keep_blank == "true" || line !~ /^[[:space:]]*$/) {
                print line
            }
        }
        ' "$input"
    fi
}

# Process the file
if [[ "$INLINE" == true ]]; then
    remove_inline_comments "$FILE"
else
    remove_comment_lines "$FILE"
fi
