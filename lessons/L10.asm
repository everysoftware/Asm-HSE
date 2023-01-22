; Вывод окна с сообщением средствами BIOS по нажатии F12
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
; Получить вектор прерывания vector и занести его в destination
get_vector macro vector, destination 
	; Команда PUSHA помещает в стек регистры общего назначения в следующем порядке: AX, CX, DX, BX, SP, BP, SI, DI
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
	mov AX, 3509h
	int 21h
	mov DX, ES
	cmp CX, DX
	jne cancel_uninst
	cmp BX, offset CS:new_09h
	jne cancel_uninst
	
	mov AX, 352Fh; Вектор 2F
	int 21h
	mov DX, ES
	cmp CX, DX
	jne cancel_uninst
	cmp BX, offset CS:new_2Fh
	jne cancel_uninst
	
	; Восстанавливаем прерванные векторы
	recovery_vector 09h, old_09h
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
;
; <--- Переменные --->
;
displayMsg db '1234567890'; Отображаемое сообщение
dmsg_len dw 10
success_msg db 'Successfully installed', 13, 10, '$'
; Координаты окна
left_X db 50
right_X db 69
; width = 69 - 50 = 19
bottom_Y db 7
top_Y db 15
; height = 15 - 7 = 8
video_page db 0; Видеостраница
dmsg_y db 11; Y сообщения в окне
dmsg_x db 55; X сообщения в окне
old_09h dd ?
old_2Fh dd ?
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
new_2Fh proc
	; или AX = 0C700
	cmp AH, 0B7h;
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
new_09h proc
	pushf
	push AX
	in AL, 60h; Scan code последней нажатой клавиши в AL
	cmp AL, 58h; Проверка: это F12?
	je hotkey; Если да, идем дальше
	; Иначе восстанавливаем стек
	pop AX
	popf
	jmp dword ptr CS:[old_09h]
	hotkey:
		sti; (Set Interrupt Flag) отключаем прерывания
		; Так как порт 61h управляет не только клавиатурой, 
		; при изменении содержимого старшего бита необходимо
		; сохранить состояние остальных битов этого порта. 
		; Для этого можно сначала выполнить чтение содержимого
		; порта в регистр, изменить состояние старшего бита, 
		; затем выполнить запись нового значения в порт
		in AL, 61h; Сохраняем в AL содержимое порта
		or AL, 80h; Блокируем клавиатуру (записываем в старший бит 1)
		out 61h, AL
		and AL, 7Fh; Снова разрешим работу клавиатуры (обратное действие к or 80h)
		out 61h, AL
		; Вывод окна средствами BIOS
		push BX
		push CX
		push DX
		push DS
		push CS; Настройкка DS на наш сегмент
		pop DS
		mov AX, 0600h; BIOS ф-ия задания окна
		mov BH, 70h; Атрибут черный по серому
		; Координаты окна
		mov CH, CS:bottom_Y
		mov CL, CS:left_X
		mov DH, CS:top_Y
		mov DL, CS:right_X
		int 10h
		; Позиционируем сообщение в окне
		mov AH, 02h; BIOS функция позиционирования
		mov BH, CS:video_page; Видеостраница
		mov DH, CS:dmsg_y
		mov DL, CS:dmsg_x
		int 10h
		mov CX,	CS:dmsg_len
		mov BX, offset CS:displayMsg
		mov AH, 0Eh; BIOS функция вывода одного символа
		next_sym:
			mov AL, CS:[BX]; Символ в AL
			inc BX
			int 10h
		loop next_sym
		pop	DS
		pop DX
		pop CX
		pop BX
		cli; Разрешаем прерывания
		mov AL, 20h; Пошлем приказ EOI (End Of Interrupt)
		out 20h, AL
		pop AX
		popf
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
already_init:
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
		jne not_init
		jmp already_init
		not_init:
		cmp flag_off, 1
		jne cont
		print_str msg2
		exit
	cont:
	get_vector 2Fh, old_2Fh
	set_vector 2Fh, new_2Fh
	get_vector 09h,	old_09h
	set_vector 09h,	new_09h
	print_str success_msg
	mov DX, offset main
	int 27h; Делаем программу резидентной
end start