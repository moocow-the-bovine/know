# -*- Mode: Tcl -*-
#
#             File: vpieces.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game:
#                   vector-based pieces

#=====================================================================
# Data structures:
#   colorSpecs = {penColor fillColor highlightColor shadowColor}
#   coordSpecs = {coordX coordY}
#=====================================================================
proc colorspecPen {colorSpec} { return [lindex $colorSpec 0]; }
proc colorspecFill {colorSpec} { return [lindex $colorSpec 1]; }
proc colorspecHigh {colorSpec} { return [lindex $colorSpec 2]; }
proc colorspecShade {colorSpec} { return [lindex $colorSpec 3]; }

proc coordspecX {coordSpec} { return [lindex $coordSpec 0]; }
proc coordspecY {coordSpec} { return [lindex $coordSpec 1]; }

#=====================================================================
# Color defaults: {pen bodyFill highlight shadow}
#=====================================================================
array set colorSpecs\
    { \
	  white {black grey90 white grey60}\
	  black {white grey30 grey60 black}\
	  red {"\#b00000" "\#ff0000" "\#ff7474" "\#b00000"}\
	  blue {"\#0000b0" "\#0000ff" "\#7474ff" "\#0000b0"}\
    }
#set colorSpecs(black) {white grey30 grey60 black}
#set colorSpecs(red) {"\#b00000" "\#ff0000" "\#ff7474" "\#b00000"}
#set colorSpecs(red) {{} "\#c70000" "\#ff0000" "\#b00000"}
#set colorSpecs(red) {{} "\#ff0000" "\#ff7474" black}
#set colorSpecs(blue) {"\#0000b0" "\#0000ff" "\#7474ff" "\#0000b0"}
#set colorSpecs(blue) {{} "\#0000ff" "\#7474ff" black}

#=====================================================================
# Globals: piece properties
#=====================================================================

# pieceScaleFactor:
#   + scale piece base-lengths to this fraction of board-radius
set pieceScaleFactor 0.055
proc ResizeTopLevel {} {
    global CanvasX CanvasY BoardRadius AutoResize pieceScaleFactor
    if { $AutoResize &&
	 ($CanvasX != [winfo width  .c] || $CanvasY != [winfo height .c])   } \
    {
	set CanvasX [winfo width  .c]
	set CanvasY [winfo height .c]
  	;#set MinDimension [mut:min $defOpts(CanvasX) $defOpts(CanvasY)]
	;#set BoardRadius [expr $MinDimension / 2]
	set BoardRadius [expr [mut:min $CanvasX $CanvasY] / 2]
	set BoardPad [mut:max $BoardPadMin [expr 3*$pieceScaleFactor*$BoardRadius]]
	ReDrawWonkBoard
	replacePieces
	# scroll region
	.c configure -scrollregion "0 0 $CanvasX $CanvasY"
    }
}

#=====================================================================
# piece properties
#  + pieceLocs: array of piece-locations (space names)
#    indexed by piece-names
#  + pieceColors: array of piece color-specs indexed by piece name
#  + pieceShapes: array of piece shape names indexed by piece name
#=====================================================================

# setPieceColors $p1Color $p2Color
#   + requires an "initPieces; replacePieces" to take effect
proc setPieceColors {{p1Color red} {p2Color blue}} {
    global playerColors
    array set playerColors "\
				1 $p1Color\
				2 $p2Color\
			    "
    .c delete piece
}
setPieceColors red blue
#setPieceColors white black

array set typeShapes {\
			  bard Sphere\
			  fool Cone\
			  herald Cylinder\
		      }


#=====================================================================
# Initialization
#=====================================================================
proc initPieces {} {
    global pieceLocs pieceColors pieceShapes playerColors typeShapes
    foreach type {bard fool herald} {
	foreach player {1 2} {
	    foreach stripe {a b} {
		set name "$type$player$stripe"
		set pieceColors($name) $playerColors($player)
		set pieceShapes($name) $typeShapes($type)
	    }
	}
    }
}
initPieces;


