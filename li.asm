; LIBRARY MANAGEMENT SYSTEM - EMU8086 PROJECT
; Supports: Add Book, View Book, Borrow Book, Return Book

.model small
.stack 100h
.data
    max_books db 5
    book_count db 0

    ; Book info (fixed length fields for 5 books)
    book_ids dw 5 dup(0)
    book_names db 5 dup(20 dup('$'))
    book_authors db 5 dup(20 dup('$'))
    book_categories db 5 dup(15 dup('$'))
    book_copies db 5 dup(0)

    ; Buffers
    input_buffer db 20 dup(?)

    ; Messages
    msg_main db 0Dh,0Ah,"=== Library Management System ===$"
    msg_menu db 0Dh,0Ah,"1. Add Book",0Dh,0Ah,"2. View Books",0Dh,0Ah,"3. Borrow Book",0Dh,0Ah,"4. Return Book",0Dh,0Ah,"5. Exit",0Dh,0Ah,"Enter your choice: $"
    msg_add db 0Dh,0Ah,"--- Add Book ---$"
    msg_enter_name db 0Dh,0Ah,"Enter Book Name: $"
    msg_enter_author db 0Dh,0Ah,"Enter Author Name: $"
    msg_enter_cat db 0Dh,0Ah,"Enter Category: $"
    msg_enter_copy db 0Dh,0Ah,"Enter Number of Copies: $"
    msg_done db 0Dh,0Ah,"Book added successfully!$"
    msg_full db 0Dh,0Ah,"Book limit reached!$"
    msg_view db 0Dh,0Ah,"--- Book List ---$"
    msg_empty db 0Dh,0Ah,"No books available!$"
    msg_borrow db 0Dh,0Ah,"--- Borrow Book ---$"
    msg_return db 0Dh,0Ah,"--- Return Book ---$"
    msg_found db 0Dh,0Ah,"Operation successful!$"
    msg_notfound db 0Dh,0Ah,"Book not found!$"
    msg_invalid db 0Dh,0Ah,"Invalid operation!$"
    msg_exit db 0Dh,0Ah,"Exiting...$"

.code
main:
    mov ax, @data
    mov ds, ax
menu:
    lea dx, msg_main
    call print
    lea dx, msg_menu
    call print
    call get_char
    cmp al, '1'
    je add_book
    cmp al, '2'
    je view_books
    cmp al, '3'
    je borrow_book
    cmp al, '4'
    je return_book
    cmp al, '5'
    je exit_program
    jmp menu

add_book:
    ; Allow adding multiple books
    lea dx, msg_add
    call print
add_loop:
    mov al, book_count
    cmp al, max_books
    jae book_full
    lea dx, msg_enter_name
    call print
    lea di, input_buffer
    call get_string
    mov si, offset book_names
    mov al, book_count
    mov ah, 0
    mov bx, 20
    mul bl
    add si, ax
    call store_string

    ; Author
    lea dx, msg_enter_author
    call print
    lea di, input_buffer
    call get_string
    mov si, offset book_authors
    mov al, book_count
    xor ah, ah
    mov bx, 20
    mul bl
    add si, ax
    call store_string

    ; Category
    lea dx, msg_enter_cat
    call print
    lea di, input_buffer
    call get_string
    mov si, offset book_categories
    mov al, book_count
    xor ah, ah
    mov bx, 15
    mul bl
    add si, ax
    call store_string

    ; Copies
    lea dx, msg_enter_copy
    call print
    call get_num
    mov bx, offset book_copies
    mov al, book_count
    xor ah, ah
    add bx, ax
    mov [bx], cl

    inc book_count
    lea dx, msg_done
    call print

    ; Ask if user wants to add another book
    lea dx, msg_add
    call print
    lea dx, msg_empty
    call print
    call get_char
    cmp al, 'y'
    je add_loop

    jmp menu

book_full:
    lea dx, msg_full
    call print
    jmp menu

view_books:
    lea dx, msg_view
    call print
    cmp book_count, 0
    je empty_list

    mov cx, 0                  ; Initialize counter for book display loop
