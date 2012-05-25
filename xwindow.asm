section .bss
	display resd 1
	screen 	resd 1
	window	resd 1
	event 	resd 24
	gc 	resd 1

section .text
	global _create_window
	global _process_events
	global _draw_line
	global _flush

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

_create_window:
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
	push dword [display]
	call XPending
	add esp, 4
	test eax, eax
	jz .exit

	push event
	push dword [display]
	call XNextEvent
	add esp, 8

	jmp _process_events

.exit:
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
