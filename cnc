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
    local file="$1"
    local input="$1"
    
    if [[ "$input" == "-" ]]; then
        input="/dev/stdin"
    fi
    
    while IFS= read -r line; do
        local is_comment=false
        
        # Check if line starts with any comment pattern (after whitespace)
        for pattern in "${PATTERNS[@]}"; do
            if [[ "$line" =~ ^[[:space:]]*$(echo "$pattern" | sed 's/[]\/$*.^[]/\\&/g') ]]; then
                is_comment=true
                break
            fi
        done
        
        if [[ "$is_comment" == false ]]; then
            # Not a comment line
            if [[ "$KEEP_BLANK" == true ]] || [[ -n "${line//[[:space:]]/}" ]]; then
                echo "$line"
            fi
        fi
    done < "$input"
}

# Function to remove inline comments
remove_inline_comments() {
    local file="$1"
    local input="$1"
    
    if [[ "$input" == "-" ]]; then
        input="/dev/stdin"
    fi
    
    while IFS= read -r line; do
        local processed_line="$line"

        # Find earliest occurrence of any pattern and trim from there
        local found=false
        local min_pos=${#line}
        for pattern in "${PATTERNS[@]}"; do
            if [[ "$line" == *"$pattern"* ]]; then
                local before="${line%%$pattern*}"
                local pos=${#before}
                if (( pos < min_pos )); then
                    min_pos=$pos
                    found=true
                fi
            fi
        done
        if [[ "$found" == true ]]; then
            processed_line="${line:0:min_pos}"
        fi
        
        # Output line if not blank or if keeping blanks
        if [[ "$KEEP_BLANK" == true ]] || [[ -n "${processed_line//[[:space:]]/}" ]]; then
            echo "$processed_line"
        fi
    done < "$input"
}

# Process the file
if [[ "$INLINE" == true ]]; then
    remove_inline_comments "$FILE"
else
    remove_comment_lines "$FILE"
fi