#=====================================================================
# Piece Naming
#  + piece names are of the form "${type}${player}${stripe}",
#    where:
#     - type = bard | fool | herald
#     - player = 1 | 2
#     - stripe = a | b
#=====================================================================
proc pieceName {pieceType piecePlayer pieceStripe} {
    return "${pieceType}${piecePlayer}${pieceStripe}"
}

#=====================================================================
# Placement
#=====================================================================
proc placePiece {pcType pcPlayer pcStripe spSeg spSkew spTier} {
    placePieceNamed \
	[pieceName $pcType $pcPlayer $pcStripe] \
	[NameSpace $spSeg $spSkew $spTier]
}
proc placePieceNamed {pieceName spaceName} {
    global colorSpecs pieceLocs pieceColors pieceShapes pieceBaseLen
    global BoardRadius pieceScaleFactor
    draw$pieceShapes($pieceName) \
	[expr double($pieceScaleFactor*$BoardRadius)] \
	[NamedSpaceCenter $spaceName] \
	$colorSpecs($pieceColors($pieceName))\
	$pieceName "piece $pieceShapes($pieceName)"
    set pieceLocs($pieceName) $spaceName
}

proc replacePieces {} {
    global pieceLocs
    foreach piece [array names pieceLocs] {
	if {[array get pieceLocs $piece] != {}} {
	    placePieceNamed $piece $pieceLocs($piece)
	}
    }
}

#---------------------------------------------------------------------
# initial placement
#---------------------------------------------------------------------
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
    for {set player 1; set quadrant 4} {$player < 3} {incr player; incr quadrant 8} {
	foreach {posn} $posns {
	    set type [lindex $posn 0]
	    set stripe [lindex $posn 1]
	    set offset [lindex $posn 2]
	    set skew [lindex $posn 3]
	    set tier [lindex $posn 4]
	    placePiece \
		$type $player $stripe \
		[expr $quadrant + $offset] $skew $tier
	}
    }
}

#=====================================================================
# Drawing
#=====================================================================

