# Makefile for pics for know rulebook

#-----------------------------------------------------------------------
# PDF & PS Targets
#-----------------------------------------------------------------------
PDF_BOARDS = theboard.pdf
PDF_EXAMPLES = $(foreach bwcolor,bw color,\
			tiers-$(bwcolor).pdf\
			newgame-$(bwcolor).pdf\
			connect-$(bwcolor).pdf)
PDF_KEYS = $(foreach tier,rim tier1 tier2 center ambig,\
		$(foreach bwcolor,bw color,\
		   $(tier)-box-$(bwcolor).pdf))
PDF_PIECES = $(foreach type,bard fool herald,\
	          $(foreach player,1 2,\
		      $(foreach bwcolor,bw color,\
			  $(type)$(player)-$(bwcolor).pdf)))
PS_LOGOS = board-globe.ps

#-----------------------------------------------------------------------
# PNG Targets
#-----------------------------------------------------------------------
PNG_LOGOS = board-globe.png
PNG_HTML = know-logo-large.png know-name-small.png \
		 tiers.png tiers-key.png newgame.png connect.png \
		 bard1.png fool1.png herald1.png \
		 bard2.png fool2.png herald2.png \
		 theboard.png

#-----------------------------------------------------------------------
# Top-Level targets
#-----------------------------------------------------------------------
# pdf targets
PDF_TARGETS = $(PDF_BOARDS) $(PDF_EXAMPLES) $(PDF_KEYS) $(PDF_PIECES)

# ps targets
PS_TARGETS = $(patsubst %.pdf,%.ps,$(PDF_TARGETS)) $(PS_LOGOS)

# png targets not yet made automagically...
PNG_TARGETS = $(PNG_LOGOS) $(PNG_HTML)

TARGETS= $(PS_TARGETS) $(PDF_TARGETS) $(PNG_TARGETS)

#-----------------------------------------------------------------------
# Rules: top-levle
#-----------------------------------------------------------------------
all: $(TARGETS)

#-----------------------------------------------------------------------
# Rules: PDF
#-----------------------------------------------------------------------
pdf: $(PDF_TARGETS)

%.eps: sources/boards/%.ps
	ps2epsi $< $@

%.eps: sources/examples/%.ps
	ps2epsi $< $@

%.eps: sources/keys/%.ps
	ps2epsi $< $@

%.eps: sources/pieces/%.ps
	ps2epsi $< $@

%.pdf: %.eps
	epstopdf $<

#-----------------------------------------------------------------------
# Rules: ps
#-----------------------------------------------------------------------
ps: $(PS_TARGETS)

%.ps: sources/boards/%.ps
	cp $< $@

%.ps: sources/examples/%.ps
	cp $< $@

%.ps: sources/keys/%.ps
	cp $< $@

%.ps: sources/pieces/%.ps
	cp $< $@

%.ps: sources/logos/%.ps
	cp $< $@

#-----------------------------------------------------------------------
# Rules: PNG
#  - just copy, at the moment
#-----------------------------------------------------------------------
png: $(PNG_TARGETS)

%.png: sources/logos/%.png
	cp $< $@

%.png: sources/html/%.png
	cp $< $@

#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------
.PHONY: clean realclean distclean

clean:
	rm -f *~

realclean: clean
	rm -f $(TARGETS)

distclean: realclean
