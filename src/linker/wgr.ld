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
    *(.rodata)
    *(.rodata.*)
    . = ALIGN(4);
  } > MEM

  .data :
  {
    . = ALIGN(4);
    *(.data)
    *(.data.*)
    *(.bss)
    *(.bss.*)
    *(COMMON)
    . = ALIGN(4);
  } > MEM

  _end = .;

  _estack = ORIGIN(MEM) + LENGTH(MEM) - 4;
  _sstack = _end; /* Stack uses the remaining memory */
}
