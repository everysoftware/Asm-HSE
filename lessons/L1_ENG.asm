; Hello world
.model tiny
.data
hello db 'Hello world!', 13, 10, '$'

.code
org 100h

start:
	mov DX, offset hello ;������ � DX ����� ������
	mov AH, 9 ;� AH ������ ����� DOS-�������, ���. ������� ������
	int 21h ;��������� � ������� DOS
	
	mov AX, 4C00h
	int 21h ;return 0
end start
