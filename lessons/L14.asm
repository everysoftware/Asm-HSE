; Сохранение экрана
.286
.model tiny
.code
org 100h
;
; <--- Макросы --->
;
; Сохранить содержимое
saveScreen macro destination
	pusha
	cld; Сброс DF (Direction Flag) - направление вперед
    mov CX, 25 * 80; Кол-во слов для копирования
    lea DI, destination; Смещение относительно буфера
	mov AX,	0B800h; Начало видеобуфера
	mov DS,	AX; DS указывает на строку 0 видеобуфера
	xor SI,	SI; Смещение относительно источника (в нашем случае это смещение относительно B800h, и оно равно 0)
	rep movsw; Пересылаем весь экран в буфер DS:[SI] --> ES:[DI]
	popa
endm
; Очистить экран
clearScreen macro
	pusha
	cld; Сброс DF (Direction Flag) - направление вперед
	mov CX,	25 * 80; Сколько раз повторять строковую команду
	mov AX,	0B800h; Начало видеобуфера
	mov ES, AX; ES указывает на строку 0 видеобуфера
	xor DI,	DI; Смещение относительно видеобуфера (буфер)
	xor AX,	AX; Источник - что выводим (в нашем случае пустоту)
	; Команда STOSW сохраняет регистр AX в ячейке памяти по адресу ES:DI. 
	; После выполнения команды, регистр DI увеличивается на 2, если флаг DF = 0, или уменьшается на 2, если DF = 1.
	rep	stosw; Выгрузим AX в видеобуфер 25 * 80 раз, ES:[DI] = AX
	popa
endm
; Восстановить экран
loadScreen macro source
	pusha
	push CS
	pop DS; Настраиваем DS на CS, чтобы можно было прочитать сохраненное содержимое экрана
	mov CX,	25 * 80
	lea SI,	source; Смещение относительно источника
	mov AX,	0B800h
	mov ES, AX; ES указывает на строку 0 видеобуфера
	xor DI, DI; Смещение относительно буфера
	rep movsw; Переслать данные (DS:[SI] --> ES:[DI])
	popa
endm
start:
jmp main
;
; <--- Переменные --->
;
bufscr dw 25 * 80 dup(?); Буфер для сохранения экрана
main:
	saveScreen bufscr
	; Ждем нажатия на любую клавишу
	mov AH, 1
	int 21h
	clearScreen
	; Ждем нажатия на любую клавишу
	mov AH, 1
	int 21h
	loadScreen bufscr
	; Выход
	mov AX, 4C00h
	int 21h
end start