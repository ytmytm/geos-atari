#!/usr/bin/python3

# Atari RAM DISK image builder, Maciej Witkowiak, 2022

# this tool will build 3 or 15 chunks of 16K blocks that are loaded into expanded RAM
# (segments RAM0/RAM1/.. from kernal/kernal_atari.cfg)
# files need to be inclded by incbin in kernal/ramexp/ramexp1.s

# number of available memory banks-1
# 3  for 128K (130XE)
# 15 for 256K (320K)
# more is unsupported (will needs changes both here and in the disk driver - where to put BAM2/BAM3)

################## const.inc

# directory
#  disk header
OFF_TO_BAM              =       4
OFF_DISK_NAME           =       144
OFF_GS_DTYPE            =       189
OFF_OP_TR_SC            =       171
OFF_GS_ID               =       173
#  dir entry
FRST_FILE_ENTRY         =       2
OFF_CFILE_TYPE          =       0
OFF_DE_TR_SC            =       1
OFF_FNAME               =       3
OFF_GHDR_PTR            =       19
OFF_GSTRUC_TYPE         =       21
OFF_GFILE_TYPE          =       22
OFF_YEAR                =       23
OFF_SIZE                =       28
OFF_NXT_FILE            =       32

##################

def ts_to_page(track,sector):
	return (track-1)*128+sector

def page_to_ts(page):
	track = int(page/128)
	sector = page-track*128
	return (track+1,sector)

def page_to_offset(page):
	return page*256

def offset_to_page(offs):
	return int(offs/256)

def offset_to_ts(offs):
	return page_to_ts(offset_to_page(offs))

def formatImage(image, nbanks, nfiles=8, diskname="RAMDISKWITKOWIAKAAAAAAAA", diskid="64"):
	# format:
	# convert parameters to ascii and trim
	diskname = bytes(diskname.encode('ascii'))[0:16]
	diskid = bytes(diskid.encode('ascii'))[0:2]
	# to make it simple write (ff) into every 2nd byte in a block, no need for clear & write
	for k in range(1,nbanks*64):
		image[k*256+2] = 0xff
	# init disk header at (1,0)
	# - disk name+id + $a0 padding
	# - BAM (according to nbanks)
	# - geos format string
	# - first directory sector at (1,1) (required because of DESK TOP)
	#   as many directory sectors as needed to accomodate files
	# - border sector

	# padding
	image[OFF_DISK_NAME:OFF_DISK_NAME+16+13] = (16+13)*[0xa0]
	# write diskname user id and system id '2A', pad with $A0
	image[OFF_DISK_NAME:OFF_DISK_NAME+len(diskname)] = diskname
	image[OFF_DISK_NAME+16+2:OFF_DISK_NAME+16+2+2] = diskid
	image[OFF_DISK_NAME+16+2+2+1:OFF_DISK_NAME+16+2+2+2+1+2] = bytes("2A".encode('ascii'))
	# signature
	image[OFF_GS_ID:OFF_GS_ID+15] = bytes("GEOS format V1.0".encode("ascii"))
	# BAM (all free)
	for k in range(int(nbanks*64/8)):
		image[OFF_TO_BAM+k] = 0xff
	# link dir head to 1st dir sector at (1,2)
	image[0] = 1
	image[1] = 1
	freePage = 1 # 0,1 already occupied
	needDirSectors = int(nfiles/8)
	print(f'need {needDirSectors} for directory')
	for k in range(0,needDirSectors):
		print(f'link 1,{freePage+1} to sector 1,{freePage} at {freePage*256}')
		# link to the next one
		image[freePage*256] = 1
		image[freePage*256+1] = freePage+1
		freePage = freePage + 1
	# link to border sector at (1,freePage)
	freePage = freePage+1
	image[OFF_OP_TR_SC] = 1
	image[OFF_OP_TR_SC+1] = freePage
	# return first free page (1,3) = (1-1)*128+3 = 3
	freePage = freePage+1
	return freePage


def writeImageChunks(image, nbanks, prefix = "image"):
	# write the outputs
	for k in range(nbanks):
		outfile = open(f'{prefix}{format(k,"02x")}.bin',"wb")
		print(f'writing {format(k,"02x")} from ${format(k*0x4000,"04x")} to ${format((k+1)*0x4000,"04x")}')
		outfile.write(image[k*0x4000:(k+1)*0x4000])
		outfile.close()

def copyDirEntry(image, nFiles, dirEntry):
	# directory blocks start on page 1 and there is enough of them to hold all the files
	offs = 0x100 + nFiles*32 + 2
	image[offs:offs+30] = dirEntry[0:30]

def allocateUntilPage(image,lastPage):
	# allocate until freepage in BAM
	#  full bytes (8 pages)
	fullBytes = int(lastPage/8)
	for n in range(fullBytes):
		image[OFF_TO_BAM+n] = 0
	k = lastPage - 8*fullBytes
	#  last incomplete byte
	if (k!=0):
		image[OFF_TO_BAM+fullBytes] = (0x100 - (1 << k)) & 0xff

