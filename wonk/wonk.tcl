#!/usr/X11/bin/wish
# -*- Mode: Tcl -*-
#
#             File: wonk.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game

;# ========================= Globals ===============================
set DEVEL 1

set CanvasX 300
set CanvasY 300
set AutoResize 1  ;# hack for forced-size drawing

set BoardRadius [expr $CanvasX / 2]
set BoardPadMin 10
set BoardPad 10 ;# must adjust this for piece sizes (on resize)

set pi 3.14159265358979

set AngleOffset [expr $pi / 16]
set AngleHyp 100

set GeometryTolerance 0.01


;# -------------- global arrays
# Points(PointName)      : holds list (x-center y-center) of point named "PointName"
# Segments(SegmentName)  : holds list (x1 y1 x2 y2) of endpoints for segment "SegmentName" [OBSOLETE]
# Equations(SegmentName) : holds list (slope y-offset) of line-eqns for segment "SegmentName"
# Spaces(SpaceName)      : holds canvas-tag of space named "SpaceName"


;# ================= Initialize main interface window ===============

;# ----------------- Menus
source "menus.tcl"

;# ---------------- Titlebar
wm title . "TkWonk"

;#  ---------------- canvas
canvas .c -width $CanvasX -height $CanvasY \
    -background [.mbar cget -background] -confine 1 \
    -relief groove -bd 2

;# ------------ coordinate status-panel
frame .status -relief raised -bd 2
label .status.abs -textvariable absCoords -justify left
label .status.canv -textvariable canCoords -justify right
pack .status.abs -anchor w -side left
pack .status.canv -anchor e -side right
pack .status -side bottom -fill x


;# ---------------- Pack up the menu-bar
pack .mbar -side top -fill x  ;#-padx 1m -pady 1m 


;# ======================== Board Drawing =========================
source "board.tcl"

;# ======================== Piece Drawing =========================
#source "ipieces.tcl" ;# image-based
source "vpieces.tcl" ;# vector-based

;# ======================== User-Interface =========================
source "ui.tcl"


;# =========================== Hacks ==============================
set DEVEL 0
if {$DEVEL} {
    source "marks.tcl"
    source "hacks.tcl"
    # -- canvas background & scrollbars
    .c configure -bg white
    scrollbar .ys -command ".c yview" -orient "vertical"
    scrollbar .xs -command ".c xview" -orient "horizontal"
    .c configure -yscrollcommand ".ys set"
    .c configure -xscrollcommand ".xs set"
    pack .ys -side right -fill y
    pack .xs -side bottom -fill x
}



;# ---------------- Pack up the rest
pack .c -fill both -expand true


;# ======================== Event Handlers ========================

;# --------------------- Resize
proc ResizeTopLevel {} {
    global \
	CanvasX CanvasY AutoResize BoardRadius \
	BoardPadMin BoardPad pieceScaleFactor
    if {$AutoResize && ($CanvasX != [winfo width .c] || $CanvasY != [winfo height .c])} {
	;#puts "BoardPadMin={$BoardPadMin} BoardPad={$BoardPad} \
	       pieceScaleFactor={$pieceScaleFactor}"
	set CanvasX [winfo width  .c]
	set CanvasY [winfo height .c]
  	;#set MinDimension [mut:min $defOpts(CanvasX) $defOpts(CanvasY)]
	;#set BoardRadius [expr $MinDimension / 2]
	set BoardRadius [expr [mut:min $CanvasX $CanvasY] / 2]
	set BoardPad \
	    [expr ceil([mut:max $BoardPadMin [expr $pieceScaleFactor*$BoardRadius]])]
	ReDrawWonkBoard
	replacePieces
	# scroll region
	.c configure -scrollregion [.c bbox all]
    }
}


;# ======================== About Dialog ==========================
proc ShowAboutDialog {} {
    j:about .about -title "About TkWonk" {
	j:rt:h0 "TkWonk"
	j:rt:cr
	j:rt:rm "Version: 0.02"
	j:rt:cr
	j:rt:rm "Author: Bryan Jurish <moocow@ling.uni-potsdam.de>"
	j:rt:cr
	j:rt:rm "Copyright 1999, 2000 Bryan Jurish"
	j:rt:cr
	j:rt:rm "Copyright Policy: GPL"
	j:rt:cr
    }
}

;# ======================== bindings =========================
bind . <Any-Configure> "ResizeTopLevel"

bind all <Motion> {
    set absCoords "Absolute: (%x, %y)"
    set canCoords "Canvas: ([.c canvasx %x], [.c canvasy %y])"
}

;# >>>>>>>>>>>>>>>>>>>>> CONTINUE HERE <<<<<<<<<<<<<<<<<<
