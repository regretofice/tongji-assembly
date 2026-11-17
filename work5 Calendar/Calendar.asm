assume ss:stack,ds:data
data segment 
        year_msg db 'PLEASE INPUT YEAR (1900-2099): $'
        month_msg db 'PLEASE INPUT MONTH (1-12): $'
        crlf db 0dh, 0ah, '$'   ;回车换行符
        input_buf db 5, 0, 6 dup('$')   ;DOS 输入缓冲区结构
        n_year dw 0
        n_month dw 0
        top_bar db 'Su Mo Tu We Th Fr Sa',0dh, 0ah, '$'
        ;可以用类似指针方式进行调用
        m1  db 'January$'
        m2  db 'February$'
        m3  db 'March$'
        m4  db 'April$'
        m5  db 'May$'
        m6  db 'June$'
        m7  db 'July$'
        m8  db 'August$'
        m9  db 'September$'
        m10 db 'October$'
        m11 db 'November$'
        m12 db 'December$'
        month_table dw m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12
        day_table dw 31,28,31,30,31,30,31,31,30,31,30,31
        shift db 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4
data ends

stack segment
        dw 100 dup(0)
stack ends

code segment 
        assume cs:code
begin:
        mov    ax,data
        mov    ds,ax
        mov    ax,stack
        mov    ss,ax
        mov    sp,200

        call   get_input

        call   print_bar

        call   print_calendar

        mov    ax,4c00h
        int    21h

        get_num proc
                ;==========================
                ;允许用户输入一个4位十进制数字，并将结果存储到ax寄存器，输入非数字字符则返回-1
                ;======================
                lea  dx,input_buf
                mov  ah,0ah
                int  21h

                ;输出一次换行，防止原本的输出被新输出覆盖
                lea  dx, crlf
                mov  ah, 9
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
                cmp  bl,'0'
                jb   read_error ;检查输入错误
                cmp  bl,'9'
                ja   read_error
                sub  bl,'0'

                inc  si
                mul  bp
                add  ax,bx
                loop read_loop

read_end:
                ret  
read_error:
                mov  ax,-1
                ret  

        get_num endp

        get_input proc
;==========================
;输出提示词，并读取合法输入，不合法则一直询问，年月存入对应的内存中
;======================
get_year:
                lea  dx,year_msg
                mov  ah,9
                int  21h
                call get_num
                cmp  ax,1900
                jb   get_year
                cmp  ax,2099
                ja   get_year     ;不合法则一直询问
                mov  ds:[n_year],ax  ;存储到内存中
get_month:
                lea  dx,month_msg
                mov  ah,9
                int  21h
                call get_num
                cmp  ax,1
                jb   get_month
                cmp  ax,12
                ja   get_month     ;不合法则一直询问,如果是-1，则会在这里才跳转，因为用的是无符号比较
                mov  ds:[n_month],ax  ;存储到内存中

                ret  
        get_input endp 
        print_num proc
                push ax
                push bx
                push cx
                push dx
                ;==========================
                ;从ax传入参数，并输出这个十进制数字，会使用到栈进行中转
                ;======================

                cmp  ax,10
                jae  divide      ;如果是两位数，就不输出空格了
                push ax
                mov  dl,' '
                mov  ah, 02h
                int  21h         ;输出一个空格
                pop  ax
divide:
                mov  bx,10
                xor  cx,cx          ;清空当前的cx,将要用来记录当前数字共有多少位
divide_loop:
                xor  dx,dx          ;清空dx,防止前一轮除法的结果影响运算
                div  bx             
                push dx
                inc  cx
                test ax,ax          ;相当于cmp ax,0但是字节开销更小
                jnz  divide_loop

print:
                pop  dx
                add  dl,'0'
                mov  ah, 02h
                int  21h         ;输出字符
                loop print

                mov  dl,' '
                mov  ah, 02h
                int  21h         ;输出数字完成后再一个空格用于对齐
                pop  dx
                pop  cx
                pop  bx
                pop  ax
                ret  
        print_num endp

        print_bar proc
                push ax
                push bx
                push cx
                push dx

                lea  dx, crlf       ;输出一次换行,便于观察
                mov  ah, 9
                int  21h

                mov  ax,ds:[n_year]
                call print_num

                mov  ax, ds:[n_month]
                dec  ax
                shl  ax, 1           ;乘以 2,因为month_table是dw
                mov  bx, ax
                mov  dx, [month_table + bx] ;从表里取地址
                mov  ah, 09h
                int  21h

                lea  dx, crlf       ;输出一次换行,便于观察
                mov  ah, 9
                int  21h

                lea  dx, top_bar       
                mov  ah, 9
                int  21h

                pop  dx
                pop  cx
                pop  bx
                pop  ax

                ret  
        print_bar endp

        print_blank proc
                ;=====================
                ;输出三个空格，便于对齐
                ;==========================
                push cx
                mov  cx,3
