code_seg segment
	assume cs:code_seg,ds:code_seg,ss:code_seg
	org 100h
start:
    jmp begin
mes:    DB 13,10,'    PSP contents',13,10,13,10,13,10,'$'
begin:
         mov    AH, 9h  
         lea    DX, mes
         int    21h     ; print string

    xor SI,SI
    mov CX,16
cycle:
    push    CX
    mov     CX,8
inside:
    mov BX,word ptr [DS:SI]
;    mov BL,0AFh
	mov 	AH,02
	mov 	DL,BL
	rcr	DL,4
	call 	print_hex
	mov	DL,BL
	call	print_hex
;
    mov     AH,02
    mov     DL,20h
    int     21h
;
    mov     DL,BH
	rcr	DL,4
	call 	print_hex
    mov DL,BH
	call	print_hex
;
    mov     AH,02
    mov     DL,20h
    int     21h
;
;
    mov     AH,02
    mov     DL,20h
    int     21h
;
;
    mov     AH,02
    mov     DL,20h
    int     21h
;
    inc SI
    inc SI
    loop    inside
;
    mov     AH,02
    mov     DL,10
    int     21h
;
;
    mov     AH,02
    mov     DL,13
    int     21h
;
;    mov     AH,02
;    mov     DL,10
;    int     21h
;
    pop     CX
    loop    cycle
	int	20h
print_hex:
	and	DL,0Fh
	add	DL,30h
	cmp	DL,3Ah
	jl	print
	add	DL,07h
print:	int	21H
        ret
code_seg ends
         end start
