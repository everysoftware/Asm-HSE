; Hello world
.model tiny
.data
hello db 'Hello world!', 13, 10, '$'

.code
org 100h

start:
	mov DX, offset hello ;Кладем в DX адрес строки
	mov AH, 9 ;В AH кладем номер DOS-функции, кот. выводит строку
	int 21h ;Обращение к функции DOS
	
	mov AX, 4C00h
	int 21h ;return 0
end start
