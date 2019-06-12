# test-wasm-memory

This repository demonstrates an issue interacting with the memory in an innative-built WASM module when accessing functions directly from C. As you can see in `main.c`, we are trying to `add` two boxed values. When we compile all of the C together in `build/no-wasm`, there is no issue calling `add`. However, when we call `add` in the innative-compiled library (note the indirection in `wrap.h` to get to the mangled name) we run into a segfault (shown in GDB):

```
Program received signal SIGSEGV, Segmentation fault.
0x00007ffff7fc9076 in add#2|test () from build/libtest.so

(gdb) disassemble
Dump of assembler code for function add#2|test:
   0x00007ffff7fc9060 <+0>:	mov    %edi,-0xc(%rsp)
   0x00007ffff7fc9064 <+4>:	mov    %esi,-0x10(%rsp)
   0x00007ffff7fc9068 <+8>:	mov    0x1fe1(%rip),%rcx        # 0x7ffff7fcb050 <test_WASM_memory>
   0x00007ffff7fc906f <+15>:	mov    %rcx,-0x8(%rsp)
   0x00007ffff7fc9074 <+20>:	mov    %esi,%eax
=> 0x00007ffff7fc9076 <+22>:	mov    (%rcx,%rax,1),%eax
   0x00007ffff7fc9079 <+25>:	mov    %edi,%edx
   0x00007ffff7fc907b <+27>:	add    (%rcx,%rdx,1),%eax
   0x00007ffff7fc907e <+30>:	retq   
End of assembler dump.

(gdb) info registers
rax            0xffffcf48          4294954824
rbx            0x0                 0
rcx            0x7ffff7fa7008      140737353773064
rdx            0x7fffffffd048      140737488343112
rsi            0x7fffffffcf48      140737488342856
rdi            0x7fffffffcf40      140737488342848
rbp            0x4011a0            0x4011a0 <__libc_csu_init>
rsp            0x7fffffffcf28      0x7fffffffcf28
r8             0x7ffff7f9cd90      140737353731472
r9             0x7ffff7fe2130      140737354015024
r10            0x4004cc            4195532
r11            0x7ffff7fc90d0      140737353912528
r12            0x4010b0            4198576
r13            0x7fffffffd030      140737488343088
r14            0x0                 0
r15            0x0                 0
rip            0x7ffff7fc9076      0x7ffff7fc9076 <add#2|test+22>
eflags         0x10202             [ IF RF ]
cs             0x33                51
ss             0x2b                43
ds             0x0                 0
es             0x0                 0
fs             0x0                 0
gs             0x0                 0
```

The result of `$rcx+$rax*1` is clearly an unmapped address so the segfault makes sense. But then, how should functions operating on memory be called? I suspect that this comes from WebAssembly's efforts at memory safety but I am not sure the correct way to do this type of thing. For example, should the boxed values be created in the WebAssembly memory? And if so, how?

For reference, note how clang does not export the memory of the WASM module:

```
(module
  (type (;0;) (func))
  (type (;1;) (func (param i32 i32) (result i32)))
  (type (;2;) (func (param i32 i32)))
  (func $__wasm_call_ctors (type 0))
  (func $add (type 1) (param i32 i32) (result i32)
    local.get 1
    i32.load
    local.get 0
    i32.load
    i32.add)
  (func $add_in_place (type 2) (param i32 i32)
    local.get 1
    local.get 1
    i32.load
    local.get 0
    i32.load
    i32.add
    i32.store)
  (table (;0;) 1 1 funcref)
  (memory (;0;) 2)
  (global (;0;) (mut i32) (i32.const 66560))
  (global (;1;) i32 (i32.const 66560))
  (global (;2;) i32 (i32.const 1024))
  (global (;3;) i32 (i32.const 1024))
  (export "memory" (memory 0))
  (export "__wasm_call_ctors" (func $__wasm_call_ctors))
  (export "__heap_base" (global 1))
  (export "__data_end" (global 2))
  (export "__dso_handle" (global 3))
  (export "add" (func $add))
  (export "add_in_place" (func $add_in_place)))
```
