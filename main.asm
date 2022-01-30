    ; entry point
    ; fox32 starts here on reset
    org 0xF0000000

const system_stack:     0x01FFF800
const background_color: 0xFF414C50

    ; initialization code
entry:
    mov rsp, system_stack
    mov [event_stack_pointer], event_stack

    mov [0x000003FC], system_vsync_handler

    ; disable all overlays
    mov r31, 0x1F
    mov r0, 0x80000300
disable_all_overlays_loop:
    out r0, 0
    inc r0
    loop disable_all_overlays_loop

    ; write the cursor bitmap to the overlay framebuffer
    mov r0, [overlay_31_framebuffer_ptr]
    mov r1, mouse_cursor
    mov r31, 96 ; 8x12
cursor_overlay_loop:
    mov [r0], [r1]
    add r0, 4
    add r1, 4
    loop cursor_overlay_loop

cursor_enable:
    ; set properties of overlay 31
    mov r0, 0x8000011F ; overlay 31: size
    mov.16 r1, [overlay_31_height]
    sla r1, 16
    mov.16 r1, [overlay_31_width]
    out r0, r1
    mov r0, 0x8000021F ; overlay 31: framebuffer pointer
    mov r1, [overlay_31_framebuffer_ptr]
    out r0, r1

    ; enable overlay 31 (cursor)
    mov r0, 0x8000031F
    out r0, 1

    mov r0, background_color
    call fill_background

menu_bar_enable:
    ; set properties of overlay 30
    mov r0, 0x8000001E ; overlay 30: position
    mov.16 r1, [overlay_30_position_y]
    sla r1, 16
    mov.16 r1, [overlay_30_position_x]
    out r0, r1
    mov r0, 0x8000011E ; overlay 30: size
    mov.16 r1, [overlay_30_height]
    sla r1, 16
    mov.16 r1, [overlay_30_width]
    out r0, r1
    mov r0, 0x8000021E ; overlay 30: framebuffer pointer
    mov r1, [overlay_30_framebuffer_ptr]
    out r0, r1

    ; enable overlay 30 (menu bar)
    mov r0, 0x8000031E
    out r0, 1

    call clear_menu_bar
    mov r0, menu_items_root
    mov r1, 0xFFFFFFFF
    call draw_menu_bar_root_items

draw_startup_text:
    mov r0, 252
    mov r1, 229
    mov r2, 136
    mov r3, 40
    mov r4, 0xFF505C60
    ;mov r4, 0xFFFFFFFF
    call draw_filled_rectangle_to_background
    mov r0, 253
    mov r1, 230
    mov r2, 134
    mov r3, 38
    mov r4, 0xFFFFFFFF
    ;mov r4, 0xFF000000
    call draw_filled_rectangle_to_background
    mov r0, 254
    mov r1, 231
    mov r2, 132
    mov r3, 36
    mov r4, 0xFF505C60
    ;mov r4, 0xFFFFFFFF
    call draw_filled_rectangle_to_background

    mov r0, startup_str_1
    mov r1, 256
    mov r2, 232
    mov r3, 0xFFFFFFFF
    mov r4, 0x00000000
    call draw_str_to_background

    mov r0, startup_str_2
    mov r1, 256
    mov r2, 248
    call draw_str_to_background

    ise
event_loop:
    halt
    call pop_event

    ; was the mouse clicked?
    cmp r0, mouse_click_event_type
    ;ifz call mouse_click_event

    ; did the user click the menu bar?
    cmp r0, menu_bar_click_event_type
    ifz mov r0, menu_items_root
    ifz call menu_bar_click_event

    ; is the user in a submenu?
    cmp r0, submenu_update_event_type
    ifz call submenu_update_event

    ; did the user click a submenu item?
    cmp r0, submenu_click_event_type
    ifz call submenu_click_event

    ; check if a disk is mounted as disk 0
    ; if port 0x8000100n returns a non-zero value, then a disk is mounted as disk n
    in r0, 0x80001000
    cmp r0, 0
    ifnz call load_boot_disk

    jmp event_loop

submenu_click_event:
    ; r3 contains the clicked submenu item

    ; about
    cmp r3, 0
    ;

    ; mount disk
    cmp r3, 1
    ifz jmp mount_boot_disk

    ; halt
    cmp r3, 2
    ifz icl
    ifz halt

    ret

mount_boot_disk:
    mov r0, 0x80001000
    out r0, 0
    ret

