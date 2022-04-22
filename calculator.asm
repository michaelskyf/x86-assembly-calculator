global _start
bits 32

section .text
_start:
	; init stack
	push esp
	mov ebp, esp

	; strlen(welcome_msg)
	push welcome_msg
	call strlen
	add esp, 0x4

	; Write welcome_msg to stdout
	mov edx, eax
	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, welcome_msg
	int 0x80

	; if stdin == +, set operation_selector to 0, if - to 1, ...
	mov eax, 0x3
	mov ebx, 0x0
	mov ecx, operation_selector
	mov edx, 2
	int 0x80

	; display message and save user's response to num1 and num2
	push ask1
	call strlen
	add esp, 0x4

	mov edx, eax
	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, ask1
	int 0x80

	mov eax, 0x3
	mov ebx, 0x0
	mov ecx, buffer
	mov edx, 32
	int 0x80

	push buffer
	call strlen
	add eax, buffer
	push eax
	call strtol
	add esp, 0x4
	mov dword [num1], eax

	; clear buffer
	mov dword [buffer], 0x0
	mov dword [buffer+4], 0x0
	mov dword [buffer+8], 0x0
	mov dword [buffer+12], 0x0
	mov dword [buffer+16], 0x0
	mov dword [buffer+20], 0x0
	mov dword [buffer+24], 0x0
	mov dword [buffer+28], 0x0


	push ask2
	call strlen
	add esp, 0x4

	mov edx, eax
	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, ask2
	int 0x80

	mov eax, 0x3
	mov ebx, 0x0
	mov ecx, buffer
	mov edx, 32
	int 0x80

	push buffer
	call strlen
	add eax, buffer
	push eax
	call strtol
	add esp, 0x4
	mov dword [num2], eax

	; add 2 numbers
	mov eax, [num1]
	mov ebx, [num2]
	add eax, ebx

	; Print result
	push eax
	call ltostr
	add esp, 0x4
	push buffer
	call strlen
	mov edx, eax
	mov eax, 0x4
	mov ebx, 0x1
	mov ecx, buffer
	int 0x80

	; exit
	pop ebp
	mov eax, 0x1
	mov ebx, 0
	int 0x80
;---------------------------------------------------------------- Functions
; size_t strlen(const char *s) // return length of c-string
strlen:
	push esp
	mov ebp, esp

	; 1. Count chars
	; 2. Return count

	mov eax, [ebp+0x8] ; move string to eax
	mov ebx, eax ; set ebx to start of string

_strlen_count_loop:
	cmp byte [eax], 0x0 ; if char in eax i \0, go to end
	je _strlen_end
	add eax, 1
	jmp _strlen_count_loop

_strlen_end:
	sub eax, ebx

	pop ebp
	ret

; long pow(int x, int y)
pow:
	push esp
	mov ebp, esp

	mov eax, [ebp+0xc]
	mov ecx, eax
	mov ebx, [ebp+0x8]

	; if ebx <= 0 && eax != 0 then eax = 1
	cmp ebx, 0x0 ; if ebx == 0
	jg _pow_loop
	cmp eax, 0x0 ; if eax == 0
	je _pow_zero_zero
	mov eax, 1
	jmp _pow_end
_pow_zero_zero:
	mov eax, 0
	jmp _pow_end

_pow_loop:
	sub ebx, 1
	cmp ebx, 0
	jle _pow_end

	mul ecx

	jmp _pow_loop

_pow_end:

	pop ebp
	ret

; long strtol(char *nptr, char **endptr)
strtol:
	push esp
	mov ebp, esp

	mov eax, 0x0 ; result
	mov edi, 0
	mov ebx, [ebp+0xc] ; start of string
	; check if there's '-' at the start of the string
	mov ecx, '-'
	movzx edx, byte [ebx]
	cmp ecx, edx
	jne _strtol_not_negative

	mov edi, 1
	add ebx, 1

_strtol_not_negative:
	push edi ; at the end check if edi == 1 to get negative number

	mov ecx, [ebp+0x8] ; end of string
	sub ecx, 2
	mov edi, 0 ; iterator


_strtol_loop:
	cmp ecx, ebx ; if everything is processed, go to end
	jl _strtol_end

	movzx edx, byte [ecx] ; example -> 0x31
	sub edx, '0' ; 0x31 - 0x30

	push eax
	push ecx
	push ebx
	push edx
	mov eax, 0xa
	push eax
	push edi
	call pow
	add esp, 0x8

	pop edx
	mul edx
	mov edx, eax
	pop ebx
	pop ecx
	pop eax
	add eax, edx

	; end iteration
	sub ecx, 1
	add edi, 1
	jmp _strtol_loop

_strtol_end:

	pop edi
	cmp edi, 1
	jne _strtol_ret

	mov edi, 0
	sub edi, eax
	mov eax, edi

_strtol_ret:
	pop ebp
	ret

; void (saves to -> buffer) ltostr(long l)
ltostr:
	push ebp
	mov ebp, esp

	mov eax, [ebp+0x8]
	mov ebx, 10
	mov ecx, buffer

	; find out length of our string
_ltostr_loop_length:
	xor edx, edx
	div ebx
	add ecx, 1
	cmp eax, 0x0
	jne _ltostr_loop_length

	; add \0 to end of our string
	mov byte [ecx], 0x0
	sub ecx, 1

	mov eax, [ebp+0x8]
; eax - number, ebx - dividor, dl - dividend, ecx - end of buffer
_ltostr_loop:
	cmp eax, 0x0
	je _ltostr_end
	xor dl, dl
	div ebx

	; zapisz dl do stringa
	add dl, '0' ; add '0' to get ascii characters
	mov [ecx], dl
	sub ecx, 1

	jmp _ltostr_loop
_ltostr_end:

	leave
	ret
;---------------------------------------------------------------- Data

section .data
	welcome_msg db "Welcome to simple calculator written in assmebly by Michał Kostrzewski", 0xa, "Select operation (+):", 0xa, 0x0
	ask1 db "Type first number (overflow at 4294967296, only positive integers!): ", 0xa,  0x0
	ask2 db "Type second number (overflow at 4294967296, only positive integers!): ", 0xa,  0x0

section .bss
	operation_selector resb 2
	num1 resb 4
	num2 resb 4
	buffer resb 32