#----------------------------------------------------------
# Spheres
#  + extra tags/suffixes: sphere + body | highlight | shadow
#  + 'name' is (typically) a piece name
#----------------------------------------------------------
proc drawSphere {baseLen coordSpec colorSpec {name {}} {tags "sphere"} {canvs .c}} {
    #puts "SPHERE: base={$baseLen} coords={$coordSpec} colors={$colorSpec} name={$name}"
    set x [coordspecX $coordSpec]
    set y [coordspecY $coordSpec]

    # coords: main body (filled/outline)
    set main_coords\
	"[expr $x - $baseLen] [expr $y - $baseLen] \
         [expr $x + $baseLen] [expr $y + $baseLen]"

    # coords: highlight
    set hlx [expr $x - ($baseLen/3.0)]
    set hly [expr $y - ($baseLen/3.0)]
    set hlbaseLen [expr $baseLen / 4.0]
    set hl_coords\
	"[expr $hlx - $hlbaseLen] [expr $hly - $hlbaseLen] \
         [expr $hlx + $hlbaseLen] [expr $hly + $hlbaseLen]"

    # coords: shadows: upper-left
    set shadowWidth [expr $baseLen/30.0]
    set sh_lhs_radius [expr (0.95*$baseLen)]
    set sh_lhs_coords\
	"[expr $x + $sh_lhs_radius] [expr $y + $sh_lhs_radius] \
         [expr $x - $sh_lhs_radius] [expr $y - $sh_lhs_radius]"

    # shadows: lower-right (outer)
    set sh_rhs_outer_radius [expr (0.9*$baseLen)]
    set sh_rhs_outer_coords\
	"[expr $x - $sh_rhs_outer_radius] [expr $y - $sh_rhs_outer_radius] \
         [expr $x + $sh_rhs_outer_radius] [expr $y + $sh_rhs_outer_radius]"

    # shadows: lower-right (inner)
    set sh_rhs_inner_radius [expr (0.8*$baseLen)]
    set sh_rhs_inner_coords\
	"[expr $x - $sh_rhs_inner_radius] [expr $y - $sh_rhs_inner_radius] \
         [expr $x + $sh_rhs_inner_radius] [expr $y + $sh_rhs_inner_radius]"

    # drawing: main body (filled)
    if {$name != {} && [$canvs find withtag "${name}_body_fill"] != {}} {
	eval $canvs coords "${name}_body_fill" $main_coords
    } else {
	eval $canvs create oval \
	    $main_coords \
	    -fill [colorspecFill $colorSpec] \
	    -outline "{}" \
	    -tags "{[concat $tags $name ${name}_body_fill]}"
    }

    # drawing: shadows: upper-left
    if {$name != {} && [$canvs find withtag "${name}_sh_lhs"] != {}} {
	eval $canvs coords "${name}_sh_lhs" $sh_lhs_coords
	$canvs itemconfigure "${name}_sh_lhs" -width $shadowWidth
    } else {
	eval $canvs create arc \
	    $sh_lhs_coords \
	    -style arc \
	    -start 110 \
	    -extent 50 \
	    -width $shadowWidth \
	    -outline "[colorspecShade $colorSpec]" \
	    -tags "{[concat $tags $name ${name}_sh_lhs]}"
    }

    # drawing: highlight
    if {$name != {} && [$canvs find withtag "${name}_hl"] != {}} {
	eval $canvs coords "${name}_hl" $hl_coords
    } else {
	eval $canvs create oval \
	    $hl_coords \
	    -fill [colorspecHigh $colorSpec] \
	    -outline "{}" \
	    -tags "{[concat $tags $name ${name}_hl]}"
    }

    # drawing: shadows: lower-right (outer)
    if {$name != {} && [$canvs find withtag "${name}_sh_rhs_outer"] != {}} {
	eval $canvs coords "${name}_sh_rhs_outer" $sh_rhs_outer_coords
	$canvs itemconfigure "${name}_sh_rhs_outer" -width $shadowWidth
    } else {
	eval $canvs create arc \
	    $sh_rhs_outer_coords \
	    -style arc \
	    -start 270 \
	    -extent 90 \
	    -width $shadowWidth \
	    -outline [colorspecShade $colorSpec] \
	    -tags "{[concat $tags $name ${name}_sh_rhs_outer]}"
    }

    # shadows: lower-right (inner)
    if {$name != {} && [$canvs find withtag "${name}_sh_rhs_inner"] != {}} {
	eval $canvs coords "${name}_sh_rhs_inner" $sh_rhs_inner_coords
	$canvs itemconfigure "${name}_sh_rhs_inner" -width $shadowWidth
    } else {
	eval $canvs create arc \
	    $sh_rhs_inner_coords \
	    -style arc \
	    -start 280 \
	    -extent 70 \
	    -width $shadowWidth \
	    -outline [colorspecShade $colorSpec] \
	    -tags "{[concat $tags $name ${name}_sh_rhs_inner]}"
    }

    # drawing: main body (outline)
    set olwidth 0.5
    if {$name != {} && [$canvs find withtag "${name}_body_outline"] != {}} {
	eval $canvs coords "${name}_body_outline" $main_coords
    } else {
	eval $canvs create oval \
	    $main_coords \
	    -fill "{}" \
	    -width $olwidth \
	    -outline [colorspecPen $colorSpec] \
	    -tags "{[concat $tags $name ${name}_body_outline]}"
    }
}

