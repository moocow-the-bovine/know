# -*- Mode: Makefile -*-
#
#        File: Makefile
#      Author: Bryan Jurish <moocow@cudmuncher.de>
# Description: Generic Makefile for LaTeX documents with many targets
#   User Vars: $(TEXBASE), $(TEXFILES), etc.
#     Outputs: dvi, html, html-zip, frames, frames-zip, pdf, ps, ps2 (2-sided),
#              dvi-gz, pdf-gz, ps-gz, 2.ps-gz
#       Other: install (installs $(INSTALL_TARGETS) to $(INSTALL_DIR))
#	       arc (.tar.gz), stamp (<date>.<hostname>.tar.gz)

# -----------------------------------------------------------------------------
# User Variables
# -----------------------------------------------------------------------------
# Which tex files we need
TEXMASTER = know.tex
TEXOTHER = $(HEADERS) $(PICS) $(ADMIN) $(RULES)

HEADERS = kmacros.tex klogos.tex \
	  title-latex.tex title-html.tex \
	  headers-1sided.tex headers-2sided.tex

ADMIN_BASE = acknowledge.tex docversions.tex \
	     feedback.tex history.tex legal.tex todo.tex
ADMIN = $(patsubst %,admin/%,$(ADMIN_BASE))

RULES_BASE = layout.tex pieces.tex movement.tex connect.tex \
	     versions.tex hints.tex
RULES = $(patsubst %,rules/%,$(RULES_BASE))


# pictures: see Makefile in the pics/ directory
PICS_HTML_BASE = know-logo-large.png know-name-small.png \
		 tiers.png tiers-key.png newgame.png connect.png \
		 bard1.png fool1.png herald1.png \
		 bard2.png fool2.png herald2.png \
		 theboard.png
PICS_HTML = $(patsubst %,pics/%,$(PICS_HTML_BASE))

PICS_HTML_AUXFILES = $(PICS_HTML)
PICS_FRAMES_AUXFILES = $(PICS_HTML)


# for pdf: modification-date-string
PDFDATE_FILE = pdfdate.tex
PDFDATE_STR = $(shell /bin/date +%Y%m%d%H%M%S)

# Whether to use BibTeX 
# NOTE: you must place the commands
#       \bibliographystyle{style} and \bibliography{file}
#       in the TeX document yourself!
# USE_BIBTEX = 
USE_BIBTEX = no

# Whether to stratify the BibTeX database
# NOTE: only if USE_BIBTEX = yes
USE_BIBSTRAT = yes

# Which formats to build by default
#   Choose from the following:
#      tgz dvi ps 2.ps pdf html frames html-zip frames-zip dvi-gz pdf-gz ps-gz 2.ps-gz
# BUILD_FORMATS = dvi ps 2.ps pdf html frames html-zip frames-zip dvi-gz pdf-gz ps-gz 2.ps-gz
# BUILD_FORMATS = dvi ps html html-zip dvi-gz ps-gz
# BUILD_FORMATS = dvi ps
BUILD_FORMATS = pdf

# Which formats to install by default
INSTALL_FORMATS = $(BUILD_FORMATS)
# Where to install them
INSTALL_DIR = $(PWD)/installed
# Where to publish them
PUBLISH_FORMATS = $(INSTALL_FORMATS)
PUBLISH_DIR = $(PWD)/published

# Where to put (simple) tar archives
# ARC_DEST_DIR = ../arc
ARC_DEST_DIR = $(PWD)
# Where to put date-host stamped tar archives
STAMP_DEST_DIR = $(ARC_DEST_DIR)
# What to archive
ARC_TARGETS = Makefile $(TEXTARGETS) $(wildcard *.bib) $(wildcard *.vst)

# HTML: Author address
HTML_ADDRESS := "<a href=mailto:moocow@cudmuncher.de>Bryan Jurish</a><br>`date`"
# HTML: Title
HTML_TITLE = "know"
# HTML: Language
HTML_LANGUAGE = EN
# HTML: section->file splitting
HTML_SPLIT = +2

# -----------------------------------------------------------------------------
# Variables that should not need to be changed
# -----------------------------------------------------------------------------

