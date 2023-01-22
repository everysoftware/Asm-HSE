; Hello world (rus)
.model tiny
.data
hello db 'Здравствуй мир!', 13, 10, '$'

.code
org 100h
start:
	mov DX, offset hello
	mov AH, 9
	int 21h
	
	mov AX, 4C00h
	int 21h ;return 0
end start
