; ��ਠ�� 20
; TSR-�ணࠬ��. �� ������ ����祩 ������ ���� ���㦭���� � ����᪮� ०���. 
; � ������� ��५�� ���㦭���� ����� ��६���� �� �࠭�. �� ��㣮� ����祩 ������ TSR-�ணࠬ�� ���㦠����.
; ���ᮢ��� - F1, ���㧨���� - F2
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
print_byte macro xbyte
	pusha
	mov BL, xbyte
	mov DL, BL
	shr DL, 4
	call print_hex; �맮� ��楤���
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
	cmp AL, 1
	je cancel_uninst
	
	; ����塞 ���
	mov AH, 00h
	mov AL, CS:last_videomode
	int 10h
	
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
; <--- ����⠭�� --->
;
STEP_SIZE equ 3
RADIUS equ 20
BOTTOM_EDGE equ 480 - RADIUS - STEP_SIZE; 457
RIGHT_EDGE equ 640 - RADIUS - STEP_SIZE; 617
;
; <--- ��६���� --->
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
	mov AH, 0Ch; �㭪�� ���ᮢ�� �窨
	mov AL, 6; ����
	int 10h; ���ᮢ��� ���
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
	int 10h; ����祭�� �����०��� VGA
	call draw_circle
	; mov AH,	1; �㭪�� ��墠� ���� ������ (�����筠 getch �� "�")
	; int 21h
endm
; ���⨯���᭮� ���뢠���
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
	cmp AL, 3Bh; ���� ��� F1
	je draw_09h; ���㥬 ���
	cmp AL, 48h; ���� ��� ��५�� �����
	je circle_shu; shift up
	cmp AL, 50h; ���� ��� ��५�� ����
	je circle_shd; shift down
	cmp AL, 4Bh; ���� ��� ��५�� �����
	je circle_shl; shift left
	cmp AL, 4Dh; ���� ��� ��५�� ��ࠢ�
	je circle_shr; shift right
	cmp AL, 3Ch; ���� ��� F2
	jne exit_09h
	jmp f2_uninst; ���㧪� �ணࠬ��
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
		mov AX, 0B701h; ����㭪�� ���㧪�
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
	get_vector 09h,	old_09h
	set_vector 09h,	new_09h
	; ���࠭塞 ⥪�騩 �����०��
	mov AH, 0Fh
	int 10h
	mov last_videomode, AL
	print_str mymsg
	; ��⠭�������� ���祭�� �� 㬮�砭��
	; mov radius, 21; ������ ��襣� ��㣠
	mov x0, 80; ����� ��ப�, � ���஬ �㤥� ��室����� 業�� ��㣠
	mov y0, 80; ����� �⮫��, � ���஬ �㤥� ��室����� 業�� ��㣠
	mov DX, offset main
	int 27h; ������ �ணࠬ�� १����⭮�
end start