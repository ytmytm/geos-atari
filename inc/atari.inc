
ATARI_EXPBASE	= $4000			; base address for banked memory

; defines copied from LUnix Next Generation

ANTIC 		= $d400

ANTIC_DMACTL	= ANTIC+0		; direct memory access control
ANTIC_CHACTL	= ANTIC+1		; character mode control
ANTIC_DLISTL	= ANTIC+2		; display list pointer lo
ANTIC_DLISTH	= ANTIC+3		; display list pointer hi
ANTIC_VSCROL	= ANTIC+4		; vertical scroll enable
ANTIC_HSCROL	= ANTIC+5		; horizontal scroll enable
;//ANTIC_UNUSED	= ANTIC+6		; unused
ANTIC_PMBASE	= ANTIC+7		; p/m base address hi
;//ANTIC_UNUSED	= ANTIC+8		; unused
ANTIC_CHBASE	= ANTIC+9		; character base address
ANTIC_WSYNC	= ANTIC+10	; wait for horizontal synchronization
ANTIC_VCOUNT	= ANTIC+11	; vertical line counter
ANTIC_PENH	= ANTIC+12	; light pen horizontal position
ANTIC_PENL	= ANTIC+13	; light pen vertical position
ANTIC_NMIEN	= ANTIC+14	; non-maskable interrupt enable
ANTIC_NMIRES	= ANTIC+15	; nmi reset/status

GTIA		= $d000

;// write only registers
GTIA_HPOSP0	= GTIA+0		; horizontal position player 0
GTIA_HPOSP1	= GTIA+1		; horizontal position player 1
GTIA_HPOSP2	= GTIA+2		; horizontal position player 2
GTIA_HPOSP3	= GTIA+3		; horizontal position player 3
GTIA_HPOSM0	= GTIA+4		; horizontal position missile 0
GTIA_HPOSM1	= GTIA+5		; horizontal position missile 1
GTIA_HPOSM2	= GTIA+6		; horizontal position missile 2
GTIA_HPOSM3	= GTIA+7		; horizontal position missile 3
GTIA_SIZEP0	= GTIA+8		; size of player 0
GTIA_SIZEP1	= GTIA+9		; size of player 1
GTIA_SIZEP2	= GTIA+10		; size of player 2
GTIA_SIZEP3	= GTIA+11		; size of player 3
GTIA_SIZEM	= GTIA+12		; size of missiles
GTIA_GRAFP0	= GTIA+13		; graphics shape of player 0
GTIA_GRAFP1	= GTIA+14		; graphics shape of player 1
GTIA_GRAFP2	= GTIA+15		; graphics shape of player 2
GTIA_GRAFP3	= GTIA+16		; graphics shape of player 3
GTIA_GRAFM	= GTIA+17		; graphics shape of missiles
GTIA_COLPM0	= GTIA+18		; color player and missile 0
GTIA_COLPM1	= GTIA+19		; color player and missile 1
GTIA_COLPM2	= GTIA+20		; color player and missile 2
GTIA_COLPM3	= GTIA+21		; color player and missile 3
GTIA_COLPF0	= GTIA+22		; color playfield 0
GTIA_COLPF1	= GTIA+23		; color playfield 1
GTIA_COLPF2	= GTIA+24		; color playfield 2
GTIA_COLPF3	= GTIA+25		; color playfield 3
GTIA_COLBK	= GTIA+26		; color background
GTIA_PRIOR	= GTIA+27		; priority selection
GTIA_VDELAY	= GTIA+28		; vertical delay
GTIA_GRACTL	= GTIA+29		; stick/paddle latch, p/m control
GTIA_HITCTL	= GTIA+30		; clear p/m collision
GTIA_CONSOL	= GTIA+31		; console buttons (r/w)

