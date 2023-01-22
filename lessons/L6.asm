; Цветной Hello world
.model tiny
.data
string db 'Hello, men!', 10, 13
len = $-string
.code
org 100h
start:
   ; Получение текущей позиции курсора
	mov AH, 3; Читать позицию курсора
	mov BH, 0; Для видеостраницы
	int 10h; Выход: DH, DL - позиция курсора
	; Вывод строки
	mov AX, 1301h; Функция вывода строки
	mov BL, 47h; BL - цвет текста, сразу меняем
	mov BH, 0; Страница видеопамяти
	; mov DL, DL; Позиция X экрана (не меняем - используем текущую)
	; mov DH, DH; Позиция Y экрана (не меняем - используем текущую)
	mov CX, len; Длина строки
	lea BP, [string]; В BP помещаем адрес начала строки
	int 10h
	
	mov AX, 4C00h
	int 21h
end start