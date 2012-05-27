section .data
	usage 	db "Usage: visualizer motion_vectors previous_frame.bmp estimated_frame.bmp", 10, 0
	rb	db "rb", 0
	wb	db "wb", 0

section .bss
	file	resd 1
	width	resd 1
	height 	resd 1
	count 	resd 1
	coords	resd 1

	input	resd 1
	output 	resd 1

section .text
	global _start

	extern _create_window
	extern _process_events
	extern _draw_line
	extern _flush
	extern _load_bitmap
	extern _draw_bitmap

	extern fopen
	extern fclose
	extern fread
	extern fwrite
	extern malloc
	extern memcpy
	extern free
	extern printf
	extern exit

_start:
	cmp dword [esp], 4
	je .arguments_ok
	push usage
	call printf
	add esp, 4
	jmp _exit
.arguments_ok:

	push rb
	push dword [esp + 12]
	call fopen
	add esp, 8
	test eax, eax
	jz _exit
	mov [file], eax

	push dword [file]
	push 2
	push 4
	push width
	call fread
	add esp, 16

	mov eax, [width]
	shr eax, 3
	mov ecx, [height]
	mul ecx

	push eax
	call malloc
	mov [coords], eax
	pop eax
	shr eax, 2
	mov ecx, eax
	shr ecx, 1
	mov [count], ecx

	push dword [file]
	push eax
	push 4
	push dword [coords]
	call fread
	add esp, 16

	push dword [esp + 16]
	push dword [esp + 16]
	call _build
	add esp, 8

	push _redraw
	push dword [height]
	push dword [width]
	call _create_window
	add esp, 12

	push dword [esp + 12]
	call _load_bitmap
	add esp, 4

.loop:
	call _process_events
	jmp .loop

_exit:
	push 0
	call exit

_redraw:
	push ebx
	push esi
	push edi

	call _draw_bitmap

	mov esi, 4
	mov edi, [height]
	sub edi, 4
	mov ebx, 0

.loop:
	mov eax, [coords]

	push edi
	mov ecx, [eax + ebx * 8 + 4]
	sub [esp], ecx
	push esi
	mov ecx, [eax + ebx * 8]
	add [esp], ecx
	push edi
	push esi
	call _draw_line
	add esp, 16

	add esi, 8
	cmp esi, [width]
	jl .no_row_change
	mov esi, 4
	sub edi, 8
.no_row_change:

	inc ebx
	cmp ebx, [count]
	jne .loop

	pop edi
	pop esi
	pop ebx
	ret

_copy_block:
	push ebx
	push esi
	push edi

	mov edi, [esp + 16]
	mov esi, [esp + 20]

	mov ebx, 8
.loop:
	push 24
	push esi
	push edi
	call memcpy
	add esp, 12

	mov eax, [width]
	mov ecx, 3
	mul ecx
	add edi, eax
	add esi, eax

	dec ebx
	jnz .loop

	pop edi
	pop esi
	pop ebx
	ret

_build:
	push ebx
	push esi
	push edi

	push rb
	push dword [esp + 20]
	call fopen
	add esp, 8
	mov [input], eax

	push wb
	push dword [esp + 24]
	call fopen
	add esp, 8
	mov [output], eax

	push 54
	call malloc
	add esp, 4

	push dword [input]
	push 54
	push 1
	push eax
	call fread
	pop eax
	add esp, 12

	push dword [output]
	push 54
	push 1
	push eax
	call fwrite
	pop eax
	add esp, 12

	push eax
	call free
	add esp, 4

	mov eax, [width]
	mov ecx, [height]
	mul ecx
	mov ecx, 3
	mul ecx

	push eax
	call malloc
	mov esi, eax
	call malloc
	mov edi, eax
	pop eax

	push dword [input]
	push eax
	push 1
	push esi
	call fread
	mov eax, [esp + 8]
	add esp, 16

	push eax

	mov ebx, 0
	push 0
	push 0
.loop:
	mov eax, [esp]
	mov [esp + 4], eax

	add [esp], edi
	add [esp + 4], esi

	mov ecx, [coords]
	mov eax, [ecx + ebx * 8]
	mov edx, 3
	mul edx
	add [esp + 4], eax
	mov eax, [ecx + ebx * 8 + 4]
	mov ecx, [width]
	mul ecx
	mov edx, 3
	mul edx
	add [esp + 4], eax

	call _copy_block

	sub [esp], edi
	add dword [esp], 24
	inc ebx

	mov ecx, [width]
	shr ecx, 3
	mov eax, ebx
	xor edx, edx
	div ecx
	test edx, edx
	jnz .no_row_change
	mov eax, [width]
	mov ecx, 21
	mul ecx
	add dword [esp], eax
.no_row_change:

	cmp ebx, [count]
	jne .loop

	add esp, 8

	pop eax

	push dword [output]
	push eax
	push 1
	push edi
	call fwrite
	add esp, 16

	push edi
	call free
	add esp, 4

	push esi
	call free
	add esp, 4

	push dword [output]
	call fclose
	add esp, 4

	pop edi
	pop esi
	pop ebx
	ret
