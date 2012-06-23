section .data
	usage 	db "Usage: visualizer <vectors> <frame>", 10, 0
	rb	db "rb", 0
	wb	db "wb", 0

section .bss
	file	resd 1
	width	resd 1
	height 	resd 1
	count 	resd 1
	coords	resd 1

	frame	resd 1
	estimated_frame resd 1

	state	resb 1

section .text
	global _start

	extern _read_bitmap
	extern _create_bitmap
	extern _scale_bitmap
	extern _get_pixel
	extern _set_pixel

	extern _create_window
	extern _get_window_size
	extern _is_key_pressed
	extern _process_events
	extern _draw_line
	extern _flush
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
	mov byte [state], 0x01

	cmp dword [esp], 3
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

	push dword [esp + 12]
	call _read_bitmap
	add esp, 4
	mov [frame], eax

	push dword [coords]
	push dword [frame]
	call _build_estimation
	add esp, 8
	mov [estimated_frame], eax

	push _redraw
	push dword [height]
	push dword [width]
	call _create_window
	add esp, 12

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

	push "V"
	call _is_key_pressed
	add esp, 4
	test eax, eax
	jz .v_not_pressed
	xor byte [state], 0x1
.v_not_pressed:

	push "E"
	call _is_key_pressed
	add esp, 4
	test eax, eax
	jz .e_not_pressed
	xor byte [state], 0x2
.e_not_pressed:

	sub esp, 8
	lea eax, [esp + 4]
	push eax
	lea eax, [esp + 4]
	push eax
	call _get_window_size
	add esp, 8

	cvtpi2ps xmm0, [esp]
	add esp, 8
	mov eax, [frame]
	cvtpi2ps xmm1, [eax + 4]
	divps xmm0, xmm1
	xorps xmm1, xmm1
	unpcklps xmm0, xmm1
	movhlps xmm1, xmm0
	minss xmm0, xmm1
	sub esp, 4
	movss [esp], xmm0

	test byte [state], 0x2
	jz .frame
	push dword [estimated_frame]
	jmp .estimated_frame
.frame:
	push dword [frame]
.estimated_frame:
	call _scale_bitmap
	add esp, 4

	push eax
	call _draw_bitmap
	add esp, 4

	test byte [state], 0x1
	jz .skip_vectors

	mov esi, 4
	mov edi, [height]
	sub edi, 4
	mov ebx, 0

.loop:
	mov eax, [coords]

	movss xmm0, [esp]

	push edi
	mov ecx, [eax + ebx * 8 + 4]
	sub [esp], ecx
	cvtsi2ss xmm1, [esp]
	mulss xmm1, xmm0
	cvttss2si ecx, xmm1
	mov [esp], ecx

	push esi
	mov ecx, [eax + ebx * 8]
	add [esp], ecx
	cvtsi2ss xmm1, [esp]
	mulss xmm1, xmm0
	cvttss2si ecx, xmm1
	mov [esp], ecx

	push edi
	cvtsi2ss xmm1, [esp]
	mulss xmm1, xmm0
	cvttss2si ecx, xmm1
	mov [esp], ecx

	push esi
	cvtsi2ss xmm1, [esp]
	mulss xmm1, xmm0
	cvttss2si ecx, xmm1
	mov [esp], ecx

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

.skip_vectors:
	add esp, 4

.return:
	pop edi
	pop esi
	pop ebx
	ret

_copy_block:
	push ebx
	push esi
	push edi

	mov edi, 8
.loop_height:
	dec edi
	mov esi, 8
.loop_width:
	dec esi

	push dword [esp + 36]
	add [esp], edi
	push dword [esp + 36]
	add [esp], esi
	push dword [esp + 36]
	call _get_pixel
	add esp, 12

	push eax
	push dword [esp + 28]
	add [esp], edi
	push dword [esp + 28]
	add [esp], esi
	push dword [esp + 28]
	call _set_pixel
	add esp, 16

	test esi, esi
	jnz .loop_width

	test edi, edi
	jnz .loop_height

	pop edi
	pop esi
	pop ebx
	ret

_build_estimation:
	push ebx
	push esi
	push edi

	mov eax, [esp + 16]
	push dword [eax + 8]
	push dword [eax + 4]
	call _create_bitmap
	add esp, 8
	mov ebx, eax

	mov eax, [esp + 16]
	mov edi, [eax + 8]
	shr edi, 3
.loop_height:
	dec edi
	mov eax, [esp + 16]
	mov esi, [eax + 4]
	shr esi, 3
.loop_width:
	dec esi

	mov eax, [esp + 16]
	mov eax, [eax + 4]
	shr eax, 3
	mul edi
	add eax, esi

	mov ecx, [esp + 20]
	mov edx, [ecx + eax * 8 + 4]
	mov ecx, [ecx + eax * 8]

	mov eax, [esp + 16]
	push edi
	shl dword [esp], 3
	add [esp], edx
	push esi
	shl dword [esp], 3
	add [esp], ecx
	push eax
	push edi
	shl dword [esp], 3
	push esi
	shl dword [esp], 3
	push ebx
	call _copy_block
	add esp, 24

	test esi, esi
	jnz .loop_width

	test edi, edi
	jnz .loop_height

	mov eax, ebx

	pop edi
	pop esi
	pop ebx
	ret