;// read only registers
GTIA_M0PF	= GTIA+0		; missile 0 to playfield collision
GTIA_M1PF	= GTIA+1		; missile 1 to playfield collision
GTIA_M2PF	= GTIA+2		; missile 2 to playfield collision
GTIA_M3PF	= GTIA+3		; missile 3 to playfield collision
GTIA_P0PF	= GTIA+4		; player 0 to playfield collision
GTIA_P1PF	= GTIA+5		; player 1 to playfield collision
GTIA_P2PF	= GTIA+6		; player 2 to playfield collision
GTIA_P3PF	= GTIA+7		; player 3 to playfield collision
GTIA_M0PL	= GTIA+8		; missile 0 to player collision
GTIA_M1PL	= GTIA+9		; missile 1 to player collision
GTIA_M2PL	= GTIA+10		; missile 2 to player collision
GTIA_M3PL	= GTIA+11		; missile 3 to player collision
GTIA_P0PL	= GTIA+12		; player 0 to player collision
GTIA_P1PL	= GTIA+13		; player 1 to player collision
GTIA_P2PL	= GTIA+14		; player 2 to player collision
GTIA_P3PL	= GTIA+15		; player 3 to player collision
GTIA_TRIG0	= GTIA+16		; joystick trigger 0
GTIA_TRIG1	= GTIA+17		; joystick trigger 1
GTIA_TRIG2	= GTIA+18		; joystick trigger 2
GTIA_TRIG3	= GTIA+19		; joystick trigger 3
GTIA_PAL	= GTIA+20		; pal/ntsc flag

PIA		= $d300

PIA_PORTA	= PIA+0		; port A data r/w
PIA_PORTB	= PIA+1		; port B data r/w
PIA_PACTL	= PIA+2		; port A control
PIA_PBCTL	= PIA+3		; port B control

POKEY		= $d200

;// Pokey register map

;// write only registers
POKEY_AUDF1	= POKEY+0		; audio channel #1 frequency
POKEY_AUDC1	= POKEY+1		; audio channel #1 control
POKEY_AUDF2	= POKEY+2		; audio channel #2 frequency
POKEY_AUDC2	= POKEY+3		; audio channel #2 control
POKEY_AUDF3	= POKEY+4		; audio channel #3 frequency
POKEY_AUDC3	= POKEY+5		; audio channel #3 control
POKEY_AUDF4	= POKEY+6		; audio channel #4 frequency
POKEY_AUDC4	= POKEY+7		; audio channel #4 control
POKEY_AUDCTL	= POKEY+8		; audio control
POKEY_STIMER	= POKEY+9		; start pokey timers
POKEY_SKREST	= POKEY+10	; reset serial port status reg.
POKEY_POTGO	= POKEY+11	; start paddle scan sequence
;//POKEY_UNUSED	= POKEY+12	; unused
POKEY_SEROUT	= POKEY+13	; serial port data output
POKEY_IRQEN	= POKEY+14	; interrupt request enable
POKEY_SKCTL	= POKEY+15	; serial port control

;// read only registers
POKEY_POT0	= POKEY+0		; paddle 0 value
POKEY_POT1	= POKEY+1		; paddle 1 value
POKEY_POT2	= POKEY+2		; paddle 2 value
POKEY_POT3	= POKEY+3		; paddle 3 value
POKEY_POT4	= POKEY+4		; paddle 4 value
POKEY_POT5	= POKEY+5		; paddle 5 value
POKEY_POT6	= POKEY+6		; paddle 6 value
POKEY_POT7	= POKEY+7		; paddle 7 value
POKEY_ALLPOT	= POKEY+8		; eight paddle port status
POKEY_KBCODE	= POKEY+9		; keyboard code
POKEY_RANDOM	= POKEY+10	; random number generator
;//POKEY_UNUSED	= POKEY+11	; unused
;//POKEY_UNUSED	= POKEY+12	; unused
POKEY_SERIN	= POKEY+13	; serial port input
POKEY_IRQST	= POKEY+14	; interrupt request status
POKEY_SKSTAT	= POKEY+15	; serial port status
