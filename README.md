# PBasic m6502

Integer BASIC interpreter for the MOS 6502 microprocessor.

## Highlights

- Full integer BASIC dialect designed for the MOS Technology 6502 processor
- Compact memory footprint fitting entirely within 64 KiB of address space
- Interactive REPL with prompt, line editing, and syntax error reporting
- Comprehensive command set including LET, PRINT, IF, GOTO, GOSUB, RETURN, INPUT, LIST, RUN, NEW, FREE, REM, END, and EXIT
- 32-bit signed integer arithmetic for expressions and variable storage
- Built-in mathematical and utility functions including ABS and pseudo-random numbers via RND
- Efficient linked-list program memory manager with dynamic line insertion and deletion
- Headless execution and verification support via the Mojave m6502 emulator

## Prerequisites

- **cc65** (`ca65` and `ld65`) — required to assemble and link source files; install via `apt install cc65`
- **mojave** — optional emulator required to run and test; install from [Mojave](https://github.com/carlos/mojave)

## Installation

### Build from Source

From a checkout of this repository:

```bash
make build
```

The resulting flat binary will be output to `bin/pbasic.bin`.

## Usage

### Interactive REPL

Start the interactive BASIC environment in the Mojave emulator:

```bash
make run
```

Or invoke Mojave directly:

```bash
mojave --machine m6502 --load-bin bin/pbasic.bin@0000
```

## Project Layout

```
pbasic-m6502/
├── .make/                  # Build scripts and linker configuration
│   ├── build.sh
│   ├── pbasic.cfg
│   └── test.sh
├── bin/                    # Compiled binary outputs
│   └── pbasic.bin
├── demos/                  # Sample BASIC programs
├── specs/                  # Architecture and feature specifications
├── src/                    # 6502 assembly source files
│   ├── defs.inc
│   └── main.s
├── Makefile
├── README-PT.md
└── README.md
```

## Development

Run tests and verification:

```bash
make test
```

Clean build artifacts:

```bash
make clean
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
