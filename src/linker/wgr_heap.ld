_STACK_SIZE = 0x2000;

MEMORY
{
  PERIPHERALS (rw) : ORIGIN = 0x0000, LENGTH = 0x2000
  MEM (rwx) : ORIGIN = 0x4000, LENGTH = DEFINED(MEM_LENGTH) ? MEM_LENGTH : 0x8000
}

ENTRY(_start)

SECTIONS
{
  .text :
  {
    KEEP(*(.text.boot))
    *(.text)
    *(.text.*)
    . = ALIGN(4);
  } > MEM

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata.*)
    . = ALIGN(4);
  } > MEM

  .data :
  {
    . = ALIGN(4);
    *(.data)
    *(.data.*)
  } > MEM

  .bss :
  {
    . = ALIGN(4);
    *(.bss)
    *(.bss.*)
    *(COMMON)
  } > MEM

  . = ALIGN(4);
  _end = .;

  PROVIDE(_heap_start = _end);
  
  PROVIDE(_heap_end = ORIGIN(MEM) + LENGTH(MEM) - _STACK_SIZE);

  PROVIDE(_estack = ORIGIN(MEM) + LENGTH(MEM));
  PROVIDE(_sstack = _estack - _STACK_SIZE);

  .stack :
  {
    . = ALIGN(4);
    . += _STACK_SIZE;
  } > MEM

  PROVIDE(__stack_top = _estack);
  PROVIDE(__stack_bottom = _sstack);
}
