;----------------------------------------
; Syscall constants
SYS_WRITE equ 1  ; write text to stdout
SYS_READ  equ 0  ; read text from stdin
SYS_EXIT  equ 60 ; terminate the program
STDOUT    equ 1  ; stdout
STDIN     equ 0  ; stdin

;-----------------------------------------
; Macros
%macro print 2
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro input 2
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, %1
    mov rdx, %2
    syscall
%endmacro

%macro exit 0
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
%endmacro

;--------------------------------------------
; Uninitialized variables
section .bss
    next_term: resd 1
    inp: resb 4
    terms: resd 1

    lenStr: equ 8
    intToStr: resb lenStr

;--------------------------------------------
; Initialized variables
section .data
    ; Input prompt
    prompt: db "How many terms? ", 0
    lenPrompt: equ $-prompt

    ; newline
    newline: db 0xa
    len_newline: equ $-newline

    ; Error msgs
    invalidAscii: db "Error: Invalid number entered. Only positive numberrs accepted.", 0xa
    len_invalidAscii: equ $-invalidAscii

    noTerms: db "No terms to be printed :)", 0xa
    len_noTerms: equ $-noTerms

    ; Defining the first 2 terms
    t1: dd 0
    t2: dd 1

;---------------------------------------------
; Code
section .text

;**************** Utilities ******************
;---------------------------------------------
; ASCII to integer (atoi function)
; Input       :  String-address in rdi 
; Output      :  Integer in esi
; Constraints :  Maximum length of string = 8 
atoi:
    mov rsi, 0             ; Set initial total to 0
     
.makeInt:
    movzx r8, byte [rdi]   ; Get the current character
    cmp byte [rdi + 1], 0  ; Check for \0
    je .finishedInt
    
    cmp r8, 0x30           ; Anything less than 0 is invalid
    jl .invalidAscii
    
    cmp r8, 0x39           ; Anything greater than 9 is invalid
    jg .invalidAscii
     
    sub r8, 0x30           ; Convert from ASCII to decimal 
    imul esi, 10           ; Multiply total by 10
    add esi, r8d           ; Add current digit to total
    
    inc rdi                ; Get the address of the next character
    jmp .makeInt

.invalidAscii:
    ; Print error message and exit
    print invalidAscii, len_invalidAscii
    exit
 
.finishedInt:
    xor r8, r8             ; Putting r8=0
    ret                    ; Return total or error code

;---------------------------------------------
; Integer to ASCII (itoa function)
; Input      :  Integer in rdi
; Output     :  intToStr (defined in section .bss) 
; Constraint :  Integer must be positive and can't be more than 8 digit long.
itoa:
    lea rsi, [intToStr + lenStr - 1] ; Getting the last address for the string
    mov rax, rdi                     ; Moving the dividend into rax
    mov rbx, 10                      ; rbx = 10 (divisor)

.makeStr:
    xor rdx, rdx                     ; Cleaning up rdx (remainder will be stored here)
    div rbx

    xor dl, byte 0x30                ; Integer to ASCII

    mov byte [rsi], dl               ; Putting the ASCII onto the required address.
    dec rsi                          ; Get the next address

    cmp rax, 0                       ; If the dividend = 0, then it's done.
    jz .finishedStr
    jmp .makeStr                     ; else, repeat

.finishedStr:
    ret                              ; Execution finished

;*********************************************

global _start
_start:

    ; Show prompt and get input into variable 'inp'
    print prompt, lenPrompt
    input inp, 4

    ; Converting into integer and storing in 'terms'
    mov rdi, inp
    call atoi
    mov [terms], esi

    ; Error handling for <= 1 terms asked
    cmp esi, 1
    jl noTerms_exit         ; <1 terms to be printed
    je oneterm_exit         ; print 1st term and exit

    ; Printing the first and second terms
    mov edi, [t1]
    call itoa
    print intToStr, lenStr
    print newline, len_newline

    mov edi, [t2]
    call itoa
    print intToStr, lenStr
    print newline, len_newline

    ; r8 and r9 will store the terms
    ; r10 will serve as a counter
    xor r8, r8
    xor r9, r9
    mov r10d, [terms]

    l1:
        ; If counter < 2: successfully executed
        dec r10
        cmp r10, 2
        jl  executed 

        mov r8d, [t1]         ; r8 = t1
        mov r9d, [t2]         ; r9 = t2
        add r8d, r9d          ; r8 += r9
        mov [next_term], r8d  ; next_term = r8
        
        ; Print the next_term
        mov edi, r8d
        call itoa
        print intToStr, lenStr
        print newline, len_newline

        mov [t1], r9d         ; t1 = t2
        mov [t2], r8d         ; t2 = next_term

        ; Counter >= 2: repeat
        jge l1

; Successfully executed
executed:
    exit

; <1 terms to be printed
noTerms_exit:
    print noTerms, len_noTerms
    exit

; Only 1 term to be printed
oneterm_exit:
    mov edi, [t1]
    call itoa
    print intToStr, lenStr
    print newline, len_newline
    exit