; Выгрузка и защита от повторного запуска
.286
.model tiny
.data
uflag db '/off'
uflag_len = $-uflag
old_1Ch dd ?
old_2Fh dd ?
count db 0
flag_off db 0
msg1 db 'Already installed', 13, 10, '$'
msg2 db 'Not installed', 13, 10, '$'
msg3 db 'Uninstalled', 13, 10, '$'
msg4 db 'Uninstalling error', 13, 10, '$'
.code
org 100h
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
	mov AH, 2
	call print_hex; Вызов процедуры
	mov DL, BL
	call print_hex
	popa
endm
print_word macro xword
	pusha
	mov DX, xword
	print_byte DH
	mov DX, xword
	print_byte DL
	popa
endm
exit macro
	mov	AX,	4C00h
	int	21h
endm
; Получить вектор прерывания vector и занести его в destination
get_vector macro vector, destination 
	; Команда PUSHA помещает в стек регистры общего назначения в следующем порядке: AX, CX, DX, BX, SP, BP, SI, DI (в случае регистра SP используется значение, которое находилось в этом регистре до начала работы команды).
	pusha
	push ES
	mov AX, 35&vector; Функция получения вектора прерывания
	int 21h
	;  ES:BX - вектор
	mov word ptr destination, BX; Заполняем первые два байта содержимым BX
	mov word ptr destination + 2, ES; Остальные два байта - содержимым ES
	pop	ES
	popa
endm
; Установить вектор прерывания vector на новый handler
set_vector macro vector, handler
    mov DX, offset handler; В случае COM программы заполнять нужно только DX
    mov AX, 25&vector; Функция установки прерывания (изменить вектор AL - номер прерыв. DS:DX - ук-ль программы обр. прер.)
    int 21h
endm
; Восстановить вектор прерывания vector на old_vector
recovery_vector	macro vector, source
	pusha
	push DS
	push ES
	; Команда LDS REG, MEM выполняет те же действия, что и две следующие команды (LOAD DS):
	; MOV REG, WORD PTR MEM
	; MOV DS,  WORD PTR MEM+2
	lds DX, CS:source
	; Аналогично les, lgs, lfs, lss, lea
	mov	AX,	25&vector; Заполнение вектора старым содержимым
	int 21h; DS:DX - указатель программы обработки прер.
	pop	ES
	pop	DS
	popa
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
	; Проверка на возможность выгрузки
	mov CX, CS
	mov AX, 351Ch; Вектор 1Ch
	int 21h
	mov DX, ES
	cmp CX, DX
	jne cancel_uninst
	cmp BX, offset CS:new_1Ch
	jne cancel_uninst
	
	mov AX, 352Fh; Вектор 2F
	int 21h
	mov DX, ES
	cmp CX, DX
	jne cancel_uninst
	cmp BX, offset CS:new_2Fh
	jne cancel_uninst
	
	; Восстанавливаем прерванные векторы
	recovery_vector 1Ch, old_1Ch
	recovery_vector 2Fh, old_2Fh
	
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
	new_2Fh proc
		; или AX = 0C700
		cmp AH, 0C7h;
		jne pass_2Fh
		cmp AL, 00h
		je inst
		cmp AL, 01h
		je uninst
		jmp pass_2Fh
		; jmp short pass_2Fh - если хотите оптимизацию, пишите так
		inst:
			mov AL, 0FFh
			iret
			jmp pass_2Fh
		uninst:
			unload
			iret
		pass_2Fh:
			jmp dword ptr CS:[old_2Fh]
	endp
	; 1Ch вызывается примерно 18 раз в секунду. Поэтому чтобы печатать букву A каждую секунду, поставим счётчик итераций, и каждую 18 итерацию будем печататть.
	new_1Ch proc
		; Через регистр DS получить доступ не получится (inc count писать нельзя)
		; Нужно использовать CS!!!
		inc CS:count; CS - это префикс замены
		cmp CS:count, 18
		jg setzero
		cmp	CS:count, 18
		jne	gonext
		print_letter 'A'
		setzero:
			mov CS:count, 0
		gonext:
			jmp	dword ptr CS:[old_1Ch]
	endp
	; Второй способ получения доступа к переменным
	; new_1Ch2 proc
		; push DS
		; push CS
		; pop DS
		; cmp count, 18
		; jg setzero
		; inc count; CS - это префикс замены
		; cmp	count, 18
		; jne	gonext
		; print_letter 'A'
		; setzero:
			; mov count, 0
		; gonext:
			; pop DS
			; jmp	dword ptr CS:[old_1Ch]
	; endp
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
	uninstall:
		mov AX, 0C701h; Подфункция выгрузки
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
	already_init:
		cmp flag_off, 1
		je uninstall
		print_str msg1
		exit
	; TSR программа - Terminate and Stay Resident - Резидентная программа
	main:
		; Обработка аргументов
		process_args
		; Проверка, установлена ли программа
		check_init:
			mov AX, 0C700h; mov AH, 0C7; mov AL, 00 - ф-ия проверки статуса мультиплексного прерывания (запущена уже программа или нет)
			int 2Fh
			cmp AL, 0FFh; Программа уже установлена
			je already_init
			cmp flag_off, 1
			jne cont
			print_str msg2
			exit
		cont:
		; mov AX, 352Fh; Команда получения вектора прерывания 2F
		; int 21h; Теперь вектор сохранен в ES:BX
		; mov word ptr int_2Fh_vector, BX
		; mov word ptr int_2Fh_vector + 2, ES; Переносим в переменную
		; mov DX, offset int_2Fh
		; mov AX, 252Fh; Команда установки вектора прерывания 2F на новый int_2Fh
		; int 21h
		get_vector 2Fh, old_2Fh
		set_vector 2Fh, new_2Fh
		get_vector 1Ch,	old_1Ch; 1Ch - таймер (обработчик loop)
		set_vector 1Ch,	new_1Ch
		mov	CX, 20
		cycle:
			xor	AX,	AX
			go:
				inc	AX
				cmp	AX,	0
				jne	go
		loop cycle
		print_letter 'D'
		mov DX, offset main
		int 27h; Делаем программу резидентной
end start
