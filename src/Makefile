# Makefile for tanklight project


MCU		= attiny13
F_CPU	= 9600000
L_FUSE	= 0x7A
H_FUSE	= 0xFF


# Main target
TARGET=tanklights

FORMAT=ihex

# assembler
AVRA=avra

# Extra includes, part headers, etc.
INCLUDES=/usr/share/avra

ASMFLAGS=



#---------------- Programming Options (avrdude) ----------------
# Programming hardware
# Type: avrdude -c ?
# to get a full listing.
#
AVRDUDE_PROGRAMMER = stk500v2

# com1 = serial port. Use lpt1 to connect to parallel port.
AVRDUDE_PORT = /dev/ttyACM0    # programmer connected to serial device

AVRDUDE_WRITE_FLASH = -U flash:w:$(TARGET).hex
AVRDUDE_WRITE_EEPROM = -U eeprom:w:$(TARGET).eep.hex


# Uncomment the following if you want avrdude's erase cycle counter.
# Note that this counter needs to be initialized first using -Yn,
# see avrdude manual.
#AVRDUDE_ERASE_COUNTER = -y

# Uncomment the following if you do /not/ wish a verification to be
# performed after programming the device.
#AVRDUDE_NO_VERIFY = -V

# Increase verbosity level.  Please use this when submitting bug
# reports about avrdude. See <http://savannah.nongnu.org/projects/avrdude> 
# to submit bug reports.
#AVRDUDE_VERBOSE = -v -v

# Force avrdude
#AVRDUDE_OVERRIDE = -F

AVRDUDE_FLAGS = -p $(MCU) -P $(AVRDUDE_PORT) -c $(AVRDUDE_PROGRAMMER)
AVRDUDE_FLAGS += $(AVRDUDE_BITCLOCK)
AVRDUDE_FLAGS += $(AVRDUDE_NO_VERIFY)
AVRDUDE_FLAGS += $(AVRDUDE_VERBOSE)
AVRDUDE_FLAGS += $(AVRDUDE_ERASE_COUNTER)
AVRDUDE_FLAGS += $(AVRDUDE_OVERRIDE)



#---------------- Programming Options (avrdude) ----------------
# Programs
REMOVE = rm
SIZE = avr-size
AVRDUDE = avrdude
REMOVE = rm -f
REMOVEDIR = rm -rf


# Messages
MSG_BUILD = Compiling $(TARGET)
MSG_CLEANING = Cleaning build files
MSG_SIZE_BEFORE = Size before:
MSG_SIZE_AFTER = Size after:

all:	begin sizebefore build sizeafter end

begin:
	@echo
	@echo $(MSG_BUILD)

end:
	@echo


HEXSIZE = $(SIZE) $(TARGET).hex

sizebefore:
	@if test -f $(TARGET).hex; then echo; echo $(MSG_SIZE_BEFORE); $(HEXSIZE); \
	2>/dev/null; echo; fi

sizeafter:
	@if test -f $(TARGET).hex; then echo; echo $(MSG_SIZE_AFTER); $(HEXSIZE); \
	2>/dev/null; echo; fi


reeprom:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U eeprom:r:.\eeprom.txt:d

weeprom:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U eeprom:w:.\$(TARGET).eep.hex:d


# Program the device.  
program: begin sizebefore build sizeafter end
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH) $(AVRDUDE_WRITE_EEPROM)


# Write fuse values
wfuses:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U lfuse:w:$(L_FUSE):m -U hfuse:w:$(H_FUSE):m


# Read fuse values
rfuses:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U lfuse:r:.\fuse-l.txt:h -U hfuse:r:.\fuse-h.txt:h


build:
	@$(AVRA) $(TARGET).asm \
	-I $(INCLUDES) \
	2>/dev/null

clean: clean_list end


clean_list:
	@echo
	@echo $(MSG_CLEANING)
	$(REMOVE) $(TARGET).hex
	$(REMOVE) $(TARGET).eep.hex
	$(REMOVE) $(TARGET).cof
	$(REMOVE) $(TARGET).obj
 