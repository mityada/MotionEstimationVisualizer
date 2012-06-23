section .data
	mode_read db "rb", 0
	mode_write db "wb", 0

	SEEK_SET equ 0
	SEEK_CUR equ 1

section .text
	global _read_bitmap
	global _create_bitmap
	global _write_bitmap
	global _scale_bitmap
	global _get_pixel
	global _set_pixel

	extern fopen
	extern fclose
	extern fread
	extern fwrite
	extern fseek
	extern malloc
	extern realloc
	extern free
	extern memcpy

	extern printf

_read_bitmap:
	mov eax, [esp + 4]
	push mode_read
	push eax
	call fopen
	add esp, 8

	test eax, eax
	jz .error

	push eax

	push 14
	call malloc
	add esp, 4

	push 14
	push 1
	push eax
	call fread

	mov eax, [esp]
	add esp, 12

	cmp word [eax], "BM"		; file type
	jne .error

	push dword [eax + 10]		; pixel array

	push eax
	call free
	add esp, 4

	push 40
	call malloc
	add esp, 4

	push dword [esp + 4]
	push 40				; count
	push 1				; size
	push eax
	call fread
	mov eax, [esp]
	add esp, 16

	cmp dword [eax + 16], 0		; compression
	je .no_compression
	add esp, 8
	jmp .error
.no_compression:
	cmp word [eax + 14], 8
	je .valid_bpp
	cmp word [eax + 14], 24		; bits per pixel
	je .valid_bpp
	cmp word [eax + 14], 32
	je .valid_bpp
	add esp, 8
	jmp .error
.valid_bpp:

	push eax

	push SEEK_SET
	push dword [esp + 8]
	push dword [esp + 16]
	call fseek
	add esp, 12

	pop eax
	add esp, 4

	mov ecx, [eax + 4]		; width
	mov edx, [eax + 8]		; height
	cmp edx, 0
	jge .positive
	neg edx
.positive:

	push eax

	mov eax, edx
	mul ecx
	shl eax, 2

	push eax

	lea ecx, [eax + 40]
	push ecx
	push dword [esp + 8]
	call realloc
	add esp, 8
	mov [esp + 4], eax

	push dword [esp + 8]
	push dword [esp + 4]
	push 1
	push dword [esp + 16]
	add dword [esp], 40
	call fread
	add esp, 12

	call fclose
	add esp, 4

	mov eax, [esp + 4]
	add esp, 12

	mov edx, [eax + 8]
.loop_height:
	dec edx
	mov ecx, [eax + 4]
.loop_width:
	dec ecx
	push edx
	push ecx
	push eax
	call _get_pixel
	xchg eax, [esp + 8]
	mov edx, eax
	pop eax
	pop ecx

	push edx
	push ecx
	push eax
	call _set_pixel
	pop eax
	pop ecx
	pop edx
	add esp, 4

	test ecx, ecx
	jnz .loop_width

	test edx, edx
	jnz .loop_height

	mov word [eax + 14], 32

	ret

.error:
	xor eax, eax
	ret

_create_bitmap:
	mov eax, [esp + 4]
	mov ecx, [esp + 8]
	mul ecx
	lea eax, [eax * 4 + 40]
	push eax
	call malloc
	add esp, 4

	mov dword [eax], 40		; header size
	mov ecx, [esp + 4]
	mov [eax + 4], ecx		; bitmap width
	mov ecx, [esp + 8]
	mov [eax + 8], ecx		; bitmap height
	mov word [eax + 12], 1		; color planes
	mov word [eax + 14], 32		; bpp
	mov dword [eax + 16], 0		; compression
	mov dword [eax + 20], 0		; image size
	mov dword [eax + 24], 0		; horizontal resolution
	mov dword [eax + 28], 0		; vertical resolution
	mov dword [eax + 32], 0		; colors
	mov dword [eax + 36], 0		; important colors

	ret

_write_bitmap:
	push mode_write
	push dword [esp + 8]
	call fopen
	add esp, 8

	test eax, eax
	jz .error

	push 54	; pixel array offset
	push 0	; reserved
	push 0	; BMP size
	sub esp, 2
	mov word [esp], "BM"

	mov ebp, esp
	push eax
	push 14
	push 1
	push ebp
	call fwrite
	add esp, 12
	pop eax
	add esp, 14

	push eax
	mov ecx, [esp + 12]
	mov eax, [ecx + 4]
	mov edx, [ecx + 8]
	mul edx
	lea eax, [eax * 4 + 40]
	push eax
	push 1
	push ecx
	call fwrite
	add esp, 12

	call fclose
	add esp, 4

	ret

.error:
	xor eax, eax
	add eax, 1
	ret

