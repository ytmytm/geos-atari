# GEOS Atari port

GEOS 2.0 by Berkeley Softworks

This is a fork of [GEOS 2.0 for C64/128 reverse-engineered](https://github.com/mist64/geos) by *Maciej Witkowiak*, *Michael Steil*

GEOS 2.0 ported to 8-bit Atari by *Maciej Witkowiak*

## What is GEOS?

Please read main README.md for that.

## Atari port requirements

An 8-bit Atari computer with at least 128K of RAM: 130XE or expanded 65XE as a minimum.

Except the very first bank, whole extra memory is meant to be used by RAM disk.

Right now memory above 320K is not used. The disk driver can address it but it doesn't have space for extra
Block Allocation Maps (BAMs) and so the image creator can't write such images.

There is only RAM disk available at the moment. I don't know how to handle communication with disk drives over SIO.
Please help if you can!

Unlike Apple 2 version, this port is *binary compatible with well-behaved GEOS software released for C64/128*.

Unfortunately even some of BSW's own software for GEOS 64 make assumptions about the system that may cause (in best scenario) visual glitches.
Many of these issues were later corrected for GEOS 128 due to 80-column mode support, but this port doesn't try to be compatible with GEOS128.

## Quickstart

Download one of the XEX files from the Releases section. Such file contains RAM disk image, GEOS Kernal, disk driver, input driver and loader for the whole thing.

Run emulator and make sure to choose PAL system with at least 128K/320K of RAM. Setup joystick in port 1. Load the XEX file into emulator.

GEOS will boot into DeskTop in just few seconds.

## Atari port remarks

### Compatibility

This port has no reference implementation so I felt free to remove conditional C64/C128/Wheels/Gateway
code whenever I touched the files.

Order of segments is also rearranged to make the best use of available memory segments.

Well-beaved applications that run on both GEOS 64 and GEOS 128 (in 80-column mode) should also run on Atari.

BSW's own applications are not that well behaved. They write to VIC registers directly and use [custom screen recovery](https://www.pagetable.com/?p=1428) to save some RAM, but that recovery routine works on bitmap in VIC format.

You will have better luck trying out random GEOS software from 3rd party developers rather than running BSW flagship products. It shouldn't be too hard to patch some of the big applications (GeoPaint, GeoWrite and friends) to make them work in a reasonable way.

Compatibility problems come from:

- hardware differences (Atari Players vs VIC sprites, POKEY vs SID)
- memory map changes (hires bitmap screen with different organization for ANTIC than for VIC)
- missing capatibilities (24-pixel wide sprites, color matrix for hires mode)

Programs will not work correctly if:

- they use sprites or change their colors (e.g. Preferences Manager)
- they change color matrix in 40-column mode (e.g. DESK TOP)
- they require REU
- they access bitmap screen in 40-column mode directly (e.g. Maverick)
- they have custom recovery routine (e.g. GeoWrite)
- they write directly to I/O registers (e.g printer drivers)

They may not work at all or show some graphical glitches. For example, if an application tries to add some color it will write to `COLOR_MATRIX` space, which is now occupied by Player0/1/2/3 data, so mouse pointer will be temporarily overwritten.

Just like on C64 the processes (sleep and multitasking) are clocked by video frame rate.

### Performance

Atari port is supposedly faster than C64/128. It has higher CPU clock rate and linear screen organization that is easier to handle than VIC bitmap.

Keyboard has its own interrupt and doesn't have to be scanned for every row/column.

All the rectangle functions (*Rectangle*, *InvertRectangle*, *ImprintRectangle*, *RecoverRectangle*) have also been optimized to reuse calculated screen coordinates.

### System startup

The boot code jumps right into DeskTop, but it should at least try to run Auto-Exec applications from RAM disk.
In order to do it, that code has to be moved into higher memory area (at least over $5000 out of current $2000).

### Players (sprites)

Player 0 is reserved for mouse pointer. Player 1 is reserved for text prompt, it will support fonts of any size.

Players 2 and 3 can be used by applications. The *DrawSprite* function takes VIC sprite format as input.
It will take every third byte to show the leftmost 8-pixels only. The sprite will appear stretched in X direction because VIC sprites have hires pixel size.

Missiles are not used.

### Memory

There are severe memory constraints. GEOS on C64 uses all available memory (64K), under I/O space and otherwise.

Atari has less RAM available because it can't switch off I/O and allocates whole 1K of RAM for sprites (Players).

Because of that part of space reserved for disk driver is now occupied by Kernal code (about 5 pages) and
a little bit of Kernal code resides in banked memory in bank 0.

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

GEOS Kernal implements on top of that a Commodore DOS-like file system. Track number 0 is forbidden, so the largest possible disk/partition (see my [CIAIDE project](https://github.com/ytmytm/c64-ciaide)) may have
up to 255 tracks, 256 sectors each for a total of almost 16MB.

Current RAM drive implementation:

- uses expanded memory that starts in bank 1, bank 0 is reserved for GEOS Kernal
- uses tracks with 128 sectors each
- DeskTop ignores track&sector information for disk directory so track 18 (directory) is mapped to track 1

### Printer drivers

There are none, they will have to be ported. See Disk Drive section for notes about ROM code use for SIO.

### Time and date

There is no CIA time-of-day (TOD) clock, timekeeping is done by counting vertical blank interrupts. During banked operations a short interrupt routine is called and some of these events may be lost.

Clock in DeskTop doesn't work, my guess is that DeskTop tries to read CIA registers directly.

There is no support for alarm clock. It's tied to CIA TOD clock hardware feature.
The system doesn't provide any function to set the alarm (it's done in hardware by a Desk Accessory) you can only choose if/how it should react to the alarm.
There is no POKEY replacement code for playing sound chimes.

There is no PAL/NTSC detection yet, the system is assumed to be PAL.

## Building the system

It's best to use Linux or WSL for that.

Install Python3 and cc65 suite and then:

- if you like, run Makefile from `cc65/apps` (this will build filesel.cvt - tiny application launcher for DeskTop replacement among others)
- put the CVT files that you want to have in the system into `ramdisk/cvt/`
- run top-level Makefile to assemble system and link it into XEX file

By default Makefile will produce file for a system with 128K (130XE). For more, pass `SYSTEM=atari320` option:
```
make SYSTEM=atari320
```

The result is in `build/<atari system>/GEOS<atari system>.XEX` file, ready to be used with an emulator.