blank_loop:
                mov  dl,' '
                mov  ah, 02h
                int  21h         ;输出一个空格
                loop blank_loop

                pop  cx
                ret  
        print_blank endp

        print_calendar proc

                ;==================
                ;对齐输出完整日历
                ;=======================
                push ax
                push bx
                push cx
                push dx
                push si
                push di

                mov  di,ds:[n_year]
                mov  bx,ds:[n_month]
                ;先算这个月有多少天
                dec  bx
                shl  bx,1
                mov  si,ds:[day_table+bx]   ;si存储当前月份的天数

                mov  bx,ds:[n_month]    ;计算当前是不是闰月
                cmp  bx,2 
                jnz  not_leap_year      ;不是2月就不考虑闰年

                mov  ax,di
                mov  cx,4
                xor  dx,dx
                div  cx
                test dx,dx              ;dx存储的是余数
                jnz  not_leap_year       ;被4除，余数不为0，不是闰年

                mov  ax,di
                mov  cx,400
                xor  dx,dx
                div  cx
                test dx,dx              ;dx存储的是余数
                jz   leap_year       ;能被400整除，是闰年

                ;剩下的是能被4整除，并且不是400倍数的年份
                mov  ax,di
                mov  cx,100
                xor  dx,dx
                div  cx
                test dx,dx              ;dx存储的是余数
                jz   not_leap_year       ;能被100整除，不是闰年
;剩下的都是闰年，直接顺着行动
leap_year:
                ;闰年的二月加一天
                inc  si
not_leap_year:
                mov  ax,di
                mov  bx,ds:[n_month]
                call far ptr Sakamoto
                mov  cx,ax              ;cx=ax的值说明需要输出多少次空格进行占位(第一天的日期)
                ;下面这句不能放在pre_blank下方，由于print_blank会清空ax
                mov  di,ax               ;现在开始，di变为存储已经输出的次数，每逢7换一次行
                test cx,cx
                jz   no_blank              ;有可能不需要输出空格
pre_blank:
                call print_blank
                loop pre_blank

no_blank:
                mov  bx,1

                inc  si                  ;由于break的方式，导致需要将输循环上界调整为日期+1
print_exec:
                mov  ax,bx
                call print_num
                inc  bx
                inc  di
                cmp  bx,si
                jz   complete             ;输出结束
                cmp  di,7
                jz   endl                 ;检查是否需要换行
                jmp  print_exec            ;都不需要则继续输出

endl:
                xor  di,di
                lea  dx, crlf       ;输出一次换行
                mov  ah, 9          ;这里会清空ax，所以得用bx进行存储当前的日期
                int  21h
                jmp  print_exec
complete:
                lea  dx, crlf       ;输出一次换行
                mov  ah, 9
                int  21h


                pop  di
                pop  si
                pop  dx
                pop  cx
                pop  bx
                pop  ax


                ret  
        print_calendar endp
code ends

calendar segment
        assume  cs:calendar

        ;==========================
        ;使用Sakamoto算法进行快速计算，通过ax(年),bx(月)进行参数的传递，最后通过ax返回计算出的日期(0是周日)
        ;======================
        Sakamoto proc far
                push bx
                push cx
                push dx
                push di


                cmp  bx,2
                ja   greater_3        ;若月份<3，则年份减1，以避免闰日提前计入
                dec  di
greater_3:
                ;(y + y/4 - y/100 + y/400 + t[m-1] + d) % 7,如果是1号则d=1
                dec  bx 
                mov  cl,ds:[shift+bx]   ;ans=t[m-1]
                xor  ch,ch
                inc  cx                 ;ans+=d

                add  cx,di       ;ans+=y

                xor  dx,dx
                mov  ax,di
                mov  bx,4           
                div  bx
                add  cx,ax      ;ans+=y/4

                xor  dx,dx
                mov  ax,di
                mov  bx,100           
                div  bx
                sub  cx,ax      ;ans-=y/100

                xor  dx,dx
                mov  ax,di
                mov  bx,400           
                div  bx
                add  cx,ax      ;ans+=y/400

                mov  ax,cx    
                xor  dx,dx
                mov  bx,7           
                div  bx         ;ans/=7，余数在dx
                mov  ax,dx      ;结果存储到ax中

                pop  di
                pop  dx
                pop  cx
                pop  bx      
                ret  
        Sakamoto endp

calendar ends
        end begin 