[bits 32]

global start

extern init_idt, init_pic
extern main

	start:
		; Run initialization code
		jmp init

align 4
	mboot:
		; Multiboot macros
		MULTIBOOT_PAGE_ALIGN equ 1 << 0
		MULTIBOOT_MEMORY_INFO equ 1 << 1
		MULTIBOOT_AOUT_KLUDGE equ 1 << 16
		MULTIBOOT_HEADER_MAGIC equ 0x1BADB002
		MULTIBOOT_HEADER_FLAGS equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_AOUT_KLUDGE
		MULTIBOOT_CHECKSUM equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

		extern code, bss, end

		; GRUB multiboot signature
		dd MULTIBOOT_HEADER_MAGIC
		dd MULTIBOOT_HEADER_FLAGS
		dd MULTIBOOT_CHECKSUM

		; AOUT kludge (filled in by linker)
		dd mboot
		dd code
		dd bss
		dd end
		dd start

	; Global Descriptor Table (GDT)
	gdt:
		dq 0x0000000000000000 ; Null
		dq 0x00CF9A000000FFFF ; Code
		dq 0x00CF92000000FFFF ; Data
	gdt_ptr:
		dw (gdt_ptr - gdt) - 1
		dd gdt

	init_gdt:
		lgdt [gdt_ptr]

		mov ax, 0x10
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax

		jmp 8:init_gdt_end

	init_gdt_end:
		ret

	; Initialize environment
	init:
		; Disable interrupts
		cli

		; Initialize stack
		mov esp, stack

		; Clear flags
		push 0
		popf

		; Load GDT, IDT and PIC
		call init_gdt
		call init_idt
		call init_pic

		; Enable interrupts
		sti

		; Start game
		call main

		; Do nothing if main for some reason returns
	halt:
		cli
		hlt
		jmp halt
		
section .bss

		; 16 kB stack
		stack resb 0x4000