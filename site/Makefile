# Makefile for know website

#-----------------------------------------------------------------------
# source directories
#-----------------------------------------------------------------------
TOP_SRC = .
PDF_SRC = ../pdftex
HTML_SRC = $(PDF_SRC)/know-html
FRAMES_SRC = $(PDF_SRC)/know-frames
BOARD_SRC = $(TOP_SRC)/boards

TOP_SRCS = $(TOP_SRC)/index.html
PDF_SRCS = $(foreach side,1sided 2sided, \
		$(foreach bwcolor,bw color, \
		    $(PDF_SRC)/know-$(bwcolor)-$(side).pdf))

BOARD_BASE = $(foreach size,iso-a4 iso-a3 iso-a2 iso-a1 iso-a0\
			    ansi-a ansi-b ansi-c ansi-d ansi-e,\
		knowboard-$(size))
BOARD_SRCS = $(patsubst %,$(BOARD_SRC)/%,$(BOARD_BASE))

# hacks
HTMLPDF_SRCS = $(patsubst %,%.pdf,$(HTML_SRC) $(FRAMES_SRC))
HTML_SRCS = $(HTML_SRC)/index.html
FRAMES_SRCS = $(FRAMES_SRC)/index.html

#-----------------------------------------------------------------------
# target directories
#-----------------------------------------------------------------------
TOP_DST = know
PDF_DST = $(TOP_DST)/pdf
HTML_DST = $(TOP_DST)/html
FRAMES_DST = $(TOP_DST)/frames
BOARD_DST = $(TOP_DST)/boards

#-----------------------------------------------------------------------
# targets
#-----------------------------------------------------------------------
TOP_TARGETS = $(patsubst $(TOP_SRC)/%,$(TOP_DST)/%,$(TOP_SRCS))
PDF_TARGETS = $(patsubst $(PDF_SRC)/%,$(PDF_DST)/%,$(PDF_SRCS))
HTML_TARGETS = $(patsubst $(HTML_SRC)/%,$(HTML_DST)/%,$(HTML_SRCS))
FRAMES_TARGETS = $(patsubst $(FRAMES_SRC)/%,$(FRAMES_DST)/%,$(FRAMES_SRCS))
BOARD_TARGETS = $(patsubst %,$(BOARD_DST)/%.pdf,$(BOARD_BASE))

#		$(patsubst %,$(BOARD_DST)/%.ps.gz,$(BOARD_BASE))

TARGETS = $(TOP_TARGETS) $(PDF_TARGETS) $(HTML_TARGETS) $(FRAMES_TARGETS) \
	  $(BOARD_TARGETS)


######################################
# for archiving & snapshots
######################################
ARC_TARGETS = $(TOP_SRC)/Makefile \
	      $(TOP_SRCS) $(patsubst %,%.ps,$(BOARD_SRCS))
SNAP_TARGETS = $(TOP_TARGETS) $(PDF_TARGETS)
SNAP_DIRTARGETS = $(HTML_DST) $(FRAMES_DST)

# Where to put (simple) tar archives
SNAP_DEST_DIR = $(PWD)
ARC_DEST_DIR = $(PWD)
# Where to put date-host stamped tar archives
STAMP_DEST_DIR = $(SNAP_DEST_DIR)

TAR = tar
TAR_FLAGS = -C.. -cvIhf
SNAP_BASE = $(shell basename $(PWD))
ARC_BASE = $(shell basename $(PWD))
# SNAP_BASENAME = $(SNAP_BASE)
SNAP_BASENAME = know-site
ARC_BASENAME = know-site
SNAP_SUFFIX = snap.tar.bz2
ARC_SUFFIX = arc.tar.bz2
ARC_DEST_FILE = $(ARC_BASENAME).$(ARC_SUFFIX)

STAMP_DATE_INFIX := $(shell /bin/date +%Y-%m-%d)
STAMP_HOSTNAME_INFIX := $(shell /bin/hostname -s)
STAMP_DEST_INFIX = $(STAMP_DATE_INFIX).$(STAMP_HOSTNAME_INFIX)
STAMP_DEST_FILE = $(ARC_BASENAME)-$(STAMP_DEST_INFIX).$(ARC_SUFFIX)
STAMP_FILE = .stamp

SNAP_DEST_FILE = $(SNAP_BASENAME)-$(STAMP_DEST_INFIX).$(SNAP_SUFFIX)
SNAP_FILE = .snap

#-----------------------------------------------------------------------
# programs
#-----------------------------------------------------------------------
CP = cp
CP_FLAGS = -LR

CHMOD = chmod
DIR_MODE = 0755
FILE_MODE = 0644


#-----------------------------------------------------------------------
# Rules
#-----------------------------------------------------------------------
all: $(TARGETS)

###################################################
# Source initialization
###################################################
.PHONY: init

init:
	$(foreach pdf,\
	  $(patsubst $(PDF_SRC)/%.pdf,%,$(PDF_SRCS))\
	  $(patsubst $(PDF_SRC)/%.pdf,%,$(HTMLPDF_SRCS)),\
		$(MAKE) -C $(PDF_SRC) pdflatex-$(pdf); \
		$(MAKE) -C $(PDF_SRC) pdflatex-$(pdf); )

.PHONY: latex pdflatex
latex:
	$(foreach pdf,\
	  $(patsubst $(PDF_SRC)/%.pdf,%,$(PDF_SRCS))\
	  $(patsubst $(PDF_SRC)/%.pdf,%,$(HTMLPDF_SRCS)),\
		$(MAKE) -C $(PDF_SRC) latex-$(pdf); )

