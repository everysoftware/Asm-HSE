; Вариант 20
; TSR-программа. По нажатию горячей клавиши рисует окружность в графическом режиме. 
; С помощью стрелок окружность можно перемещать по экрану. По другой горячей клавише TSR-программа выгружается.
; Нарисовать - F1, выгрузиться - F2
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
print_str macro strv
	push AX
	push DX
	mov AH, 9
	mov DX, offset strv
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
exit macro
	mov	AX,	4C00h
	int	21h
endm
get_vector macro vector, destination 
	pusha
	push ES
	mov AX, 35&vector
	int 21h
	;  ES:BX - вектор
	mov word ptr destination, BX
	mov word ptr destination + 2, ES
	pop	ES
	popa
endm
set_vector macro vector, handler
    mov DX, offset handler
    mov AX, 25&vector
    int 21h
endm
recovery_vector	macro vector, source
	pusha
	push DS
	push ES
	lds DX, CS:source
	mov	AX,	25&vector
	int 21h
	pop	ES
	pop	DS
	popa
endm
unload_vector macro vector, old_vector, new_vector
	local unload_err, unload_exit
	mov CX, CS
	mov AX, 35&vector
	int 21h
	mov DX, ES
	cmp CX, DX
	jne unload_err
	cmp BX, offset CS:new_vector
	jne unload_err
	recovery_vector vector, old_vector
	jmp unload_exit
	
	unload_err:
		mov AL, 1
	unload_exit:
endm
process_args macro
	local pa_exit, pa_cont
	; Обработка аргументов
	mov CL, ES:80h
	cmp CL, 0
	jne pa_cont; Если нет аргументов, не считываем их
	jmp pa_exit
	pa_cont:
	; Если аргументы есть, то удаляем пробелы в начале
	xor CH, CH
	cld; DF = 0 - флаг направления вперед (AL -> AH)
	mov DI, 81h
	mov SI, offset uflag
	mov AL, ' '
	; Все эти три префикса являются синонимами и имеют один и тот же код операции. Префиксы повторяют выполнение следующей за ними команды, работающей со строками. Количество повторений заносится в регистр CX до выполнения команды с префиксом. После каждого повторения команды регистр CX уменьшается на 1 и, если он стал равен нулю или в результате выполнения команды флаг ZF стал равен 0, происходит выход из цикла.
	; Команда SCASB сравнивает регистр AL с байтом в ячейке памяти по адресу ES:DI и устанавливает флаги аналогично команде CMP. После выполнения команды, регистр DI увеличивается на 1, если флаг DF = 0, или уменьшается на 1, если DF = 1.
	; SCASB - Scan a Set of Bytes
	; * Флаги OF, SF, ZF, AF, PF, CF устанавливаются в соответствии с результатом.
	repe scasb
	; Проверяем, что передан флаг /off
	dec DI; DI ставим на первый символ после пробелов
	mov CX, uflag_len
	; Команда CMPSB сравнивает один байт из памяти по адресу DS:SI с байтом по адресу ES:DI. Аналогична по действию команде CMP
	; После выполнения команды, регистры SI и DI увеличиваются на 1, если флаг DF = 0, или уменьшаются на 1, если DF = 1.
	; CMPSB - Compare a Set of Bytes
	repe cmpsb
	jne pa_exit; Если в аргументы передан не тот флаг, который ожидается (/off), то flag_off = 0
	inc flag_off; Иначе flag_off = 1
	pa_exit:
endm
unload macro
	local exit_uninst, cancel_uninst
	push BX
	push CX
	push DX
	push ES
	; Проверяем возможность выгрузки и выгружаем векторы
	xor AX, AX
	unload_vector 09h, old_09h, new_09h
	unload_vector 2Fh, old_2Fh, new_2Fh
	cmp AL, 1
	je cancel_uninst
	
	; Удаляем круг
	mov AH, 00h
	mov AL, CS:last_videomode
	int 10h
	
	; Освобождаем память
	mov ES, CS:2Ch; Кладем окружение в ES
	mov AH, 49h; DOS-функция освобождения блока памяти
	int 21h
	mov AX, CS
	mov ES, AX; mov ES, CS - кладем PSP
	mov AH, 49h
	int 21h
	
	mov AL, 0Fh; Признак успешной выгрузки
	jmp exit_uninst
	
	cancel_uninst:
		mov AL, 0F0h; Признак того, что выгружать нельяз
		
	exit_uninst:
		pop ES
		pop DX
		pop CX
		pop BX
endm
start:
jmp main
;
; <--- Константы --->
;
STEP_SIZE equ 3
RADIUS equ 20
BOTTOM_EDGE equ 480 - RADIUS - STEP_SIZE; 457
RIGHT_EDGE equ 640 - RADIUS - STEP_SIZE; 617
;
; <--- Переменные --->
;
mymsg db 'Press F1 to draw a circle', 13, 10, 'Press F2 to uninstall programm', 13, 10, '$'
last_videomode db ?
dc_err dw ?
x dw ?
y dw ?
x0 dw ?
y0 dw ?
delta dw ?
flag db 0
old_2Fh dd ?
old_09h	dd ?
; Выгрузка программы
uflag db '/off'
uflag_len dw 4
flag_off db 0
msg1 db 'Already installed', 13, 10, '$'
msg2 db 'Not installed', 13, 10, '$'
msg3 db 'Uninstalled', 13, 10, '$'
msg4 db 'Uninstalling error', 13, 10, '$'
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
plot proc
	mov AH, 0Ch; Функция отрисовки точки
	mov AL, 6; Цвет
	int 10h; Нарисовать точку
	ret