def writeCVTFile(image,fname,freePage,nFiles):
	print(f'{fname}')
	with open(fname,"rb") as f:
		direntry = bytearray(f.read(254))
		header   = bytearray(f.read(254))
		data     = bytearray(f.read(-1))
		print(f'\ttotal data has {len(data)} bytes')
#		print(f'{direntry[33:34+21].decode("ascii")}')
		signature = (direntry[33:34+19].decode('ascii') == ' formatted GEOS file')
		if not signature:
			print(f'{fname} is not a GEOS Converted file, skipping')
			return(nFiles,freePage)
		datachunks = []
		for n in range(int(len(data)/254)+1):
			datachunks.append(data[n*254:(n+1)*254])
		print(f'\t{len(datachunks)} sectors')
#		for n in range(len(datachunks)):
#			print(f'chunk {n} has {len(datachunks[n])} bytes')
		# store header on first free page
		offs = page_to_offset(freePage)+2
		image[offs:offs+254] = header
		# store header t&s in direntry
		direntry[OFF_GHDR_PTR:OFF_GHDR_PTR+2] = page_to_ts(freePage)
		freePage = freePage+1
		# is this VLIR?
#		print(f'structure : {direntry[OFF_GSTRUC_TYPE]}')
		isVLIR = (direntry[OFF_GSTRUC_TYPE]!=0)
		# store data t&s in direntry
		if (isVLIR):
			print("\tthis is a VLIR file")
			recordPage = freePage
		direntry[OFF_DE_TR_SC:OFF_DE_TR_SC+2] = page_to_ts(freePage)
		# store size in direntry
		sizehi = int((1+len(datachunks))/256)
		sizelo = 1+len(datachunks) - sizehi*256
		direntry[OFF_SIZE] = sizelo
		direntry[OFF_SIZE+1] = sizehi
		# store data on following pages
		for n in range(len(datachunks)):
			offs = page_to_offset(freePage)+2
			if (n+1 == len(datachunks)): # if last block - last used byte in that block
				image[offs-1] = len(datachunks[n])+1
				image[offs:offs+len(datachunks[n])] = datachunks[n]
			else:
				image[offs:offs+254] = datachunks[n]
				image[offs-2:offs]   = page_to_ts(freePage+1)
			freePage = freePage+1
		# copy direntry into directory
		copyDirEntry(image,nFiles,direntry)
		# data was stored in one run, now go back and adjust VLIR chains if needed
		if isVLIR:
			print(f"\tadjusting VLIR chains, record block on page ${format(recordPage,'04x')}")
			offs = page_to_offset(recordPage)
			filePage = recordPage+1
			image[offs] = 0
			image[offs+1] = 0xff
			offs = offs + 2
			for chain in range(0,127):
				if image[offs]>0:
					npages = image[offs]
					lastbyte = image[offs+1]
					print(f'\tfound chain {chain} at {format(filePage,"04x")} ({npages} long, last byte {lastbyte})')
					image[offs:offs+2] = page_to_ts(filePage)	# adjust record pointer
					filePage = filePage + npages
					offs_chain = page_to_offset(filePage-1)
					image[offs_chain] = 0
					image[offs_chain+1] = lastbyte			# adjust last sector - last used byte (we don't keep earlier value because on RAM disk the interleave is 1, next chunk starts in the following page)
				offs = offs+2
	return (nFiles+1,freePage)

######### MAIN

import argparse

import pdb

parser = argparse.ArgumentParser(description='Build RAM disk image for Atari GEOS')
parser.add_argument('files',metavar='FILE.CVT',type=str,nargs='+',help=".cvt files to be copied")
parser.add_argument('--outfile','-o',metavar='IMAGE',type=str,help="output file name prefix",default="image")
parser.add_argument('--nbanks','-n',type=int,help="number of memory banks (16K each), 4 for 130XE, 16 for 320K",default=4,choices=[4,16])

args = parser.parse_args()

args.nbanks = args.nbanks - 1                           # skip bank 0

# mutable buffer to hold the data
image = bytearray(args.nbanks * 0x4000+1)		# why +1? is that right?

# format image and return first free page
freePage = formatImage(image,args.nbanks,len(args.files))

print(f'{len(args.files)} files to import')

# there are no files in the image yet
nFiles = 0
for fname in args.files:
	(nFiles,freePage) = writeCVTFile(image,fname,freePage,nFiles)

print(f'{nFiles} imported')

print(f"last available page is {format(freePage,'04x')} out of {format(args.nbanks*64,'04x')}, {format(args.nbanks*64-freePage,'04x')} sectors remaining")

allocateUntilPage(image,freePage)

writeImageChunks(image, args.nbanks, args.outfile)
