.286
.model tiny
.data

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
ftbegin macro fhandler
	pusha
	mov BX, fhandler
	xor CX, CX
    xor DX, DX
    mov AX, 4200h
    int 21h
	popa
endm
exit macro
	mov	AX,	4C00h
	int	21h
endm
start:
jmp main
;
; <--- Переменные --->
;
fileName db	14, 0, 14 dup(0); Имя файла
buffer db 2048 dup(?)
BUFFER_SIZE dw 2048
;
; <--- Процедуры --->
;
print_hex proc
	mov AH, 2
	and DL, 0Fh
	add DL, 30h
	cmp DL, 3Ah
	jb printh
	add DL, 7
	printh:
		int 21h
	ret
endp
; В DI = адрес массива
; В AX = размер массива (в байтах)
bubble_sort proc
	pusha
	cld; Clear Direction Flag
	cmp	DX,	1
	jbe	sort_exit; Если массив из одного элемента, выходим к чертовой бабушке
	dec	DX
	sn_loop1:
		mov	CX,	DX; Устанавливаем длину цикла
		xor	BX,	BX; Флаг обмена (зачем?)
		mov	SI,	DI; Указатель на текущий элемент
	sn_loop2:
		; Команда LODSB копирует один байт из памяти по адресу DS:SI в регистр AL. 
		; После выполнения команды, регистр SI увеличивается на 1, если флаг DF = 0, или уменьшается на 1, если DF = 1.
		lodsb; Загружаем новый байт в AL (есть аналогичная команда lodsw для загрузки слова)
		cmp	AL, byte ptr[SI]; Сравниваем с предыдущим
		jbe	no_swap; Если они в прав. порядке, то пропускаем обмен
		xchg AL, byte ptr[SI]; Иначе меняем местами
		mov	byte ptr[SI - 1], AL
		inc BX; Устанавливаем флаг обмена
	no_swap:
		loop sn_loop2
		cmp	BX, 0; Если после очереднего прогона массив не изменился, то выходим
		jne	sn_loop1; Иначе запускаем следующий прогон
	sort_exit:
		popa
		ret
endp
readFile proc
	print_msg 10, 13
	print_msg 'Open OK', 10, 13
	clc
	; Если в input.txt лежало "fbacde54321", то fileData[0] будет содержать f, fileData[1] - b, fileData[2] - c и т. д.
	mov BX, AX; Handler
	mov CX, BUFFER_SIZE
	mov AH, 3Fh
	mov DX, offset buffer
	int 21h
	jnc read_cont
	print_msg 'Read error', 10, 13
	exit
	ret
	read_cont:
		mov SI, offset buffer; Адрес конца строки
		mov DI, SI
		mov DX, AX
		add SI, AX
		mov byte ptr[SI], '$'
		print_msg 'Source string: '
		print_str DI
		print_msg 10, 13
		call bubble_sort
		print_msg 'Sorted string: '
		print_str DI
		print_msg 10, 13
		call writeFile
		exit
		ret
endp
writeFile proc
	clc
	ftbegin BX; Записывать будем в начало файла
	mov CX, AX; Кол-во байт для записи
	mov DX, DI; Адрес содержимого для записи
	mov AH, 40h; DOS-функция записи в файл
	int 21h
	jc writeError
	print_msg 'Write OK', 10, 13
	jmp writeExit
	writeError:
		print_msg 'Write error', 10, 13
	writeExit:
		ret
endp
main:
	; Печатаем на экран служебную инфу - параметры программы в HEX'е
	mov SI, 80h
	mov AH, 2
	mov CX, 16
	printing:
		mov BL,	byte ptr[SI]
		mov DL,	BL
		;call print_byte
		print_byte DL
		print_letter ' '
		inc SI
	loop printing
	print_letter 10
	print_letter 13
	; Проверяем есть ли вообще параметры
	mov SI, 80h
	mov AL, byte ptr[SI]
	cmp AL, 0
	jne readParams; Если есть, то читаем их
	print_msg 'Not params', 10, 13
	jmp inputFilename
	readParams:
		xor BH, BH
		mov BL, ES:[80h]
		mov byte ptr[BX + 81h], 0
		print_msg 'Params length: '
		;call print_BX
		print_word BX
		mov SI, 80h
		mov AH, 2
		mov CX, 16
		mov AX, 3D02h; Команда для чтения из файла/записи в файл 
		mov DX, 82h; Смещение, где находится имя файла (81h - пробел, поэтому начинаем с 82h)
		int 21h
		jnc openOK; Если получилось
		print_msg 10, 13
		print_msg 'Open ERR', 10, 13
		exit
		openOK:
			call readFile
	inputFilename:
		print_msg 'Input file name > '
		mov AH, 10; Чтение строки из stdin
		mov DX, offset fileName; Distination
		int 21h
		xor BH, BH
		mov BL, fileName[1]; Заносим длину прочитанной строки
		mov fileName[BX + 2], 0; Делаем fileName строкой, обозначая конец нулем
		mov AX, 3D02h
		mov DX, offset fileName + 2
		int 21h
		jnc openOK; Если получилось
		print_msg 10, 13
		print_msg 'Open ERR', 10, 13
	exit
end start
