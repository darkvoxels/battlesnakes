# BattleSnakes
BattleSnakes is a 512 Byte 2 Player Bootsector Game - Written in NASM x86 Assembly

Shout out to XlogicX for insperation for this project, some codeing techniques were borrowed, (https://github.com/XlogicX/tronsolitare)

<h2>Gameplay</h2>
&nbsp&nbsp 2 snakes start out moving away from there inital wall, they create a tail as they move, if they touch there own wall the tail will solidify and beome a wall, if they touch their own tail they die, if they touch the other players wall they die, and if they go out of bounds they die. Kill the other player by trapping in your walls or cutting the tail!

<h2>Assembly and Execution</h2>
To Assemble Sourcecode:
  Ensure you have nasm installed and run:
  nasm battlesnakes.asm -f bin -o battlesnakes.img

This tells nasm to assemble the file as binary file with no ELF or PE headers

To Execute you have a few options

Qemu
&nbsp qemu battlensakes.img or qemu-system-i386 battlesnakes.img
