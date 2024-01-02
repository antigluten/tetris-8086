.model small
.stack 100h
;.386

.data
message BYTE "Hello World",0dh,0ah,0

.code
main PROC
	mov ax,@data
	mov ds,ax

	mov ah,40h            ; write to device
	mov bx,1              ; output handle
	mov cx,SIZEOF message ; size in bytes of message
	mov dx,OFFSET message ; address of buffer
	int 21h

	.exit
main ENDP
END main
