; Арифметические операции
.model tiny
.data
; Числа
x db 56
y db 32
.code
org 100h
; Macro
print_letter macro letter
	push AX
	push DX; Заносим регистры в стек, чтобы потом восстановить их! Чтобы не испортить содержимое до/после макроса
	mov DL, letter
	mov AH, 2
	int 21h
	pop DX
	pop AX
endm
start:
	jmp main
	; Proc
	print_tetrada proc
		add DL, 30h
		cmp DL, 3Ah
		jb print
		add DL, 7
		print:
			int 21h
		ret
	endp
	print_byte proc
		push DX
		shr DL, 4
		mov AH, 2
		call print_tetrada; Вызов процедуры
		pop DX
		and DL, 0Fh
		call print_tetrada
		ret
	endp
	main:
		; Будем искать x + y, x - y, -y + 1, -y - 1
		mov AL, [x]
		mov BL, [y]
		add AL, BL ; Складываем x и y, результат записываем в регистр AX
		mov DL, AL
		call print_byte
		print_letter 10
		print_letter 13
		mov AL, [x]
		sub AL, BL; Вычитаем x и y, результат записываем в регистр AX
		mov DL, AL
		call print_byte
		print_letter 10
		print_letter 13
		neg BL; BX = -BX, меняем знак числа y на противоположный
		inc BL; BX += 1, увеличиваем на единицу
		mov DL, BL
		call print_byte
		print_letter 10
		print_letter 13
		dec BX; BX -= 1
		dec BX; BX -= 1
		mov DL, BL
		call print_byte
	mov AX, 4C00h
	int 21h
end start