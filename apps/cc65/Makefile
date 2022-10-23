
CFLAGS = -t geos -I /usr/local/share/cc65/include
ASFLAGS = -t geos -I /usr/local/share/cc65/asminc
LDFLAGS = -L /usr/local/share/cc65/lib -C /usr/local/share/cc65/cfg/geos-cbm.cfg

CL = cl65
CC = cc65
AS = ca65
LD = ld65
GRC = grc65

RESDEPS = \
	getid/getid.grc \
	geosver/geosver.grc \
	filesel/filesel.grc

CDEPS = \
	getid/getid.c \
	geosver/geosver.c \
	filesel/filesel.c

RESAS = $(RESDEPS:.grc=.grcs)
RESOBJS = $(RESDEPS:.grc=.grco)
CAS = $(CDEPS:.c=.s)
COBJS = $(CDEPS:.c=.o)

BUILD = build

BINS = \
	getid/getid.cvt \
	geosver/geosver.cvt \
	filesel/filesel.cvt

%.grcs: %.grc
	$(GRC) -s $@ $<

%.grco: %.grcs
	$(AS) $(ASFLAGS) -o $@ $<

%.s: %.c
	$(CC) $(CFLAGS) -o $@ $<

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

%.cvt: %.o %.grco
	$(LD) $(LDFLAGS) $^ geos-cbm.lib -o $@

all: $(CAS) $(COBJS) $(RESAS) $(COBJS) $(BINS)

clean:
	-rm -f $(RESAS) $(RESOBJS) $(CAS) $(COBJS) $(BINS)
