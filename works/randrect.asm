; Вывод прямоугольников рандомного цвета и размера
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
start:
jmp main
;
; <--- Переменные --->
;
DL_	DB 80
DH_	DB 25
CL_	DB 0
CH_	DB 0
deltaY DB 0
deltaX DB 0
seed dw -1
delayCount dw 0
;
; <--- Процедуры --->
;
; Возвращает случайное 8-битное число в AL
; Переменная seed должна быть инициализирована заранее,
; например из области данных BIOS, как в примере для конгруэнтного генератора (???)
rand8 proc
	mov AX, word ptr seed
	test AX, AX
	js fetch_seed; Если seed = -1, создаем seed
	randomize:
		mov AX, word ptr seed
		mov CX, 8
		newbit:
			mov BX, AX
			and BX, 002Dh
			xor BH, BL
			clc; Сброс флага переноса (Clear Carry Flag)
			jpe shift
			stc; Установка флага переноса (Set Carry Flag)
		shift:
			rcr AX, 1
		loop newbit
		mov word ptr seed, AX
		xor AH, AH
	ret
	fetch_seed: 
		push DS
		push 0040h
		pop	DS
		; Считать двойное слово из области данных BIOS (0040:006C)
		; Это текущее число тактов таймера
		mov	AX,	word ptr DS:006Ch + 2
		pop	DS
		jmp randomize
endp
main:
	print_msg 10, 13
	mov CX, 16
	printing_col:
		push CX
		mov CX, 16
		printing_str:
			mov DL, 80
			mov DH, 25
			push CX
			; Узнаем X
			call rand8
			xor AH, AH
			div DL
			xor AL, AL
			shr AX, 8
			mov DL_, AL
			sub DL, AL
			mov AL, DL
			cmp DL, 0
			jne to_div1
			inc DL
			to_div1:
				div DL
				shr AX, 8
				mov CL_, AL
				mov DL, 79
				sub DL, DL_
				mov deltaX, DL
				add CL, deltaX
				add DL, deltaX
				mov CL_, CL
				mov DL_, DL
			; Узнаем Y
			call rand8
			xor AH, AH
			div DH
			shr AX, 8
			mov DH_, AL
			mov DL, AL
			sub DL, AL
			cmp DL, 0
			jne to_div
			inc DL
			to_div:
				div DL
				shr AX, 8
				mov CH_, AL
			; Устанавливаем видеорежим
			mov BX, AX
			mov AH, 00h
			mov AL, 02h; Режим
			int 10h
			; Устаналиваем цвет
			call rand8
			xor AH, AH
			mov BL, 16
			div BL
			shl AH, 4
			and AH, 0F0h
			mov BH, AH
			; Отрисовываем прямоугольник
			mov CL, CL_
			mov CH, CH_
			mov DL, DL_
			mov DH, DH_
			mov AH, 06h; Создать окно
			xor AL, AL; Создать (без скроллинга)
			int 10h
			; Делаем искусственную задержку вывода прямоугольников
			mov	CX,	03h
			delay:
				inc	delayCount
				jnz	delay
				mov	delayCount, 0
			loop delay
			; Продолжаем...
			pop CX
		jmp printing_str
	print_msg 10, 13
	pop CX
	jmp printing_col
	; Выход
	mov AX, 4C00h
	int 21h
end start