# -*- Mode: Tcl -*-
#
#             File: ui.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game:
#                   user-interface niceties

#=====================================================================
# Piece highlighting: constants
#=====================================================================

# active highlight colors
set activeFill yellow
set activeOutline yellow

# player highlight colors
array set playerActiveOutline\
    {\
	 1 red\
	 2 blue\
     }

# currently active player/piece
set activePlayer 0
set activePiece {}
set activeSpace {}

#=====================================================================
# Piece identification: procs 
#=====================================================================
# getPieceName $tags
#  + looks up piece-name from $tags
proc getPieceName {{tags {}}} {
    foreach t $tags {
	if {[string match "pn:*" $t]} {
	    return [lindex [split $t :] 1]
	}
    }
    return {}
}

# currentPiece
#  + looks up piece-name from canvas 'current' tag
proc currentPiece {} {
    return [getPieceName [.c itemcget current -tags]]
}


#=====================================================================
# Piece highlighting: procs
#=====================================================================

# highlightPiece $pieceName
proc highlightPiece {pieceName} {
    global activeFill activeOutline
    ;# draw/move a bbox around pieceName
    set bbox [.c bbox $pieceName]
    set x1 [expr [lindex $bbox 0] - 1]
    set y1 [expr [lindex $bbox 1] - 1]
    set x2 [expr [lindex $bbox 2] + 1]
    set y2 [expr [lindex $bbox 3] + 1]
    if {[.c find withtag activePieceBox] == {}} {
	.c create rectangle\
	    $x1 $y1 $x2 $y2\
	    -outline $activeOutline\
	    -fill $activeFill\
	    -tags {activeMark activePieceBox}
    } else {
	.c coords activePieceBox \
	    $x1 $y1 $x2 $y2
	.c itemconfigure activePieceBox \
	    -outline $activeOutline\
	    -fill $activeFill
    }
    .c lower activePieceBox piece
}


#=====================================================================
# Piece-choose mode: highlight pieces
#=====================================================================
proc choosePieceMode {player} {
    global activePlayer activePiece activeSpace
    set activePlayer $player
    set activePiece {}
    set activeSpace {}

    set other [otherPlayer $player]

    .c delete activePieceBox
    .c lower activeSpace

    # delete old bindings
    .c bind pp:$other <Any-Enter> {}
    .c bind pp:$other <Any-Leave> {}
    .c bind pp:$other <Button-1> {}
    .c bind space <Any-Enter> {}
    .c bind activeSpace <Button-1> {}

    # set new bindings: highlight on enter
    .c bind pp:$player <Any-Enter> { highlightPiece [currentPiece] }
    # un-highlight on leave
    .c bind pp:$player <Any-Leave> { .c delete activePieceBox }
    # activate on button-1-press
    .c bind pp:$player <Button-1> { activatePiece [currentPiece] }
}

#=====================================================================
# Piece-choose mode: (dis)-activate pieces
#=====================================================================
proc activatePiece {pieceName} {
    global activePiece activePlayer playerActiveOutline
    # -- set active-piece flag
    set activePiece $pieceName

    .c itemconfigure activePieceBox\
	-outline $playerActiveOutline($activePlayer)

    # -- re-bind "leave", "Enter", and "Button-1" for pieces
    .c bind pp:$activePlayer <Any-Enter> {}
    .c bind pp:$activePlayer <Any-Leave> {}
    .c bind pp:$activePlayer <Button-1> {}
    .c bind $pieceName <Button-1> \
	"disactivatePiece $pieceName;
         highlightPiece $pieceName"
    bind .c <Button-3> "disactivatePiece $pieceName"

    # -- enter movement-mode
    moveMode
}

proc disactivatePiece {pieceName} {
    global activePiece activePlayer
    set activePiece {}
    .c lower activeSpace
    .c bind $pieceName <Button-1> {}
    choosePieceMode $activePlayer
}

#=====================================================================
# Spaces: identifaction
#=====================================================================
proc getSpaceName {{tags {}}} {
    foreach t $tags {
	if {[string match {[0-9]*:[0-2]/[0-3]} $t]} {
	    return $t
	}
    }
    return {}
}
proc currentSpace {} {
    return [getSpaceName [.c itemcget current -tags]]
}

#=====================================================================
# Spaces: highlighting
#=====================================================================
proc highlightSpace {spaceName {hlColor yellow}} {
    global activeSpace
    ;# set active-space flag
    set activeSpace $spaceName
    ;# draw/move a higlight around spaceName
    if {[.c find withtag activeSpace] == {}} {
	eval .c create polygon\
	    [.c coords $spaceName]\
	    -width 2\
	    -outline $hlColor\
	    -fill {{}}\
	    -tags "{activeMark activeSpace}"
    } else {
	eval .c coords activeSpace \
	    [.c coords $spaceName]
	.c itemconfigure activeSpace \
	    -outline $hlColor\
	    -fill {}
    }
    .c raise activeSpace
    .c lower activeSpace piece
}

#=====================================================================
# Move-mode: highlight spaces
#=====================================================================
proc moveMode {} {
    global activePlayer playerActiveOutline
    
    # highlight spaces on enter
    .c bind space <Any-Enter> {
	global activePlayer playerActiveOutline
	highlightSpace [currentSpace] $playerActiveOutline($activePlayer)
    }

    # place piece on button-1 down (hack!)
    .c bind activeSpace <Button-1> { makeMove }
}

#=====================================================================
# Move-mode: piece placement
#=====================================================================
# makeMove
#  + moves global $activePiece to global $activeSpace
#  + no checking (yet!)
proc makeMove {} {
    global activePiece activeSpace activePlayer
    if {$activePiece == {}} { return }
    #puts "makeMove $activePiece -> $activeSpace ($activePlayer)"
    placePieceNamed $activePiece $activeSpace
    disactivatePiece $activePiece
    choosePieceMode $activePlayer
}

#=====================================================================
# Player identification
#=====================================================================
proc otherPlayer {thisPlayer} {
    if {$thisPlayer == 1} {
	return 2
    }
    return 1
}