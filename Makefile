CC 			= gcc
CFLAGS 		= -Wall -O3
LDFLAGS 	= -lbcm2835 -lm
HEADERS 	= GPIO.h leds.h parser.h
EXECUTABLE 	= lyftcube
SOURCES 	= lyftcube.c GPIO.c leds.c parser.c
OBJECTS 	= $(SOURCES:.c=.o)

all: $(EXECUTABLE)

%.o: %.c $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

$(EXECUTABLE):: $(OBJECTS) $(HEADERS)
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -rf *.o $(EXECUTABLE)
