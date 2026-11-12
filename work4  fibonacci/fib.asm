assume cs:code,ds:data,ss:stack

data segment
    fib db 2222 dup(0) ;存储格式: 第0位存储当前是否被计算，后21位倒序存储数值
    welcome_msg db 'please enter a decimal number between 0 and 100',0dh,0ah,'$'
    result_msg  db 'The value of that term in the Fibonacci sequence is :',0dh,0ah,'$'
    input_buf db 6, 0, 6 dup('$')   ;DOS 输入缓冲区结构
    n_val dw 0
    crlf db 0dh, 0ah, '$'   ; 新增：回车换行符
data ends

stack segment
    dw 1000 dup(0) ;最多需要1200字节
stack ends



code segment
begin:
    mov  ax,data
    mov  ds,ax
    mov  ax,stack
    mov  ss,ax
    mov  sp,2000

    lea  dx,welcome_msg
    mov  ah,9
    int  21h

    call read_proc

    ;初始化fib(0),fib(1)
    mov  byte ptr ds:[fib],1        ;fib(0)标志 = 1，值全 0
    mov  byte ptr ds:[fib+22],1     ;fib(1)标志 = 1
    mov  byte ptr ds:[fib+23],1     ;fib(1)的值 = 1(最低位在 +23)

    ;传入参数
    push ds:[n_val]

    call fib_fun

    call print_res 


    mov  ax,4c00h
    int  21h

    read_proc proc
        ;==========================
        ;直接读取完整的数字，并转换为10进制数字，存储到n_val(max=65535)
        ;======================

        lea  dx,input_buf
        mov  ah,0ah
        int  21h

        xor  ax,ax      ;后续用不到符号位，所以可以使用xor进行清空
        xor  bx,bx
        lea  si,input_buf+2
        mov  bp, 10      ; 乘数放BP,防止dx被mul破坏
        mov  cl,ds:[input_buf+1]
        xor  ch,ch      

        cmp  cx,0
        jz   read_end    ;防止不输入任何数字
read_loop:
        mov  bl,ds:[si]
        sub  bl,'0'
        inc  si
        mul  bp
        add  ax,bx
        loop read_loop

read_end:
        mov  ds:[n_val],ax

        ;输出一次换行，防止原本的输出被新输出覆盖
        lea  dx, crlf
        mov  ah, 9
        int  21h

        ret  
    read_proc endp

    fib_fun proc
        ;==========================
        ;读取栈顶的参数，计算出fib(n)
        ;======================

        push bp         ; 保存旧的 bp
        mov  bp, sp     ; 此时 bp 指向栈顶
        push ax
        push bx
        push di
        push si
        ; 当前栈里的结构:
        ; SS:[bp + 0] = 旧的bp
        ; SS:[bp + 2] = 返回地址(IP)
        ; SS:[bp + 4] = 参数n

        ;先检查当前fib(n)是否已被计算
        mov  ax,ss:[bp+4]
        mov  bx,22
        mul  bx         ;乘积最大不超过2200，一个ax装得下
        mov  bx,ax      ; bx = ax = n * 22
        cmp  byte ptr ds:[bx],0
        jnz  fib_end    ;当前参数的结果已经计算过了

        mov  ax,ss:[bp+4]
        dec  ax
        push ax
        call fib_fun    ;求解fib(n-1)
        pop  ax
        dec  ax
        push ax
        call fib_fun    ;求解fib(n-2)
        pop  ax

        mov  byte ptr ds:[bx],1     ;标记当前fib(n)已经计算
        mov  si,bx
        mov  cx,22
        sub  si,cx
        mov  di,si
        sub  di,cx
        dec  cx                     ;只需要循环21次
        mov  dl,10
        mov  dh,0                   ;dh存储进位

calc_fib:
        inc  bx
        inc  di
        inc  si
        mov  ah,ds:[di]
        mov  al,ds:[si]
        add  ah,al
        add  ah,dh                  ;加上进位，后续需要清空

        cmp  ah,dl                  ;与10进行比较，处理进位
        jb   less_10

        ;如果计算结果大于十，则需要进位(计算结果最大为19)
        sub  ah,10
        mov  byte ptr ds:[bx],ah
        mov  dh,1
        loop calc_fib

less_10:
        ;否则直接存储至内存中
        mov  byte ptr ds:[bx],ah
        mov  dh,0
        loop calc_fib


fib_end:
        pop  si
        pop  di
        pop  bx
        pop  ax
        pop  bp
        ret  
    fib_fun endp

    print_res proc
        ;==========================
        ;输出fib(n)，需要注意n==0的特殊情况
        ;======================
        lea  dx,result_msg
        mov  ah,9
        int  21h

        mov  ax,ds:[n_val]
        mov  bx,22
        mul  bx         ;乘积最大不超过2200，一个ax装得下
        mov  di,ax      ;di代表末尾，因为需要倒序输出
        mov  si,ax      
        add  di, 21     ;di指向最高位 n*22+21
        inc  si         ;si指向最低位 n*22+1

        mov  cx,20   ;总共有21位，先检查前20位，需要消去前导0
        mov  al,0
pre_0:
        mov  ah,ds:[di]
        cmp  ah,al
        jnz  print       ;不相等则说明前导零清除完成，当前di即为第一位有效数字
        dec  di
        loop pre_0

print:
        mov  dl,ds:[di]
        add  dl,'0'
        mov  ah,02h
        int  21h

        cmp  di,si
        je   print_end
        dec  di
        jmp  print

print_end:
        ret  

    print_res endp

code ends

    end begin