#----------------------------------------------------------
# Cones
#  + extra tags: cone + body | highlight | shadow
#----------------------------------------------------------
set DEBUG_CONE 0
proc drawCone {baseLen coordSpec colorSpec {name {}} {tags "cone"} {canvs .c}} {
    #puts "CONE: baseLen={$baseLen}, coordSpec={$coordSpec}, colorSpec={$colorSpec}"
    set x [expr double([coordspecX $coordSpec])]
    set y [expr double([coordspecY $coordSpec])]

    # universal/main: base points, equations, etc.
    set xw [expr $x - $baseLen]
    set yn [expr $y - ($baseLen/5.0)]
    set xe [expr $x + $baseLen]
    set ys [expr $y + ($baseLen/5.0)]

    set height [expr $baseLen*2.0]
    set yTop [expr $y - $height]

    set lhsEqn [CoordEquation $x $yTop $xw $y]
    set rhsEqn [CoordEquation $x $yTop $xe $y]

    #-- main body: body triangle (filled)
    if {$name != {} && [$canvs find withtag "${name}_body_fill"] != {}} {
	$canvs coords "${name}_body_fill" \
	    $xw $y \
	    $x $yTop \
	    $xe $y
    } else {
	$canvs create polygon \
	    $xw $y \
	    $x $yTop \
	    $xe $y \
	    -outline {} \
	    -fill [colorspecFill $colorSpec] \
	    -tags [concat $tags $name ${name}_body_fill]
    }

    #-- main body: lower "chord" (filled)
    if {$name != {} && [$canvs find withtag "${name}_base_fill"] != {}} {
	$canvs coords "${name}_base_fill" \
	    $xw $yn \
	    $xe $ys
    } else {
	$canvs create oval \
	    $xw $yn \
	    $xe $ys \
	    -outline {} \
	    -fill [colorspecFill $colorSpec] \
	    -tags [concat $tags $name "${name}_base_fill"]
    }

    #-- shadows: lhs
    set shWidth [expr $baseLen/30.0]
    set shyOffTop [expr 1.0*$baseLen] ;# pixel distance to offset shadow top from $yTop
    set shyOffBot [expr 0.1*$baseLen] ;# pixel distance to offset shadow bot from $y
    set shxOff [expr 2.0*$shWidth] ;# pixel offset left-leg -> shadow
    set shxFloor [expr $xw + $shxOff]
    set shxCeil [expr $x + $shxOff]
    set shEqn [CoordEquation $shxFloor $y $shxCeil $yTop]

    set shyTop [expr $yTop+$shyOffTop]
    set shyBot [expr $y-$shyOffBot]

    if {$name != {} && [$canvs find withtag "${name}_sh_lhs"] != {}} {
	$canvs coords "${name}_sh_lhs" \
	    [eqSolveX $shyTop $shEqn] $shyTop \
	    [eqSolveX $shyBot $shEqn] $shyBot
	$canvs itemconfigure "${name}_sh_lhs" \
	    -width $shWidth
    } else {
	$canvs create line \
	    [eqSolveX $shyTop $shEqn] $shyTop \
	    [eqSolveX $shyBot $shEqn] $shyBot \
	    -capstyle round \
	    -width $shWidth \
	    -fill [colorspecShade $colorSpec] \
	    -tags [concat $tags $name "${name}_sh_lhs"]
    }

    #-- highlight: constants & equations
    set hlWidth [expr $baseLen/20.]  
    set hlFrac [expr 1/2.0]      ;# fraction of leg xcenter->x1 for highlight-bottom point
    set hlyOff [expr 5*$hlWidth] ;# pixel distance to offset hightlight top from $yTop
    set hlxFloor [expr $x - ($hlFrac*$baseLen)]
    set hlEqn [CoordEquation $x $yTop $hlxFloor $y]

    if {$name != {} && [$canvs find withtag "${name}_hl"] != {}} {
	$canvs coords "${name}_hl" \
	    [eqSolveX [expr $yTop+$hlyOff] $hlEqn] [expr $yTop + $hlyOff]\
	    $hlxFloor $y
	$canvs itemconfigure "${name}_hl" \
	    -width $hlWidth
    } else {
	$canvs create line \
	    [eqSolveX [expr $yTop+$hlyOff] $hlEqn] [expr $yTop + $hlyOff]\
	    $hlxFloor $y \
	    -capstyle round \
	    -width $hlWidth \
	    -fill [colorspecHigh $colorSpec] \
	    -tags [concat $tags $name "${name}_hl"]
    }


    #-- shadows: rhs (inner)
    set shyOffTop [expr 1.0*$baseLen] ;# pixel distance to offset shadow top from $yTop
    set shyOffBot [expr 0.1*$baseLen] ;# pixel distance to offset shadow bot from $y
    set shxOff [expr 5.0*$shWidth] ;# pixel offset right-leg -> shadow
    set shxFloor [expr $xe - $shxOff]
    set shxCeil [expr $x - $shxOff]
    set shEqn [CoordEquation $shxFloor $y $shxCeil $yTop]

    set shyTop [expr $yTop+$shyOffTop]
    set shyBot [expr $y-$shyOffBot]

    if {$name != {} && [$canvs find withtag "${name}_sh_rhs_inner"] != {}} {
	$canvs coords "${name}_sh_rhs_inner" \
	    [eqSolveX $shyTop $shEqn] $shyTop \
	    [eqSolveX $shyBot $shEqn] $shyBot
	$canvs itemconfigure "${name}_sh_rhs_inner" \
	    -width $shWidth
    } else {
	$canvs create line \
	    [eqSolveX $shyTop $shEqn] $shyTop \
	    [eqSolveX $shyBot $shEqn] $shyBot \
	    -capstyle round \
	    -width $shWidth \
	    -fill [colorspecShade $colorSpec] \
	    -tags [concat $tags $name "${name}_sh_rhs_inner"]
    }

    #-- shadows: rhs (outer)
    set shyOffTop [expr 0.3*$baseLen] ;# pixel distance to offset shadow top from $yTop
    set shyOffBot [expr 0.1*$baseLen] ;# pixel distance to offset shadow bot from $y
    set shxOff [expr 2.0*$shWidth] ;# pixel offset right-leg -> shadow
    set shxFloor [expr $xe - $shxOff]
    set shxCeil [expr $x - $shxOff]
    set shEqn [CoordEquation $shxFloor $y $shxCeil $yTop]

    set shyTop [expr $yTop+$shyOffTop]
    set shyBot [expr $y-$shyOffBot]

    if {$name != {} && [$canvs find withtag "${name}_sh_rhs_outer"] != {}} {
	$canvs coords "${name}_sh_rhs_outer" \
	    [eqSolveX $shyTop $shEqn] $shyTop \
	    [eqSolveX $shyBot $shEqn] $shyBot
	$canvs itemconfigure "${name}_sh_rhs_outer" \
	    -width $shWidth
    } else {
	$canvs create line \
	    [eqSolveX $shyTop $shEqn] $shyTop \
	    [eqSolveX $shyBot $shEqn] $shyBot \
	    -capstyle round \
	    -width $shWidth \
	    -fill [colorspecShade $colorSpec] \
	    -tags [concat $tags $name "${name}_sh_rhs_outer"]
    }

    #-- main body: triangle base (outline)
    set olwidth 0.5
    if {$name != {} && [$canvs find withtag "${name}_body_outline_lhs"] != {}} {
	$canvs coords "${name}_body_outline_lhs" \
	    $xw $y \
	    $x $yTop
    } else {
	$canvs create line \
	    $xw $y \
	    $x $yTop \
	    -capstyle round \
	    -width $olwidth \
	    -fill [colorspecPen $colorSpec] \
	    -tags [concat $tags $name "${name}_body_outline_lhs"]
    }
    if {$name != {} && [$canvs find withtag "${name}_body_outline_rhs"] != {}} {
	$canvs coords "${name}_body_outline_rhs" \
	    $xe $y \
	    $x $yTop
    } else {
	$canvs create line \
	    $xe $y \
	    $x $yTop \
	    -capstyle round \
	    -width $olwidth \
	    -fill [colorspecPen $colorSpec] \
	    -tags [concat $tags $name "${name}_body_outline_rhs"]
    }

    #-- main body: lower chord (outline)
    if {$name != {} && [$canvs find withtag "${name}_base_outline"] != {}} {
	$canvs coords "${name}_base_outline" \
	    $xw $yn \
	    $xe $ys
    } else {
	$canvs create arc \
	    $xw $yn \
	    $xe $ys \
	    -style arc \
	    -start 180 \
	    -extent 180 \
	    -width $olwidth \
	    -outline [colorspecPen $colorSpec] \
	    -tags [concat $tags $name "${name}_base_outline"]
    }

    # DEBUG mark points
    global DEBUG_CONE;
    if {$DEBUG_CONE} {
	markThisPoint "$x $y" "(x,y)"
	markThisPoint "$xw $yn" "(x1,y1)"
 	markThisPoint "$xe $ys" "(x2,y2)"
	markThisPoint "$x $yTop" "(x1,yTop)"
	markThisPoint "$hlxFloor $y" "(hlxFloor,y)"
    }
}

