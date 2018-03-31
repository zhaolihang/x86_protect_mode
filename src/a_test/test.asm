; 显卡字符发生器 起始内存地址0xb800  每两个字节定义一个字符  低地址是ASCII码高地址是字符颜色属性
[bits 16]

            jmp near start
message:    db '1+2+3+...+100='
messageEnd: 
start:
            mov ax,0x7c00>>4
            mov ds,ax

            mov ax,0xb800
            mov es,ax

            mov si,message
            xor di,di
            mov cx,messageEnd-message

showMes:    mov al,[si]
            mov [es:di],al
            inc di
            mov byte [es:di],0x07
            inc di
            inc si
            loop showMes

            xor ax,ax
            mov cx,1
calc:       
            add ax,cx ;结果存放在ax中
            inc cx
            cmp cx,100
            jle calc ;<=


            xor cx,cx;set ss
            mov ss,cx
            mov sp,cx

            mov bx,10
            xor cx,cx
calcNum:
            inc cx
            xor dx,dx
            div bx
            or dl,0x30; 0011_0000 or 0000_00xx  ===  0000_00xx + 0011_0000
            push dx  ; no push dl 
            cmp ax,0
            jne calcNum

            ;loop cx times
showNum:
            pop dx
            mov [es:di],dl
            inc di
            mov byte [es:di],0x07
            inc di
            loop showNum


            jmp near $
            db 0,0,0,0,0
            times 510-($-$$) db 0
            db 0x55,0xaa