######################################
# program variables
######################################
MAKE = make
LATEX = latex
# LATEX = $(PDFLATEX)
BIBTEX = bibtex
BIBTEX_FLAGS = -min-crossrefs=1
BIBVIEW = bibview
BIBVIEW_FLAGS = -file
LATEX2HTML = latex2html
LATEX2HTML_FLAGS = -local_icons -show_section_numbers
PDFLATEX = pdflatex
PS2PDF = ps2pdf
DVIPS = dvips
PSNUP = psnup
ZIP = zip
ZIP_FLAGS = -r -9
INSTALL = cp
INSTALL_FLAGS = -a -f
UNINSTALL = rm
UNINSTALL_FLAGS = -r -f
GZIP = gzip
GZIP_FLAGS = -c


######################################
# for bibliography-stratification
# (via bibstrat.perl)
######################################
BIBSTRAT = bibstrat.perl
BIBSTRAT_FLAGS = -f $(BIBSTRAT_SORTFIELDS)

# (unstratified) input file for bibstrat
BIBSTRAT_SRC = $(TEXBASE).bib
# (stratified) output file for bibstrat
BIBSTRAT_DEST = $(TEXBASE)-stratified.bib

# Arguments to bibstrat: list of sort fields
#    sort entries according to <list>, which should be
#    a comma-separated list of field names with optional
#    prefixes '<' (ascending sort) or '>' (descending
#    sort).  Default sort is ascending, default <list>
#    is "<stratum".  Set this to 'none' to avoid sorting
#    altogether.
BIBSTRAT_SORTFIELDS = '<stratum,<author,<year,<title'

# set bbl prerequisite if using bibstrat
ifeq '$(USE_BIBSTRAT)' 'yes'
BBL_PREREQ = $(BIBSTRAT_DEST)
endif

######################################
# for publishing
######################################
PUBLISH = $(INSTALL)
PUBLISH_FLAGS = $(INSTALL_FLAGS)
UNPUBLISH = $(UNINSTALL)
UNPUBLISH_FLAGS = $(UNINSTALL_FLAGS)

######################################
# for archiving
######################################
TAR = tar
TAR_FLAGS = -C.. -cvzhf
ARC_BASE = $(shell basename $(PWD))
# ARC_BASENAME = $(ARC_BASE)
ARC_BASENAME = know-tex
ARC_SUFFIX = tar.gz
ARC_DEST_FILE = $(ARC_BASENAME).$(ARC_SUFFIX)
STAMP_DATE_INFIX := $(shell /bin/date +%Y-%m-%d.%H-%M-%S)
STAMP_HOSTNAME_INFIX := $(shell /bin/hostname -s)
STAMP_DEST_INFIX = $(STAMP_DATE_INFIX).$(STAMP_HOSTNAME_INFIX)
STAMP_DEST_FILE = $(ARC_BASENAME).$(STAMP_DEST_INFIX).$(ARC_SUFFIX)
STAMP_FILE = .stamp

######################################
# for previewing
######################################
XDVI = xdvi
BROWSER = mozilla
# BROWSER = netscape
# BROWSER = kfmclient
# BROWSERFLAGS = openURL

#XPDF = acroread
XPDF = xpdf
GV = gv

######################################
# LaTeX target variables
######################################
TEXBASE = $(TEXMASTER:%.tex=%)
TEXBASE_FRAMES = $(TEXBASE)-frames
TEXMASTER_FRAMES = $(TEXBASE_FRAMES).tex
TEXTARGETS = $(TEXMASTER) $(TEXOTHER)

######################################
# latex2html variables
######################################
HTML_BASE = $(TEXBASE)-html
FRAMES_BASE = $(TEXBASE)-frames
# HTML_DIR = $(PWD)/$(HTML_BASE)
HTML_DIR = $(HTML_BASE)
HTML_AUXFILES = $(PICS_HTML_AUXFILES)

# FRAMES_DIR = $(PWD)/$(FRAMES_BASE)
FRAMES_DIR = $(FRAMES_BASE)
HTML_TARGET_FILE = $(HTML_DIR)/index.html
FRAMES_TARGET_FILE = $(FRAMES_DIR)/index.html
FRAMES_AUXFILES = $(PICS_FRAMES_AUXFILES)

