; �뢮� �㪢� A, B, C, D, ... �㪢� ������� �� ����⨨ LeftAlt+F10
.286
.model tiny
.code
org 100h
;
; <--- ������ --->
;
print_letter macro letter
	push AX
	push DX; ����ᨬ ॣ����� � �⥪, �⮡� ��⮬ ����⠭����� ��! �⮡� �� �ᯮ���� ᮤ�ন��� ��/��᫥ �����
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
	;  ES:BX - �����
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
	; ��ࠡ�⪠ ��㬥�⮢
	mov CL, ES:80h
	cmp CL, 0
	jne pa_cont; �᫨ ��� ��㬥�⮢, �� ���뢠�� ��
	jmp pa_exit
	pa_cont:
	; �᫨ ��㬥��� ����, � 㤠�塞 �஡��� � ��砫�
	xor CH, CH
	cld; DF = 0 - 䫠� ���ࠢ����� ���। (AL -> AH)
	mov DI, 81h
	mov SI, offset uflag
	mov AL, ' '
	; �� �� �� ��䨪� ����� ᨭ������� � ����� ���� � �� �� ��� ����樨. ��䨪�� �������� �믮������ ᫥���饩 �� ���� �������, ࠡ���饩 � ��ப���. ������⢮ ����७�� �������� � ॣ���� CX �� �믮������ ������� � ��䨪ᮬ. ��᫥ ������� ����७�� ������� ॣ���� CX 㬥��蠥��� �� 1 �, �᫨ �� �⠫ ࠢ�� ��� ��� � १���� �믮������ ������� 䫠� ZF �⠫ ࠢ�� 0, �ந�室�� ��室 �� 横��.
	; ������� SCASB �ࠢ������ ॣ���� AL � ���⮬ � �祩�� ����� �� ����� ES:DI � ��⠭�������� 䫠�� �������筮 ������� CMP. ��᫥ �믮������ �������, ॣ���� DI 㢥��稢����� �� 1, �᫨ 䫠� DF = 0, ��� 㬥��蠥��� �� 1, �᫨ DF = 1.
	; SCASB - Scan a Set of Bytes
	; * ����� OF, SF, ZF, AF, PF, CF ��⠭���������� � ᮮ⢥��⢨� � १���⮬.
	repe scasb
	; �஢��塞, �� ��।�� 䫠� /off
	dec DI; DI �⠢�� �� ���� ᨬ��� ��᫥ �஡����
	mov CX, uflag_len
	; ������� CMPSB �ࠢ������ ���� ���� �� ����� �� ����� DS:SI � ���⮬ �� ����� ES:DI. �������筠 �� ����⢨� ������� CMP
	; ��᫥ �믮������ �������, ॣ����� SI � DI 㢥��稢����� �� 1, �᫨ 䫠� DF = 0, ��� 㬥������� �� 1, �᫨ DF = 1.
	; CMPSB - Compare a Set of Bytes
	repe cmpsb
	jne pa_exit; �᫨ � ��㬥��� ��।�� �� �� 䫠�, ����� ��������� (/off), � flag_off = 0
	inc flag_off; ���� flag_off = 1
	pa_exit:
endm
unload macro
	local exit_uninst, cancel_uninst
	push BX
	push CX
	push DX
	push ES
	; �஢��塞 ����������� ���㧪� � ���㦠�� ������
	xor AX, AX
	unload_vector 09h, old_09h, new_09h
	unload_vector 2Fh, old_2Fh, new_2Fh
	unload_vector 1Ch, old_1Ch, new_1Ch
	cmp AL, 1
	je cancel_uninst
	
	; �᢮������� ������
	mov ES, CS:2Ch; ������ ���㦥��� � ES
	mov AH, 49h; DOS-�㭪�� �᢮�������� ����� �����
	int 21h
	mov AX, CS
	mov ES, AX; mov ES, CS - ������ PSP
	mov AH, 49h
	int 21h
	
	mov AL, 0Fh; �ਧ��� �ᯥ譮� ���㧪�
	jmp exit_uninst
	
	cancel_uninst:
		mov AL, 0F0h; �ਧ��� ⮣�, �� ���㦠�� �����
		
	exit_uninst:
		pop ES
		pop DX
		pop CX
		pop BX
endm
start:
jmp main
;
; <--- ��६���� --->
;
old_2Fh dd ?
old_1Ch dd ?
old_09h	dd ?
char db 'A'
count db 0
flag db 0
; ���㧪� �ணࠬ��
uflag db '/off'
uflag_len dw 4
flag_off db 0
msg1 db 'Already installed', 13, 10, '$'
msg2 db 'Not installed', 13, 10, '$'
msg3 db 'Uninstalled', 13, 10, '$'
msg4 db 'Uninstalling error', 13, 10, '$'
;
; <--- ��楤��� --->
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
	jne	check_f10; 㦥 ����� LeftAlt, ���� �� �஢��� ������ F10
	in AL, 60h
	cmp AL, 38h; �� LeftAlt?
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
		cmp AL, 44h; �� F10?
		jne	reset_flag; �᫨ ���, � ᨬ��� �� �������
		inc	CS:char
	reset_flag:
		mov	CS:flag, 0
		jmp	exit_09h
endp
new_2Fh proc
	; ��� AX = 0C700
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
	mov AX, 0B701h; ����㭪�� ���㧪�
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
    ; ��ࠡ�⪠ ��㬥�⮢
	process_args
	; �஢�ઠ, ��⠭������ �� �ணࠬ��
	check_inst:
		mov AX, 0B700h; mov AH, 0B7; mov AL, 00 - �-�� �஢�ન ����� ���⨯���᭮�� ���뢠��� (����饭� 㦥 �ணࠬ�� ��� ���)
		int 2Fh
		cmp AL, 0FFh; �ணࠬ�� 㦥 ��⠭������
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
	int 27h; ������ �ணࠬ�� १����⭮�
end start