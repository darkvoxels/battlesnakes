;Lets NASM Know our origin address so that it can calculate the correct offsets
[ORG 0x7c00]

;SETUP STACK
mov ax, 0x9000
mov ss, ax
mov ax, 0xFFFF
mov sp, ax

;Specify a new Interrupt Service Routine for Keyboard in the Interrupt Vector Table,
;REF
  ;https://en.wikipedia.org/wiki/Interrupt_descriptor_table
  ;http://wiki.osdev.org/Interrupt_Vector_Table

;IVT Offset | INT # | IRQ # | Description
;-----------+-------+-------+------------------------------
;0x0024     | 0x09  | 1     | Keyboard
;NOTE: Found that ES defaulted to 0x00 so removed this..
;mov ax, 0x0000
;mov es, ax
cli							;Disable Interrupts
mov [es:4 * 9], word get_keys				;Update the IVT with the location of our Interrupt Service Routine (get_keys)
mov [es:4 * 9 + 2], cs					;Specify what segment our ISR is in
sti							;Enable Interrupts

;POINT ES TO VIDEO MEMORY
mov ax, 0xA000
mov es, ax

;SWITCH TO VIDEO MODE 0x13, GRAPHICS MODE, REF https://en.wikipedia.org/wiki/Mode_13h
	;resolution of 320×200 pixels
mov ah, 0x00
mov al, 0x13
int 0x10

;HIDE TEXT CURSOR
mov ah, 1
mov ch, 0x20
mov cl, 0x00
int 0x10

start:
mov al, 0x07
call clearScreen

;PLAYER SETUP
;Player Start points p1(75,49) p2(245,50)
mov al, 0x03
mov di, 320*100+65
mov cx, 10
rep stosb

mov al, 0x06
mov di, 320*100+245
mov cx, 10
rep stosb

loop:
	;RENDER PLAYER 1
	mov al, 0x01
	mov bx, [player1y]
	mov cx, [player1x]
	call render_player

	;RENDER PLAYER 2
	mov al, 0x04
	mov bx, [player2y]
	mov cx, [player2x]
	call render_player	

	hlt ;Add a Delay, this is based off Interrupts

	;RENDER PLAYER 1 CURRENT POS AS TAIL
	mov al, 0x0B
	mov bx, [player1y]
	mov cx, [player1x]
	call render_player

	;RENDER PLAYER 2 CURRENT POS AS TAIL
	mov al, 0x0E
	mov bx, [player2y]
	mov cx, [player2x]
	call render_player

	;PLAYER MOVEMENT
	mov al, [playerI]
	mov bl, al
	and al, 0x0F
	and bl, 0xF0

	mov cx, [player1x]
	mov dx, [player1y]
move_p1_w:
	cmp al, 0x01
	jne move_p1_a
	dec dx
move_p1_a:
	cmp al, 0x02
	jne move_p1_s
	dec cx
move_p1_s:
	cmp al, 0x04
	jne move_p1_d
	inc dx
move_p1_d:
	cmp al, 0x08
	jne p1_update
	inc cx
p1_update:
	mov di, 320
	imul di, dx
	add di, cx
	mov ah, [es:di]
	cmp ah, 0x03    ;CHECK FOR TAIL COMPLETE
	jne p1_kill
	pusha
	mov bh, 0x03
	mov bl, 0x0b
	call fillscan
	popa

p1_kill:
	cmp ah, 0x0E
	jne p1_tail_die
	mov al, 0x01
	call clearScreen

p1_tail_die:
	cmp ah, 0x0B ;Check for tail suicide
	je p1_die

p1_wall_die:
	cmp ah, 0x06 ;Check for p2 Wall
	jne p1_npos

p1_die:
	mov al, 0x04
	call clearScreen

p1_npos:
	;SET NEW POS
	mov [player1x], cx
	mov [player1y], dx

	mov al, 0x04
	call bounds_check

	mov cx, [player2x]
	mov dx, [player2y]
move_p2_u:
	cmp bl, 0x10
	jne move_p2_l
	dec dx
move_p2_l:
	cmp bl, 0x20
	jne move_p2_d
	dec cx
