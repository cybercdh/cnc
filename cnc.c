/*
 * cnc - cat no comments
 * A fast utility to display files without comment lines
 * https://github.com/cybercdh/cnc
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <getopt.h>
#include <errno.h>

#define VERSION "1.1.0"
#define INITIAL_LINE_SIZE 4096
#define MAX_PATTERNS 32

/* Command line options */
static bool keep_blank = false;
static bool inline_mode = false;
static bool simple_mode = false;

/* Comment patterns */
static const char *patterns[MAX_PATTERNS];
static int pattern_count = 0;

/* Default patterns: ordered by length (longest first for correct matching) */
static const char *default_patterns[] = {"--", "//", "#", ";"};
static const int default_pattern_count = 4;

static void show_help(const char *progname) {
    printf("Usage: %s [OPTIONS] [FILE]\n\n", progname);
    printf("Display file contents without comment lines.\n\n");
    printf("By default, cnc recognizes common comment styles:\n");
    printf("  #   (Shell, Python, Ruby, YAML, Perl, Make, etc.)\n");
    printf("  //  (C, C++, Java, JavaScript, Go, Rust, etc.)\n");
    printf("  ;   (Assembly, INI files, Lisp)\n");
    printf("  --  (SQL, Lua, Haskell)\n\n");
    printf("OPTIONS:\n");
    printf("    -h, --help          Show this help message\n");
    printf("    -v, --version       Show version\n");
    printf("    -b, --keep-blank    Keep blank lines (default: remove them)\n");
    printf("    -i, --inline        Also remove inline comments (after code)\n");
    printf("    -c, --char CHARS    Override comment characters (comma-separated)\n");
    printf("                        Example: -c '#,//'\n");
    printf("    -s, --simple        Only remove # comments (fastest)\n\n");
    printf("INPUT:\n");
    printf("    If FILE is omitted or '-', read from stdin\n\n");
    printf("EXAMPLES:\n");
    printf("    %s /etc/ssh/sshd_config     # SSH config\n", progname);
    printf("    %s -b nginx.conf            # Keep blank lines\n", progname);
    printf("    %s -i script.sh             # Remove inline comments too\n", progname);
    printf("    %s -s Makefile              # Fast mode, # only\n", progname);
    printf("    %s -c ';' config.ini        # Only ; comments\n", progname);
    printf("    %s -c '#,;' app.conf        # Only # and ; comments\n\n", progname);
    printf("NOTES:\n");
    printf("    - Lines that start with comments (after whitespace) are removed\n");
    printf("    - With -i, everything after a comment character is removed\n");
    printf("    - String literals are not parsed; use carefully with -i\n");
}

static void show_version(void) {
    printf("cnc version %s\n", VERSION);
}

/* Parse comma-separated custom patterns */
static void parse_custom_patterns(const char *chars) {
    char *copy = strdup(chars);
    if (!copy) {
        fprintf(stderr, "Error: Memory allocation failed\n");
        exit(1);
    }

    char *token = strtok(copy, ",");
    while (token && pattern_count < MAX_PATTERNS) {
        /* Skip leading whitespace */
        while (*token && isspace(*token)) token++;
        if (*token) {
            patterns[pattern_count++] = strdup(token);
        }
        token = strtok(NULL, ",");
    }
    free(copy);
}

/* Check if line is blank (only whitespace) */
static bool is_blank_line(const char *line) {
    while (*line) {
        if (!isspace((unsigned char)*line)) {
            return false;
        }
        line++;
    }
    return true;
}

/* Check if line starts with a comment (after optional whitespace) */
static bool is_comment_line(const char *line) {
    /* Skip leading whitespace */
    while (*line && isspace((unsigned char)*line)) {
        line++;
    }

    /* Check against each pattern */
    for (int i = 0; i < pattern_count; i++) {
        size_t plen = strlen(patterns[i]);
        if (strncmp(line, patterns[i], plen) == 0) {
            return true;
        }
    }
    return false;
}

