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

; Seat booking prompt messages
bookmsg db 13,10,'Enter Row (0-2): $'
colmsg db 13,10,'Enter Column (0-2): $'
done db 13,10,'Seat booked successfully!$'
already db 13,10,'Seat already booked!$'
invalid_seat db 13,10,'Invalid seat. Row and Column must be between 0 and 2.$'

; Payment messages
payment_prompt db 13,10,'Proceed to payment (Press 1 to pay): $'
payment_done db 13,10,'Payment successful. Enjoy the show!$'
payment_invalid db 13,10,'Invalid payment option!$'

; Variables
choice db ?
row db ?
col db ?

; Three 3x3 seat matrices
matrix1 db 0,0,0,0,0,0,0,0,0
matrix2 db 0,0,0,0,0,0,0,0,0           
matrix3 db 0,0,0,0,0,0,0,0,0

.code
main:
    ; Initialize data segment
    mov ax, @data
    mov ds, ax

start_menu:
    ; Display the main menu with options to the user
    mov ah, 09h
    lea dx, menu
    int 21h

    ; Get the user's menu choice
    mov ah, 01h
    int 21h
    sub al, '0'    ; Convert the input from ASCII to integer
    mov choice, al

    ; Compare user input and jump to the corresponding options
    cmp al, 1
    je show_list
    cmp al, 2
    je view_seats
    cmp al, 3
    je book_seat
    cmp al, 4
    je quit
    jmp invalid_choice

; Show available movies list
show_list:
    mov ah, 09h
    lea dx, shows
    int 21h
    jmp start_menu

; View seat matrix
view_seats:
    call ask_show_id     ; Ask user for show ID
    call show_matrix     ; Show seat availability
    jmp start_menu

; Book a seat
book_seat:
    call ask_show_id     ; Ask user for show ID

    ; Ask user to select row
    mov ah, 09h
    lea dx, bookmsg
    int 21h
    mov ah, 01h
    int 21h
    sub al, '0'
    mov row, al

    ; Ask user to select column
    mov ah, 09h
    lea dx, colmsg
    int 21h
    mov ah, 01h
    int 21h
    sub al, '0'
    mov col, al

    ; Check if the seat is within the valid range
    cmp row, 0
    jl invalid_input
    cmp row, 2
    jg invalid_input
    cmp col, 0
    jl invalid_input
    cmp col, 2
    jg invalid_input

    ; Calculate the seat index based on row and column
    mov al, row
    mov bl, 3
    mul bl          ; al = row * 3 (multiplying by the number of columns)
    add al, col     ; al = row * 3 + col
    mov si, ax      ; Store the seat index in si

    ; Select the correct seat matrix based on the show choice
    cmp choice, 1
    je book_in_matrix1
    cmp choice, 2
    je book_in_matrix2  
    cmp choice, 3
    je book_in_matrix3
    jmp invalid_choice

; Book the seat in matrix 1 (for Show 1)
book_in_matrix1:
    mov bx, offset matrix1
    add bx, si          ; Move pointer to the selected seat
    cmp byte ptr [bx], 0 ; Check if the seat is available (0 = available)
    jne already_booked   ; If booked (1), show the message
    mov byte ptr [bx], 1  ; Mark the seat as booked
    jmp booked

; Book the seat in matrix 2 (for Show 2)
book_in_matrix2:
    mov bx, offset matrix2
    add bx, si
    cmp byte ptr [bx], 0
    jne already_booked
    mov byte ptr [bx], 1
    jmp booked   

; Book the seat in matrix 3 (for Show 3)
book_in_matrix3:
    mov bx, offset matrix3
    add bx, si
    cmp byte ptr [bx], 0
    jne already_booked
    mov byte ptr [bx], 1
    jmp booked

booked:
    ; After booking, show payment prompt
    mov ah, 09h
    lea dx, payment_prompt
    int 21h

    ; Wait for the user to enter payment choice
    mov ah, 01h
    int 21h
    sub al, '0'
    cmp al, 1
    je payment_success
    jmp invalid_payment

payment_success:
    ; Show payment successful message
    mov ah, 09h
    lea dx, payment_done
    int 21h

    ; Show seat booking successful message
    mov ah, 09h
    lea dx, done
    int 21h

    jmp start_menu

invalid_payment:
    ; If invalid payment option, show error message
    mov ah, 09h
    lea dx, payment_invalid
    int 21h
    jmp start_menu

already_booked:
    ; If the seat was already booked, show error message
    mov ah, 09h
    lea dx, already
    int 21h
    jmp start_menu

invalid_input:
    ; If invalid seat choice (outside 0-2 range), show error
    mov ah, 09h
    lea dx, invalid_seat
    int 21h
    jmp start_menu

ask_show_id:
    ; Ask the user to select the show ID
    mov ah, 09h
    lea dx, shows
    int 21h
    mov ah, 01h
    int 21h
    sub al, '0'
    mov choice, al
    ret

show_matrix:
    ; Display seat matrix for the selected show
    mov ah, 09h
    lea dx, seatmsg
    int 21h

    ; Based on the selected show, print the corresponding seat matrix
    cmp choice, 1
    je print_matrix1
    cmp choice, 2
    je print_matrix2 
    cmp choice, 3
    je print_matrix3
    jmp invalid_choice

print_matrix1:
    mov si, offset matrix1
    mov di, offset matrix1 + 9
    jmp print_matrix

print_matrix2:
    mov si, offset matrix2
    mov di, offset matrix2 + 9
    jmp print_matrix   

print_matrix3:
    mov si, offset matrix3
    mov di, offset matrix3 + 9
    jmp print_matrix

print_matrix:
    ; Loop to print the seat matrix (either available (0) or booked (1))
    mov cx, 0
print_loop:
    cmp si, di
    jae print_end

    mov al, [si]
    cmp al, 0
    je print_zero
    mov dl, '1'  ; Display '1' for booked seats
    jmp print_char

print_zero:
    mov dl, '0'  ; Display '0' for available seats

print_char:
    ; Display the character (either '1' or '0')
    mov ah, 02h
    int 21h

    mov dl, ' '
    mov ah, 02h
    int 21h

    inc si
    inc cx
    cmp cx, 3
    jne not_newline
    mov dl, 13
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
    ; If the user enters an invalid menu choice, show an error
    mov ah, 09h
    lea dx, invalid
    int 21h
    jmp start_menu

quit:
    ; If the user chooses to exit, display the exit message and terminate
    mov ah, 09h
    lea dx, exitmsg
    int 21h
    mov ah, 4ch
    int 21h
end main
