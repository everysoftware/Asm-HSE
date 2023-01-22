; Типы данных
.model tiny
.data
; Минус работает во всех СС
a db -7
b db -77o
k db -101b
s db -'a'

xdec dw 537; Десятичная
xbin db 11010001b; Двоичная
xoct db 57o; Восьмиричная
xhex db 0C2h; 16-ричная

x1 db 5; 1 байт со значением 5 (DEFINE BYTE) [0, 255] / [-128, 127]
x2 dw 10; 2-байтные данные  (DEFINE WORD)
x3 dd 15; 4-байтные данные (DEFINE DOUBLEWORD)
x4 df 20; 6-байтные данные (DEFINE FANVORD)
x5 dq 25; 8-байтные данные (DEFINE QUADROWORD)
x6 dt 30; 10-байтные данные (DEFINE TEN BYTES)

array1 dw 31, 32, 33, 34, 35; Массив пяти 2-байтных чисел
array2 db 5 dup(1); Массив из пяти байтов, равных 1 (DUPLICATE)
array3 dd 4 dup(3, 7, 0); Массив из четырех троек 3, 7, 0

; Объявление неинициализированных переменных (резервирование места под данные)
y1 db ?
y2 dw ?, ?, ?
y3 dd 10 dup(?)

.code
org 100h

start:
	mov AX, 4C00h
	int 21h
end start