move_p2_d:
	cmp bl, 0x40
	jne move_p2_r
	inc dx
move_p2_r:
	cmp bl, 0x80
	jne p2_update
	inc cx
p2_update:
	mov di, 320
	imul di, dx
	add di, cx
	mov ah, [es:di]
	cmp ah, 0x06	;CHECK FOR TAIL COMPLETE
	jne p2_kill
	pusha
	mov bh, 0x06
	mov bl, 0x0E
	call fillscan
	popa

p2_kill:
	cmp ah, 0x0B
	jne p2_tail_die
	mov al, 0x04
	call clearScreen

p2_tail_die:
	cmp ah, 0x0E ;Check for tail suicide
	je p2_die

p2_wall_die:
	cmp ah, 0x03 ;Check for p1 Wall
	jne p2_npos

p2_die:
	mov al, 0x01
	call clearScreen

p2_npos:
	mov [player2x], cx
	mov [player2y], dx

	mov al, 0x01
	call bounds_check

next:
	jmp loop

fillscan:
	mov di, 0x00
	mov cx, 320 * 200
scan:
	cmp [es:di], bl
	jne sloop
	mov [es:di], bh
sloop:
	inc di
	cmp cx, di
	jnz scan
	ret

render_player:						;al=color, bx=y, cx=x
	mov di, 320
	imul di, bx
	add di, cx
	mov [es:di], al
	ret

bounds_check:						;al=color to clear screen, dx=y, cx=x
	pusha
	;x lower bounds
	cmp cx, 0x00
	jl p_bounds_die

	;x upper bounds
	cmp cx, 320
	jg p_bounds_die

	;y lower bounds
	cmp dx,0x00
	jl p_bounds_die

	;y upper bounds
	cmp dx, 200
	jg p_bounds_die

	;Return if no bounds conditions met:
	popa
	ret

	;Game Over on player who hit bounds
p_bounds_die:
	call clearScreen

clearScreen:
	;AL = Hex Color
	mov cx, 320*200					;number of times to inc.. row * columns for whole screen
	mov di, 0					; Start...
	rep stosb
	cmp al, 0x07					;CHECK if its the default color
	je cs_exit					;if it is exit, if not, Game Over reboot
cs_gameover:
	hlt						;Long Delay, TODO, do more optimizations and build better timing
	hlt
	hlt
	hlt
	hlt
	hlt
	hlt
	hlt
	hlt
	int 0x19					;Reboot system to restart the game... 
cs_exit:
	ret

;CUSTOM KEYBOARD INTTERUPT FOR READING MULTIPLE KEYS AT ONCE..
get_keys:
	pusha						;Push all registers to the stack
	in al, 0x60					;read keyboard scan code
	mov bl, [playerI]
P1_W:
	cmp al, 0x11
	jne P1_A
	and bl, 0xF0
	add bl, 0x01
P1_A:
	cmp al, 0x1E
	jne P1_S
	and bl, 0xF0
	add bl, 0x02
P1_S:
	cmp al, 0x1F
	jne P1_D
	and bl, 0XF0
	add bl, 0x04
P1_D:
	cmp al, 0x20
	jne P2_U
	and bl, 0xF0
	add bl, 0x08
P2_U:
	cmp al, 0x48
	jne P2_L
	and bl, 0x0F
	add bl, 0x10
P2_L:
	cmp al, 0x4B
	jne P2_D
	and bl, 0x0F
	add bl, 0x20
P2_D:
	cmp al, 0x50
	jne P2_R
	and bl, 0x0F
	add bl, 0x40
P2_R:
	cmp al, 0x4D
	jne get_keys_done
	and bl, 0x0F
	add bl, 0x80

get_keys_done:
	mov [playerI], bl

	;Send "END OF INTERRUPT" to the Programmable Interrupt Controller
	mov al, 0x20
	out 0x20, al

	popa                   				;Pop all registers back from the stack
	iret ; Return


;Player Input's and Cord's
playerI db 0x28
player1x dw 0x004b
player1y dw 0x0064
player2x dw 0x00f5
player2y dw 0x0064

;NASM Padding for BootSector Boot Signature
times 510-($-$$) db 0
dw 0xAA55
