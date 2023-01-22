; Вектор 1Ch
.286
.model tiny
.data
old_1Ch dd ?
.code
org 100h
print_letter macro letter
	push AX
	push DX; Заносим регистры в стек, чтобы потом восстановить их! Чтобы не испортить содержимое до/после макроса
	mov AH, 2
	mov DL, letter
	int 21h
	pop DX
	pop AX
endm
; Получить вектор прерывания vector и занести его в destination
get_vector macro vector, destination 
	; Команда PUSHA помещает в стек регистры общего назначения в следующем порядке: AX, CX, DX, BX, SP, BP, SI, DI (в случае регистра SP используется значение, которое находилось в этом регистре до начала работы команды).
	pusha
	push ES
	mov AX, 35&vector; Функция получения вектора прерывания
	int 21h
	;  ES:BX - вектор
	mov word ptr destination, BX; Заполняем первые два байта содержимым BX
	mov word ptr destination + 2, ES; Остальные два байта - содержимым ES
	pop	ES
	popa
endm
; Установить вектор прерывания vector на новый handler
set_vector macro vector, handler
    mov DX, offset handler
    mov AX, 25&vector; Функция установки прерывания (изменить вектор AL - номер прерыв. DS:DX - ук-ль программы обр. прер.)
    int 21h
endm
; Восстановить вектор прерывания vector на old_vector
recovery_vector	macro vector, source
	pusha
	push DS
	push ES
	; Команда LDS REG, MEM выполняет те же действия, что и две следующие команды (LOAD DS):
	; MOV REG, WORD PTR MEM
	; MOV DS,  WORD PTR MEM+2
	lds DX, CS:source
	mov	AX,	25&vector; Заполнение вектора старым содержимым
	int 21h; DS:DX - указатель программы обработки прер.
	pop	ES
	pop	DS
	popa
endm
start:
	jmp main
	new_1Ch	proc
		print_letter 'A'
		jmp	dword ptr CS:[old_1Ch]
	new_1Ch	endp
	main:
		get_vector 1Ch,	old_1Ch; 1Ch - таймер (обработчик loop)
		set_vector 1Ch,	new_1Ch
		mov	CX, 20
		cycle:
			xor	AX,	AX
			go:
				inc	AX
				cmp	AX,	0
				jne	go
		loop cycle
		recovery_vector	1Ch, old_1Ch
		print_letter 'D'		
		mov AX, 4C00h
		int 21h
end start
