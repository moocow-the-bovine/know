# -*- Mode: Tcl -*-
#
#             File: hacks.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game
#                   hacks

# different canvas style

# save the board
proc saveBoard {file {pageheight "8i"} {padWidth {}}} {
    global CanvasX CanvasY BoardRadius BoardPad pieceScaleFactor

    if {$padWidth == {}} {
	set padWidth [expr 0.4 * $pieceScaleFactor * $BoardRadius]
    }

    set bbox [.c bbox all]
    set x1 [expr [lindex $bbox 0]-$padWidth]
    set y1 [expr [lindex $bbox 1]-$padWidth]
    set x2 [lindex $bbox 2]
    set y2 [lindex $bbox 3]
    set width [expr ($x2 - $x1) + $padWidth]
    set height [expr ($y2 - $y1) + $padWidth]

    .c postscript -file "$file" \
	-x $x1 -y $y1 \
	-width $width -height $height \
	-pageheight $pageheight
}

# save a single piece
proc savePiece {pieceName file {pageheight "15c"}} {
    global CanvasX CanvasY
    global colorSpecs pieceLocs pieceColors pieceShapes pieceBaseLen
    global BoardRadius pieceScaleFactor

    .c delete all
    draw$pieceShapes($pieceName) \
	[expr double($BoardRadius/2)] \
	"[expr $CanvasX / 2] [expr $CanvasY / 2]" \
	$colorSpecs($pieceColors($pieceName)) \
	$pieceName {piece $pieceShapes($pieceName)}

    set bbox [.c bbox $pieceName]
    set x1 [expr [lindex $bbox 0] - 1]
    set y1 [expr [lindex $bbox 1] - 1]
    set x2 [expr [lindex $bbox 2] + 1]
    set y2 [expr [lindex $bbox 3] + 1]
    .c postscript -file "$file" \
	-x $x1 \
	-y $y1 \
	-width [expr $x2 - $x1] \
	-height [expr $y2 - $y1] \
	-pageheight $pageheight
}

# save all pieces
#   - pieces will be saved to file "${pieceName}.ps"
proc savePieces {{types {bard fool herald}} {players {1 2}} {stripes {a b}}} {
    foreach type $types {
	foreach player $players {
	    foreach stripe $stripes {
		set name [pieceName $type $player $stripe]
		savePiece $name "${name}.ps"
		puts "piece '$name' saved to file '${name}.ps'"
	    }
	}
    }
}



# re-draw with forced size
proc resizeBoard {leglength} {
    global CanvasX CanvasY BoardRadius AutoResize
    set AutoResize 0
    if { $CanvasX != $leglength || $CanvasY != $leglength } \
    {
	set CanvasX $leglength
	set CanvasY $leglength
	set BoardRadius [expr $leglength / 2.0]
	ReDrawWonkBoard
    }
    .c configure -scrollregion "0 0 $CanvasX $CanvasY"
}

# resize the board
#resizeBoard 4096

# piece-color-switcing
proc bwpieces {} {
    setPieceColors white black
    .c delete piece
    initPieces
    replacePieces
}
proc colorpieces {} {
    setPieceColors red blue
    .c delete piece
    initPieces
    replacePieces
}

# connection-example from the docs
proc connect_example {} {
    placePieceNamed bard1a 7:2/1
    placePieceNamed bard1b 15:2/1
    placePieceNamed fool1a 8:0/0
    placePieceNamed fool1b 0:0/0
    placePieceNamed herald1a 8:0/2
    placePieceNamed herald1b 0:0/2
    placePieceNamed bard2a 10:0/2
    placePieceNamed bard2b 14:0/2
    placePieceNamed fool2a 10:0/0
    placePieceNamed fool2b 2:0/0
    placePieceNamed herald2a 13:2/2
    placePieceNamed herald2b 5:2/2
}

#-------------------------------
# save example boards
#-------------------------------

# papersizes: $mpSizes($paperName) == {$width,$height} [in mm]
array set mpSizes \
    {\
	 iso-a4 {210 297}\
	 iso-a3 {297 420}\
	 iso-a2 {420 594}\
	 iso-a1 {594 841}\
	 iso-a0 {841 1189}\
    }
# papersizes: $ipSizes($paperName) == {$width,$height} [in inches]
array set ipSizes \
    {\
	 ansi-a {8.5 11.0}\
	 ansi-b {11.0 17.0}\
	 ansi-c {17.0 22.0}\
	 ansi-d {22.0 34.0}\
	 ansi-e {34.0 44.0}\
     }
# convert all metric sizes to imperial
foreach size [array names mpSizes] {
    set ipSizes($size) \
	"[expr [lindex $mpSizes($size) 0] / 25.4]\
         [expr [lindex $mpSizes($size) 1] / 25.4]"
}