# -----------------------------------------------------------------------------
# Targets (shouldn't need to change these)
# -----------------------------------------------------------------------------
all: $(BUILD_FORMATS)

######################################
# pics subdirectory
######################################
.PHONY: pics
pics:
	$(MAKE) -C pics all

pics/%: ; $(MAKE) -C pics $*

######################################
# Fake target for forced builds
# --> use .PHONY instead!
######################################
#FORCE:

######################################
# Don't auto-remove files
######################################
.SECONDARY:

######################################
# forced LaTeX runs (for init, bbl)
######################################
.PHONY: latex latex-*

latex: latex-$(TEXBASE)

latex-%: %.tex
	$(LATEX) $<

pdflatex: pdflatex-$(TEXBASE)

pdflatex-%: %.tex
	$(PDFLATEX) $<


######################################
# initialization targets (2x LaTeX)
######################################
init: $(foreach format,$(filter dvi frames frames-%,$(BUILD_FORMATS)),init-$(format))

init-dvi: init-$(TEXBASE)
init-frames: init-$(TEXBASE_FRAMES)

init-%: %.tex
	if test '$(USE_BIBTEX)' == 'yes' ; then \
	  for run in 1 2 ; do \
	    echo "=========> LaTeX Pre-Initialization Run #$$run <==========" ;\
	    $(MAKE) latex-$* ;\
	  done ;\
	  $(MAKE) bbl ;\
	fi ;\
	for run in 1 2 3 ; do \
	  echo "=========> LaTeX Initialization Run #$$run <==========" ;\
	  $(MAKE) latex-$* ;\
	done

######################################
# forced LaTeX runs (for init, bbl)
######################################
.PHONY: latex-*
latex-frames: latex-$(TEXBASE_FRAMES) ;
latex-%: %.tex
	$(LATEX) $<


######################################
# extra dvi targets
######################################
%-2sided.tex: %.tex
	sed \
	  -e 's/^\\documentclass\[\(.*\)\]\(.*\)/\\documentclass[twoside,\1]\2/' \
	  -e 's/^\\newcommand{\\istwosided}{0}/\\newcommand{\\istwosided}{1}/' \
	  $< > $@

%-1sided.tex: %.tex
	sed \
	  -e 's/^\\documentclass\[twoside,\(.*\)\]\(.*\)/\\documentclass[\1]\2/' \
	  $< > $@


%-color.tex: %.tex
	sed \
	  -e 's/^\\newcommand{\\iscolor}{0}/\\newcommand{\\iscolor}{1}/' \
	  $< > $@

%-bw.tex: %.tex
	sed \
	  -e 's/^\\newcommand{\\iscolor}{1}/\\newcommand{\\iscolor}{0}/' \
	  $< > $@


%-lores.tex: %.tex
	sed \
	  -e 's/^\\newcommand{\\islores}{0}/\\newcommand{\\islores}{1}/' \
	  $< > $@

%-hires.tex: %.tex
	sed \
	  -e 's/^\\newcommand{\\islores}{1}/\\newcommand{\\islores}{0}/' \
	  $< > $@


######################################
# dvi targets (create)
######################################
dvi: $(TEXBASE).dvi $(TEXBASE).aux
dvi-frames: $(TEXBASE_FRAMES).dvi

%.aux:  %.dvi ;

%.dvi: %.tex $(TEXTARGETS)
	$(LATEX) $<

%-frames.tex: %.tex makeframes.sed
	sed -f makeframes.sed $< > $@

makeframes.sed:
	echo -e '/\\\\usepackage{html}/a\\\n\\\\usepackage{frames}' > makeframes.sed

######################################
# bbl (BibTeX) targets
######################################
bbl: $(foreach format,$(filter dvi frames,$(BUILD_FORMATS)),bbl-$(format))

bbl-dvi: $(TEXBASE).bbl
bbl-frames: $(TEXBASE_FRAMES).bbl

%.bbl: %.aux $(BBL_PREREQ)
	$(BIBTEX) $(BIBTEX_FLAGS) $*

