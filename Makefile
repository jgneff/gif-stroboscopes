# ======================================================================
# Makefile - creates bilevel animated GIFs from image sequences
# Copyright (C) 2019 John Neffenger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ======================================================================
SHELL = /bin/bash

# Commands
CONVERT = convert
MKBITMAP = mkbitmap
POTRACE = potrace
INKSCAPE = inkscape

# Command options
POTRACE_FLAGS = --backend svg --resolution 90 --turdsize 64
INKSCAPE_FLAGS = --export-height=600

# Bitmap options (defaults: -f 4 -s 2 -3 -t 0.45)
stampfer_bitmap = --filter 12 --scale 2 --cubic --threshold 0.45
baynes_bitmap = --filter 16 --scale 2 --cubic --threshold 0.48

# Image processing options
monochrome = -layers Flatten -dither None -monochrome -negate
animation = -delay 13 -dispose None -loop 0 -background white
extract = -coalesce -scene 1
stampfer_threshold = -resize x600 -threshold 45% -background white
baynes_threshold = -resize x600 -threshold 50% -background white

# Lists of targets and prerequisites
stampfer_seq := {01,04,07,10,13,17,20,23,26,29}
stampfer_ppm_list := $(shell echo stampfer/frame-$(stampfer_seq).ppm)
stampfer_gif_list := $(shell echo stampfer/frame-$(stampfer_seq).gif)
stampfer_pbm_list := $(shell echo stampfer/cutoff-$(stampfer_seq).pbm)

baynes_seq := {01..16}
baynes_ppm_list := $(shell echo baynes/frame-$(baynes_seq).ppm)
baynes_gif_list := $(shell echo baynes/frame-$(baynes_seq).gif)
baynes_pbm_list := $(shell echo baynes/cutoff-$(baynes_seq).pbm)

# ======================================================================
# Pattern Rules
# ======================================================================

stampfer/%.pbm: stampfer/%.ppm
	$(MKBITMAP) $(stampfer_bitmap) --output $@ $<

baynes/%.pbm: baynes/%.ppm
	$(MKBITMAP) $(baynes_bitmap) --output $@ $<

stampfer/cutoff-%.pbm: stampfer/frame-%.ppm
	$(CONVERT) $< $(stampfer_threshold) $@

baynes/cutoff-%.pbm: baynes/frame-%.ppm
	$(CONVERT) $< $(baynes_threshold) $@

%.svg: %.pbm
	$(POTRACE) $(POTRACE_FLAGS) --output $@ $<

%.png: %.svg
	$(INKSCAPE) $(INKSCAPE_FLAGS) --export-png=$@ $<

%.gif: %.png
	$(CONVERT) $< $(monochrome) $@

# ======================================================================
# Explicit rules
# ======================================================================

.PHONY: all clean

all: stroboscope-stampfer.gif stroboscope-stampfer-cutoff.gif \
    stroboscope-baynes.gif stroboscope-baynes-cutoff.gif

$(stampfer_ppm_list): extracted_stampfer

$(baynes_ppm_list): extracted_baynes

extracted_stampfer: src/Prof._Stampfer's_Stroboscopische_Scheibe_No._X.gif
	$(CONVERT) "$^" $(extract) stampfer/frame-%02d.ppm
	touch $@

extracted_baynes: src/Animated_phenakistiscope_disc_-_Running_rats_Fantascope_by_Thomas_Mann_Baynes_1833.gif
	$(CONVERT) "$^" $(extract) baynes/frame-%02d.ppm
	touch $@

stroboscope-stampfer.gif: $(stampfer_gif_list)
	$(CONVERT) $(animation) $^ $@

stroboscope-stampfer-cutoff.gif: $(stampfer_pbm_list)
	$(CONVERT) $(animation) $^ $@

stroboscope-baynes.gif: $(baynes_gif_list)
	$(CONVERT) $(animation) $^ $@

stroboscope-baynes-cutoff.gif: $(baynes_pbm_list)
	$(CONVERT) $(animation) $^ $@

clean:
	rm -f *.gif extracted_* stampfer/* baynes/*