#----------------------------------------------------------
# Cylinders
#  + extra tags: cylinder + body | highlight | shadow
#----------------------------------------------------------
set DEBUG_CYLINDER 0
proc drawCylinder {baseLen coordSpec colorSpec {name {}} {tags "cone"} {canvs .c}} {
    #puts "CYLINDER: baseLen={$baseLen}, coordSpec={$coordSpec}, colorSpec={$colorSpec}"
    set x [expr double([coordspecX $coordSpec])]
    set y [expr double([coordspecY $coordSpec])]

    # universal/main: baseLen & height
    set height [expr $baseLen*2.0]
    set baseLen [expr $baseLen/2.0]

    # universal/main: base points
    set xw [expr $x - $baseLen]
    set xe [expr $x + $baseLen]
    set yhi [expr $y - $height]
    set ylo $y
    set yn_lo [expr $ylo - ($baseLen/5.0)]
    set yn_hi [expr $yhi - ($baseLen/5.0)]
    set ys_lo [expr $ylo + ($baseLen/5.0)]
    set ys_hi [expr $yhi + ($baseLen/5.0)]

    # DEBUG mark points
    global DEBUG_CYLINDER;
    if {$DEBUG_CYLINDER} {
	markThisPoint "$x $y" "(x,y)"
	markThisPoint "$x $ylo" "(x,ylo)"
 	markThisPoint "$x $yhi" "(x,yhi)"
	markThisPoint "$xw $yhi" "(xw,yhi)"
	markThisPoint "$xe $yhi" "(xe,yhi)"
	markThisPoint "$xw $ylo" "(xw,ylo)"
	markThisPoint "$xe $ylo" "(xe,ylo)"
    }

    #-- main body: rectangle (filled)
    if {$name != {} && [$canvs find withtag "${name}_body_fill"] != {}} {
	$canvs coords "${name}_body_fill" \
	    $xw $yhi \
	    $xe $ylo
    } else {
	$canvs create rectangle \
	    $xw $yhi \
	    $xe $ylo \
	    -outline {} \
	    -fill [colorspecFill $colorSpec] \
	    -tags [concat $tags $name "${name}_body_fill"]
    }

    #-- main body: lower "chord" (filled)
    if {$name != {} && [$canvs find withtag "${name}_base_fill"] != {}} {
	$canvs coords "${name}_base_fill" \
	    $xw $yn_lo \
	    $xe $ys_lo
    } else {
	$canvs create oval \
	    $xw $yn_lo \
	    $xe $ys_lo \
	    -outline {} \
	    -fill [colorspecFill $colorSpec] \
	    -tags [concat $tags $name "${name}_base_fill"]
    }


    #-- main body: upper oval (filled+outlined)
    set olwidth 0.5
    if {$name != {} && [$canvs find withtag "${name}_cap"] != {}} {
	$canvs coords "${name}_cap" \
	    $xw $yn_hi \
	    $xe $ys_hi
    } else {
	$canvs create oval \
	    $xw $yn_hi \
	    $xe $ys_hi \
	    -width $olwidth \
	    -outline [colorspecPen $colorSpec] \
	    -fill [colorspecHigh $colorSpec] \
	    -tags [concat $tags $name "${name}_cap"]
    }

    #-- highlight: constants & equations
    set hlWidth [expr $baseLen/10.]  
    set hlx [expr $x - ($baseLen*0.5)]
    set hly_hi [expr $yhi+($baseLen*0.3)]
    set hly_lo [expr $ylo+($hlWidth*0.3)]

    if {$name != {} && [$canvs find withtag "${name}_hl"] != {}} {
	$canvs coords "${name}_hl" \
	    $hlx $hly_lo \
	    $hlx $hly_hi
	$canvs itemconfigure "${name}_hl" \
	    -width $hlWidth
    } else {
	$canvs create line \
	    $hlx $hly_lo \
	    $hlx $hly_hi \
	    -capstyle round \
	    -width $hlWidth \
	    -fill [colorspecHigh $colorSpec] \
	    -tags [concat $tags $name "${name}_hl"]
    }


    # shadows: lhs
    set shWidth [expr $baseLen/15.0]
    set shx [expr $xw + ($shWidth*2.0)]
    set shy_hi [expr $yhi+($baseLen*0.8)]
    set shy_lo [expr $ylo-($baseLen*0.6)]

    if {$name != {} && [$canvs find withtag "${name}_sh_lhs"] != {}} {
	$canvs coords "${name}_sh_lhs" \
	    $shx $shy_hi \
	    $shx $shy_lo
	$canvs itemconfigure "${name}_sh_lhs" \
	    -width $shWidth
    } else {
	$canvs create line \
	    $shx $shy_hi \
	    $shx $shy_lo \
	    -capstyle round \
	    -width $shWidth \
	    -fill [colorspecShade $colorSpec] \
	    -tags [concat $tags $name "${name}_sh_lhs"]
    }

    # shadows: rhs (inner)
    set shx [expr $xe - ($shWidth*4.5)]
    set shy_hi [expr $yhi+($baseLen*0.8)]
    set shy_lo [expr $ylo-($baseLen*0.6)]

    if {$name != {} && [$canvs find withtag "${name}_sh_rhs_inner"] != {}} {
	$canvs coords "${name}_sh_rhs_inner" \
	    $shx $shy_hi \
	    $shx $shy_lo
	$canvs itemconfigure "${name}_sh_rhs_inner" \
	    -width $shWidth
    } else {
	$canvs create line \
	    $shx $shy_hi \
	    $shx $shy_lo \
	    -capstyle round \
	    -width $shWidth \
	    -fill [colorspecShade $colorSpec] \
	    -tags [concat $tags $name "${name}_sh_rhs_inner"]
    }


    # shadows: rhs (outer)
    set shx [expr $xe - ($shWidth*2.0)]
    set shy_hi [expr $yhi+($baseLen*0.2)]
    set shy_lo [expr $ylo-($baseLen*0.1)]

    if {$name != {} && [$canvs find withtag "${name}_sh_rhs_outer"] != {}} {
	$canvs coords "${name}_sh_rhs_outer" \
	    $shx $shy_hi \
	    $shx $shy_lo
	$canvs itemconfigure "${name}_sh_rhs_outer" \
	    -width $shWidth
    } else {
	$canvs create line \
	    $shx $shy_hi \
	    $shx $shy_lo \
	    -capstyle round \
	    -width $shWidth \
	    -fill [colorspecShade $colorSpec] \
	    -tags [concat $tags $name "${name}_sh_rhs_outer"]
    }

    #-- main body: lower chord (outline)
    if {$name != {} && [$canvs find withtag "${name}_base_outline"] != {}} {
	$canvs coords "${name}_base_outline" \
	    $xw $yn_lo \
	    $xe $ys_lo
    } else {
	$canvs create arc \
	    $xw $yn_lo \
	    $xe $ys_lo \
	    -style arc \
	    -start 180 \
	    -extent 180 \
	    -width $olwidth \
	    -outline [colorspecPen $colorSpec] \
	    -tags [concat $tags $name "${name}_base_outline"]
    }

    #-- main body: rectangle (outline)
    if {$name != {} && [$canvs find withtag "${name}_body_outline_lhs"] != {}} {
	$canvs coords "${name}_body_outline_lhs" \
	    $xe $ylo \
	    $xe $yhi
    } else {
	$canvs create line \
	    $xe $ylo \
	    $xe $yhi \
	    -capstyle round \
	    -width $olwidth \
	    -fill [colorspecPen $colorSpec] \
	    -tags [concat $tags $name "${name}_body_outline_lhs"]
    }
    if {$name != {} && [$canvs find withtag "${name}_body_outline_rhs"] != {}} {
	$canvs coords "${name}_body_outline_rhs" \
	    $xw $yhi \
	    $xw $ylo
    } else {
	$canvs create line \
	    $xw $yhi \
	    $xw $ylo \
	    -capstyle round \
	    -width $olwidth \
	    -fill [colorspecPen $colorSpec] \
	    -tags [concat $tags $name "${name}_body_outline_rhs"]
    }
}


