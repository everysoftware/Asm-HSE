; Ввод/вывод числа в 2/10/16 СС
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
print_str macro str_offset
	push AX
	push DX
	mov AH, 9
	mov DX, str_offset
	int 21h
	pop DX
	pop AX
endm
print_byte_bin macro bin
	local print, zero
	pusha
	mov CX, 8; Счётчик для вывода 1 байта
	mov BL, bin
	print:
		mov AH, 2; Вывод одного символа (1 бита)
		mov DL, '0'
		; test - логическое И - результат никуда не записывается, команда влияет только на флаги
		test BL, 10000000b; Проверяем первую цифру - это 0 или 1?
		jz zero; Если 0, то DL оставляем 0 (0 & 1 = 0)
		mov DL, '1'; Если 1, то заменяем DL на '1' (1 & 1 = 1)
		zero:
			int 21h
			shl BL, 1; Сдвигаемся влево (1111 0101 -> 1110 1010), чтобы взять следующая цифра стала первой
	loop print
	popa
endm
print_word_bin macro bin
	push DX
	mov DX, bin
	print_byte_bin DH
	print_byte_bin DL
	pop DX
endm
input_word_bin macro read_buffer, buffer
	local toNumber, finish, zero
	pusha
	; Читаем строку в zs
	mov AH, 10
	mov DX, offset read_buffer
	int 21h
	mov SI, offset read_buffer + 2; Указатель на текущий байт (текущий символ)
	; Кладем инфу, сколько символов прочиталось в CX
	xor CX, CX
	mov CL, read_buffer[1]
	xor DX, DX; В DX будем хранить само число
	; Начинаем анализировать
	; Алгоритм работы:
	; '1110 0011'
	; 1 цифра 0000 0000 -> 0000 0001 -> 0000 0010
	; 2 цифра 0000 0010 -> 0000 0011 -> 0000 0110
	; 3 цифра 0000 0110 -> 0000 0111 -> 0000 1110
	; 4 цифра 0000 1110 -> 0000 1110 -> 0001 1100
	; 5 цифра 0001 1100 -> 0001 1100 -> 0011 1000
	; 6 цифра 0011 1000 -> 0011 1000 -> 0111 0000
	; 7 цифра 0111 0000 -> 0111 0001 -> 1110 0010
	; 8 цифра 1110 0010 -> 1110 0011 -> 1100 0111
	; сдвиг право: 1100 0111 -> 1110 0011
	toNumber:
		mov AL, byte ptr[SI]; Кладем символ в AL
		cmp AL, '0'
		je zero
		add DX, 1
		zero:
			rcl DX, 1; Rotate Carry Left - Циклический сдвиг влево
			inc SI
	loop toNumber
	finish:
		rcr DX, 1; Rotate Carry Right - Циклический сдвиг вправо
		mov buffer, DX
		popa
endm
print_byte macro xbyte
	pusha
	mov BL, xbyte
	mov DL, BL
	shr DL, 4
	call print_hex; Вызов процедуры
	mov DL, BL
	call print_hex
	popa
endm
print_word macro xword
	push DX
	mov DX, xword
	print_byte DH
	print_byte DL
	pop DX
endm
input_word macro read_buffer, buffer
	local toNumber, finish, zero, ascii_letter, cont
	pusha
	; Читаем строку в read_buffer
	mov AH, 10
	mov DX, offset read_buffer
	int 21h
	mov SI, offset read_buffer + 2; Указатель на текущий байт (текущий символ)
	; Кладем инфу, сколько символов прочиталось в CX
	xor CX, CX
	mov CL, read_buffer[1]
	xor DX, DX; В DX будем хранить само число
	; Начинаем анализировать
	toNumber:
		xor AX, AX
		mov AL, byte ptr[SI]; Кладем символ в AL
		cmp AL, 3Ah; 58
		jg ascii_letter
		sub AL, 30h; Если это цифра, то отнимает от ASCII кода 48
		jmp cont
		ascii_letter:
			sub AL, 37h; Если это буква, то отнимаем 55 
		cont:
			add DX, AX
			rcl DX, 4
			inc SI
	loop toNumber
	finish:
		rcr DX, 4
		mov buffer, DX
		popa
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
pow macro number, power; Возводит number в степень power - 1, результат записывает в регистр AX
	local raising, pow_exit
	push BX
	push SI
	push DX
	mov AX, 1
	mov BX, number
	mov SI, power
	dec SI
	raising:
		cmp SI, 0
		jle pow_exit
		mul BX; Умножаем AX на BX
		dec SI
		jmp raising
	pow_exit:
		pop DX
		pop SI
		pop BX
endm
input_word_dec macro read_buffer, buffer
	local toNumber, finish, zero
	pusha
	; Читаем строку в read_buffer
	mov AH, 10
	mov DX, offset read_buffer
	int 21h
	mov SI, offset read_buffer + 2; Указатель на текущий байт (текущий символ)
	; Кладем инфу, сколько символов прочиталось в CX
	xor CX, CX
	mov CL, read_buffer[1]
	xor DX, DX; В DX будем хранить само число
	; Начинаем анализировать
	; Принцип работы:
	; Пусть число было 12345
	; DX += 1 * 10 ^ 4 (+= 10000)
	; DX += 2 * 10 ^ 3 (+= 2000)
	; DX += 3 * 10 ^ 2 (+= 300)
	; DX += 4 * 10 ^ 1 (+= 40)
	; DX += 5 * 10 ^ 0 (+= 5)
	; Результат: DX = 12345
	toNumber:
		xor BX, BX
		mov BL, byte ptr[SI]; Кладем цифру в BX
		sub BL, 30h; Отнимаем от ASCII кода 48
		pow 10, CX; Поскольку 10 - это не степень двойки, то приходится использовать костыли
		push DX; Сохраняем в стек DX, потому что mul его будет портить
		mul BX
		pop DX
		add DX, AX
		inc SI
	loop toNumber
	finish:
		mov buffer, DX
		popa
endm
start:
jmp main
;
; <--- Переменные --->
;
a db 215; 11010111
b db 192; 11000000
x dw 0AF51h; = 44881 = 1010111101010001b
y dw 0CF97h; = 53143 = 1100111110010111b
z10_read db 6, 0, 6 dup(?)
z10 dw ?
z16_read db 5, 0, 5 dup(?)
z16 dw ?
z2_read db 17, 0, 17 dup(?)
z2 dw ?
;
; <--- Процедуры --->
; 
print_hex proc
	mov AH, 02h; Команда вывода символа
	and DL, 0Fh; Маска 0000 1111 (для обнуления первых четырех бит)
	add DL, 30h; Добавляем 30h (для нахождения соответствующего ASCII кода)
	cmp DL, 3Ah; Проверяем, буква перед нами или цифра
	jb printh; Если буква
	add DL, 7; Если цифра
	printh:
		int 21h
	ret
endp
main:
	print_msg 'Input a dec number > '
	input_word_dec z10_read, z10
	print_msg 10, 13
	print_msg 'Input a hex number > '
	input_word z16_read, z16
	print_msg 10, 13
	print_msg 'Input a bin number > '
	input_word_bin z2_read, z2
	print_msg 10, 13
	print_msg 'Output: '
	print_word_dec z10
	print_letter ' '
	print_word z16
	print_letter ' '
	print_word_bin z2
	print_msg 10, 13
	print_msg 'Test bin a b x y: '
	print_byte_bin a
	print_letter ' '
	print_byte_bin b
	print_letter ' '
	print_word_bin x
	print_letter ' '
	print_word_bin y
	mov AX, 4C00h
	int 21h
end start
