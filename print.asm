section .text

global MyPrint
global main
extern exit


;RETURN:rcx - string length
;DESTROY: RDI, AL, RCX
;ASSUME: RDI - string address
GetLength:
;                       RETURN RCX - LENGHT OF STRING
    push rbp;           PROLOG
    mov rbp, rsp

    mov rcx, rdi;       rcx - start of string (start)

    mov AL, [endChar];  al = '\0'
    repne SCASB;        rdi++ while rdi != '\0'
                        ;(rdi = start+len+1, rcx = start-(len+1))

    sub rdi, rcx;       CALCULATE STRING LENGTH
    shr rdi, 1
    dec rdi
    mov rcx, rdi

    leave
    ret

;DESTROY:
;ASSUME: RDI - string address
ParseFormat:
    push rbp;
    mov rbp, rsp

.contParsing:
    mov AL, [stopChar];     AL = '%'
    cmp BYTE [rdi], AL;     if rdi == '%' -> check specifier
    jz .getFormat

.print:
    mov rax, 1;             system call code
    mov rsi, rdi;           rsi - string to print
    mov rdi, 1;             stdout
    mov rdx, 1;             len = 1 byte

    push rcx;               save rcx
    syscall
    pop rcx

    inc rsi
    mov rdi, rsi

    LOOP .contParsing;      continue until rcx!=0

.endProg:
    leave
    ret

.getFormat:
    inc rdi;                rdi - specifier after %
    dec rcx
    mov rbx, rdi;           save rdi

    xor rax, rax;           GET SPECIFIER NUMBER
    mov AL, BYTE [rdi]
    cmp AL, [stopChar]
    je .print
    sub AL, 'a'

    lea rsi, jmpTable;      GET FUNC ADDRESS
    shl rax, 3
    add rsi, rax

    dec rcx;

    push rcx
    push rbx

    mov rcx, rsp;           save rsp

    push r8;                old stack pointer
    pop rsp

    pop r9;                 put next argument into r9
    mov r8, rsp

    mov rsp, rcx;           return rsp to its previous value

    call [rsi];             call function

    pop rbx
    pop rcx

    cmp rcx, 0
    jz .endProg

    inc rbx
    mov rdi, rbx
    jmp .contParsing


MyPrint:
    pop rax;            save retrun address

    push r9;            pushing arguments on to the stack (all arguments
    push r8;            are stored in the stack)
    push rcx
    push rdx
    push rsi

    mov r8, rsp;        r8 pointer to the arguments in stack
    push rax

    push rbp;
    mov rbp, rsp;

    mov rbx, rdi;       save rdi, rsi, rdx, rcx, r8, r9

    call GetLength;     rcx - string length

    mov rdi, rbx
    call ParseFormat

    leave
    ret

;ASSUME: number stores in r9
;DESTROY: rax, rdi, rsi, rdx, rdx
DoBin:
    push rbp
    mov rbp, rsp

    mov rax, 1;             syscall number
    mov rdi, 1;             stdout
    mov rdx, 1;             string length
    lea rsi, [freeChar];    string address

    push rcx;               SKIP ZEROS
    mov rcx, 64
.skipZeros:
    shl r9, 1
    setc [freeChar]
    cmp BYTE [freeChar], 0
    LOOPE .skipZeros
    inc rcx

.printBin:;                 PRINT BIN NUMBER
    add BYTE [freeChar], 30h

    push rcx
    syscall
    pop rcx

    shl r9, 1
    setc [freeChar]
    LOOP .printBin

    pop rcx
    leave 
    ret


DoChar:
    push rbp
    mov rbp, rsp

    mov [freeChar], r9
    mov rax, 1
    mov rdi, 1
    lea rsi, [freeChar]
    mov rdx, 1
    syscall

    leave
    ret

DoDigit:
    push rbp
    mov rbp, rsp

    mov rcx, maxDec;            max digit = 2^64 - 1 -> len digit < 20
    
    mov rax, r9;                get mod r9 mod 10, store it in memory
    mov rbx, 10;                print numbers in reverse order
    lea rsi, [decimal]
.divLoop:
    cdq
    div rbx
    add DX, 30h
    mov [rsi], DX
    inc rsi
    xor rdx,rdx
    LOOP .divLoop

    mov rcx, maxDec
.skipZeros:
    dec rsi
    mov AL, [rsi]
    cmp AL, 30h 
    LOOPE .skipZeros
    inc rcx

.printDigit:
    push rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    push rcx
    syscall
    pop rcx
    pop rsi
    dec rsi
    LOOP .printDigit

    leave
    ret

DoString:
    push rbp;
    mov rbp, rsp;

    mov rdi, r9;            system write function
    call GetLength

    mov rax, 1
    mov rdi, 1
    mov rsi, r9
    mov rdx, rcx

    syscall

    leave 
    ret

DoOct:
    push rbp;
    mov rbp, rsp

    mov rax, 1;             syscall number
    mov rdi, 1;             stdout
    mov rdx, 1;             string length
    lea rsi, [decimal];     string address

    mov rcx, maxOct;        max bin length = 64 -> max oct len = 64/3 = 22
.divLoop:
    mov rbx, 7;             111b
    and rbx, r9
    shr r9, 3
    add rbx, 30h 
    mov [rsi], rbx
    inc rsi
    LOOP .divLoop

    mov rcx, maxOct
.skipZeros:
    dec rsi
    cmp BYTE [rsi], 30h 
    LOOPE .skipZeros

    inc rcx

.printOct:
    push rcx
    syscall
    pop rcx

    dec rsi
    LOOP .printOct

    leave
    ret

Dohex:
    push rbp;
    mov rbp, rsp

    mov rax, 1;             syscall number
    mov rdi, 1;             stdout
    mov rdx, 1;             string length
    lea rsi, [decimal];     string address

    mov rcx, maxHex
.divLoop:
    mov rbx, 15;             1111b
    and rbx, r9
    shr r9, 4
    cmp rbx, 10
    jb .number
    sub rbx, 10
    add rbx, 41h 
    jmp .next
.number:
    add rbx, 30h
.next:
    mov [rsi], rbx
    inc rsi
    LOOP .divLoop

    mov rcx, maxHex
.skipZeros:
    dec rsi
    cmp BYTE [rsi], 30h
    LOOPE .skipZeros

    inc rcx

.printHex:
    push rcx
    syscall
    pop rcx

    dec rsi
    LOOP .printHex

    leave
    ret



section .data
    maxBin equ 64

    maxOct equ 22

    maxDec equ 20

    maxHex equ 16

    stopChar db 25h

    endChar db 0h

    freeChar db 0

    decimal db 22 dup(0)


section .rodata
    alignb 8

    jmpTable:
        dq 0,
        dq DoBin,
        dq DoChar,
        dq DoDigit,
        dq 10 dup(0),
        dq DoOct,
        dq 3 dup(0),
        dq DoString,
        dq 4 dup(0),
        dq Dohex