plot endp
draw_circle proc
    mov x, 0
	mov AX, RADIUS
    mov y, AX
    mov delta, 2
	mov AX, 2
	mov DX, 0
	imul y
	sub delta, AX
	mov dc_err, 0
	jmp drawing
	dc_finally:
		ret
	drawing:
		mov AX, y
		cmp AX, 0
		jl dc_finally
		;
		mov CX, x0
		add CX, x
		mov DX, y0
		add DX, y
		call plot
		;
		mov CX, x0
		add CX, x
		mov DX, y0
		sub DX, y
		call plot
		;
		mov CX, x0
		sub CX, x
		mov DX, y0
		add DX, y
		call plot
		;
		mov CX, x0
		sub CX, x
		mov DX, y0
		sub DX, y
		call plot
		;
		mov AX, delta
		mov dc_err, AX
		mov AX, y
		add dc_err, AX
		mov AX, dc_err
		mov DX, 0
		mov BX, 2
		imul BX
		sub AX, 1
		mov dc_err, AX
		cmp delta, 0
		jg dc_sstep
		je dc_sstep
		cmp dc_err, 0
		jg dc_sstep
		inc x
		mov AX, 2
		mov DX, 0
		imul x
		add AX, 1
		add delta, AX
    jmp drawing
	dc_sstep:
		mov AX, delta
		sub AX, x
		mov BX, 2
		mov DX, 0
		imul BX
		sub AX, 1
		mov dc_err, AX
		cmp delta, 0
		jg dc_tstep
		cmp dc_err, 0
		jg dc_tstep
		inc x
		mov AX, x
		sub AX, y
		mov BX, 2
		mov DX, 0
		imul BX
		add delta, AX
		dec y
	jmp drawing
	dc_tstep:
		dec y
		mov AX, 2
		mov DX, 0
		imul y
		mov BX, 1
		sub BX, AX
		add delta, BX
	jmp drawing
endp
redraw_circle macro
	mov AH, 0
	mov AL, 11h
	int 10h; Включение видеорежима VGA
	call draw_circle
	; mov AH,	1; Функция захвата кода клавиши (идентична getch из "с")
	; int 21h
endm
; Мультиплексное прерывание
new_2Fh proc
	cmp AH, 0B7h;
	jne pass_2Fh
	cmp AL, 00h
	je inst
	cmp AL, 01h
	je uninst
	jmp pass_2Fh
	inst:
		mov AL, 0FFh
		iret
		jmp pass_2Fh
	pass_2Fh:
		jmp dword ptr CS:[old_2Fh]
	uninst:
		unload
		iret
endp
new_09h proc
	push AX
	pushf
	push DS
	push CS
	pop DS
	in AL, 60h
	cmp AL, 3Bh; Скан код F1
	je draw_09h; Рисуем круг
	cmp AL, 48h; Скан код стрелки вверх
	je circle_shu; shift up
	cmp AL, 50h; Скан код стрелки вниз
	je circle_shd; shift down
	cmp AL, 4Bh; Скан код стрелки влево
	je circle_shl; shift left
	cmp AL, 4Dh; Скан код стрелки вправо
	je circle_shr; shift right
	cmp AL, 3Ch; Скан код F2
	jne exit_09h
	jmp f2_uninst; Выгрузка программы
	; Videomode 11 window size 640x480
	circle_shu:
		cmp y0, RADIUS
		jle exit_09h
		sub y0, STEP_SIZE
		jmp draw_09h
	circle_shd:
		cmp y0, BOTTOM_EDGE; 480 - RADIUS - STEP_SIZE
		jge exit_09h
		add y0, STEP_SIZE
		jmp draw_09h
	circle_shr:
		cmp x0, RIGHT_EDGE; 640 - RADIUS - STEP_SIZE
		jge exit_09h
		add x0, STEP_SIZE
		jmp draw_09h
	circle_shl:
		cmp x0, RADIUS
		jle exit_09h
		sub x0, STEP_SIZE
	draw_09h:
		redraw_circle
	exit_09h:
		pop DS
		popf
		pop AX
		jmp dword ptr CS:[old_09h]
	f2_uninst:
		mov AX, 0B701h; Подфункция выгрузки
		int 2Fh
		cmp AL, 0F0h
		je uninst_err
		cmp AL, 0Fh
		jne uninst_err
		print_str msg3
		exit
		jmp exit_09h
endp
uninstall:
	mov AX, 0B701h; Подфункция выгрузки
	int 2Fh
	cmp AL, 0F0h
	je uninst_err
	cmp AL, 0Fh
	jne uninst_err
	print_str msg3
	exit
uninst_err:
	print_str msg4
	exit	
already_inst:
	cmp flag_off, 1
	je uninstall
	print_str msg1
	exit
main:
    ; Обработка аргументов
	process_args
	; Проверка, установлена ли программа
	check_inst:
		mov AX, 0B700h; mov AH, 0B7; mov AL, 00 - ф-ия проверки статуса мультиплексного прерывания (запущена уже программа или нет)
		int 2Fh
		cmp AL, 0FFh; Программа уже установлена
		jne not_inst
		jmp already_inst
		not_inst:
		cmp flag_off, 1
		jne cont
		print_str msg2
		exit
	cont:
	get_vector 2Fh, old_2Fh
	set_vector 2Fh, new_2Fh
	get_vector 09h,	old_09h
	set_vector 09h,	new_09h
	; Сохраняем текущий видеорежим
	mov AH, 0Fh
	int 10h
	mov last_videomode, AL
	print_str mymsg
	; Устанавливаем значения по умолчанию
	; mov radius, 21; Радиус нашего круга
	mov x0, 80; Номер строки, в котором будет находиться центр круга
	mov y0, 80; Номер столбца, в котором будет находиться центр круга
	mov DX, offset main
	int 27h; Делаем программу резидентной
end start