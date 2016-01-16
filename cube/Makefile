CC 			= gcc
SUDO		= /usr/bin/sudo
CFLAGS 		= -Wall -O3 -std=gnu99
LDFLAGS 	= -lbcm2835 -lm -lgif
HEADERS 	= GPIO.h animation.h parser.h
EXECUTABLE 	= lyftcube
SOURCES 	= lyftcube.c GPIO.c animation.c parser.c
OBJECTS 	= $(SOURCES:.c=.o)

all: $(EXECUTABLE) permissions
	@cd server; make

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

$(EXECUTABLE):: $(OBJECTS) $(HEADERS)
	$(CC) -o $@ $^ $(LDFLAGS)

permissions: 
	$(SUDO) chown root:lyftcube $(EXECUTABLE)
	$(SUDO) chmod 4750 $(EXECUTABLE)

clean:
	rm -rf *.o $(EXECUTABLE)
	@cd server; make clean
