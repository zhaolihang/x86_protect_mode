

SECTION mbr align=16 vstart=0x7c00
            [bits 16]

            mov ax,0
            mov ds,ax
            mov es,ax
            ;0x7c00以下是栈段
            mov ax,0
            mov ss,ax  
            mov sp,0x7c00

            mov ax,[es:gdt_baseP]
            mov dx,[es:gdt_baseP+2]
            mov bx,16
            div bx
            mov ds,ax;set data segment

            ; first null gdt
            mov dword [0x00],0x00
            mov dword [0x04],0x00

            ;this code segment
            mov dword [0x08],0x7c0001ff ;段基址是0x7c00 
            mov dword [0x0c],0x00409800
            
            ; video segment
            mov dword [0x10],0x8000ffff     
            mov dword [0x14],0x0040920b

            ;stack segment
            mov dword [0x18],0x00007a00; 粒度=0 byte type=0010 向下拓展 基地址0x00000000 界限是0x7a00 
            mov dword [0x1c],0x00409600 ;即 0x0000ffff → 0x00007a00 属于此段

            mov word [es:gdt_baseSizeP],31 ;最大索引值 按bit计算

            lgdt [es:gdt_baseSizeP]

fastA20:    in al,0x92                         ;南桥芯片内的端口 
            or al,0000_0010B
            out 0x92,al                        ;打开A20        

            cli ;关中断

            mov eax,cr0
            or eax,0x01 ;最低位(pe) 为1 开启保护模式
            mov cr0,eax

            ;dword 说明偏移量是32位 由于这条代码是在16位模式下编译的所以有后缀0x66
            ;已经进入了保护模式所以段前缀表示段选择子 1号段即当前代码段 进行跳转的目的是刷新代码段寄存器缓存，清空流水线 
            ;由于 vstart=0x7c00 并且代码段的基址是0x7c00 所以flush-0x7c00 才是真正的偏移地址
            jmp dword 0_0000_0000_0001_000b:(flush-0x7c00)  

            [bits 32]
flush:
_32Start:;一下代码是在32位模式下运行的
            mov ax,0_0000_0000_0010_000b;加载第2号段 即显卡数据段
            mov ds,ax

            ; 在屏幕上显示字符 说明成功的进入了保护模式
            mov byte [0x00],'P'  
            mov byte [0x02],'r'
            mov byte [0x04],'o'
            mov byte [0x06],'t'
            mov byte [0x08],'e'
            mov byte [0x0a],'c'
            mov byte [0x0c],'t'
            mov byte [0x0e],' '
            mov byte [0x10],'m'
            mov byte [0x12],'o'
            mov byte [0x14],'d'
            mov byte [0x16],'e'
            mov byte [0x18],' '
            mov byte [0x1a],'O'
            mov byte [0x1c],'K'
            mov byte [0x1e],'!'
            mov byte [0x20],'!'
            mov byte [0x22],'!'
            mov byte [0x24],' '
            mov byte [0x26],' '

            ;test 32 prodect mode stack opration
            mov ax,0_0000_0000_0011_000b
            mov ss,ax
            mov esp,0x7c00

            mov eax,esp
            push byte '.'  ;压入的是字节 编译之后还是4字节的

            sub eax,4
            cmp eax,esp
            jnz infi
            pop eax
            mov byte [0x28],al
            mov byte [0x2a],' '
            mov byte [0x2c],' '

infi:       jmp near infi


gdt_baseSizeP:  
            dw 0
gdt_baseP:  
            dd 0x00007e00

            times 510-($-$$) db 0
            db 0x55,0xaa