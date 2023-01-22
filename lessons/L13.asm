; Выводит 256 случайных чисел
.286
.model tiny
.code
org 100h
;
; <--- Макросы --->
;
print_letter macro letter
	push AX
	push DX; Заносим регистры в стек, чтобы потом восстановить их! Чтобы не испортить содержимое до/после макроса
	mov AH, 2
	mov DL, letter
	int 21h
	pop DX
	pop AX
endm
print_str macro strv
	push AX
	push DX
	mov AH, 9
	mov DX, offset strv
	int 21h
	pop DX
	pop AX
endm
print_msg macro msg, letter1, letter2
	local tmp, nxt
	push AX
	push DX
	mov AH, 9
	mov DX, offset tmp
	int 21h
	ifnb <letter1>
		print_letter letter1
	endif
	ifnb <letter2>
		print_letter letter2
	endif
	pop DX
	pop AX
	jmp nxt
	tmp db msg, '$'
	nxt:
endm
print_word_dec macro xword
	local forming, printing, finish
	pusha
	mov	AX,	xword
	push -1; Потом понадобится
	mov	CX,	10
	forming:
		xor	DX,	DX
		div	CX; Деление
		push DX; Кладем цифру в стек
		or AX, AX; cmp ax, 0 - проверяем, остаток равен 0? (Это условие завершения числа)
		jne	forming; Если нет, то повторяем операцию
		mov	AH, 2; Если да, то запускаем посимвольный вывод из стека (полностью число считали)
	printing:
		pop	DX; Берем цифру
		cmp	DX,	-1; Число кончилось (не зря писали push -1 в самом начале...)
		je finish; Если да, завершаемся
		add	DL,	'0'; Добавляем ASCII код нуля для того, чтобы можно было выводить :)
		int	21h
	jmp	printing
	finish:
	popa
endm
start:
jmp main
;
; <--- Переменные --->
;
seed dw 44
;
; <--- Процедуры --->
;
; Возвращает случайное 8-битное число в AL
; Переменная seed должна быть инициализирована заранее,
; например из области данных BIOS, как в примере для конгруэнтного генератора (???)
rand8 proc
	mov AX, word ptr seed
	mov CX, 8
	newbit:
		mov BX, AX
		and BX, 002Dh
		xor BH, BL
		clc
		jpe shift
		stc
	shift:
		rcr AX, 1
	loop newbit
	mov word ptr seed, AX
	mov AH, 0
	print_letter ' '
	print_word_dec AX
	ret
endp
main:
	print_msg 10, 13
	mov CX, 16
	printing_col:
		push CX
		mov CX, 16
		printing_str:
			push CX
			call rand8
			pop CX
		loop printing_str
		print_msg 10, 13
		pop CX
	loop printing_col
	; Выход
	mov AX, 4C00h
	int 21h
end start