######################################
# bibstrat (BibTeX) targets
######################################
strat: $(BIBSTRAT_DEST)
bibstrat: $(BIBSTRAT_DEST)

$(BIBSTRAT_DEST): $(BIBSTRAT_SRC)
	$(BIBSTRAT) $(BIBSTRAT_FLAGS) -o $@ $<

######################################
# bibview targets
######################################
.PHONY: bibview

bibview: $(TEXBASE).bib
	$(BIBVIEW) $(BIBVIEW_FLAGS) $(TEXBASE).bib &


######################################
# dvi targets (preview)
######################################
.PHONY: view-*
view-dvi: $(TEXBASE).dvi
	$(XDVI) $(TEXBASE).dvi &

view-dvi-frames: $(TEXBASE_FRAMES).dvi
	$(XDVI) $(TEXBASE_FRAMES).dvi &


######################################
# html targets
######################################
html: html-mkdir $(HTML_TARGET_FILE)
frames: frames-mkdir $(FRAMES_TARGET_FILE)

$(HTML_BASE): html
$(FRAMES_BASE): frames

.PHONY: html-mkdir frames-mkdir

html-mkdir:
	mkdir -p $(HTML_DIR)
	if [ "$(HTML_AUXFILES)" ] ; then \
	  cp $(HTML_AUXFILES) $(HTML_DIR) ;\
	fi

frames-mkdir:
	mkdir -p $(FRAMES_DIR)
	if [ "$(FRAMES_AUXFILES)" ] ; then \
	  cp $(FRAMES_AUXFILES) $(FRAMES_DIR) ;\
	fi

$(HTML_TARGET_FILE): $(TEXBASE).dvi
	$(LATEX2HTML) $(LATEX2HTML_FLAGS) \
		-dir $(HTML_DIR) \
		-address $(HTML_ADDRESS) \
		-t $(HTML_TITLE) \
		-iso_language $(HTML_LANGUAGE) \
		-split $(HTML_SPLIT) \
		$(TEXMASTER)

$(FRAMES_TARGET_FILE): $(TEXBASE_FRAMES).dvi
	$(LATEX2HTML) $(LATEX2HTML_FLAGS) \
		-dir $(FRAMES_DIR) \
		-address $(HTML_ADDRESS) \
		-t $(HTML_TITLE) \
		-iso_language $(HTML_LANGUAGE) \
		-split $(HTML_SPLIT) \
		$(TEXMASTER_FRAMES)

######################################
# html targets (preview)
######################################
browse: view-html
view-html: $(HTML_TARGET_FILE)
	$(BROWSER) $(BROWSERFLAGS) file://$(HTML_TARGET_FILE) &

browse-frames: view-frames
view-frames: $(FRAMES_TARGET_FILE)
	$(BROWSER) $(BROWSERFLAGS) file://$(FRAMES_TARGET_FILE) &

######################################
# pdf targets (create)
######################################
pdf: $(TEXBASE).pdf

%-ps2pdf.pdf: %.ps
	$(PS2PDF) $<

$(TEXBASE).pdf: $(PDFDATE_FILE)
	$(PDFLATEX) $(TEXMASTER)

$(PDFDATE_FILE): $(TEXMASTER) $(TEXTARGETS)
	echo "\\pdfinfo{/ModDate (D:$(PDFDATE_STR))}" > $(PDFDATE_FILE)

######################################
# pdf targets (preview)
######################################
xpdf: view-pdf
acroread: view-pdf
view-pdf: $(TEXBASE).pdf
	$(XPDF) $(TEXBASE).pdf &

######################################
# ps targets (create)
######################################
ps: $(TEXBASE).ps

%.ps: %.dvi
	$(DVIPS) $<

######################################
# ps targets (preview)
######################################
gv: view-ps
gsview: view-ps
view-ps: $(TEXBASE).ps
	$(GV) $(TEXBASE).ps &

######################################
# 2.ps targets (create)
######################################
ps2: 2.ps
ps2-gz: 2.ps-gz

2.ps: $(TEXBASE).2.ps
%.2.ps: %.ps
	$(PSNUP) -2 $< $@

