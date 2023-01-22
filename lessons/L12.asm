; ������� ������ �� ������� ���� ����������� ��������
.286
.model tiny
.code
org 100h
;
; <--- ������� --->
;
print_letter macro letter
	push AX
	push DX; ������� �������� � ����, ����� ����� ������������ ��! ����� �� ��������� ���������� ��/����� �������
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
	;  ES:BX - ������
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
	; ��������� ����������
	mov CL, ES:80h
	cmp CL, 0
	jne pa_cont; ���� ��� ����������, �� ��������� ��
	jmp pa_exit
	pa_cont:
	; ���� ��������� ����, �� ������� ������� � ������
	xor CH, CH
	cld; DF = 0 - ���� ����������� ������ (AL -> AH)
	mov DI, 81h
	mov SI, offset uflag
	mov AL, ' '
	; ��� ��� ��� �������� �������� ���������� � ����� ���� � ��� �� ��� ��������. �������� ��������� ���������� ��������� �� ���� �������, ���������� �� ��������. ���������� ���������� ��������� � ������� CX �� ���������� ������� � ���������. ����� ������� ���������� ������� ������� CX ����������� �� 1 �, ���� �� ���� ����� ���� ��� � ���������� ���������� ������� ���� ZF ���� ����� 0, ���������� ����� �� �����.
	; ������� SCASB ���������� ������� AL � ������ � ������ ������ �� ������ ES:DI � ������������� ����� ���������� ������� CMP. ����� ���������� �������, ������� DI ������������� �� 1, ���� ���� DF = 0, ��� ����������� �� 1, ���� DF = 1.
	; SCASB - Scan a Set of Bytes
	; * ����� OF, SF, ZF, AF, PF, CF ��������������� � ������������ � �����������.
	repe scasb
	; ���������, ��� ������� ���� /off
	dec DI; DI ������ �� ������ ������ ����� ��������
	mov CX, uflag_len
	; ������� CMPSB ���������� ���� ���� �� ������ �� ������ DS:SI � ������ �� ������ ES:DI. ���������� �� �������� ������� CMP
	; ����� ���������� �������, �������� SI � DI ������������� �� 1, ���� ���� DF = 0, ��� ����������� �� 1, ���� DF = 1.
	; CMPSB - Compare a Set of Bytes
	repe cmpsb
	jne pa_exit; ���� � ��������� ������� �� ��� ����, ������� ��������� (/off), �� flag_off = 0
	inc flag_off; ����� flag_off = 1
	pa_exit:
endm
unload macro
	local exit_uninst, cancel_uninst
	push BX
	push CX
	push DX
	push ES
	; ��������� ����������� �������� � ��������� �������
	xor AX, AX
	unload_vector 2Fh, old_2Fh, new_2Fh
	unload_vector 21h, old_21h, new_21h
	cmp AL, 1
	je cancel_uninst
	
	; ����������� ������
	mov ES, CS:2Ch; ������ ��������� � ES
	mov AH, 49h; DOS-������� ������������ ����� ������
	int 21h
	mov AX, CS
	mov ES, AX; mov ES, CS - ������ PSP
	mov AH, 49h
	int 21h
	
	mov AL, 0Fh; ������� �������� ��������
	jmp exit_uninst
	
	cancel_uninst:
		mov AL, 0F0h; ������� ����, ��� ��������� ������
		
	exit_uninst:
		pop ES
		pop DX
		pop CX
		pop BX
endm
start:
jmp main
;
; <--- ���������� --->
;
old_2Fh dd ?
old_21h dd ?
prog_name db 80 dup(' ')
success_msg db 'Successfully installed', 13, 10, '$'
; �������� ���������
uflag db '/off'
uflag_len dw 4
flag_off db 0
msg1 db 'Already installed', 13, 10, '$'
msg2 db 'Not installed', 13, 10, '$'
msg3 db 'Uninstalled', 13, 10, '$'
msg4 db 'Uninstalling error', 13, 10, '$'
;
; <--- ��������� --->
;
new_21h proc
	pushf
	pusha
	push ES
	push DS
	push CS
	pop	ES; ES = CS
	cmp AH, 4Bh; ������� ������� ������� ���������?
	je exec_func
	jmp	other_func
	exec_func:
		xor CX, CX
		mov SI, DX; DS:DX programm_name
		mov	DI,	offset CS:prog_name
		next:
			mov	AL,	[SI]; �������� � AL ��������� ������
			mov	CS:[DI], AL; �������� ������ �� AL � prog_name
			cmp	AL, 0
			je cycle_br
			inc SI
			inc	DI
			inc CX
		jmp next
		; ������ ����� ���������
		cycle_br:
			mov	DH, 10; Y
			mov	DL, 28; X
			mov AH, 13h; �-�� ������ ���������
			mov AL, 0h; ???
			mov BH, 0h; �������������
			mov BL, 04h; ������� �� �������
			mov	BP,	offset CS:prog_name; ����� ��������� � ES:BP
			int 10h; ������ ������ � ����������� DH:DL
	other_func:
		pop	DS
		pop	ES
		popa
		popf
		jmp dword PTR CS:[old_21h]
endp
new_2Fh proc
	; ��� AX = 0C700
	cmp AH, 0C8h;
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
	mov AX, 0C801h; ���������� ��������
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
    ; ��������� ����������
	process_args
	; ��������, ����������� �� ���������
	check_inst:
		mov AX, 0C800h; mov AH, 0B7; mov AL, 00 - �-�� �������� ������� ��������������� ���������� (�������� ��� ��������� ��� ���)
		int 2Fh
		cmp AL, 0FFh; ��������� ��� �����������
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
	get_vector 21h, old_21h
	set_vector 21h, new_21h
	print_str success_msg
	mov DX, offset main
	int 27h; ������ ��������� �����������
end start