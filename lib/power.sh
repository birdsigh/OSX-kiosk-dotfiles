#!/bin/bash

# Never go into computer sleep mode.
sudo pmset sleep 0

# Restart automatically from power failure.
# autorestartatconnect is supported on Mac mini 2024+, Mac Studio 2025+, iMac 2024+.
# On older hardware this may have no effect.
sudo pmset autorestartatconnect 1

# Restart at 2am every day.
# Note: two separate pmset repeat calls conflict; only the last one takes effect.
# Using a single 'restart' event is cleaner and works on Apple Silicon.
sudo pmset repeat restart MTWRFSU 02:00:00
