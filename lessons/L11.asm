; Вывод буквы A, B, C, D, ... Буква меняется при нажатии LeftAlt+F10
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
	unload_vector 1Ch, old_1Ch, new_1Ch
	cmp AL, 1
	je cancel_uninst
	
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
; <--- Переменные --->
;
old_2Fh dd ?
old_1Ch dd ?
old_09h	dd ?
char db 'A'
count db 0
flag db 0
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
new_1Ch proc
    pusha
	pushf
	inc	CS:count
	cmp CS:count, 30
	jne	exit_1ch
	mov	CS:count, 0
	mov AH,	02
	mov DL, CS:char
	int 21h
	exit_1ch:
		popf
		popa
		jmp dword ptr CS:[old_1Ch]
endp
new_09h proc
	push AX
	pushf
	cmp	CS:flag, 0
	jne	check_f10; уже нажат LeftAlt, идем на проверку нажатия F10
	in AL, 60h
	cmp AL, 38h; Это LeftAlt?
	je lalt_pressed
	exit_09h:
		popf
		pop AX
		jmp dword ptr CS:[old_09h]
	lalt_pressed:
		mov CS:flag, 1
		jmp	exit_09h
	check_f10:
		in AL, 60h
		cmp AL, 44h; Это F10?
		jne	reset_flag; Если нет, то символ не меняется
		inc	CS:char
	reset_flag:
		mov	CS:flag, 0
		jmp	exit_09h
endp
new_2Fh proc
	; или AX = 0C700
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
	get_vector 1Ch, old_1Ch
	set_vector 1Ch, new_1Ch
	get_vector 09h,	old_09h
	set_vector 09h,	new_09h
	mov DX, offset main
	int 27h; Делаем программу резидентной
end start