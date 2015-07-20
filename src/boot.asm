;%define	_BOOT_DEBUG_	; 做 Boot Sector 时一定将此行注释掉!将此行打开后用 nasm Boot.asm -o Boot.com 做成一个.COM文件易于调试

%ifdef	_BOOT_DEBUG_
	org  			0100h			; 调试状态, 做成 .COM 文件, 可调试
%else
	org  			07c00h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
%endif

;====================================================================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack			equ	0100h	; 调试状态下堆栈基地址(栈底, 从这个位置向低地址生长)
%else
BaseOfStack			equ	07c00h	; 堆栈基地址(栈底, 从这个位置向低地址生长)
%endif

BaseOfLoader			equ	09000h	; LOADER.BIN 被加载到的位置 ----  段地址
OffsetOfLoader			equ	0100h	; LOADER.BIN 被加载到的位置 ---- 偏移地址
RootDirSectors			equ	14	; 根目录占用空间
SectorNoOfRootDirectory	equ	19	; Root Directory 的第一个扇区号
;====================================================================================================================

	jmp short LABEL_START	
	nop
	BS_OEMName		DB 	'S;G     '		; OEM String,
	BPB_BytsPerSec		DW 	512			; 每扇区字节数
	BPB_SecPerClus		DB 	1			; 每簇多少扇区
	BPB_RsvdSecCnt	DW 	1			; Boot 记录占用多少扇区
	BPB_NumFATs		DB 	2			; 共有多少 FAT 表
	BPB_RootEntCnt	DW 	224			; 根目录文件数最大值
	BPB_TotSec16		DW 	2880		; 逻辑扇区总数
	BPB_Media		DB 	0xF0		; 媒体描述符
	BPB_FATSz16		DW 	9			; 每FAT扇区数
	BPB_SecPerTrk		DW 	18			; 每磁道扇区数
	BPB_NumHeads	DW 	2			; 磁头数(面数)
	BPB_HiddSec		DD 	0			; 隐藏扇区数
	BPB_TotSec32		DD 	0			; wTotalSectorCount为0时这个值记录扇区数
	BS_DrvNum		DB 	0			; 中断 13 的驱动器号
	BS_Reserved1		DB 	0			; 未使用
	BS_BootSig		DB 	29h			; 扩展引导标记 (29h)
	BS_VolID		DD 	0			; 卷序列号
	BS_VolLab		DB 	'FG204      '	; 卷标, 必须 11 个字节
	BS_FileSysType		DB 	'FAT12   '		; 文件系统类型, 必须 8个字节  

;====================================================================================================================
LABEL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	xor	ah, ah	; `.
	xor	dl, dl	;  |  软驱复位
	int	13h	; /

;Search loader.bin
	mov 	word[wSectorNo],	SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp 	word [wRootDirSizeForLoop],	0
	jz 	LABEL_NO_LOADERBIN
	dec 	word [wRootDirSizeForLoop]
	mov 	ax,	BaseOfLoader
	mov 	es,	ax
	mov 	bx,	OffsetOfLoader	
	mov 	ax,	[wSectorNo]
	mov 	cl,	1
	call 	ReadSector

	mov 	si,	LoaderFileName
	mov 	di,	OffsetOfLoader	
	cld
	mov 	dx,	10h

LABEL_SEARCH_FOR_LOADERBIN:
	cmp 	dx,	0
	jz 	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec 	dx
	mov 	cx, 	11

LABEL_CMP_FILENAME:
	cmp 	cx, 	0
	jz 	LABEL_FILENAME_FOUND
	dec 	cx
	lodsb
	cmp 	al, 	byte[es:di]
	jz 	LABEL_GO_ON
	jmp 	LABEL_DIFFERENT

LABEL_GO_ON:
	inc 	di
	jmp 	LABEL_CMP_FILENAME

LABEL_DIFFERENT:
	and 	di,	0FFE0h
	add 	di,	20h
	mov 	si,	LoaderFileName
	jmp 	LABEL_SEARCH_FOR_LOADERBIN	
	
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add 	word[wSectorNo],	1
	jmp 	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov 	dh,	2
	call 	Dispstr
%ifdef 	_BOOT_DEBUG_
	mov 	ax,	4c00h
	int 	21h
%else 
	jmp 	$
%endif

LABEL_FILENAME_FOUND:
	jmp 	$


wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数，
						; 在循环中会递减至零
wSectorNo		dw	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数

;字符串
LoaderFileName		db	"LOADER  BIN", 0 ; LOADER.BIN 之文件名
; 为简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
BootMessage		db	"Booting  " ; 9字节, 不够则用空格补齐. 序号 0
Message1		db	"Ready.   " ; 9字节, 不够则用空格补齐. 序号 1
Message2		db	"No LOADER" ; 9字节, 不够则用空格补齐. 序号 2

Dispstr:
	mov 	ax,	MessageLength	
	mul 	dh
	add 	ax,	BootMessage
	mov 	bp,	ax
	mov 	ax,	ds
	mov 	es,	ax
	mov 	cx,	MessageLength	
	mov 	ax,	01301h
	mov 	bx, 	0007h
	mov 	dl,	0
	int 	10h
	ret

ReadSector:
	push 	bp
	mov 	bp,	sp
	sub 	esp,	2

	mov 	byte	[bp- 2],	cl
	push 	bx
	mov 	bl,	[BPB_SecPerTrk]
	div 	bl
	inc 	ah
	mov 	cl, 	ah
	mov 	dh,	al
	shr 	al,	1
	mov 	ch,	al
	and	dh,	1
	pop 	bx
	;get all
	mov 	dl,	[BS_DrvNum]

.GoOnReading:
	mov 	ah,	2
	mov 	al,	byte	[bp- 2]
	int 	13h
	jc 	.GoOnReading

	add 	esp,	2
	pop 	bp

	ret

times 	510-($-$$)		db 0			; 填充剩下的空间，使生成的二进制代码恰好为512字节
				dw 0xaa55		; 结束标志