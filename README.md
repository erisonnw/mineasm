<p align="right">
  <strong>Language:</strong>
  <a href="README">English</a> | 
  <a href="README_PT-BR">Português (Brasil)</a>
</p>

![Banner](./.assets/banner/Mineasm.png)

> A simple Minecraft-style voxel world engine written in "Assembly"

![language](https://img.shield.io/badge/linguage-Assembly%20x86--64-orange)
![platform](https://img.shield.io/badge/platform-linux-blue)
![license](https://img.shield.io/badge/license-MIT-green)

## About the Project
- **Spatial Hashing**: Maps block/chunk coordinates into an avalanche-mixed 32 bits hash based on dynamic linear-congruential strides.
- **Procedual Biomes**: Distributes terrain archetypes via 2D Nearest-Neighbor vector distance mapping inside Temperature/Humidity space.
- **Chunk Lookup Cache**: A fixed structure in memory that holds active chunks and tracks load flags using iterative linear search scanning.
- **Voxel Math Translation**: Leverages specialized hardware float instructions (`roundss`) to convert global 3D spatial points into local chunk block offsets.

All architecture code targets **Linux x86-64 Native ABI**, maintaining low-level stack requirements and calling conventions.

## Project Structure
```bash
.
├── AUTHORS
├── build
│   ├── exec
│   │   └── *elf
│   └── obj
│       └── *.o
├── CONTRIBUTING
├── Makefile
├── README.md
├── README_PT-BR.md
└── src
    ├── biome.asm
    ├── block.asm
    ├── chunk.asm
    ├── main.asm
    └── seed.asm
```

## Requirements
- Linux **x86-64**
- GNU binutils (`as` / gas syntax compilation targets)

## Build and Running
### Using Makefiles
```bash
make
make debug        # (Optional)
./build/exec/seed
```

<details>
<summary>
<br>
Makefile
</br>
</summary>

```Makefile
AS                          = as
LD                          = ld

LDFLAGS                     = -m elf_x86_64 -o
ASFLAGS                     = --64 -g -o

DIR_BUILD                   = build
DIR_SRC                     = src
DIR_OBJ                     = $(DIR_BUILD)/obj
DIR_EXEC                    = $(DIR_BUILD)/exec

SOURCES                     := $(wildcard $(DIR_SRC)/*.asm) $(wildcard $(DIR_SRC)/*.s)
OBJECTS                     := $(patsubst $(DIR_SRC)/%.asm,$(DIR_OBJ)/%.o,$(patsubst $(DIR_SRC)/%.s,$(DIR_OBJ)/%.o,$(SOURCES)))
TARGET                      = $(DIR_EXEC)/seed

.PHONY: all clean debug

all: $(TARGET)

$(DIR_OBJ)/%.o: $(DIR_SRC)/%.asm
	@mkdir -p $(DIR_OBJ)
	$(AS) $(ASFLAGS) $@ $<

$(DIR_OBJ)/%.o: $(DIR_SRC)/%.s
	@mkdir -p $(DIR_OBJ)
	$(AS) $(ASFLAGS) $@ $<

$(TARGET): $(OBJECTS)
	@mkdir -p $(DIR_EXEC)
	$(LD) $(LDFLAGS) $(TARGET) $(OBJECTS)

clean:
	rm -rf $(DIR_BUILD)
	rm -f .gdbinit

debug: all
	@echo "set debuginfod enabled off" > .gdbinit
	@echo "tbreak .exit_program" >> .gdbinit
	@echo "run" >> .gdbinit
	gdb -q -iex "set auto-load safe-path /" -x .gdbinit \
		-ex "print/x \$$eax" \
		-ex "print/u \$$eax" \
		-ex "print/x \$$ax" \
		-ex "print/u \$$al" \
		-ex "print/u \$$ah" \
		$(TARGET)
```
</details>

## Example Output
```bash
gdb -q -iex "set auto-load safe-path /" -x .gdbinit \
        -ex "print/x \$eax" \
        -ex "print/u \$eax" \
        -ex "print/x \$ax" \
        -ex "print/u \$al" \
        -ex "print/u \$ah" \
        build/exec/seed
Reading symbols from build/exec/seed...
Temporary breakpoint 1 at 0x40149a: file src/main.asm, line 41.
Savanna
Temporary breakpoint 1, exit_program () at src/main.asm:41
41          movq %rax, %rdi
Temporary breakpoint 2 at 0x40149a: file src/main.asm, line 41.
Savanna
Temporary breakpoint 2, exit_program () at src/main.asm:41
41          movq %rax, %rdi
$1 = 0x103
$2 = 259
$3 = 0x103
--Type <RET> for more, q to quit, c to continue without paging--
$4 = 3
$5 = 1
(gdb) 
```

---

## API Reference

| Function | Signature (C-Equivalent) | Description |
| :--- | :--- | :--- |
| `coord_tohash` | `uint32_t coord_tohash(int x, int y, int z, int seed)` | Computes a pseudo-random bitwise avalanche mixing hash. |
| `biome_type` | `int biome_type(int x, int y, int z, int seed)` | Evaluates positions and logs the chosen biome to stdout. |
| `chunk` | `void *chunk(int cx, int cz)` | Performs a linear scan through `loaded` array to find matching chunk. |
| `get_block` | `uint16_t get_block(int x, int y, int z)` | Resolves global targets and returns packed 16-bit block data. |
| `set_block` | `void set_block(int x, int y, int z, uint8_t type, uint8_t is_solid)` | Updates 2-byte chunk states at specific coordinate targets. |
| `break_block` | `void break_block(int x, int y, int z, ...)`| *(Under Construction)* Will handle voxel-ray casting intersection. |

---

## Technical Details

### Spatial Hashing (`seed.asm`)
The coordinate seed engine utilizes fixed integer constants to randomize input vectors (`POSX = 0xcc9e2d51`, `POSY = 0x1b873593`, `POSZ = 0xe6546b64`, `SEED = 0x85ebca6b`).
The resultant linear summation passes through a bitwise shifting avalanche filter:
```text
h = h ^ (h >> 13) * 0xc2b2ae35
h = h ^ (h >> 16)
```

### Biome Generation (`biome.asm`)
1. **Temperature Extraction**: Computes `coord_tohash(x, y, z, seed)`, scales it by `4.656612875e-10`, and clamps the result between `[-1.0, 1.0]`.
2. **Humidity Extraction**: Computes `coord_tohash(x, y, z, seed + 12345)`, scales it similarly, and clamps it between `[-1.0, 1.0]`.
3. **Altitude Shifting**: Adjusts the temperature based on its vertical position relative to sea level ($y = 64.0$):
$$\text{Temperature} = \text{Temperature} - ((y - 64.0) \times 0.0016)$$
4. **Nearest-Neighbor Mapping**: Iterates through the climate chart, choosing the biome ID with the minimum Euclidean distance squared ($d^2 = \Delta \text{Temp}^2 + \Delta \text{Humid}^2$).

---

### Chunk Cache Architecture (`chunk.asm`)
The memory engine allocates a continuous `40,000` byte tracking matrix labeled `loaded` inside the `.bss` region. 
- **Array Layout**: Up to **9 active slots**, with each entry consuming exactly **`4,112` bytes**:
  - `bytes 0-3` (Offset 0): Chunk X coordinate (`int`, 4 bytes)
  - `bytes 4-7` (Offset 4): Chunk Z coordinate (`int`, 4 bytes)
  - `bytes 8-4103` (Offset 8): Raw voxel block memory payload array (`6,144` bytes)
  - `byte 4104` (Offset 4104): `is_loaded` tracking activation flag (`uint8_t`, 1 byte)
- **Scanning Engine**: `chunk(cx, cz)` maps registers `%r8d` and `%r9d` to scan entries sequentially. If an entry is marked active (`is_loaded != 0`) and matches target dimensions, it returns the base pointer address of that specific entry via `%rax`. If not found after 9 checks, it falls back to a null return pointer.

---

### Voxel Block Access Logic (`block.asm`)
- **Dimensions**: Chunks enforce a rigid spatial grid size of **X: 16 × Y: 24 × Z: 16**, resulting in exactly `6,144` blocks per loaded sector.
- **Global-to-Local Conversion**: Coordinates are processed using SSE math routines. The code computes chunk bounds by dividing coordinates by `16.0` and applying a downward rounding pattern (`roundss $1` for `floor()` equivalent):
  $$cx = \lfloor x / 16.0 \rfloor, \quad cz = \lfloor z / 16.0 \rfloor$$
- **Local Grid Offset**: Local coordinates are extracted by subtracting the calculated chunk origins:
  $$lx = x - (cx \times 16), \quad lz = z - (cz \times 16)$$
- **Memory Flattening Mapping**: Voxel arrays resolve target structures by flattening multidimensional matrices into a single continuous index:
  $$\text{Index} = lx \times (24 \times 16) + y \times 16 + lz \implies lx \times 384 + y \times 16 + lz$$
- **Byte Storage Protocol**: Each voxel block consumes **2 sequential bytes** within the target memory region (`Index * 2` offset):
  - `Byte 0`: Voxel material block `type`
  - `Byte 1`: Structural configuration flag (`is_solid`)
- **Access Boundary Guards**: Requests that point outside valid vertical bounds ($y < 0$ or $y \ge 24$) bypass processing completely. In `get_block`, out-of-bounds queries or missing chunk targets return a fallback **sentinel code of `10`** (treated as void air/error space).

---

## Lower-Level Constraints & ABI Rules
- **Calling Convention**: Strict adherence to the **System V AMD64 ABI**. Integer/pointer parameters flow via `%edi`, `%esi`, `%edx`, `%ecx`, `%r8d`, and `%r9d`.
- **Hardware Float Math**: Handled entirely via **SSE Scalar Extensions** (`movss`, `maxss`, `minss`, `mulss`, `subss`, `addss`, `comiss`, `cvtsi2ss`, `roundss`).
- **Memory References**: Uses strict `%rip`-relative addressing for localized string sections, structures, and float buffers to comply with modern Position-Independent Executable (`-pie`) linker setups.
- **I/O Subsystem**: Standard diagnostic messages use raw POSIX `syscall` writes (`%rax = 1`, `%rdi = 1`) to eliminate dependency layers where applicable.

## Development Status
- [x] Matrix spatial coordinate mixing algorithm
- [x] Float clamping and Nearest-Neighbor vector distance biome system
- [x] Native Assembly POSIX sys-call integration for localized printing
- [x] Iterative memory tracking cache tables for chunk pointers
- [x] Multi-dimensional array flattening coordinate translations
- [ ] Raycasting logic for breaking blocks (`break_block` loop scaffolding initialized)
- [ ] Biome-dependent terrain generation
- [ ] 16-byte stack alignment audit across internal routines to prevent ABI runtime faults during libc extensions

## License
Distributed under the **MIT License**. See the [`LICENSE`](LICENSE) file for details.

---

> NOTE: The code hosted in this repository contains a few intentional/unresolved logical errors.

---

<p align="center">
  <img src="https://upload.wikimedia.org/wikipedia/commons/8/8a/Google_Gemini_logo.svg" alt="Google Gemini Logo" width="120"/><br>
  <sub>README and README_PT-BR files generated automatically by <strong>Google Gemini</strong></sub>
</p>