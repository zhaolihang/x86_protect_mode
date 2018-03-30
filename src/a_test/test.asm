; 显卡字符发生器 起始内存地址0xb800  每两个字节定义一个字符  低地址是ASCII码高地址是字符颜色属性
[bits 16]

            jmp near start
mytext:     db 'L',0x07,'a',0x07,'b',0x07,'e',0x07,'l',0x07,' ',0x07,'o',0x07, \
            'f',0x07,'f',0x07,'s',0x07,'e',0x07,'t',0x07,':',0x07
mytextEnd:            
number:     db 0,0,0,0,0

start:
            mov ax,0x7c00>>4
            mov ds,ax

            mov ax,0xb800
            mov es,ax

            cld ; set DF=0 正向
            ; std ; set DF=1

            mov si,mytext
            xor di,di
            mov cx,mytextEnd-mytext
            rep movsb ;movsb 默认只能执行一次 加了rep 才能重复执行直到ZF=1

            mov bx,number

            mov ax,number
            mov cx,5
            mov si,10
digit:      xor dx,dx
            div si ; 有符号除法 idiv  cbw (covert sign_byte to sign_word)
            mov [bx],dl
            inc bx
            loop digit

            mov bx,number
            mov si,4
show:       
            mov al,[bx+si]
            add al,0x30
            mov ah,0x04
            mov word [es:di],ax
            add di,2
            dec si
            jns show  ;if SF!=1 then jmp
            ; neg ax ; 0-ax中的数

            mov byte [es:di],'D'
            mov byte [es:di+1],0x07

infi:       jmp near infi
            db 0,0,0,0,0
            times 510-($-$$) db 0
            db 0x55,0xaa