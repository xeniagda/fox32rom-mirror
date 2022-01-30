; event system routines

const event_stack:         0x01FFFFFC ; pre-decremented
const event_stack_pointer: 0x01FFFFFC

; event types
const mouse_click_event_type:    0x00000000
const menu_bar_click_event_type: 0x00000001
const submenu_update_event_type: 0x00000002
const submenu_click_event_type:  0x00000003
const empty_event_type:          0xFFFFFFFF

; block until an event is available
; inputs:
; none
; outputs:
; r0: event type
; r1-r5: event parameters
wait_for_event:
    ise
    halt

    ; check the event stack pointer
    ; if equal to its base address, then the event stack is empty
    cmp [event_stack_pointer], event_stack_pointer
    ifz jmp wait_for_event

    ; an event is available in the event stack, pop it from the stack and return it
    call pop_event

    ret

; push an event to the event stack
; inputs:
; r0: event type
; r1-r5: event parameters
; outputs:
; none
push_event:
    icl
    push r6
    mov r6, rsp
    mov rsp, [event_stack_pointer]
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    mov [event_stack_pointer], rsp
    mov rsp, r6
    pop r6
    ise

    ret

; pop an event from the event stack
; inputs:
; none
; outputs:
; r0: event type
; r1-r5: event parameters
pop_event:
    ; check the event stack pointer
    ; if equal to its base address, then the event stack is empty
    cmp [event_stack_pointer], event_stack_pointer
    ifz jmp pop_event_empty

    icl
    push r6
    mov r6, rsp
    mov rsp, [event_stack_pointer]
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    mov [event_stack_pointer], rsp
    mov rsp, r6
    pop r6
    ise

    ret
pop_event_empty:
    mov r0, empty_event_type
    mov r1, 0
    mov r2, 0
    mov r3, 0
    mov r4, 0
    mov r5, 0

    ret
