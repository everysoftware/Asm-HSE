.model tiny
.data
fileName db	14, 0, 14 dup(0)
.code
org 100h

CR EQU 10
NL EQU 13
SPA EQU 32

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
print_msg macro msg
	local tmp
	.data
	tmp db msg, CR, NL, "$"
	.code
	push AX
	push DX
	mov AH, 9
	mov DX, offset tmp
	int 21h
	pop DX
	pop AX
endm

start:
	jmp main
	; Proc
	print_hex proc
		and DL, 0Fh
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
		call print_hex; Вызов процедуры
		pop DX
		and DL, 0Fh
		call print_hex
		ret
	endp
	print_AX proc
		push AX
		push BX
		push CX
		push DX
		mov BX, AX
		mov DL, BH
		call print_byte
		mov DL, BL
		call print_byte
		pop DX
		pop CX
		pop BX
		pop AX
		ret
	endp
	; Ужасный костыль...
	print_BX proc
		push AX
		mov AX, BX
		call print_AX
		print_letter 10
		print_letter 13
		pop AX
		ret
	endp
	main:
		; Печатаем на экран служебную инфу - параметры программы в HEX'е
		mov SI, 80h
		mov AH, 2
		mov CX, 16
		printing:
			mov BL,	byte ptr [SI]
			mov DL,	BL
			call print_byte
			print_letter SPA
			inc SI
		loop printing
		print_letter CR
		print_letter NL
		; Проверяем есть ли вообще параметры
		mov SI, 80h
		mov AL, byte ptr [SI]
		cmp AL, 0
		jne readParams; Если есть, то читаем их
		print_msg 'Not params'
		jmp inputFilename
		readParams:
			xor BH, BH
			mov BL, ES:[80h]
			mov byte ptr[BX + 81h], 0
			print_msg 'Params length: '
			call print_BX
			mov SI, 80h
			mov AH, 2
			mov CX, 16
			mov AX, 3D02h; Команда для чтения из файла/записи в файл 
			mov DX, 82h; Смещение, где находится имя файла (81h - пробел, поэтому начинаем с 82h)
			int 21h
			jnc openOK; Если получилось
			print_msg 'Open ERR'
			jmp finish
			openOK:
				print_msg 'Open OK'
				jmp finish
		inputFilename:
			print_msg 'Input file name >'
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
			print_msg 'Open ERR'
		finish:
			mov AX, 4C00h
			int 21h
end start