pdflatex:
	$(foreach pdf,\
	  $(patsubst $(PDF_SRC)/%.pdf,%,$(PDF_SRCS))\
	  $(patsubst $(PDF_SRC)/%.pdf,%,$(HTMLPDF_SRCS)),\
		$(MAKE) -C $(PDF_SRC) pdflatex-$(pdf); )



###################################################
# Top-level: directories
###################################################
$(TOP_DST):
	mkdir -p $(TOP_DST)
	$(CHMOD) $(DIR_MODE) $(TOP_DST)

$(PDF_DST):
	mkdir -p $(PDF_DST)
	$(CHMOD) $(DIR_MODE) $(PDF_DST)

$(BOARD_DST):
	mkdir -p $(BOARD_DST)
	$(CHMOD) $(DIR_MODE) $(BOARD_DST)


###################################################
# Top-level: files
###################################################
top: $(TOP_TARGETS)

$(TOP_DST)/%: $(TOP_DST) $(TOP_SRC)/%
	$(CP) $(CP_FLAGS) $(TOP_SRC)/$* $@
	$(CHMOD) $(FILE_MODE) $@

###################################################
# PDF: files
###################################################
pdf: $(PDF_TARGETS)

$(PDF_DST)/%: $(PDF_DST) $(PDF_SRC)/%
	$(CP) $(CP_FLAGS) $(PDF_SRC)/$* $@
	$(CHMOD) $(FILE_MODE) $@

###################################################
# Boards
###################################################
boards: $(BOARD_TARGETS)

$(BOARD_DST)/%.ps.gz: $(BOARD_DST) $(BOARD_DST)/%.ps
	rm -f $@
	gzip $(BOARD_DST)/$*.ps
	$(CHMOD) $(FILE_MODE) $@

$(BOARD_DST)/%.ps: $(BOARD_DST) $(BOARD_SRC)/%.ps
	$(CP) $(CP_FLAGS) $(BOARD_SRC)/$*.ps $@
	$(CHMOD) $(FILE_MODE) $@

$(BOARD_DST)/%.pdf: $(BOARD_DST) $(BOARD_SRC)/%.ps
	epstopdf --outfile=$@ $(BOARD_SRC)/$*.ps
	$(CHMOD) $(FILE_MODE) $@


###################################################
# HTML
###################################################
htmall: html frames ;

html: $(HTML_TARGETS)

$(HTML_TARGETS): $(HTML_SRCS)
	rm -rf $(HTML_DST)
	$(CP) $(CP_FLAGS) $(HTML_SRC) $(HTML_DST)
	$(CHMOD) $(DIR_MODE) $(HTML_DST)
	$(CHMOD) $(FILE_MODE) $(HTML_DST)/*

$(HTML_SRCS):
	$(MAKE) -e -C $(PDF_SRC) html


frames: $(FRAMES_TARGETS)

$(FRAMES_TARGETS): $(FRAMES_SRCS)
	rm -rf $(FRAMES_DST)
	$(CP) $(CP_FLAGS) $(FRAMES_SRC) $(FRAMES_DST)
	$(CHMOD) $(DIR_MODE) $(FRAMES_DST)
	$(CHMOD) $(FILE_MODE) $(FRAMES_DST)/*

$(FRAMES_SRCS):
	$(MAKE) -e -C $(PDF_SRC) frames


###################################################
# Source re-making
###################################################
$(PDF_SRC)/%: ; $(MAKE) -C $(PDF_SRC) $*


######################################
# archive & stamp targets
######################################
arc: $(ARC_DEST_DIR)/$(ARC_DEST_FILE)
snap: $(SNAP_DEST_DIR)/$(SNAP_DEST_FILE)
stamp: $(STAMP_FILE)

$(ARC_DEST_DIR)/$(ARC_DEST_FILE): $(ARC_TARGETS)
	$(TAR) $(TAR_FLAGS) $(ARC_DEST_DIR)/$(ARC_DEST_FILE) \
		$(foreach target,$(ARC_TARGETS),$(ARC_BASE)/$(target))

$(SNAP_DEST_DIR)/$(SNAP_DEST_FILE): $(SNAP_TARGETS)
	echo "$(SNAP_DEST_DIR)/$(SNAP_DEST_FILE)" > $(SNAP_FILE)
	$(TAR) $(TAR_FLAGS) $(SNAP_DEST_DIR)/$(SNAP_DEST_FILE) \
		$(foreach target,$(SNAP_TARGETS),$(SNAP_BASE)/$(target))\
		$(foreach target,$(SNAP_DIRTARGETS),$(SNAP_BASE)/$(target))

$(STAMP_FILE): $(ARC_DEST_DIR)/$(ARC_DEST_FILE)
	echo "$(STAMP_DEST_DIR)/$(STAMP_DEST_FILE)" > $(STAMP_FILE)
	cp $(ARC_DEST_DIR)/$(ARC_DEST_FILE) \
	   $(STAMP_DEST_DIR)/$(STAMP_DEST_FILE)


###################################################
# Cleanup
###################################################
.PHONY: clean realclean distclean
clean:
	find . -name '*~' -exec rm {} \;


realclean: clean
	rm -rf $(TOP_DST) $(PDF_DST) $(HTML_DST) $(FRAMES_DST)

distclean: realclean

