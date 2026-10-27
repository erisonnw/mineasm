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