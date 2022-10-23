#!/usr/bin/python3

print("Hello!")

# this will be created out of a command line option
# split this by $4000 pieces already?
outname = "image.bin"

# number of available memory banks-1
# 3  for 128K (130XE)
# 15 for 256K (320K)
# more unsupported (needs changes both here and in the disk driver - where to put BAM2/BAM3)
# this will be created out of a command line option
nbanks = 3

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

def formatImage(image, nbanks, diskname="RAMDISKWITKOWIAKAAAAAAAA", diskid="64"):
	# format:
	# convert parameters to ascii and trim
	diskname = bytes(diskname.encode('ascii'))[0:16]
	diskid = bytes(diskid.encode('ascii'))[0:2]
	# to make it simple write (ff) into every 2nd byte in a block, no need for clear & write
	for k in range(1,nbanks*64):
		image[k*256+2] = 0xff
		image[k*256+3] = (k & 0xff00) >> 8	# page number marker for debug
		image[k*256+4] = k & 0xff
	# init disk header at (1,0)
	# - disk name+id + $a0 padding
	# - BAM (according to nbanks)
	# - geos format string
	# - border sector at (1,1)
	# - first directory sector at (1,2)
	# - allocate (1,0),(1,1),(1,2) in BAM already
	# - setup link from (1,0) to (1,2)

	# padding
	image[OFF_DISK_NAME:OFF_DISK_NAME+16+13] = (16+13)*[0xa0]
	# write diskname user id and system id '2A', pad with $A0
	image[OFF_DISK_NAME:OFF_DISK_NAME+len(diskname)] = diskname
	image[OFF_DISK_NAME+16+2:OFF_DISK_NAME+16+2+2] = diskid
	image[OFF_DISK_NAME+16+2+2+1:OFF_DISK_NAME+16+2+2+2+1+2] = bytes("2A".encode('ascii'))
	# link to border sector at (1,1)
	image[OFF_OP_TR_SC] = 1
	image[OFF_OP_TR_SC+1] = 1
	# signature
	image[OFF_GS_ID:OFF_GS_ID+15] = bytes("GEOS format V1.0".encode("ascii"))
	# BAM (all free)
	for k in range(int(nbanks*64/8)):
		image[OFF_TO_BAM+k] = 0xff
	# allocate first 3 sectors on track 0 (head, border, 1st dir)
#	image[OFF_TO_BAM] = image[OFF_TO_BAM] & 0b11111000
	# link dir head to 1st dir sector
	image[0] = 1
	image[1] = 2
	# return first free page (1,3) = (1-1)*128+3 = 3
	return 3


def writeImageChunks(image, nbanks, prefix = "image"):
	# write the outputs
	for k in range(nbanks):
		outfile = open(f'{prefix}{format(k,"02x")}.bin',"wb")
		print(f'writing {format(k,"02x")} from {k*0x4000} to {(k+1)*0x4000}')
		outfile.write(image[k*0x4000:(k+1)*0x4000])
		outfile.close()

######### MAIN

# buffer to hold the data
image = bytearray(nbanks * 0x4000)

# format image and return first free page
freePage = formatImage(image,nbanks)
# there are no files in the image (up to 8)
nFiles = 0

def copyDirEntry(image, nFiles, dirEntry):
	# directory block on page 2
	offs = 0x200 + nFiles*32 + 2
	image[offs:offs+30] = dirEntry[0:30]


# load 1st file
if (True):
	with open("yesno.cvt","rb") as f:
		direntry = bytearray(f.read(254))
		header   = bytearray(f.read(254))
		data     = bytearray(f.read(-1))
		print(f'data is {len(data)} bytes')
		datachunks = []
		for n in range(int(len(data)/254)+1):
			datachunks.append(data[n*254:(n+1)*254])
		print(f'{len(datachunks)} chunks')
		for n in range(len(datachunks)):
			print(f'chunk {n} has {len(datachunks[n])} bytes')
		# store header on first free page
		offs = page_to_offset(freePage)+2
		image[offs:offs+254] = header
		# store header t&s in direntry
		direntry[OFF_GHDR_PTR:OFF_GHDR_PTR+2] = page_to_ts(freePage)
		freePage = freePage+1
		# store data t&s in direntry
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
		nFiles = nFiles+1

if (True):
	with open("geosver.cvt","rb") as f:
		direntry = bytearray(f.read(254))
		header   = bytearray(f.read(254))
		data     = bytearray(f.read(-1))
		print(f'data is {len(data)} bytes')
		datachunks = []
		for n in range(int(len(data)/254)+1):
			datachunks.append(data[n*254:(n+1)*254])
		print(f'{len(datachunks)} chunks')
		for n in range(len(datachunks)):
			print(f'chunk {n} has {len(datachunks[n])} bytes')
		# store header on first free page
		offs = page_to_offset(freePage)+2
		image[offs:offs+254] = header
		# store header t&s in direntry
		direntry[OFF_GHDR_PTR:OFF_GHDR_PTR+2] = page_to_ts(freePage)
		freePage = freePage+1
		# store data t&s in direntry
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
		nFiles = nFiles+1

if (True):
	with open("getid.cvt","rb") as f:
		direntry = bytearray(f.read(254))
		header   = bytearray(f.read(254))
		data     = bytearray(f.read(-1))
		print(f'data is {len(data)} bytes')
		datachunks = []
		for n in range(int(len(data)/254)+1):
			datachunks.append(data[n*254:(n+1)*254])
		print(f'{len(datachunks)} chunks')
		for n in range(len(datachunks)):
			print(f'chunk {n} has {len(datachunks[n])} bytes')
		# store header on first free page
		offs = page_to_offset(freePage)+2
		image[offs:offs+254] = header
		# store header t&s in direntry
		direntry[OFF_GHDR_PTR:OFF_GHDR_PTR+2] = page_to_ts(freePage)
		freePage = freePage+1
		# store data t&s in direntry
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
		nFiles = nFiles+1

if (True):
	with open("filesel.cvt","rb") as f:
		direntry = bytearray(f.read(254))
		header   = bytearray(f.read(254))
		data     = bytearray(f.read(-1))
		print(f'data is {len(data)} bytes')
		datachunks = []
		for n in range(int(len(data)/254)+1):
			datachunks.append(data[n*254:(n+1)*254])
		print(f'{len(datachunks)} chunks')
		for n in range(len(datachunks)):
			print(f'chunk {n} has {len(datachunks[n])} bytes')
		# store header on first free page
		offs = page_to_offset(freePage)+2
		image[offs:offs+254] = header
		# store header t&s in direntry
		direntry[OFF_GHDR_PTR:OFF_GHDR_PTR+2] = page_to_ts(freePage)
		freePage = freePage+1
		# store data t&s in direntry
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
		nFiles = nFiles+1


# allocate until freepage in BAM
fullBytes = int(freePage/8)
for n in range(fullBytes):
	image[OFF_TO_BAM+n] = 0
k = freePage - 8*fullBytes
if (k!=0):
	image[OFF_TO_BAM+fullBytes] = (0x100 - (1 << k)) & 0xff

#print(f'Have {len(buf)} bytes')

writeImageChunks(image, nbanks)