/* Find position of earliest inline comment, return -1 if none */
static int find_inline_comment(const char *line) {
    int earliest = -1;

    for (int i = 0; i < pattern_count; i++) {
        const char *pos = strstr(line, patterns[i]);
        if (pos) {
            int idx = (int)(pos - line);
            if (earliest == -1 || idx < earliest) {
                earliest = idx;
            }
        }
    }
    return earliest;
}

/* Process a single line, return true if it should be printed */
static bool process_line(char *line, size_t len) {
    /* Remove trailing newline for processing */
    if (len > 0 && line[len - 1] == '\n') {
        line[len - 1] = '\0';
        len--;
    }
    if (len > 0 && line[len - 1] == '\r') {
        line[len - 1] = '\0';
        len--;
    }

    if (inline_mode) {
        /* Remove inline comments first */
        int comment_pos = find_inline_comment(line);
        if (comment_pos >= 0) {
            line[comment_pos] = '\0';
            /* Trim trailing whitespace */
            int end = comment_pos - 1;
            while (end >= 0 && isspace((unsigned char)line[end])) {
                line[end--] = '\0';
            }
        }

        /* Check if resulting line is blank */
        if (!keep_blank && is_blank_line(line)) {
            return false;
        }

        /* Print the line */
        printf("%s\n", line);
        return true;
    } else {
        /* Check if it's a comment line */
        if (is_comment_line(line)) {
            return false;
        }

        /* Check if it's a blank line */
        if (!keep_blank && is_blank_line(line)) {
            return false;
        }

        /* Restore newline and print */
        printf("%s\n", line);
        return true;
    }
}

/* Process file with dynamic line buffer */
static int process_file(FILE *fp) {
    char *line = NULL;
    size_t bufsize = 0;
    ssize_t len;

    while ((len = getline(&line, &bufsize, fp)) != -1) {
        process_line(line, (size_t)len);
    }

    free(line);

    if (ferror(fp)) {
        fprintf(stderr, "Error: Read error\n");
        return 1;
    }

    return 0;
}

int main(int argc, char *argv[]) {
    static struct option long_options[] = {
        {"help",       no_argument,       0, 'h'},
        {"version",    no_argument,       0, 'v'},
        {"keep-blank", no_argument,       0, 'b'},
        {"inline",     no_argument,       0, 'i'},
        {"char",       required_argument, 0, 'c'},
        {"simple",     no_argument,       0, 's'},
        {0, 0, 0, 0}
    };

    const char *custom_chars = NULL;
    int opt;

    while ((opt = getopt_long(argc, argv, "hvbic:s", long_options, NULL)) != -1) {
        switch (opt) {
            case 'h':
                show_help(argv[0]);
                return 0;
            case 'v':
                show_version();
                return 0;
            case 'b':
                keep_blank = true;
                break;
            case 'i':
                inline_mode = true;
                break;
            case 'c':
                custom_chars = optarg;
                break;
            case 's':
                simple_mode = true;
                break;
            default:
                fprintf(stderr, "Try '%s --help' for more information.\n", argv[0]);
                return 1;
        }
    }

    /* Set up patterns */
    if (custom_chars) {
        parse_custom_patterns(custom_chars);
    } else if (simple_mode) {
        patterns[0] = "#";
        pattern_count = 1;
    } else {
        for (int i = 0; i < default_pattern_count; i++) {
            patterns[i] = default_patterns[i];
        }
        pattern_count = default_pattern_count;
    }

    /* Determine input source */
    FILE *fp;
    const char *filename = NULL;

    if (optind < argc && strcmp(argv[optind], "-") != 0) {
        filename = argv[optind];
        fp = fopen(filename, "r");
        if (!fp) {
            fprintf(stderr, "Error: File '%s' not found\n", filename);
            return 1;
        }
    } else {
        fp = stdin;
    }

    int result = process_file(fp);

    if (fp != stdin) {
        fclose(fp);
    }

    return result;
}