######################################
# ps2 targets (preview)
######################################
view-ps2: view-2.ps
gv2: view-2.ps
gsview2: preview-2.ps
view-2.ps: $(TEXBASE).2.ps
	$(GV) -landscape $(TEXBASE).2.ps &

######################################
# zip targets (HTML archives)
######################################
zip: $(filter %-zip,$(BUILD_FORMATS))
html-zip: $(HTML_BASE).zip
frames-zip: $(FRAMES_BASE).zip

%.zip: %
	$(ZIP) $(ZIP_FLAGS) $@ $*/

######################################
# install targets
######################################
reinstall: uninstall install
install: $(foreach format,$(INSTALL_FORMATS),install-$(format))

$(INSTALL_DIR): 
	mkdir -p $(INSTALL_DIR)

install-html: $(HTML_TARGET_FILE) $(INSTALL_DIR)
	$(INSTALL) $(INSTALL_FLAGS) $(HTML_DIR) $(INSTALL_DIR)
install-frames: $(FRAMES_TARGET_FILE) $(INSTALL_DIR)
	$(INSTALL) $(INSTALL_FLAGS) $(FRAMES_DIR) $(INSTALL_DIR)
install-%-zip: $(TEXBASE)-%.zip $(INSTALL_DIR)
	$(INSTALL) $(INSTALL_FLAGS) $(TEXBASE)-$*.zip $(INSTALL_DIR)
install-%-gz: $(TEXBASE).%.gz $(INSTALL_DIR)
	$(INSTALL) $(INSTALL_FLAGS) $(TEXBASE).$*.gz $(INSTALL_DIR)
install-%: $(TEXBASE).% $(INSTALL_DIR)
	$(INSTALL) $(INSTALL_FLAGS) $< $(INSTALL_DIR)

######################################
# uninstall targets
######################################
.PHONY: uninstall uninstall-*
uninstall: $(foreach format,$(INSTALL_FORMATS),uninstall-$(format))

uninstall-html:
	$(UNINSTALL) $(UNINSTALL_FLAGS) $(INSTALL_DIR)/$(HTML_BASE)
uninstall-frames:
	$(UNINSTALL) $(UNINSTALL_FLAGS) $(INSTALL_DIR)/$(FRAMES_BASE)
uninstall-%-zip:
	$(UNINSTALL) $(UNINSTALL_FLAGS) $(INSTALL_DIR)/$(TEXBASE)-$*.zip
uninstall-%-gz:
	$(UNINSTALL) $(UNINSTALL_FLAGS) $(INSTALL_DIR)/$(TEXBASE).$*.gz
uninstall-%:
	$(UNINSTALL) $(UNINSTALL_FLAGS) $(INSTALL_DIR)/$(TEXBASE).$*

######################################
# publish targets
######################################
republish: unpublish publish
	@echo "-- [`date`]: $@ completed."
publish:  $(foreach format,$(PUBLISH_FORMATS),publish-$(format))
	@echo "-- [`date`]: $@ completed."

$(PUBLISH_DIR):
	mkdir -p $(PUBLISH_DIR)

publish-html: $(HTML_TARGET_FILE) $(PUBLISH_DIR)
	@echo "[`date`]: $@"
	$(PUBLISH) $(PUBLISH_FLAGS) $(HTML_DIR) $(PUBLISH_DIR)
publish-frames: $(FRAMES_TARGET_FILE) $(PUBLISH_DIR)
	@echo "[`date`]: $@"
	$(PUBLISH) $(PUBLISH_FLAGS) $(FRAMES_DIR) $(PUBLISH_DIR)
publish-%-zip: $(TEXBASE)-%.zip $(PUBLISH_DIR)
	@echo "[`date`]: $@"
	$(PUBLISH) $(PUBLISH_FLAGS) $(TEXBASE)-$*.zip $(PUBLISH_DIR)
publish-%-gz: $(TEXBASE).%.gz $(PUBLISH_DIR)
	@echo "[`date`]: $@"
	$(PUBLISH) $(PUBLISH_FLAGS) $(TEXBASE).$*.gz $(PUBLISH_DIR)
