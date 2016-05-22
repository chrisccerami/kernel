BITS 64

global pop_registers_and_iret

extern interrupt_handler;
extern general_protection_fault_handler;
extern pagefault_handler;
extern keyboard_handler;

%assign i 0
%rep 256
    global interrupt_handler_%[i]
%assign i i+1
%endrep

section .interrupt_handlers

; special handlers

%macro HANDLER_WITH_ERRCODE 2
    interrupt_handler_%1:
        push qword %1
        push rax
        mov rax, %2
        jmp push_registers_and_call_handler
%endmacro

%define H8
HANDLER_WITH_ERRCODE 8, interrupt_handler
%define H8_IST 1 ;double fault stack

%define H10
HANDLER_WITH_ERRCODE 10, interrupt_handler

%define H11
HANDLER_WITH_ERRCODE 11, interrupt_handler

%define H12
HANDLER_WITH_ERRCODE 12, interrupt_handler

%define H13
interrupt_handler_13:        ; general protection fault
    sub rsp, 8      ; make room for rip (replaces interrupt number)
    push rax

    add rsp, 24     ; copy rip from trapframe to stack before rax
    pop rax
    sub rsp, 16
    push rax
    sub rsp, 8      ; move rsp to tos again

    mov rax, general_protection_fault_handler
    jmp push_registers_and_call_handler

%define H14
interrupt_handler_14:        ; pagefault
    sub rsp, 8      ; make room for cr2 (replaces interrupt number)
    push rax

    add rsp, 16     ; write cr2 on stack before rax
    mov rax, cr2
    push rax
    sub rsp, 8      ; move rsp to tos again

    mov rax, pagefault_handler
    jmp push_registers_and_call_handler

%define H33
interrupt_handler_33:        ; keyboard
    sub rsp, 8      ; room for keyboard code (replaces error code)
    push qword 33   ; interrupt number
    push rax

    mov rax, 0
    in al, 0x60
    mov [rsp + 16], rax

    mov rax, keyboard_handler
    jmp push_registers_and_call_handler


; other handlers (standard)

%macro HANDLER 1
    %ifndef H%1
    interrupt_handler_%1:
        push qword 0 ;dummy error code
        push qword %1
        push rax
        mov rax, interrupt_handler
        jmp push_registers_and_call_handler
    %endif
%endmacro

%assign i 0
%rep 256
    HANDLER i
%assign i i+1
%endrep


section .text

; Stack must contain rax on top the interrupt frame below. The interrupt
; handler address must then be passed in rax.
push_registers_and_call_handler:
    push rbx
    push rcx
    push rdx
    push rbp
    push rsi
    push rdi

    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    sub rsp, 16
    movdqu [rsp], xmm0
    sub rsp, 16
    movdqu [rsp], xmm1
    sub rsp, 16
    movdqu [rsp], xmm2
    sub rsp, 16
    movdqu [rsp], xmm3
    sub rsp, 16
    movdqu [rsp], xmm4
    sub rsp, 16
    movdqu [rsp], xmm5
    sub rsp, 16
    movdqu [rsp], xmm6
    sub rsp, 16
    movdqu [rsp], xmm7
    sub rsp, 16
    movdqu [rsp], xmm8
    sub rsp, 16
    movdqu [rsp], xmm9
    sub rsp, 16
    movdqu [rsp], xmm10
    sub rsp, 16
    movdqu [rsp], xmm11
    sub rsp, 16
    movdqu [rsp], xmm12
    sub rsp, 16
    movdqu [rsp], xmm13
    sub rsp, 16
    movdqu [rsp], xmm14
    sub rsp, 16
    movdqu [rsp], xmm15

    mov rdi, [rsp + 376]    ; interrupt number
    mov rsi, [rsp + 384]    ; error code
    mov rdx, rsp            ; stack pointer

    call rax

    mov rdi, rsp

; The stack address must be passed in rdi.
pop_registers_and_iret:
    mov rsp, rdi

    movdqu  xmm15, [rsp]
    add     rsp, 16
    movdqu  xmm14, [rsp]
    add     rsp, 16
    movdqu  xmm13, [rsp]
    add     rsp, 16
    movdqu  xmm12, [rsp]
    add     rsp, 16
    movdqu  xmm11, [rsp]
    add     rsp, 16
    movdqu  xmm10, [rsp]
    add     rsp, 16
    movdqu  xmm9, [rsp]
    add     rsp, 16
    movdqu  xmm8, [rsp]
    add     rsp, 16
    movdqu  xmm7, [rsp]
    add     rsp, 16
    movdqu  xmm6, [rsp]
    add     rsp, 16
    movdqu  xmm5, [rsp]
    add     rsp, 16
    movdqu  xmm4, [rsp]
    add     rsp, 16
    movdqu  xmm3, [rsp]
    add     rsp, 16
    movdqu  xmm2, [rsp]
    add     rsp, 16
    movdqu  xmm1, [rsp]
    add     rsp, 16
    movdqu  xmm0, [rsp]
    add     rsp, 16

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8

    pop rdi
    pop rsi
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    pop rax
    add rsp, 16 ;remove interrupt number and error code

    iretq
