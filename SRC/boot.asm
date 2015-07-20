	org	07c00h
	mov 	ax,	cs
	mov 	ds,	ax
	mov 	es,	ax
	call 	DispStr
	jmp 	$				;$= current address

DispStr:
	mov 	ax,	BootMessage 		;move the start address of BootMessage to ax
	mov 	bp,	ax			
	mov 	cx,	16			;length
	mov 	ax,	01301h			
	mov 	bx,	000ch	
	mov 	dl, 	0
	int 	10h				;interrupt
	ret

BootMessage: 			db 	"Hello,OS World!"	;string

times 		510- ($- $$)	db	0	;$$= start address
dw 		0xaa55				;End