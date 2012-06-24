section .data
	class_name	db "MotionEstimationVisualizer", 0
	window_name	db "Motion Estimation Visualizer", 0

section .bss
	hInstance	resd 1
	hWnd		resd 1
	hdc		resd 1

	keyboard	resb 32

	gdiToken	resd 1

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
	extern printf
	extern exit
	extern fopen
	extern fclose
	extern fread

	extern __imp__GetModuleHandleA@4
	extern __imp__LoadIconA@8
	extern __imp__LoadCursorA@8
	extern __imp__GetStockObject@4
	extern __imp__RegisterClassExA@4
	extern __imp__CreateWindowExA@48
	extern __imp__ShowWindow@8
	extern __imp__UpdateWindow@4
	extern __imp__DefWindowProcA@16
	extern __imp__GetMessageA@16
	extern __imp__DispatchMessageA@4
	extern __imp__PostQuitMessage@4
	extern __imp__BeginPaint@8
	extern __imp__EndPaint@8
	extern __imp__LineTo@12
	extern __imp__MoveToEx@16
	extern __imp__CreatePen@12
	extern __imp__SelectObject@8
	extern __imp__DeleteObject@4
	extern __imp__SetDIBitsToDevice@48
	extern __imp__GetWindowInfo@8
	extern __imp__InvalidateRect@12

_create_window:
	push ebx

	mov eax, [esp + 16]
	mov [callback], eax

	push 0
	call [__imp__GetModuleHandleA@4]
	mov [hInstance], eax

	push 12 * 4
	call malloc
	add esp, 4
	mov ebx, eax

	mov dword [ebx + 0 * 4], 12 * 4		; cbSize
	mov dword [ebx + 1 * 4], 0x3		; style = CS_HREDRAW | CS_VREDRAW
	mov dword [ebx + 2 * 4], _wndproc	; lpfnWndProc
	mov dword [ebx + 3 * 4], 0		; cbClsExtra
	mov dword [ebx + 4 * 4], 0		; cbWndExtra

	mov eax, [hInstance]
	mov dword [ebx + 5 * 4], eax		; hInstance

	push 0
	mov word [esp], 32512			; lpIconName = IDI_APPLICATION
	push 0					; hInstance
	call [__imp__LoadIconA@8]
	mov dword [ebx + 6 * 4], eax		; hIcon

	push 0
	mov word [esp], 32512			; lpCursorName = IDC_ARROW
	push 0					; hInstance
	call [__imp__LoadCursorA@8]
	mov dword [ebx + 7 * 4], eax		; hCursor

	push 0					; fnObject = WHITE_BRUSH
	call [__imp__GetStockObject@4]
	mov dword [ebx + 8 * 4], eax		; hbrBackground

	mov dword [ebx + 9 * 4], 0		; lpszMenuName
	mov dword [ebx + 10 * 4], class_name	; lpszClassName
	mov dword [ebx + 11 * 4], 0		; hIconSm

	push ebx				; lpwcx
	call [__imp__RegisterClassExA@4]

	push ebx
	call free
	add esp, 4

	push 0					; lpParam

	push dword [hInstance]			; hInstance

	mov ecx, [esp + 8]
	mov edx, [esp + 12]

	push 0					; hMenu
	push 0					; hWndParent
	push edx				; nHeight
	push ecx				; nWidth
	push 0x80000000				; y
	push 0x80000000				; x
	push 0x00CF0000				; dwStyle = WS_OVERLAPPEDWINDOW
	push window_name			; lpWindowName
	push class_name				; lpClassName
	push 0					; dwExStyle
	call [__imp__CreateWindowExA@48]
	mov [hWnd], eax

	push 5					; nCmdShow = SW_SHOW
	push dword [hWnd]			; hWnd
	call [__imp__ShowWindow@8]

	push dword [hWnd]			; hWnd
	call [__imp__UpdateWindow@4]

	pop ebx
	ret

