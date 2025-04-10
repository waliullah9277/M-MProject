.model small
.stack 100h
.data

; Display menu
menu db 13,10,'----- CINEMA TICKET SYSTEM -----',13,10
     db '1. View Shows',13,10
     db '2. View Available Seats',13,10
     db '3. Book a Seat',13,10
     db '4. Exit',13,10,'Choose option: $'

; Display list of shows
shows db 13,10,'Available Shows:',13,10     
      db '1. Show ID: 1 - IRON MAN 3 at 6:00 PM',13,10     
      db '2. Show ID: 2 - PUSPA2 at 3:00 PM',13,10
      db '3. Show ID: 3 - SPIDER MAN at 4:00 PM',13,10,'Choose option: $'

; Error and exit messages
invalid db 13,10,'Invalid choice!$'
exitmsg db 13,10,'Exiting...$'

; Seat matrix display message
seatmsg db 13,10,'Seat Matrix (0 = available, 1 = booked):',13,10,'$'
row0 db '0 0 0',13,10,'$'
row1 db '0 0 0',13,10,'$'
row2 db '0 0 0',13,10,'$'

; Seat booking prompt messages
bookmsg db 13,10,'Enter Row (0-2): $'
colmsg db 13,10,'Enter Column (0-2): $'
done db 13,10,'Seat booked successfully!$'
already db 13,10,'Seat already booked!$'
invalid_seat db 13,10,'Invalid seat. Row and Column must be between 0 and 2.$'

; Variables for user choice, row and column selection
choice db ?
row db ?
col db ?

; Two seat matrices (show 1 and show 2), 3x3 = 9 bytes each
matrix1 db 0,0,0,0,0,0,0,0,0
matrix2 db 0,0,0,0,0,0,0,0,0           
matrix3 db 0,0,0,0,0,0,0,0,0

.code
main:
    ; Initialize data segment and start program
    mov ax, @data
    mov ds, ax

start_menu:
    ; Print the main menu
    mov ah, 09h
    lea dx, menu
    int 21h

    ; Take user input for menu choice
    mov ah, 01h
    int 21h
    sub al, '0'     ; Convert ASCII to integer
    mov choice, al  ; Store user choice

    ; Check choice and jump to corresponding function
    cmp al, 1
    je show_list
    cmp al, 2
    je view_seats
    cmp al, 3
    je book_seat
    cmp al, 4
    je quit
    jmp invalid_choice  ; If invalid choice, show error

show_list:
    ; Display available shows
    mov ah, 09h
    lea dx, shows
    int 21h
    jmp start_menu  ; Go back to main menu

view_seats:
    ; Ask for show ID and display seat matrix
    call ask_show_id
    call show_matrix
    jmp start_menu  ; Go back to main menu

book_seat:
    ; Ask for show ID
    call ask_show_id

    ; Get Row input
    mov ah, 09h
    lea dx, bookmsg
    int 21h
    mov ah, 01h
    int 21h
    sub al, '0'     ; Convert to integer
    mov row, al     ; Store row input

    ; Get Column input
    mov ah, 09h
    lea dx, colmsg
    int 21h
    mov ah, 01h
    int 21h
    sub al, '0'     ; Convert to integer
    mov col, al     ; Store column input

    ; Validate row and column input (must be between 0 and 2)
    cmp row, 0
    jl invalid_input
    cmp row, 2
    jg invalid_input
    cmp col, 0
    jl invalid_input
    cmp col, 2
    jg invalid_input

    ; Calculate the index of the seat in the matrix: row*3 + col
    mov al, row
    mov bl, 3
    mul bl         ; Multiply row by 3
    add al, col    ; Add column to get index
    mov si, ax     ; Store result in SI (index)

    ; Check which show the user wants to book a seat for and jump accordingly
    cmp choice, 1
    je book_in_matrix1
    cmp choice, 2
    je book_in_matrix2  
    cmp choice, 3
    je book_in_matrix3
    jmp invalid_choice  ; If invalid choice, show error

book_in_matrix1:
    ; Check if the seat is available in matrix1 for show 1
    mov bx, offset matrix1
    add bx, si
    cmp byte ptr [bx], 0
    jne already_booked  ; If already booked, show error
    mov byte ptr [bx], 1  ; Book the seat
    jmp booked

book_in_matrix2:
    ; Check if the seat is available in matrix2 for show 2
    mov bx, offset matrix2
    add bx, si
    cmp byte ptr [bx], 0
    jne already_booked
    mov byte ptr [bx], 1
    jmp booked   

book_in_matrix3:
    ; Check if the seat is available in matrix3 for show 3
    mov bx, offset matrix3
    add bx, si
    cmp byte ptr [bx], 0
    jne already_booked
    mov byte ptr [bx], 1
    jmp booked

booked:
    ; Display success message after booking
    mov ah, 09h
    lea dx, done
    int 21h
    jmp start_menu  ; Go back to main menu

already_booked:
    ; Display error message if the seat is already booked
    mov ah, 09h
    lea dx, already
    int 21h
    jmp start_menu  ; Go back to main menu

invalid_input:
    ; Display error message for invalid input
    mov ah, 09h
    lea dx, invalid_seat
    int 21h
    jmp start_menu  ; Go back to main menu

ask_show_id:
    ; Display available shows and get user choice
    mov ah, 09h
    lea dx, shows
    int 21h
    mov ah, 01h
    int 21h
    sub al, '0'     ; Convert to integer
    mov choice, al  ; Store show choice
    ret

show_matrix:
    ; Display the seat matrix based on the show choice
    mov ah, 09h
    lea dx, seatmsg
    int 21h

    cmp choice, 1
    je print_matrix1
    cmp choice, 2
    je print_matrix2 
    cmp choice, 3
    je print_matrix3
    jmp invalid_choice  ; If invalid choice, show error

print_matrix1:
    ; Print seat matrix for show 1
    mov si, offset matrix1
    mov di, offset matrix1 + 9
    jmp print_matrix

print_matrix2:
    ; Print seat matrix for show 2
    mov si, offset matrix2
    mov di, offset matrix2 + 9
    jmp print_matrix   

print_matrix3:
    ; Print seat matrix for show 3
    mov si, offset matrix3
    mov di, offset matrix3 + 9
    jmp print_matrix

print_matrix:
    ; Loop through and print each seat
    mov cx, 0
print_loop:
    cmp si, di
    jae print_end  ; Exit if we've printed all 9 seats

    mov al, [si]   ; Get current seat value
    cmp al, 0
    je print_zero  ; If available, print '0'
    mov dl, '1'    ; If booked, print '1'
    jmp print_char

print_zero:
    mov dl, '0'    ; Display '0' for available seat

print_char:
    ; Print the character (either '0' or '1')
    mov ah, 02h
    int 21h

    ; Print space between seats
    mov dl, ' '
    mov ah, 02h
    int 21h

    inc si
    inc cx
    cmp cx, 3
    jne not_newline
    mov dl, 13  ; Newline for every 3rd seat
    mov ah, 02h
    int 21h
    mov dl, 10
    int 21h
    mov cx, 0
not_newline:
    jmp print_loop

print_end:
    ret

invalid_choice:
    ; Display error message for invalid menu choice
    mov ah, 09h
    lea dx, invalid
    int 21h
    jmp start_menu  ; Go back to main menu

quit:
    ; Display exit message and terminate
    mov ah, 09h
    lea dx, exitmsg
    int 21h
    mov ah, 4ch
    int 21h
end main
