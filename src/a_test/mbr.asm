; 显卡字符发生器 起始内存地址0xb800  每两个字节定义一个字符  低地址是ASCII码高地址是字符颜色属性
[bits 16]

            app_lba_start equ 100
SECTION mbr align=16 vstart=0x7c00

            mov ax,0
            mov ss,ax
            mov sp,ax

            mov ax,[cs:phy_base]
            mov dx,[cs:phy_base+2]
            mov bx,16
            div bx
            mov ds,ax
            mov es,ax


            xor di,di
            mov si,app_lba_start
            xor bx,bx
            call read_hard_disk_0
            
            mov dx,[2]
            mov ax,[0]
            mov bx,512
            div bx
            cmp dx,0
            jnz add_1
            jmp sub_1
add_1:      inc ax
sub_1:      dec ax ;ax 中记录了剩余要读取的数量
            cmp ax,0
            je set_app

            mov cx,ax
            xor di,di
            mov si,app_lba_start+1
            mov bx,512
readLoop:
        call read_hard_disk_0
        inc si
        add bx,512
        loop readLoop


set_app:
        mov dx,[0x08]
        mov ax,[0x06]
        call calc_segment_forApp
        mov word [0x06],ax

        mov cx,[0x0a]                   ;需要重定位的项目数量
        mov bx,0x0c                     ;重定位表首地址
        cmp cx,0
        je enter_app

calc_otherSegment:
        mov ax,[bx]
        mov dx,[bx+2]
        call calc_segment_forApp
        mov word [bx],ax
        add bx,4
        loop calc_otherSegment

enter_app:
        jmp far [0x04] ;enter app's code_entry

calc_segment_forApp:  ;传入 dx:ax 32位 返回ax
        push dx
        add ax,[cs:phy_base]
        adc dx,[cs:phy_base+2]
        ; 将 dx:ax 32位 数右移4位 就是段地址
        shr ax,4
        ; shl dx,12
        ror dx,4 ;循环右移
        and dx,1111_0000_0000_0000b;保留高4位
        or ax,dx

        pop dx
        ret


read_hard_disk_0:   ;   输入：DI:SI=起始逻辑扇区号 
                    ;   DS:BX=目标缓冲区地址
            push ax
            push bx
            push cx
            push dx
            
            mov dx,0x1f2 ;扇区数量端口
            mov ax,1
            out dx,al

            ; out lba number
            inc dx
            mov ax,si
            out dx,al

            inc dx
            mov al,ah
            out dx,al

            inc dx
            mov ax,di
            out dx,al

            inc dx
            mov al,ah
            or al,1110_0000b;LBA28模式，主盘
            out dx,al

            inc dx ;commond and state port 0x1f7  8 bits port
            mov al,0x20 ; read
            out dx,al
    waitState:       
            in al,dx
            and al,1000_1000b
            cmp al,0000_1000b
            jnz waitState

            mov cx,256
            mov dx,0x1f0 ;data port 16 bits port
    readWord:   
            in ax,dx
            mov [bx],ax
            add bx,2
            loop readWord

            pop dx
            pop cx
            pop bx
            pop ax

            ret


            jmp near $
phy_base:   dd 0x10000             ;用户程序被加载的物理起始地址


            times 510-($-$$) db 0
            db 0x55,0xaa