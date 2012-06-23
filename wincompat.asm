section .bss
	quote resd 1
	arg_start resd 1
	arg_length resd 1

section .text
	global _main

	global malloc
	global realloc
	global free
	global memcpy
	global fopen
	global fclose
	global fread
	global fwrite
	global fseek
	global printf
	global sprintf
	global fscanf
	global exit

	extern _start

	extern _malloc
	extern _realloc
	extern _free
	extern _memcpy
	extern _fopen
	extern _fclose
	extern _fread
	extern _fwrite
	extern _fseek
	extern _printf
	extern _sprintf
	extern _fscanf
	extern _exit

	extern __imp__GetCommandLineA@0

_main:
	call [__imp__GetCommandLineA@0]

	mov dword [quote], 1

	xor ecx, ecx

.argument_loop:
	inc ecx
	mov dword [arg_length], 0

.char_loop:
	cmp byte [eax], 0
	je .delimiter
	cmp byte [eax], " "
	jne .not_delimiter
	cmp dword [quote], 0
	je .not_delimiter
	inc eax
	cmp dword [arg_length], 0
	je .char_loop

.delimiter:
	push eax
	push ecx
	push dword [arg_length]
	add dword [esp], 1
	call _malloc

	sub dword [esp], 1
	mov edx, [esp]
	mov byte [eax + edx], 0

	push dword [arg_start]
	push eax
	call _memcpy

	pop edx
	add esp, 4

	add esp, 4
	pop ecx
	pop eax

	push edx

	cmp byte [eax], 0
	je .end_loop
	jmp .argument_loop

.not_delimiter:
	cmp byte [eax], 34 ; "
	jne .not_quote
	xor dword [quote], 1
	inc eax
	jmp .char_loop

.not_quote:
	cmp dword [arg_length], 0
	jne .not_first
	mov [arg_start], eax
.not_first:
	inc dword [arg_length]
	inc eax
	jmp .char_loop

.end_loop:

	xor edx, edx
.reverse_loop:
	push ecx
	mov eax, [esp + edx * 4 + 4]
	sub ecx, edx
	dec ecx
	xchg eax, [esp + ecx * 4 + 4]
	mov [esp + edx * 4 + 4], eax
	pop ecx

	mov eax, ecx
	shr eax, 1
	inc edx
	cmp edx, eax
	jl .reverse_loop

	push ecx

	jmp _start

malloc:
	jmp _malloc

realloc:
	jmp _realloc

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

fseek:
	jmp _fseek

printf:
	jmp _printf

sprintf:
	jmp _sprintf

fscanf:
	jmp _fscanf

exit:
	jmp _exit
