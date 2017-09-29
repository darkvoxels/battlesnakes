# BattleSnakes
BattleSnakes is a 512 Byte 2 Player Bootsector Game - Written in NASM x86 Assembly

<br>
Shout out to XlogicX for inspiration for this project and some coding techniques (https://github.com/XlogicX/tronsolitare)
<br>
<h2>Gameplay</h2><br>
2 snakes start out by moving away from their inital wall, they create a tail as they move, if they touch their own wall the tail will solidify and become a wall, if they touch their own tail they die, if they touch the other players wall they die, and if they go out-of-bounds they die. Kill the other player by trapping in your walls or cutting the tail!

<h2>Assembly and Execution</h2><br>
To Assemble Sourcecode:

  Ensure you have nasm installed and run:

  nasm battlesnakes.asm -f bin -o battlesnakes.img

<br>
This tells nasm to assemble the file as binary file with no ELF or PE headers

<br>
To Execute I recommend using one the following VM methods

<br>
Qemu<br>
qemu battlensakes.img or qemu-system-i386 battlesnakes.img

<br>
VirtualBox or VMware

Set battlesnakes.img as a floppy drive image and boot the floppy<br>
<br>
