

SECTION mbr align=16 vstart=0
            [bits 16]
            core_base_address equ 0x00040000   ;常数，内核加载的起始内存地址 
            core_start_sector equ 0x00000001   ;常数，内核的起始逻辑扇区号
            mov eax,0
            mov es,eax
            mov ds,eax
            mov ss,eax
            mov sp,0x7c00

            mov eax,[es:gdt_p+0x7c00+2]
            shr eax,4
            mov ds,eax

            ; first null gdt
            ; mov dword [0x00],0x00
            ; mov dword [0x04],0x00

            mov dword [0x08],0x0000ffff ;数据段 粒度4k 0~4GB线性空间 
            mov dword [0x0c],0x00cf9200  

            ; this code segment
            mov dword [0x10],0x7c0001ff    ;基地址为0x00007c00，512字节 
            mov dword [0x14],0x00409800    ;粒度为1个字节，代码段描述符 

            ;stack segment  0x7c00 
            mov dword [0x18],0x7c00fffe
            mov dword [0x1c],0x00cf9600

            ;建立保护模式下的显示缓冲区描述符   
            mov dword [ebx+0x20],0x80007fff    ;基地址为0x000B8000，界限0x07FFF 
            mov dword [ebx+0x24],0x0040920b    ;粒度为字节

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
            ;dword 说明偏移量是32位 由于这条代码是在16位模式下编译的所以有后缀0x66,因为cs高速缓存寄存器中的D位是0代表16位，所以在16位保护模式下执行
            ;已经进入了保护模式所以段前缀表示段选择子 1号段即当前代码段 进行跳转的目的是刷新代码段寄存器缓存，清空流水线 
            jmp dword 0_0000_0000_0010_000b:flush  ;加载第2号段

            [bits 32]
flush:
_32Start:;以下代码是在32位模式下运行的
            ;设置 数据段指向 0~4GB的空间
            mov eax,0_0000_0000_0001_000b ;加载第1号段
            mov ds,eax

            mov eax,0_0000_0000_0011_000b ;加载第4号段 stack segment
            mov ss,eax
            xor esp,esp

            mov edi,core_base_address

            mov eax,core_start_sector
            mov ebx,edi
            call read_hard_disk_0

            ;解析内核头信息
            mov eax,[edi];core length
            xor edx,edx
            mov ecx,512
            div ecx

            or edx,edx
            jz subOne
addOne:     inc eax
subOne:     dec eax
            or eax,eax
            jz setupCore

            mov ecx,eax
            mov eax,core_start_sector+1
readNext:   
            call read_hard_disk_0
            inc eax
            loop readNext

setupCore:
            mov esi,[0x7c00+gdt_p+0x02]      ;不可以在代码段内寻址pgdt，但可以通过4GB的段来访问
            ;esi gdt起始内存地址
            ;edi 内核起始内存地址

            sys_routine_seg_start_offset equ 0x04
            sys_routine_seg_length_offset equ 0x08
            ;建立公用例程段描述符
            mov ebx,[edi+sys_routine_seg_length_offset]
            dec ebx                            ;公用例程段界限
            mov eax,[edi+sys_routine_seg_start_offset]
            add eax,edi;公用例程段基地址
            mov ecx,0x00409800                 ;字节粒度的代码段描述符
            call make_gdt_descriptor
            mov [esi+0x28],eax
            mov [esi+0x2c],edx
        
            core_data_seg_start_offset equ 0x0c
            core_data_seg_length_offset equ 0x10
            ;建立核心数据段描述符
            mov ebx,[edi+core_data_seg_length_offset]
            dec ebx                            ;核心数据段界限
            mov eax,[edi+core_data_seg_start_offset]
            add eax,edi;核心数据段基地址
            mov ecx,0x00409200                 ;字节粒度的数据段描述符 
            call make_gdt_descriptor
            mov [esi+0x30],eax
            mov [esi+0x34],edx
        
            core_code_seg_start_offset equ 0x14
            core_code_seg_length_offset equ 0x18
            ;建立核心代码段描述符
            mov ebx,[edi+core_code_seg_length_offset]
            dec ebx                            ;核心代码段界限
            mov eax,[edi+core_code_seg_start_offset]
            add eax,edi;核心代码段基地址
            mov ecx,0x00409800                 ;字节粒度的代码段描述符
            call make_gdt_descriptor
            mov [esi+0x38],eax
            mov [esi+0x3c],edx

            mov word [0x7c00+gdt_p],63          ;描述符表的界限
                                            
            lgdt [0x7c00+gdt_p]                  

            jmp far [edi+0x1c];间接远调用 进入内核
;-------------------------------------------------------------------------------
read_hard_disk_0:                        ;从硬盘读取一个逻辑扇区
                                         ;EAX=逻辑扇区号
                                         ;DS:EBX=目标缓冲区地址
                                         ;返回：EBX=EBX+512
            push eax 
            push ecx
            push edx
        
            push eax
            
            mov dx,0x1f2
            mov al,1
            out dx,al                       ;读取的扇区数

            inc dx                          ;0x1f3
            pop eax
            out dx,al                       ;LBA地址7~0

            inc dx                          ;0x1f4
            mov cl,8
            shr eax,cl
            out dx,al                       ;LBA地址15~8

            inc dx                          ;0x1f5
            shr eax,cl
            out dx,al                       ;LBA地址23~16

            inc dx                          ;0x1f6
            shr eax,cl
            or al,0xe0                      ;第一硬盘  LBA地址27~24
            out dx,al

            inc dx                          ;0x1f7
            mov al,0x20                     ;读命令
            out dx,al

.waits:
            in al,dx
            and al,0x88
            cmp al,0x08
            jnz .waits                      ;不忙，且硬盘已准备好数据传输 

            mov ecx,256                     ;总共要读取的字数
            mov dx,0x1f0
.readw:
            in ax,dx
            mov [ebx],ax
            add ebx,2
            loop .readw

            pop edx
            pop ecx
            pop eax
        
            ret



;-------------------------------------------------------------------------------
make_gdt_descriptor:                     ;构造描述符
                                         ;输入：EAX=线性基地址
                                         ;      EBX=段界限
                                         ;      ECX=属性（各属性位都在原始
                                         ;      位置，其它没用到的位置0） 
                                         ;返回：EDX:EAX=完整的描述符
         mov edx,eax
         shl eax,16                     
         or ax,bx                        ;描述符前32位(EAX)构造完毕
      
         and edx,0xffff0000              ;清除基地址中无关的位
         rol edx,8
         bswap edx                       ;装配基址的31~24和23~16  (80486+)
      
         xor bx,bx
         or edx,ebx                      ;装配段界限的高4位
      
         or edx,ecx                      ;装配属性 
      
         ret

gdt_p:  
            dw 0
            dd 0x00007e00

            times 510-($-$$) db 0
            db 0x55,0xaa