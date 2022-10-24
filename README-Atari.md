# GEOS Atari port

by Berkeley Softworks, reverse-engineered by *Maciej Witkowiak*, *Michael Steil*

GEOS ported to 8-bit Atari by *Maciej Witkowiak*

## What is GEOS?

Please read main README.md for that.

## Atari port requirements

An 8-bit Atari computer with at least 128K of RAM: 130XE or expanded 65XE as a minimum.

Except the very first bank, whole extra memory is meant to be used by RAM disk.

Right now memory above 320K is not used. The disk driver can address it but it doesn't have space for extra
Block Allocation Maps (BAMs) and so the image creator can't write such images.

There is only RAM disk available at the moment. I don't know how to handle communication with disk drives over SIO.
Please help if you can!

## Quickstart

Run emulator and make sure to choose PAL system with at least 128K of RAM. Setup joystick in port 1. Load the GEOS.XEX file into emulator.

First there will be a message about detected RAM disk. RAM disk contents are loaded first from the XEX file.
This code may be reused eventually for quick reboot. Right now it's annoying but it shows how many memory banks (16K each) will be used for
RAM disk. Choose 'No' - don't reformat RAM disk yet.

Next you wil see some leftovers from graphics routines tests.

Then play with the menu. Try to type something or click on icons.

Finally: 'quit' will return to Basic, and 'file'->'DeskTop' will try to exit the boot application
and enter DeskTop.

But there is no DeskTop. Instead a 'filesel' application will load where you can choose which next application to load and run. If you quit that new application you
will return to 'filesel' our temporary DeskTop replacement.

## Atari port remarks

### Compatibility

This port has no reference implementation so I felt free to remove conditional C64/C128/Wheels/Gateway
code whenever I touched the files.

Order of segments is also rearranged to make the best use of available memory segments.

Well-beaved applications that run on both GEOS 64 and GEOS 128 (in 80-column mode) should also run on Atari.

Note that DESK TOP from GEOS 64 *is not* such application - Atari will need its own file manager.

Compatibility problems come from:

    - hardware differences (Atari Players vs VIC sprites, POKEY vs SID)
    - memory map changes (hires bitmap screen with different organization for ANTIC than for VIC)
    - missing capatibilities (24-pixel wide sprites, color matrix for hires mode)

Programs will not work correctly if:

    - they use sprites or change their colors (e.g. Preferences Manager)
    - they change color matrix in 40-column mode (e.g. DESK TOP)
    - they require REU
    - they access bitmap screen in 40-column mode directly (e.g. Maverick)
    - they write directly to I/O registers (e.g printer drivers)

They may not work at all or show some graphical glitches.

Just like on C64 the processes (sleep and multitasking) are clocked by video frame rate.

### Performance

Atari port is supposedly faster than C64/128. It has higher CPU clock rate and linear screen organization that is easier to handle than VIC bitmap.

Keyboard has its own interrupt and doesn't have to be scanned for every row/column.

All the rectangle functions (*Rectangle*, *InvertRectangle*, *ImprintRectangle*, *RecoverRectangle*) have also been optimized to reuse calculated screen coordinates.

### System startup

Atari GEOS boots into a debug app with some graphics, menu and icon demo. Also the text prompt is active - try to type something.

This is not the proper startup yet - it should at least try to run Auto-Exec applications from RAM disk. In order to do it, the code has to be moved into higher memory area
(at least over $5000 out of current $2000).

### Players (sprites)

Player 0 is reserved for mouse pointer. Player 1 is reserved for text prompt, it will support fonts of any size.

Players 2 and 3 can be used by applications. The *DrawSprite* function takes VIC sprite format as input.
It will take every third byte to show the leftmost 8-pixels only. The sprite will appear stretched in X direction because VIC sprites have hires pixel size.

Missiles are not used.

### Memory

There are severe memory constraints. GEOS on C64 uses all available memory (64K), under I/O space and otherwise.

Atari has less RAM available because it can't switch off I/O and allocates whole 1K of RAM for sprites (Players).

Because of that:

    - part of space reserved for disk driver is now occupied by Kernal code - about 5 pages
    - a little bit of Kernal code resides in banked memory in bank 0

