; Вывод числа в 10 СС
.model tiny
; include macrolib.asm; Подключение стороннего файла
.data
x dw 288 
.code
org 100h
printDecWord macro decWord
	local forming, printing, finish
	push AX
	push BX
	push CX
	push DX
	mov	AX,	decWord
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
		add	DL,	'0'; Добавляем ASCII код нуля для комфортного вывода :)
		int	21h
		jmp	printing
	finish:
	pop	DX
	pop	CX
	pop	BX
	pop	AX
endm
start:
	jmp main
	main:
	printDecWord x
	mov AX, 4C00h
	int 21h
end start