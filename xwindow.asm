section .data
	tst	db "%d", 10, 0
	mask 	db "%x", 10, "%x", 10, "%x", 10, 0
	rb	db "rb", 0

section .bss
	display 	resd 1
	screen 		resd 1
	window		resd 1
	event 		resd 24
	gc 		resd 1

	bitmap_header	resd 1
	bitmap_data	resd 1

	pixmap		resd 1

	callback	resd 1

section .text
	global _create_window
	global _process_events
	global _draw_line
	global _flush
	global _load_bitmap
	global _draw_bitmap

	extern malloc
	extern free

	extern fopen
	extern fclose
	extern fread

	extern printf

	extern XOpenDisplay
	extern XCreateSimpleWindow
	extern XSelectInput
	extern XMapWindow
	extern XCreateGC
	extern XSetForeground
	extern XPending
	extern XNextEvent
	extern XFlush
	extern XDrawLine
	extern XCreateImage
	extern XCreatePixmap
	extern XGetImage
	extern XPutImage
	extern XCopyArea
	extern XPutPixel

_create_window:
	mov eax, [esp + 12]
	mov [callback], eax

	push 0
	call XOpenDisplay
	add esp, 4
	test eax, eax
	jz .error
	mov [display], eax

 	mov ecx, [eax + 33 * 4]		; default_screen
        mov eax, [eax + 35 * 4]		; screens
        lea eax, [eax + ecx * 4]	; screens[default_screen]
        mov [screen], eax

	push dword [eax + 13 * 4]	; background color
	push dword [eax + 14 * 4]	; border color
	push 0				; border_width
	push dword [esp + 20]		; height
	push dword [esp + 20]		; width
	push 0				; y
	push 0				; x
	push dword [eax + 2 * 4]	; parent
	push dword [display]
	call XCreateSimpleWindow
	add esp, 9 * 4
	mov [window], eax

	push 1 << 15			; Expose
	push eax			; window
	push dword [display]		; display
	call XSelectInput
	add esp, 12

	push dword [window]
	push dword [display]
	call XMapWindow
	add esp, 8

	push 0
	push 0
	push dword [window]
	push dword [display]
	call XCreateGC
	add esp, 16
	mov [gc], eax

	mov eax, [screen]
	push dword [eax + 14 * 4]
	push dword [gc]
	push dword [display]
	call XSetForeground
	add esp, 12

.exit:
	ret

.error:
	xor eax, eax
	inc eax
	jmp .exit

_process_events:
	push event
	push dword [display]
	call XNextEvent
	add esp, 8

	cmp dword [event], 12
	jne .return
	call [callback]

.return:
	ret

_draw_line:
	push dword [esp + 16]
	push dword [esp + 16]
	push dword [esp + 16]
	push dword [esp + 16]
	push dword [gc]
	push dword [window]
	push dword [display]
	call XDrawLine
	add esp, 7 * 4
	ret

_flush:
	push dword [display]
	call XFlush
	add esp, 4
	ret

_load_bitmap:
	push ebx

	push rb
	push dword [esp + 12]
	call fopen
	add esp, 8
	push eax

	push 40
	call malloc
	add esp, 4
	mov [bitmap_header], eax

	push 14
	push 1
	push eax
	call fread
	mov dword [esp + 8], 40
	call fread
	add esp, 12

	mov ecx, [bitmap_header]
	mov eax, [ecx + 4]
	mov edx, [ecx + 8]
	mul edx
	lea eax, [eax + eax * 2]

	push eax
	call malloc
	mov [bitmap_data], eax

	push 1
	push eax
	call fread
	add esp, 12

	call fclose
	add esp, 4

	mov ecx, [bitmap_header]
	mov eax, [ecx + 4]
	mov edx, [ecx + 8]
	mul edx
	shl eax, 2
	push eax
	call malloc
	pop ecx
	push eax
	add eax, ecx
	shr ecx, 2

	mov ebx, [bitmap_header]
	mov ebx, [ebx + 4]
	shl ebx, 2
	sub eax, ebx

	mov edx, [bitmap_data]

.loop:
	mov ebx, [edx]
	mov [eax], ebx
	;and dword [eax], 0x00ffffff
	add eax, 4
	add edx, 3
	dec ecx
	push edx
	push eax
	mov eax, ecx
	mov ebx, [bitmap_header]
	mov ebx, [ebx + 4]
	xor edx, edx
	div ebx
	test edx, edx
	pop eax
	pop edx
	jnz .no_row_change
	shl ebx, 3
	sub eax, ebx
.no_row_change:
	test ecx, ecx
	jnz .loop

	push dword [bitmap_data]
	call free
	add esp, 4

	pop eax
	mov [bitmap_data], eax

	mov ecx, [bitmap_header]
	mov eax, [ecx + 4]
	shl eax, 2
	push eax	; bytes_per_line
	push 32	; bitmap_pad
	mov eax, [bitmap_header]
	push dword [eax + 8]	; height
	push dword [eax + 4]	; width
	push dword [bitmap_data]
	push 0	; offset
	push 2	; format = ZPixmap
	push 24	; depth
	mov eax, [screen]
	push dword [eax + 10 * 4]	; visual
	push dword [display]		; display
	call XCreateImage
	add esp, 10 * 4
	push eax

	push 24	; depth
	mov eax, [bitmap_header]
	push dword [eax + 8]	; height
	push dword [eax + 4]	; width
	push dword [window]	; drawable
	push dword [display]	; display
	call XCreatePixmap
	add esp, 5 * 4
	mov [pixmap], eax

	pop eax
	mov ecx, [bitmap_header]
	push dword [ecx + 8]	; height
	push dword [ecx + 4]	; width
	push 0	; dest_y
	push 0	; dest_x
	push 0	; src_y
	push 0	; src_x
	push eax	; image
	push dword [gc]	; gc
	push dword [pixmap]	; drawable
	push dword [display]	; display
	call XPutImage
	add esp, 10 * 4

	pop ebx
	ret

_draw_bitmap:
	push 0	; dest_y
	push 0	; dest_x
	mov eax, [bitmap_header]
	push dword [eax + 8]	; height
	push dword [eax + 4]	; width
	push 0	; src_y
	push 0	; src_x
	push dword [gc]	; gc
	push dword [window]	; dest
	push dword [pixmap]	; src
	push dword [display]	; display
	call XCopyArea
	add esp, 10 * 4

	ret