#=====================================================================
# Utilities
#=====================================================================

#----------------------------------------------------------
# eqSolveY $x $Eqn --> $y
#  + solves for $x in $Eqn, returns a y-value
#  + $Eqn is a list {slope offset} as produced
#    by proc 'CoordEquation' in board.tcl
#----------------------------------------------------------
proc eqSolveY {x eqn} {
    eval "SolveFor $x " $eqn
}

#----------------------------------------------------------
# eqSolveX $y $Eqn --> $x
#  + solves for $y in $Eqn, returns an x-value
#  + $Eqn is a list {slope offset} as produced
#    by proc 'CoordEquation' in board.tcl
#----------------------------------------------------------
proc eqSolveX {y eqn} {
    set slope [lindex $eqn 0]
    set offset [lindex $eqn 1]
    if {$slope == {}} {
	# vertical lines
	return $offset
    } elseif {$slope == 0} {
	# horizontal lines
	if {$y == $offset} {
	    return $offset
	} else {
	    return {}
	}
    }
    # normal case
    return [expr double($y - $offset) / $slope]
}

#----------------------------------------------------------
# markThisPoint { {$x $y} $text }
#----------------------------------------------------------
proc markThisPoint {coordSpec text} {
    MarkCoords [coordspecX $coordSpec] [coordspecY $coordSpec]
    LabelCoords [coordspecX $coordSpec] [coordspecY $coordSpec] $text
}

#=====================================================================
# Previewing
#=====================================================================
proc previewShapes {{baseLen 50} \
			{pshapes {Sphere Cone Cylinder}} \
			{pcolors {white black red blue}} \
			{pad 30}} {
    global colorSpecs
    set x 0
    for {set sh 0} {$sh < [llength $pshapes]} {incr sh} {
	if {$x != 0} {
	    set x [expr $x + (2*$baseLen) + $pad]
	} else {
	    set x [expr $baseLen + $pad]
	}
	set y [expr -1 * ($baseLen - $pad)]
	set shape [lindex $pshapes $sh]
	for {set c 0} {$c < [llength $pcolors]} {incr c} {
	    set color $colorSpecs([lindex $pcolors $c])
	    set y [expr $y + (2*$baseLen)+$pad]
	    eval "draw$shape $baseLen {$x $y} {$color} {$shape preview}"
	}
    }
}