# mC Scanner

Lexical scanner for the mC language. CS4318 Compiler Construction, Project 1.

## Overview

This scanner recognizes tokens in mC: keywords, identifiers, integer/character/string constants, operators, and punctuation. It reports errors for illegal tokens, unterminated comments, unterminated strings, unrecognized escape sequences, and strings spanning multiple lines—each with correct `(line:column)` positions.

## Requirements

- **flex** (lexical analyzer generator)
- **gcc** (C compiler)

On Ubuntu/WSL: `sudo apt install build-essential flex`

## Build

```bash
make clean
make
```

## Run

**Interactive** (type input, then Ctrl+D to finish):
```bash
./obj/scanner
```

**From file**:
```bash
./obj/scanner test0.txt
```

## Test Files

| File | Purpose |
|------|---------|
| `test0.txt` | Keywords (assignment sample) |
| `test1.txt` | Keywords + identifier |
| `test2.txt` | Strings, escapes, bad escape `\b` |
| `test_comment.txt` | Unterminated comment |
| `test_unterm_string.txt` | String spans multiple lines |

## Output Format

Each token is printed as:
```
<TYPE, value> : (line:column)
```

Example: `<KEYWORD, int> : (1:1)`, `<ID, x> : (1:5)`, `<ERROR, Unrecognized escape character in String> : (2:32)`

## Authors

- Knowledge Neupane
- Carson Riefel

See `writeup.txt` for contribution details.

## License

Course project. See syllabus for academic integrity policies.