If a real disk driver comes (hint, hint) then some better separation and Kernal code banking (like on C128 in bank0 and under I/O space)
is needed. Probably graphics functions are best fit for that. Since $6000-$7FFF is used as a screen back buffer this means only $4000-$5FFF would be
usable for code, with space maybe for only one additional disk driver.

### Input devices

#### Pointer

A very simple joystick driver controls the mouse pointer. This driver doesn't support acceleration (but it should!).

Joystick driver can be changed during runtime, but you can't use any joystick drivers from GEOS64/128.

#### Keyboard

Mapping of special keys, mostly untested:

    - BREAK does nothing
    - CAPS is RUN/STOP
    - ESC is <- (left arrow)
    - SHIFT+Delete is Backspace
    - CTRL+1..8 is F1-F8
    - CTRL+Clear is Home
    - CTRL+Return is LineFeed
    - Tab is Tab, Clear is Clear, Delete is Del
    - Help is pound sign
    - cursor arrows Atari style (CTRL+arrow key)
    - Inv is supposed to be C= (Commodore key) for keyboard shortcuts

Other console keys (START, OPTION) are not scanned and not used.

### Disk drives

There is only one disk device: RAM drive.

The *SetDevice* function is unimplemented and it can't swap disk drivers, altough there would be enough space for it in expanded RAM.
Besides, part of GEOS Kernal code resides in disk driver space ($9000-$9D80) and would have to become banked code first.

The supposed disk driver for SIO devices may use hardware directly or via ROM code. There are functions *InitForIO* and *DoneForIO* that in GEOS64/128 prepare
the system for using ROM routines for I/O. GEOS doesn't touch memory in $0200-$03ff. Some of zero-page registers are used by the system, but they can be easily preserved.

The requirements for a disk driver are:

    - it needs to read/write 256-byte sectors at a time
    - sectors are addressed by 8-bit track and sector numbers
    - if a device responds to an identifier (disk drive number) it should be possible to change that identifier (DESK TOP uses this feature to swap third drive with one of the first two, but it's purely UI issue, not a system requirement)

GEOS Kernal implements on top of that a Commodore DOS-like file system. Track number 0 is forbidden, so the largest possible disk/partition (see my CIAIDE project) may have
up to 255 tracks, 256 sectors each for a total of almost 16MB.

Current RAM drive implementation:

    - uses expanded memory that starts in bank 1, bank 0 is reserved for GEOS Kernal
    - number of tracks is calculated during boot, according to amount of expanded memory
    - uses tracks with 128 sectors each
    - is limited in size because it uses only one sector as a directory header

### Printer drivers

There are none, they will have to be ported. See Disk Drive section for notes about ROM code use for SIO.

### Time and date

There is no CIA time-of-day (TOD) clock, timekeeping is done by counting vertical blank interrupts.

There is no support for alarm clock. It's tied to CIA TOD clock hardware feature. The system doesn't provide any function to set the alarm (it's done in hardware by a Desk Accessory)
you can only choose if/how it should react to the alarm. Also there is no POKEY replacement code for playing chimes.

There is no PAL/NTSC detection yet, the system is assumed to be PAL.

## Building the system

It's best to use Linux or WSL for that.

Install cc65 suite and:

    - run Makefile from cc65/apps (this will build filesel.cvt)
    - run mkramdisk.py from tools/ folder (this will build tools/image*.bin files with RAM disk)
    - run top-level Makefile to assemble system and link it into XEX file

The result is in build/atari/GEOS.XEX

You can try to put some new GEOS apps in CVT format (GEOS files converted to PRG (binary stream)) - just modify tools/mkramdisk.py and list them there.

### Going beyond 128K RAM disk

You would have to modify tools/mkramdisk.py and change the number of banks.

You would also have to modify linker script kernal/kernal_atari.cfg and add more RAM memory areas (beyond RAM0/1/2) mention them with initad in order (but before START) in FORMATS section
and list memory segments that are loaded into those memory areas.

Finally change kernal/hw/ramloader.s and list new segments with *.incbin* commands for more chunks to be loaded into banks.
