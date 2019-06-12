WASI_SDK?=/opt/wasi-sdk
WASI_CC=$(WASI_SDK)/bin/clang
WASM2WAT?=wasm2wat
INNATIVE_CMD?=innative-cmd
COMMON_CFLAGS:=-g --std=c99 -Ofast -Wall
.DEFAULT_GOAL:=all

# note: in benchmark/shootouts lucet first builds with "-c $^" and no "-Wl" to make the object files for each test and then combines them with a command like the one below; here we just run the command below directly
build/test.wasm: test.c
	@mkdir -p $(@D)
	$(WASI_CC) $(COMMON_CFLAGS) $^ -o $@ -nostartfiles -Wl,--no-entry -Wl,--export-all

# this is just for human readability and is possible because innative supports both wat and wasm as inputs
build/test.wat: build/test.wasm
	@mkdir -p $(@D)
	$(WASM2WAT) $^ > $@

build/libtest.so: build/test.wat
	@mkdir -p $(@D)
	$(INNATIVE_CMD) -f library -o $@ $^

# TODO: eventually could add $(SHOOTOUT_NATIVE_CFLAGS) as in benchmark/shootouts/Makefile
build/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(COMMON_CFLAGS) -c $^ -o $@

# this binary just compiles and runs the C directly
build/no-wasm: $(patsubst %.c, %.o, $(addprefix build/, $(shell ls *.c)))
	@mkdir -p $(@D)
	$(CC) $(COMMON_CFLAGS) -o $@ $^

build/main-wrapped.o: main.c
	@mkdir -p $(@D)
	$(CC) $(COMMON_CFLAGS) -c $^ -o $@ -include wrap.h

# this binary runs the function from the wasm library (libtest)
build/through-wasm: build/main-wrapped.o
build/through-wasm: build/libtest.so
	@mkdir -p $(@D)
	$(CC) $(COMMON_CFLAGS) -rdynamic build/main-wrapped.o -L build -Wl,-rpath build -ltest -o $@

# build all binaries
all: build/through-wasm
all: build/no-wasm

# run the binaries, expecting a result of 6 from each
run: all
	build/no-wasm
	build/through-wasm

clean:
	rm -rf build
