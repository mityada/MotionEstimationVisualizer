section .data
	keycodes db 	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
		 db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
		 db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3b, 0x00, 0x3c, 0x00
		 db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
		 db	0x00, 0x26, 0x38, 0x36, 0x28, 0x1a, 0x29, 0x2a, 0x2b, 0x1f, 0x2c, 0x2d, 0x2e, 0x3a, 0x39, 0x20
		 db	0x21, 0x18, 0x1b, 0x27, 0x1c, 0x1e, 0x37, 0x19, 0x35, 0x1d, 0x34, 0x00, 0x00, 0x00, 0x00, 0x00
		 db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
		 db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

section .bss
	display 	resd 1
	screen 		resd 1
	window		resd 1
	event 		resd 24
	gc 		resd 1

	keyboard	resb 32

	pixmap		resd 1

	callback	resd 1

section .text
	global _create_window
	global _get_window_size
	global _is_key_pressed
	global _process_events
	global _draw_line
	global _flush
	global _draw_bitmap

	extern malloc
	extern free
	extern memcpy

	extern fopen
	extern fclose
	extern fread

	extern printf

	extern XOpenDisplay
	extern XCreateSimpleWindow
	extern XGetWindowAttributes
	extern XSelectInput
	extern XMapWindow
	extern XResizeWindow
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

	extern _read_bitmap
	extern _write_bitmap
	extern _scale_bitmap

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

	push 1 << 0 | 1 << 15		; KeyPressMask | ExposureMask
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

.return:
	xor eax, eax
	ret

.error:
	xor eax, eax
	inc eax
	ret

_get_window_size:
	sub esp, 23 * 4
	push esp
	push dword [window]
	push dword [display]
	call XGetWindowAttributes
	add esp, 12
	mov ecx, [esp + 8]
	mov edx, [esp + 12]
	add esp, 23 * 4
	mov eax, [esp + 4]
	mov [eax], ecx
	mov eax, [esp + 8]
	mov [eax], edx
	ret

_is_key_pressed:
	xor ecx, ecx
	mov ecx, [esp + 4]
	mov cl, [ecx + keycodes]
	and ecx, 0x000000ff
	mov edx, ecx
	shr edx, 3
	and cl, 0x07
	mov eax, 0x1
	shl eax, cl
	test [edx + keyboard], al
	jnz .pressed
	xor eax, eax
	ret
.pressed:
	xor [edx + keyboard], al
	ret

_process_events:
	push event
	push dword [display]
	call XNextEvent
	add esp, 8

	cmp dword [event], 2	; KeyPress
	jne .not_keypress
	mov eax, [event + 13 * 4]

	mov ecx, eax
	shr eax, 3
	and cl, 0x07
	mov edx, 1
	shl edx, cl
	or [eax + keyboard], dl

	call [callback]

.not_keypress:
	cmp dword [event], 12	; Expose
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

_draw_bitmap:
	push ebx
	push esi
	push edi

	mov ecx, [esp + 16]
	mov esi, [ecx + 4]
	shl esi, 2
	mov edi, [ecx + 8]
	mov eax, esi
	mul edi
	push eax
	call malloc
	pop ecx
	add eax, ecx
	mov edx, [esp + 16]
	add edx, 40

.loop:
	sub eax, esi

	push esi
	push edx
	push eax
	call memcpy
	pop eax
	pop edx
	add esp, 4

	add edx, esi
	dec edi
	jnz .loop

	mov ecx, [esp + 16]
	mov edx, [ecx + 4]
	shl edx, 2
	push edx			; bytes_per_line
	push 32				; bitmap_pad
	push dword [ecx + 8]		; height
	push dword [ecx + 4]		; width
	push eax			; bitmap data
	push 0				; offset
	push 2				; format = ZPixmap
	push 24				; depth
	mov eax, [screen]
	push dword [eax + 10 * 4]	; visual
	push dword [display]		; display
	call XCreateImage
	add esp, 10 * 4
	push eax

	push 24				; depth
	mov eax, [esp + 24]
	push dword [eax + 8]		; height
	push dword [eax + 4]		; width
	push dword [window]		; drawable
	push dword [display]		; display
	call XCreatePixmap
	add esp, 5 * 4
	mov [pixmap], eax

	pop eax
	mov ecx, [esp + 16]
	push dword [ecx + 8]		; height
	push dword [ecx + 4]		; width
	push 0				; dest_y
	push 0				; dest_x
	push 0				; src_y
	push 0				; src_x
	push eax			; image
	push dword [gc]			; gc
	push dword [pixmap]		; drawable
	push dword [display]		; display
	call XPutImage
	add esp, 10 * 4

	push 0				; dest_y
	push 0				; dest_x
	mov eax, [esp + 24]
	push dword [eax + 8]		; height
	push dword [eax + 4]		; width
	push 0				; src_y
	push 0				; src_x
	push dword [gc]			; gc
	push dword [window]		; dest
	push dword [pixmap]		; src
	push dword [display]		; display
	call XCopyArea
	add esp, 10 * 4

	pop edi
	pop esi
	pop ebx
	ret