publish-%: $(TEXBASE).% $(PUBLISH_DIR)
	@echo "[`date`]: $@"
	$(PUBLISH) $(PUBLISH_FLAGS) $< $(PUBLISH_DIR)

######################################
# unpublish targets
######################################
.PHONY: unpublish-*
unpublish: $(foreach format,$(PUBLISH_FORMATS),unpublish-$(format))
	@echo "-- [`date`]: $@ completed."

unpublish-html:
	@echo "[`date`]: $@"
	$(UNPUBLISH) $(UNPUBLISH_FLAGS) $(PUBLISH_DIR)/$(HTML_BASE)
unpublish-frames:
	@echo "[`date`]: $@"
	$(UNPUBLISH) $(UNPUBLISH_FLAGS) $(PUBLISH_DIR)/$(FRAMES_BASE)
unpublish-%-zip:
	@echo "[`date`]: $@"
	$(UNPUBLISH) $(UNPUBLISH_FLAGS) $(PUBLISH_DIR)/$(TEXBASE)-$*.zip
unpublish-%-gz:
	@echo "[`date`]: $@"
	$(UNPUBLISH) $(UNPUBLISH_FLAGS) $(PUBLISH_DIR)/$(TEXBASE).$*.gz
unpublish-%:
	@echo "[`date`]: $@"
	$(UNPUBLISH) $(UNPUBLISH_FLAGS) $(PUBLISH_DIR)/$(TEXBASE).$*

######################################
# archive & stamp targets
######################################
arc: $(ARC_DEST_DIR)/$(ARC_DEST_FILE)
stamp: $(STAMP_FILE)

$(ARC_DEST_DIR)/$(ARC_DEST_FILE): $(ARC_TARGETS)
#	@echo "==> arc unsatisfied: $?"
	$(TAR) $(TAR_FLAGS) $(ARC_DEST_DIR)/$(ARC_DEST_FILE) \
		$(foreach target,$(ARC_TARGETS),$(ARC_BASE)/$(target))

$(STAMP_FILE): $(ARC_DEST_DIR)/$(ARC_DEST_FILE)
#	@echo "==> stamp unsatisfied: $?"
	echo "$(STAMP_DEST_DIR)/$(STAMP_DEST_FILE)" > $(STAMP_FILE)
	$(INSTALL) $(INSTALL_FLAGS) $(ARC_DEST_DIR)/$(ARC_DEST_FILE) \
		$(STAMP_DEST_DIR)/$(STAMP_DEST_FILE)

######################################
# gzip targets (generic)
######################################
gz: gzip
gzip: $(filter %.gz,$(BUILD_FORMATS))

%-gz: $(TEXBASE).%.gz ;

%.gz: %
	$(GZIP) $(GZIP_FLAGS) $* > $@

######################################
# Generic preview targets
######################################
x%: view-% ;
preview-%:  view-% ;
%-preview: view-% ;
%-view: view-% ;

######################################
# cleanup targets
######################################
.PHONY: clean nohtml nozip nohtml nogz moreclean realclean
clean:
	find . -name '*~' -print -exec rm -f {} \; ;\
	rm -f *.log *.blg *.ps *.dvi *.ps _region_.tex XtemQuickDirty.* makeframes.sed nohup.out

nohtml: ; rm -rf $(HTML_DIR) $(FRAMES_DIR)

nozip: ; rm -f *.zip

nogz: ;	rm -f *.gz *.tgz

moreclean: clean
	rm -f *.out *.aux *.bbl $(BIBSTRAT_DEST) $(TEXMASTER_FRAMES)
	$(MAKE) -C pics clean

distclean: realclean uninstall
realclean: moreclean nohtml nozip nogz
	rm -rf *.toc *.pdf *.lof *.lot
	rm -f \
	  $(TEXBASE)-*1sided.tex $(TEXBASE)-*2sided.tex \
	  $(TEXBASE)-*color.tex $(TEXBASE)-*bw.tex \
	  $(TEXBASE)-*lores.tex $(TEXBASE)-*hires.tex \
	  $(PDFDATE_FILE)
	  $(MAKE) -C pics realclean