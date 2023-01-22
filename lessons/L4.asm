; Вывод числа в 16 СС
.model tiny
.data
a dw 0AF51h
lookupTable db 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h; 0-9
db 41h, 42h, 43h, 44h, 45h, 46h; A-F
outByte db ?, ?, ?, ?, '$'
.code
org 100h
start:
	jmp main
	print_tetr proc ; двоичная тетрада - это шестнадцатиричный символ
		push BX
		and AL, 0Fh; Обнуляем старшую тетраду (1101'0111 -> 0000'0111)
		mov BX, offset lookupTable
		; Команда XLAT загружает в регистр AL элемент таблицы, находящейся в памяти. Смещение таблицы задается регистром BX, индекс элемента задается самим регистром AL.
		xlat; AL = lookupTable[AL]
		mov byte ptr [SI], AL
		inc SI
		pop BX
		ret
	endp	
	print_hex_byte proc
		push AX
		shr AL, 4
		call print_tetr
		pop AX
		call print_tetr
		ret
	endp
	main:
		mov BX, a
		mov AL, BH
		mov SI, offset outByte
		call print_hex_byte
		mov AL, BL
		call print_hex_byte
		mov AH, 9
		mov DX, offset outByte
		int 21h
	mov AX, 4C00h
	int 21h
end start