_get_window_size:
	sub esp, 60
	mov dword [esp], 60
	push esp
	push dword [hWnd]
	call [__imp__GetWindowInfo@8]

	mov ecx, [esp + 12]
	sub ecx, [esp + 4]
	mov edx, [esp + 16]
	sub edx, [esp + 8]

	add esp, 60

	mov eax, [esp + 4]
	mov [eax], ecx
	mov eax, [esp + 8]
	mov [eax], edx

	ret

_is_key_pressed:
        mov ecx, [esp + 4]
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

_wndproc:
	push ebx

	cmp dword [esp + 12], 0x000F	; WM_PAINT
	je .wm_paint
	cmp dword [esp + 12], 0x0100	; WM_KEYDOWN
	je .wm_keydown
	cmp dword [esp + 12], 0x0002	; WM_QUIT
	je .wm_quit
	jmp .default

.wm_paint:
	push 64
	call malloc
	add esp, 4
	mov ebx, eax

	push ebx			; lpPaint
	push dword [esp + 12]		; hWnd
	call [__imp__BeginPaint@8]
	mov [hdc], eax

	push 0x000000			; crColor
	push 0				; nWidth
	push 0				; fsPenStyle = PS_SOLID
	call [__imp__CreatePen@12]

	push eax			; hgdiobj
	push dword [hdc]		; hdc
	call [__imp__SelectObject@8]
	push eax

	call [callback]

	push dword [hdc]		; hdc
	call [__imp__SelectObject@8]

	push eax			; hObject
	call [__imp__DeleteObject@4]

	push ebx			; lpPaint
	push dword [esp + 12]		; hWnd
	call [__imp__EndPaint@8]

	push ebx
	call free
	add esp, 4

	jmp .return

.wm_keydown:
	mov eax, [esp + 16]

	mov ecx, eax
        shr eax, 3
        and cl, 0x07
        mov edx, 1
        shl edx, cl
        or [eax + keyboard], dl

	push 0
	push 0
	push dword [hWnd]
	call [__imp__InvalidateRect@12]

	jmp .return

.wm_quit:
	push 0
	call [__imp__PostQuitMessage@4]
	push 0
	call exit
	jmp .return

.default:
	push dword [esp + 20]
	push dword [esp + 20]
	push dword [esp + 20]
	push dword [esp + 20]
	call [__imp__DefWindowProcA@16]

.return:
	pop ebx
	ret 16

_process_events:
	push 7 * 4
	call malloc
	add esp, 4
	push eax

	push 0				; wMsgFilterMax
	push 0				; wMsgFilterMin
	push 0				; hWnd
	push eax			; lpMsg
	call [__imp__GetMessageA@16]

	push dword [esp]		; lpmsg
	call [__imp__DispatchMessageA@4]

	call free
	add esp, 4

	ret

_draw_line:
	push 0				; lpPoint
	push dword [esp + 12]		; Y
	push dword [esp + 12]		; X
	push dword [hdc]		; hdc
	call [__imp__MoveToEx@16]

	push dword [esp + 16]		; nYEnd
	push dword [esp + 16]		; nXEnd
	push dword [hdc]		; hdc
	call [__imp__LineTo@12]

	ret

_flush:
	ret

_draw_bitmap:
	mov eax, [esp + 4]
	mov ecx, [esp + 8]
	mov edx, [esp + 12]

	push 0				; fuColorsUse = DIB_RGB_COLORS
	push eax			; lpbmi
	push eax			; lpvBits
	add dword [esp], 40
	push dword [eax + 8]		; cScanLines
	push 0				; uStartScan
	push 0				; YSrc
	push 0				; XSrc
	push dword [eax + 8]		; dwHeight
	push dword [eax + 4]		; dwWidth
	push edx			; YDest
	push ecx			; XDest
	push dword [hdc]		; hdc
	call [__imp__SetDIBitsToDevice@48]

.return:
	ret