load_boot_disk:
    ; in the future, this will check the header for various different types of disk types
    ; but for now, just assume the user mounted a raw binary
    ; load it to 0x00000800 (immediately after the interrupt vectors) and jump

    ; r0 contains the size of the disk in bytes
    ; divide the size by 512 and add 1 to get the size in sectors
    div r0, 512
    inc r0

    mov r31, r0
    mov r0, 0          ; sector counter
    mov r2, 0x00000800 ; destination pointer
    mov r3, 0x80003000 ; command to read a sector from disk 0 into the sector buffer
    mov r4, 0x80002000 ; command to read a byte from the sector buffer
load_boot_disk_sector_loop:
    out r3, r0         ; read the current sector into the sector buffer
    mov r1, 0          ; byte counter
load_boot_disk_byte_loop:
    mov r5, r4
    or r5, r1          ; or the byte read command with the current byte counter
    in r5, r5          ; read the current byte into r5
    mov.8 [r2], r5     ; write the byte
    inc r2             ; increment the destination pointer
    inc r1             ; increment the byte counter
    cmp r1, 512
    ifnz jmp load_boot_disk_byte_loop
    loop load_boot_disk_sector_loop

    ; done loading !!!
    ; now jump to the loaded binary
    ; TODO: clear the background, disable the menu bar, etc
    jmp 0x00000800

    ; code
    #include "background.asm"
    #include "overlay.asm"
    #include "menu.asm"
    #include "submenu.asm"
    #include "event.asm"
    #include "mouse.asm"
    #include "vsync.asm"





    ; data

    ; system jump table
    org.pad 0xF1000000
    data.32 system_vsync_handler
    data.32 get_mouse_position
    data.32 push_event
    data.32 wait_for_event

    ; background jump table
    org.pad 0xF1001000
    data.32 draw_str_to_background
    data.32 draw_font_tile_to_background
    data.32 fill_background

    ; overlay jump table
    org.pad 0xF1002000
    data.32 draw_str_to_overlay
    data.32 draw_font_tile_to_overlay
    data.32 fill_overlay
    data.32 find_overlay_covering_position
    data.32 check_if_overlay_covers_position
    data.32 check_if_enabled_overlay_covers_position

    ; menu bar jump table
    org.pad 0xF1003000
    data.32 menu_bar_click_event
    data.32 clear_menu_bar
    data.32 draw_menu_bar_root_items
    data.32 draw_submenu_items
    data.32 close_submenu

    org.pad 0xF1F00000
font:
    #include_bin "font/unifont-thin.raw"

mouse_cursor:
    #include_bin "font/cursor2.raw"

; cursor overlay struct:
overlay_31_width:           data.16 8
overlay_31_height:          data.16 12
overlay_31_position_x:      data.16 0
overlay_31_position_y:      data.16 0
overlay_31_framebuffer_ptr: data.32 0x8012D000

; menu bar overlay struct:
overlay_30_width:           data.16 640
overlay_30_height:          data.16 16
overlay_30_position_x:      data.16 0
overlay_30_position_y:      data.16 0
overlay_30_framebuffer_ptr: data.32 0x8012D180

; submenu overlay struct:
; this struct must be writable, so these are hard-coded addresses in shared memory
const overlay_29_width:           0x80137180 ; 2 bytes
const overlay_29_height:          0x80137182 ; 2 bytes
const overlay_29_position_x:      0x80137184 ; 2 bytes
const overlay_29_position_y:      0x80137186 ; 2 bytes
const overlay_29_framebuffer_ptr: 0x8013718A ; 4 bytes
const overlay_29_framebuffer:     0x8013718E

startup_str_1: data.str "Welcome to fox32" data.8 0
startup_str_2: data.str "Insert boot disk" data.8 0

menu_items_root:
    data.8 1                                                      ; number of submenus
    data.32 menu_items_system_list data.32 menu_items_system_name ; pointer to submenu list, pointer to submenu name
menu_items_system_name:
    data.8 6 data.str "System" data.8 0x00      ; text length, text, null-terminator
menu_items_system_list:
    data.8 3                                    ; number of items
    data.8 12                                   ; submenu width (usually longest item + 2)
    data.8 5  data.str "About"      data.8 0x00 ; text length, text, null-terminator
    data.8 10 data.str "Mount Disk" data.8 0x00 ; text length, text, null-terminator
    data.8 4  data.str "Halt"       data.8 0x00 ; text length, text, null-terminator

    ; pad out to 32 MiB
    org.pad 0xF2000000

    ; TODO: ideas:
    ;       rectangle drawing routine
    ;       fill background/overlay routine
    ;       seperators in submenus