_scale_bitmap:
	push ebx
	push esi
	push edi

	mov eax, [esp + 16]
	cvtsi2ss xmm0, dword [eax + 4]
	mulss xmm0, dword [esp + 20]
	cvttss2si esi, xmm0
	cvtsi2ss xmm0, dword [eax + 8]
	mulss xmm0, dword [esp + 20]
	cvttss2si edi, xmm0

	mov eax, esi
	mul edi
	lea eax, [eax * 4 + 40]
	push eax
	call malloc
	add esp, 4

	push 40
	push dword [esp + 20]
	push eax
	call memcpy
	pop ebx
	add esp, 8

	mov [ebx + 4], esi
	mov [ebx + 8], edi

	xor edi, edi
.loop_height:
	xor esi, esi

	cvtsi2ss xmm0, edi
	divss xmm0, dword [esp + 20]
	cvttss2si eax, xmm0
	push eax

.loop_width:

	cvtsi2ss xmm0, esi
	divss xmm0, dword [esp + 24]
	cvttss2si eax, xmm0
	push eax

	push dword [esp + 24]
	call _get_pixel
	add esp, 4

	push eax
	push edi
	push esi
	push ebx
	call _set_pixel
	add esp, 16

	add esp, 4

	inc esi
	cmp esi, [ebx + 4]
	jne .loop_width

	add esp, 4

	inc edi
	cmp edi, [ebx + 8]
	jne .loop_height

	mov eax, ebx

.return:
	pop edi
	pop esi
	pop ebx
	ret

_scale_by_two:
	push ebx
	push esi
	push edi

	mov ebx, [esp + 16]
	mov esi, [ebx + 4]
	shr esi, 1
	mov edi, [ebx + 8]
	shr edi, 1

	mov eax, esi
	mul edi
	lea eax, [eax + eax * 2]
	add eax, 40
	push eax
	call malloc
	add esp, 4

	push 40
	push ebx
	push eax
	call memcpy
	pop eax
	pop ebx
	add esp, 4

	mov [eax + 4], esi
	mov [eax + 8], edi

	pxor mm0, mm0

	xor edi, edi
.loop_height:
	xor esi, esi
.loop_width:
	pxor mm1, mm1

	push eax

	push edi
	push esi
	push ebx

	call _get_pixel
	movd mm2, eax
	punpcklbw mm2, mm0
	psrlw mm2, 2
	paddw mm1, mm2

	add dword [esp + 4], 1
	call _get_pixel
	movd mm2, eax
	punpcklbw mm2, mm0
	psrlw mm2, 2
	paddw mm1, mm2

	add dword [esp + 8], 1
	call _get_pixel
	movd mm2, eax
	punpcklbw mm2, mm0
	psrlw mm2, 2
	paddw mm1, mm2

	sub dword [esp + 4], 1
	call _get_pixel
	movd mm2, eax
	punpcklbw mm2, mm0
	psrlw mm2, 2
	paddw mm1, mm2

	add esp, 12

	packuswb mm1, mm0
	movd edx, mm1

	pop eax

	push edx
	push edi
	shr dword [esp], 1
	push esi
	shr dword [esp], 1
	push eax
	call _set_pixel
	pop eax
	add esp, 12

	add esi, 2
	cmp esi, [ebx + 4]
	jne .loop_width

	add edi, 2
	cmp edi, [ebx + 8]
	jne .loop_height

	emms

	pop edi
	pop esi
	pop ebx
	ret

_get_pixel:
	xor eax, eax
	mov edx, [esp + 4]

	mov ecx, [edx + 4]
	cmp dword [esp + 8], ecx
	jae .return

	mov ecx, [edx + 8]
	cmp dword [esp + 12], ecx
	jae .return

	mov eax, [edx + 4]
	mov ecx, [esp + 12]
	mul ecx
	mov ecx, [esp + 8]
	add eax, ecx
	mov ecx, [esp + 4]

	cmp word [ecx + 14], 32
	jne .not_32bpp
	shl eax, 2
.not_32bpp:
	cmp word [ecx + 14], 24
	jne .not_24bpp
	lea eax, [eax + eax * 2]
.not_24bpp:
	mov ecx, [esp + 4]
	mov eax, [ecx + eax + 40]

	cmp word [ecx + 14], 8
	jne .not_8bpp
	shr eax, 8
	and eax, 0x00ff0000
	mov edx, eax
	shr edx, 8
	or eax, edx
	shr edx, 8
	or eax, edx
	or eax, 0xff000000
.not_8bpp:
	cmp word [ecx + 14], 24
	jne .return
	or eax, 0xff000000
.return:
	ret

_set_pixel:
	mov eax, [esp + 4]

	mov ecx, [eax + 4]
	cmp dword [esp + 8], ecx
	jae .return

	mov ecx, [eax + 8]
	cmp dword [esp + 12], ecx
	jae .return

	mov eax, [eax + 4]
	mov ecx, [esp + 12]
	mul ecx
	mov ecx, [esp + 8]
	add eax, ecx
	shl eax, 2
	mov ecx, [esp + 4]
	mov edx, [esp + 16]
	mov [ecx + eax + 40], edx
.return:
	ret