# page padding
set iPagePad 1.0
proc savePapers2 {\
		     {pSizes {\
				  iso-a4 iso-a3 iso-a2 iso-a1 iso-a0\
				  ansi-a ansi-b ansi-c ansi-d ansi-e}}\
		     {boardSize 3000}\
		     {boardDir .}}\
    {
	global ipSizes iPagePad BoardRadius CanvasX CanvasY
	resizeBoard $boardSize

	foreach size $pSizes {
	    set file "${boardDir}/knowboard-${size}.ps"

	    set pWidthIn [lindex $ipSizes($size) 0] ;# page width (inches)
	    set pHeightIn [lindex $ipSizes($size) 1] ;# page height (inches)

	    set bbox [.c bbox all]
	    set xw [lindex $bbox 0]
	    set yn [lindex $bbox 1]
	    set xe [lindex $bbox 2]
	    set ys [lindex $bbox 3]
	    set bbWidth [expr $xe-$xw]
	    set bbHeight [expr $ys-$yn]

	    set centerX [expr ($xw+$xe)/2.0]
	    set centerY [expr ($yn+$ys)/2.0]

	    set pageanchor nw
	    set pagex [expr $iPagePad/2.0]i
	    set pagey [expr $pHeightIn-($iPagePad/2.0)]i

	    puts "printing '$file':"
	    puts "  center=($centerX,$centerY)"
	    puts "  bbox=($xw,$yn) ($xe,$ys)"
	    puts "  bbdim=($bbWidth x $bbHeight) pixels^2"
	    puts "  pagesize \[$size\]=($pWidthIn\" x $pHeightIn\")"
	    puts "  page(x,y)=($pagex,$pagey)"
	    puts "  anchor=$pageanchor"
	    
	    .c postscript -file "$file" \
		-x $xw -y $yn \
		-width $bbWidth \
		-height $bbHeight \
		-pageanchor $pageanchor \
		-pagex $pagex \
		-pagey $pagey \
		-pagewidth [expr $pWidthIn-$iPagePad]i
	}
    }


proc savePapers {\
		     {pSizes {\
				  iso-a4 iso-a3 iso-a2 iso-a1 iso-a0\
				  ansi-a ansi-b ansi-c ansi-d ansi-e}}\
		     {boardSize 3000}\
		     {boardDir .}}\
    {
	global ipSizes iPagePad
	resizeBoard $boardSize

	placeCopyright

	foreach size $pSizes {
	    set file "${boardDir}/knowboard-${size}.ps"
	    puts "Generating file '$file'..."

	    # board+copyrighth bbox
	    set bbox [.c bbox all]
	    set xw [lindex $bbox 0]
	    set yn [lindex $bbox 1]
	    set xe [lindex $bbox 2]
	    set ys [lindex $bbox 3]

	    set bbWidth [expr $xe-$xw]
	    set bbHeight [expr $ys-$yn]

	    # board only bbox
	    set bbox [.c bbox space chord outer-rim]
	    set xBw [lindex $bbox 0]
	    set yBn [lindex $bbox 1]
	    set xBe [lindex $bbox 2]
	    set yBs [lindex $bbox 3]

	    set centerX [expr ($xBw+$xBe)/2.0]
	    set centerY [expr ($yBn+$yBs)/2.0]

	    # rendering stuff
	    set pWidthIn [lindex $ipSizes($size) 0] ;# page width (inches)
	    set pHeightIn [lindex $ipSizes($size) 1] ;# page height (inches)
	    set bWidthIn [expr $pWidthIn - $iPagePad] ;# board diameter (inches)
	    set bDiameterPix \
		[expr $bbWidth*$pWidthIn/$bWidthIn] ;# print radius (pixels)
	    set padPix [expr $bDiameterPix-$bbWidth]

	    # page printing canvas-anchors
	    set pXw [expr $centerX-($bDiameterPix/2.0)]
	    set pYn [expr $centerY-($bDiameterPix/2.0)]

	    # current point postscript anchor
	    set pageanchor nw
	    set pagex 0
	    set pagey ${pHeightIn}i

	    .c postscript -file "$file" \
		-x $pXw -y $pYn \
		-width [expr $bDiameterPix] \
		-height [expr $bbHeight+$padPix] \
		-pageanchor $pageanchor \
		-pagex $pagex \
		-pagey $pagey \
		-pagewidth ${pWidthIn}i
	}
    }


proc placeCopyright {} {
    global BoardRadius BoardPad

    set xw $BoardPad
    set yn [expr 2*$BoardRadius+(0.05*$BoardRadius)]

    .c delete copyright

    # copyright message
    .c create text \
	$xw $yn \
	-text "k n o w" \
	-anchor nw \
	-justify left \
	-font {Courier -72}\
	-tags {know copyright}
    .c create text \
	$xw [expr $yn+80] \
	-text "Copyright" \
	-anchor nw \
	-justify left \
	-font {Helvetica -72}\
	-tags {copyright copy}

    set crOff 321
    .c create text \
	[expr $xw+$crOff] [expr $yn+80]\
	-anchor nw \
	-justify left \
	-font {Symbol -72} \
	-text "\xe3" \
	-tags {copyright symbol}
    .c create text \
	[expr $xw+$crOff+50] [expr $yn+80]\
	-anchor nw \
	-justify left \
	-font {Helvetica -72} \
	-text " 1995, 2001 by Bryan Jurish" \
	-tags {copyright date}
}