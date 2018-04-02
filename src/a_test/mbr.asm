

SECTION mbr align=16 vstart=0
            [bits 16]
            mov eax,0
            mov es,eax
            mov ds,eax

            mov eax,[es:gdt_p+0x7c00+2]
            shr eax,4
            mov ds,eax

            ; first null gdt
            mov dword [0x00],0x00
            mov dword [0x04],0x00

            mov dword [0x08],0x0000ffff ;数据段 粒度4k 0~4GB线性空间 
            mov dword [0x0c],0x00cf9200  

            ; code segment
            mov dword [0x10],0x7c0001ff    ;基地址为0x00007c00，512字节 
            mov dword [0x14],0x00409800    ;粒度为1个字节，代码段描述符 
            
            ;创建以上代码段的别名描述作为数据段
            mov dword [0x18],0x7c0001ff    ;基地址为0x00007c00，512字节
            mov dword [0x1c],0x00409200    ;粒度为1个字节，数据段描述符

            ;stack segment  0x7c00 
            mov dword [0x20],0x7c00fffe
            mov dword [0x24],0x00cf9600

            mov word [es:gdt_p+0x7c00],5*8-1 ;最大索引值 按bit计算

            lgdt [es:gdt_p+0x7c00]

fastA20:    in al,0x92                         ;南桥芯片内的端口 
            or al,0000_0010B
            out 0x92,al                        ;打开A20        

            cli ;关中断

            mov eax,cr0
            or eax,0x01 ;最低位(pe) 为1 开启保护模式
            mov cr0,eax

            ;这条代码在流水线中所以才能正确的执行
            ;dword 说明偏移量是32位 由于这条代码是在16位模式下编译的所以有后缀0x66
            ;已经进入了保护模式所以段前缀表示段选择子 1号段即当前代码段 进行跳转的目的是刷新代码段寄存器缓存，清空流水线 
            jmp dword 0_0000_0000_0010_000b:flush  ;加载第2号段

            [bits 32]
flush:
_32Start:;一下代码是在32位模式下运行的
            mov eax,0_0000_0000_0011_000b;加载第3号段
            mov ds,eax

            ;设置 数据段指向 0~4GB的空间
            mov eax,0_0000_0000_0001_000b ;加载第1号段
            mov es,eax
            mov fs,eax
            mov gs,eax

            mov eax,0_0000_0000_0100_000b ;加载第4号段 stack segment
            mov ss,eax
            xor esp,esp

            mov byte [es:0x0b8000+0x00],'P'  
            mov byte [es:0x0b8000+0x02],'r'
            mov byte [es:0x0b8000+0x04],'o'
            mov byte [es:0x0b8000+0x06],'t'
            mov byte [es:0x0b8000+0x08],'e'
            mov byte [es:0x0b8000+0x0a],'c'
            mov byte [es:0x0b8000+0x0c],'t'
            mov byte [es:0x0b8000+0x0e],' '
            mov byte [es:0x0b8000+0x10],'m'
            mov byte [es:0x0b8000+0x12],'o'
            mov byte [es:0x0b8000+0x14],'d'
            mov byte [es:0x0b8000+0x16],'e'
            mov byte [es:0x0b8000+0x18],' '
            mov byte [es:0x0b8000+0x1a],'O'
            mov byte [es:0x0b8000+0x1c],'K'
            mov byte [es:0x0b8000+0x1e],'!'
            mov byte [es:0x0b8000+0x20],'!'
            mov byte [es:0x0b8000+0x22],'!'
            mov byte [es:0x0b8000+0x24],' '
            mov byte [es:0x0b8000+0x26],' '


             ;开始冒泡排序 
            mov ecx,stringEnd-string-1              ;遍历次数=串长度-1 
@@1:
            push ecx                           ;32位模式下的loop使用ecx 
            xor bx,bx                          ;32位模式下，偏移量可以是16位，也可以 
@@2:                                      ;是后面的32位 
            mov ax,[string+bx] 
            cmp ah,al                          ;ah中存放的是源字的高字节 
            jge @@3 
            xchg al,ah 
            mov [string+bx],ax 
@@3:
            inc bx 
            loop @@2 
            pop ecx 
            loop @@1
        
            mov ecx,stringEnd-string
            xor ebx,ebx                        ;偏移地址是32位的情况 
@@4:                                      ;32位的偏移具有更大的灵活性
            mov ah,0x07
            mov al,[string+ebx]
            mov [es:0xb80a0+ebx*2],ax          ;演示0~4GB寻址。
            inc ebx
            loop @@4

infi:       jmp near infi
string:      db 's0ke4or92xap3fv8giuzjcy5l1m7hd6bnqtw.'
stringEnd:
gdt_p:  
            dw 0
            dd 0x00007e00

            times 510-($-$$) db 0
            db 0x55,0xaa