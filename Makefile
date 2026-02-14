# Makefile for Calamares Configuration Editor

CC = gcc
CFLAGS = `pkg-config --cflags gtk+-3.0` -Wall -Wextra -O2
LIBS = `pkg-config --libs gtk+-3.0`
TARGET = calamares-config-editor
SRC = calamares-config-editor.c

.PHONY: all clean install run

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS) $(LIBS)

run: $(TARGET)
	./$(TARGET)

install: $(TARGET)
	install -Dm755 $(TARGET) /usr/local/bin/$(TARGET)

clean:
	rm -f $(TARGET)

help:
	@echo "Calamares Configuration Editor - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make        - Build the application"
	@echo "  make run    - Build and run the application"
	@echo "  make install- Install to /usr/local/bin (requires sudo)"
	@echo "  make clean  - Remove built files"
	@echo ""
	@echo "Requirements:"
	@echo "  - GTK3 development libraries (gtk3 or libgtk-3-dev)"
	@echo "  - pkg-config"
	@echo ""
	@echo "Example:"
	@echo "  sudo pacman -S gtk3  # Install GTK3 on Arch Linux"
	@echo "  make                 # Build"
	@echo "  make run             # Run"
