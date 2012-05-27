section .data
	integer	db "%d", 10, 0
	string	db "%s", 10, 0
	char	db "%c", 10, 0

section .text
	global _main

	global malloc
	global free
	global memcpy
	global fopen
	global fclose
	global fread
	global fwrite
	global printf
	global exit

	extern _start

	extern __imp____argc
	extern __imp____argv

	extern _malloc
	extern _free
	extern _memcpy
	extern _fopen
	extern _fclose
	extern _fread
	extern _fwrite
	extern _printf
	extern _exit

_main:
	mov eax, [__imp____argc]
	mov ecx, [eax]
	mov edx, ecx

	mov eax, [__imp____argv]
	mov eax, [eax]

.loop:
	dec ecx
	push dword [eax + ecx * 4]
	test ecx, ecx
	jnz .loop

	push edx

	jmp _start

malloc:
	jmp _malloc

free:
	jmp _free

memcpy:
	jmp _memcpy

fopen:
	jmp _fopen

fclose:
	jmp _fclose

fread:
	jmp _fread

fwrite:
	jmp _fwrite

printf:
	jmp _printf

exit:
	jmp _exit
