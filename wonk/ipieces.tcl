# -*- Mode: Tcl -*-
#
#             File: pieces.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game:
#                   image-based pieces

#=====================================================================
# globals
#=====================================================================
set piece_image_dir "./ipieces/color"
#set piece_image_dir "./ipieces/bw"

#=====================================================================
# examples
#=====================================================================
;# create an image object
#image create photo "bard1" -file "sphere-white.gif"

;# add it to the canvas
#eval ".c create image" [NamedSpaceCenter 4:0/0] -image "bard1" -tags "{bard1 image}"

#=====================================================================
# load pieces
#=====================================================================
proc LoadPieces {{dir ""}} {
    if {"$dir" == ""} {
	global piece_image_dir
	set dir $piece_image_dir
    }
    foreach {type} {bard fool herald} {
	foreach {player} {1 2} {
	    foreach {stripe} {a b} {
		# images are 'bard1a', 'bard2a', 'fool1b', etc.
		image create photo "${type}${player}${stripe}" \
		    -file "${dir}/${type}${player}${stripe}.gif"
	    }
	}
    }
}

#=====================================================================
# procs: piece naming conventions
#=====================================================================
;# piece-names are like 'bard1a', 'bard1b', etc.
proc NamePiece {type player stripe} {
    return "${type}${player}${stripe}"
}

#=====================================================================
# procs: piece placement
#=====================================================================
proc PlacePiece {pType pPlayer pStripe sSeg sSkew sTier} {
    PlacePieceNamed [NamePiece $pType $pPlayer $pStripe] [NameSpace $sSeg $sSkew $sTier]
}
proc PlacePieceNamed {pieceName spaceName {othertags "piece"}} {
    ;# sanity check
    if {[.c coords $spaceName] == {}} {
	puts "Error -- space '$spaceName' not found!"
	return
    }
    set coords [NamedSpaceCenter $spaceName]
    # HACK
    if {[string match "bard*" "$pieceName"]} {
	set anchor "center"
    } else {
	set anchor "s"
    }
    if {[.c coords $pieceName] == {}} {
	;# must add the piece
	eval ".c create image" $coords \
	    -image "$pieceName" \
	    -tags "{$pieceName piece}" \
	    -anchor $anchor
    } else {
	;# just move it
	eval ".c coords $pieceName" $coords
    }
}

#=====================================================================
# procs: initial placement
#=====================================================================
proc PlaceNewGame {} {
    # position-indexes
    # {Type Stripe BaseQuadrantSegOffset Skew Tier}
    set posns \
	{ \
	      {bard a 2 0 0} \
	      {bard b -2 0 0} \
	      {fool a 1 1 0} \
	      {fool b -1 2 0} \
	      {herald a 1 2 0} \
	      {herald b -1 1 0} \
	  }
    ;# place the pieces
    for {set player 1; set quadrant 4} \
	{$player < 3} \
	{incr player; incr quadrant 8} {
	    foreach {posn} $posns {
		set type [lindex $posn 0]
		set stripe [lindex $posn 1]
		set offset [lindex $posn 2]
		set skew [lindex $posn 3]
		set tier [lindex $posn 4]
		PlacePiece \
		    $type $player $stripe \
		    [expr $quadrant + $offset] $skew $tier
	    }
    }
}