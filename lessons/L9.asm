; Копирование строки
.286
.model tiny
.data
source db 'Hello world!$'
source_len = $-source
dist db 256 dup(' ')
.code
org 100h
start:
	; Эта программа копирует строку
	cld; DF = 0
	mov CX, source_len
	mov DI, offset dist
	mov SI, offset source
	rep movsb
	
	mov AH, 9
	mov DX, offset dist
	int 21h
	
	mov AX, 4C00h
	int 21h
end start 