view_loop:
    ; Print Book Name
    mov al, cl
    xor ah, ah
    mov bx, 20                 ; Book name length
    mul bl
    lea si, book_names
    add si, ax
    lea dx, [si]
    call print_str

    ; Print Author
    lea dx, msg_empty
    call print
    mov al, cl
    xor ah, ah
    mov bx, 20
    mul bl
    lea si, book_authors
    add si, ax
    lea dx, [si]
    call print_str

    ; Print Category
    lea dx, msg_empty
    call print
    mov al, cl
    xor ah, ah
    mov bx, 15
    mul bl
    lea si, book_categories
    add si, ax
    lea dx, [si]
    call print_str

    ; Print Copies
    lea si, book_copies
    add si, cx
    mov dl, [si]
    call print_num_byte

    ; Add some space between books for better readability
    lea dx, msg_empty
    call print

    inc cx
    mov al, book_count      ; Compare counter with the total book count
    ;cmp cx, al
    jl view_loop            ; If not yet reached the book count, continue looping

    jmp menu

empty_list:
    lea dx, msg_empty
    call print
    jmp menu

borrow_book:
    lea dx, msg_borrow
    call print
    lea dx, msg_enter_name
    call print
    lea di, input_buffer
    call get_string
    mov si, offset book_names
    mov cx, 0
borrow_search:
    ; Compare entered name with book names
    lea di, input_buffer
    call compare_string
    cmp al, 0
    je borrow_found
    inc cx
    mov al, book_count  ; Compare counter with book count
    ;cmp cx, al
    jl borrow_search

    lea dx, msg_notfound
    call print
    jmp menu

borrow_found:
    ; Check if the book has available copies
    mov si, offset book_copies
    add si, cx
    mov al, [si]
    cmp al, 0
    je borrow_unavailable
    dec byte ptr [si]   ; Decrement copy count
    lea dx, msg_found
    call print
    jmp menu

borrow_unavailable:
    lea dx, msg_notfound
    call print
    jmp menu

return_book:
    lea dx, msg_return
    call print
    lea dx, msg_enter_name
    call print
    lea di, input_buffer
    call get_string
    mov si, offset book_names
    mov cx, 0
return_search:
    ; Compare entered name with book names
    lea di, input_buffer
    call compare_string
    cmp al, 0
    je return_found
    inc cx
    mov al, book_count  ; Compare counter with book count
    ;cmp cx, al
    jl return_search

    lea dx, msg_notfound
    call print
    jmp menu

return_found:
    ; Increment copy count
    mov si, offset book_copies
    add si, cx
    inc byte ptr [si]
    lea dx, msg_found
    call print
    jmp menu

exit_program:
    lea dx, msg_exit
    call print
    mov ah, 4ch
    int 21h

; --- Utility Routines ---
print:
    mov ah, 09h
    int 21h
    ret

get_char:
    mov ah, 01h
    int 21h
    ret

get_string:
    mov si, di
get_char_loop:
    mov ah, 01h
    int 21h
    cmp al, 0Dh
    je done_string
    mov [si], al
    inc si
    jmp get_char_loop
done_string:
    mov [si], '$'
    ret

store_string:
    lea di, si
    lea si, input_buffer
    mov cx, 20
store_loop:
    lodsb
    stosb
    loop store_loop
    ret

get_num:
    call get_char
    sub al, '0'
    mov cl, al
    xor ch, ch
    ret

compare_string:
    ; Compares two strings, returns 0 if equal
    lea si, input_buffer
    lea di, [di]         ; Pointer to stored book name
compare_loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne not_equal
    inc si
    inc di
    cmp al, '$'          ; End of string character
    je equal
    jmp compare_loop
not_equal:
    mov al, 1
    ret
equal:
    xor al, al
    ret

print_str:
    mov ah, 09h
    int 21h
    ret

print_num_byte:
    add dl, '0'
    mov ah, 02h
    int 21h
    ret
end main
