# -*- Mode: Tcl -*-
#
#             File: board.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game
#                   procs for board-drawing

;# ------ debug
set mark_points 0
set mark_segments 0
set mark_intersects 0

;# ----- mark tiers
set mark_tiers 1
;#set tier_colors {black blue green yellow}
;#set tier_bitmaps {gray12 gray25 gray50 gray75}
;#set tier_bitmaps {gray75 gray50 gray25 gray12}
set tier_bitmaps {}
set tier_colors(black) {grey25  grey50 grey75 grey100}
set tier_colors(white) $tier_colors(black)
#set tier_colors(white) {grey0 grey26 grey52 grey78}
#set tier_colors(white) {grey52 grey68 grey84 grey100}
#set tier_colors(white) {white  white  white  white}

;# ------ ambiguous spaces
# rim/1st-tier
set ambig_rim {2:0/0 6:0/0 10:0/0 14:0/0}
set ambig_rim_color "white"




;# ------ Lookup: Points: by ID
;#        where a 'PointID' is...
;#          (1) a single-element list - then, the point named is "p<element>"
;#          (2) a 4-element list of the intersect-naming form "from1 to1 from2 to2",
;#              here, the point named is "from1-to1+from2-to2"
proc PointCoords {PointID} {
    global Points
    return $Points([NamePointID $PointID])
}
;# ------ Naming Conventions: points: numbers: 0 <= n <= 15
proc CyclicPoint {pointNumber} {
    if {ceil($pointNumber) == $pointNumber} {
	return [expr $pointNumber % 16]
    } else {
	return [expr (int($pointNumber - 0.5) % 16) + 0.5]
    }
}
;# ------ Naming Conventions: points: by ID: p<number>
proc NamePointID {PointID} {
    if {[llength $PointID] == 1} { 
	return [NamePoint $PointID]
    } else {
	return [eval "NameIntersection" $PointID]
    }
}

;# ------ Naming Conventions: points: names: p<number>
proc NamePoint {pointNumber} {
    if {[regexp {^[0-9\.]+$} $pointNumber]} {
	return p[CyclicPoint $pointNumber]
    } else { return $pointNumber }
}
;# ------ Naming Conventions: segments: "<n1>-<n2>" s.t. n1 < n2
;#        (where n1,n2 are the numbers of the seg's endpoints)
proc NameSegment {pointNumber1 pointNumber2} {
    set p1 [CyclicPoint $pointNumber1]
    set p2 [CyclicPoint $pointNumber2]
    set minPoint [mut:min $p1 $p2]
    set maxPoint [mut:max $p1 $p2]
    return "$minPoint-$maxPoint"
}
;# ------ Naming Conventions: intersections: "<seg1>+<seg2>", where
;#        <seg1> ::= n1.1-n1.2  ,
;#        <seg2> ::= n2.1-n2.2  ,    and  n1.1 < n2.1
;#
;# The argument-list  is taken to be
;# a list of the form {<n1.1> <n1.2> <n2.1> <n2.2>}
proc NameIntersection {args} {
    set s1 [lsort -integer [mut:collect CyclicPoint [lrange $args 0 1]]]
    set s2 [lsort -integer [mut:collect CyclicPoint [lrange $args 2 3]]]
    if {[lindex $s1 0] < [lindex $s2 0]} {
	return "[lindex $s1 0]-[lindex $s1 1]+[lindex $s2 0]-[lindex $s2 1]"
    } else {
	return "[lindex $s2 0]-[lindex $s2 1]+[lindex $s1 0]-[lindex $s1 1]"
    }
}
;# ------ Naming Conventions: Spaces: <seg>:<skew>/<tier> , where
;#        0 <= seg <= 15 ,      number = n ==> seg between point n & point (n+1) [turnwise rotation]
;#        0 <= skew <= 2 ,      1=turnwise(=ctr-clockwise); 2=widdershins(=clockwise); 0=center
;#        0 <= tier <= 3 ,      0=rim, ... , 3=center
proc NameSpace {seg skew tier} {
    return "[expr $seg % 16]:[expr $skew % 3]/[expr $tier % 4]"
}

;# ------ Offsets
proc OffsetAngle {angle} {
    global AngleOffset
    return [expr $angle + $AngleOffset]
}


;# ------ Placement: Points
proc PlacePoint {point name} {
    global Points
    set Points($name) $point
    ;# let's see what we're doing...
    global mark_points
    if {$mark_points} {
	;#MarkLabelPoint $point $name "nw" "point"
    	LabelPoint $point $name "nw" "point"
        MarkPoint $point "$name point"
    }
}
;# ----- Placement: Segments (number-based)
proc ConnectPointNumbers {PointNum1 PointNum2 {ForceDraw 0}} {
    global Points
    PlaceSegment \
	$Points([NamePoint $PointNum1]) \
	$Points([NamePoint $PointNum2]) \
	[NameSegment $PointNum1 $PointNum2] \
	$ForceDraw
}
;# ----- Placement: Segments (point-based)
proc PlaceSegment {fromPoint toPoint name {ForceDraw 0}} {
    global Equations
    global mark_segments
    if {$mark_segments} {MarkSegment $fromPoint $toPoint "$name segment"}
    set Equations($name) [PointEquation $fromPoint $toPoint]
    if {$ForceDraw} {
	if {[.c coords $name] == {}} {
	    ;# --- draw a new one
	    .c create line \
		[lindex $fromPoint 0] [lindex $fromPoint 1] \
		[lindex $toPoint 0] [lindex $toPoint 1] \
		-tags "$name segment force"
	} else {
	    ;# --- just move it
	    .c coords $name \
		[lindex $fromPoint 0] [lindex $fromPoint 1] \
		[lindex $toPoint 0] [lindex $toPoint 1]
	}
    }
}

;# ----- Placement: Intersections (quadrant+number-based)
;#       where "quadrant" is really a full integer-offset
proc PlaceQuadrantIntersection {quadrant from1 to1 from2 to2} {
    PlaceNumberIntersection \
	[expr $quadrant + $from1] [expr $quadrant + $to1] \
	[expr $quadrant + $from2] [expr $quadrant + $to2]
}
;# ----- Placement: Intersections (number-based)
proc PlaceNumberIntersection {from1 to1 from2 to2} {
    global Equations
    PlaceEqnIntersection \
	$Equations([NameSegment $from1 $to1]) \
	$Equations([NameSegment $from2 $to2]) \
	[NameIntersection $from1 $to1 $from2 $to2]
}
;# ----- Placement: Intersections (eqn-based)
proc PlaceEqnIntersection {eqn1 eqn2 name} {
    global Points
    if {[AreParallelEqns $eqn1 $eqn2]} {return {}}
    set intersectPoint [EqnIntersection $eqn1 $eqn2]
    set Points($name) $intersectPoint
    global mark_intersects
    if {$mark_intersects} {
	LabelPoint $intersectPoint $name "nw" "intersection"
	MarkPoint $intersectPoint "$name intersection"
    }
}

;# ----- Placement: Spaces (coordinate+quadrant based)
proc PlaceQCoordSpace {quadrant seg skew tier color coordList} {
    ;# hack
    global mark_tiers
    global tier_colors
    global ambig_rim
    global ambig_rim_color
    set name [NameSpace [expr $seg + $quadrant] $skew $tier]
    if {$mark_tiers} {
	if {[lsearch $ambig_rim $name] >= 0} {
	    set color $ambig_rim_color
	} else {
	    set color [lindex $tier_colors($color) $tier]
	}
    }
    PlaceCoordSpace $name $color $coordList
}
;# ----- Placement: Spaces (coordinate-based)
proc PlaceCoordSpace {spaceName spaceColor coordList {bitmap ""}} {
    if {[.c coords $spaceName] == {}} {
	if {$bitmap == ""} {
	    ;# define the space -- create polygon [HACK!]
	    eval ".c create polygon" \
		[concat $coordList -fill $spaceColor -tags \"$spaceName space\" \
		     -outline black]
	} else {
	    ;# bitmap hack
	    eval ".c create polygon" \
		[concat $coordList -stipple $bitmap -tags \"$spaceName space\" \
		     -outline black]
	}
    } else {
	eval ".c coords $spaceName" $coordList
    }
}

;# ----- Calculation: Quadrant-Adjusting (ID-based)
proc QuadrantAdjust {quadrant pointID} {
    set adjustedList {}
    foreach el $pointID {
	if {$el != "center"} {
	    lappend adjustedList [CyclicPoint [expr $quadrant + $el]]
	} else {lappend adjustedList $el}
    }
    return $adjustedList
}

;# ----- Calculation: Solve-for-Value (slope&offset-based) [for intersect-calc]
proc SolveFor {xval slope offset} {
    expr ($slope * $xval) + $offset
}
;# ----- Calculation: Intersections (eqn-based)
proc EqnIntersection {eqn1 eqn2} {
    IntersectionPoint \
	[lindex $eqn1 0] [lindex $eqn1 1] \
	[lindex $eqn2 0] [lindex $eqn2 1]
}
;# ----- Calculation: Intersections (slope&offset-based)
proc IntersectionPoint {slope1 offset1 slope2 offset2} {
    if {[AreParallelSlopes $slope1 $slope2]} { return {} }
    if {$slope1 == {}} {
	;# handle vertical lines
	set intersectX $offset1
	set intersectY [SolveFor $intersectX $slope2 $offset2]
    } elseif {$slope2 == {}} {
	;# more vertical lines
	set intersectX $offset2
	set intersectY [SolveFor $intersectX $slope1 $offset1]
    } else {
	;# no vertical lines involved
	set intersectX [expr double($offset2 - $offset1) / double($slope1 - $slope2)]
	set intersectY [SolveFor $intersectX $slope1 $offset1]
    }
    return "$intersectX $intersectY"
}
;# ----- Calculation: Line-Equations (point-based)
proc PointEquation {fromPoint toPoint} {
    CoordEquation \
	[lindex $fromPoint 0] [lindex $fromPoint 1] \
	[lindex $toPoint   0] [lindex $toPoint   1]
}
;# ----- Calculation: Line-Equations (coord-based)
proc CoordEquation {x1 y1 x2 y2} { ;# returns list {slope y-offset} (or {{} x-offset} if vertical)
    global GeometryTolerance
    ;# handle vertical lines
    if {[expr abs($x1 - $x2)] < $GeometryTolerance} {
	return "{} [expr ($x1 + $x2) / 2]"
    } else {
	set slope [expr double($y1 - $y2) / double($x1 - $x2)]
	set yoff  [expr $y1 - ($slope * $x1)]
	return "$slope $yoff"
    }
}

;# ----- Predicate: Parallelity: Line-Equations (slope-only)
proc AreParallelSlopes {slope1 slope2} {
    global GeometryTolerance
    if {$slope1 == {} || $slope2 == {}} {
	;# handle vertical lines
	if {$slope1 == {} && $slope2 == {}} { return 1 }
    } elseif {abs($slope1 - $slope2) < $GeometryTolerance} { return 1 }
    return 0
}
;# ----- Predicate: Parallelity: Line-Equations (eqn-based)
proc AreParallelEqns {eqn1 eqn2} { AreParallelSlopes [lindex $eqn1 0] [lindex $eqn2 0] }

;# ------ Calculation: midpoints (ID-based)
;#        args are valid point-ID's
proc MidPoint {args} {
    set midx 0.0
    set midy 0.0
    foreach pointID $args {
	set coords [PointCoords $pointID]
	set midx [expr $midx + [lindex $coords 0]]
	set midy [expr $midy + [lindex $coords 1]]
    }
    return "[expr $midx / [llength $args]] [expr $midy / [llength $args]]"
}

;# ------ Calculation: vectors
proc VectorPoint {x y angle {hyp ""}} {
    if {$hyp == ""} {
	global AngleHyp
	set hyp $AngleHyp
    }
    return [list \
		[expr $x + ($hyp * cos($angle))] \
		[expr $y + ($hyp * sin($angle))] ]
}


;# ------ board re-drawing (clean slate)
proc ReDrawWonkBoard {} {
    .c delete mark
    DrawWonkBoard
    .c raise mark
}
;# ------ draw the actual board
proc DrawWonkBoard {} {
    global pi BoardRadius BoardPad CanvasX CanvasY

    set CenterX [expr $CanvasX / 2]
    set CenterY [expr $CanvasY / 2]

    ;# -- Diagonals as guidelines
    ;# MarkLine 0 0 [expr 2 * $centerX] [expr 2 * $centerY]
    ;# MarkLine 0 [expr 2 * $centerY] [expr 2 * $centerX] 0

    ;# -- Mark the center
    PlacePoint "$CenterX $CenterY" "center"

    ;# -- Place the outer base-points
    set angle_incr [expr $pi / 8]
    set i 0
    for {set angle 0} {$angle > [expr -2 * $pi]} {set angle [expr $angle - $angle_incr]} {
	PlacePoint [VectorPoint $CenterX $CenterY [OffsetAngle $angle] \
			[expr $BoardRadius - $BoardPad] ] "p$i" ;# 1
	incr i
    }

    ;# -- Place the secondary base-points (midpoints)
    for {set i 1} {$i < 16} {incr i 2} {
	PlacePoint [MidPoint $i [expr $i + 1]] "p${i}.5" ;# 1
    }
    
    ;# -- place the rim-circle [nope: bad for space-making]
    ;#.c create oval \
    ;#   [expr $CenterX - $BoardRadius + $BoardPad] [expr $CenterY - $BoardRadius + $BoardPad] \
    ;#   [expr $CenterX + $BoardRadius - $BoardPad] [expr $CenterY + $BoardRadius - $BoardPad] \
    ;#   -tags "outer-rim" ;# -outline blue

    ;# -- place segments && calculate their equations
    PlaceBoardSegments

    ;# -- place intersection-points
    PlaceSegmentIntersections

    ;# -- place actual board-spaces
    PlaceBoardSpaces

    ;# -- place board-rim
    ;# PlaceBoardRim
}

proc PlaceBoardSpaces {} {
    global Points
    for {set q 0} {$q < 16} {incr q 4} {
	foreach idx {0 1 1.5 2 3 3.5 4 {1 9 2 15} {0 8 2 15} center \
			 {1 9 3 14} {0 8 3 14} {1 9 4 13} {0 8 4 13} \
			 {1 8 2 15} {2 10 3 14} {1 8 3 14} {1 8 2 10} \
			 {2 10 4 13} {2 7 3 14} {2 7 3 11} {3 11 4 13} \
			 {1 8 4 13} {1 8 3 11} {3 11 4 13} {3 6 4 13} \
			 {3 6 4 12} {2 7 4 12} {2 7 4 13} {1 8 4 12} } \
	{
	    set "c[NamePointID $idx]" $Points([NamePointID [QuadrantAdjust $q $idx]])
	}
	;# -- seg=0
	PlaceQCoordSpace $q 0 0 0  black  "${cp0} ${cp1} ${c1-9+2-15} ${c0-8+2-15}"
	PlaceQCoordSpace $q 0 0 1  white  "${c0-8+2-15} ${c1-9+2-15} ${c1-9+3-14} ${c0-8+3-14}"
	PlaceQCoordSpace $q 0 0 2  black  "${c0-8+3-14} ${c1-9+3-14} ${c1-9+4-13} ${c0-8+4-13}"
	PlaceQCoordSpace $q 0 0 3  white  "${c0-8+4-13} ${c1-9+4-13} $ccenter"
	;# -- seg=1
	PlaceQCoordSpace $q 1 2 0  white  "${cp1} ${c1-9+2-15} ${c1-8+2-15} ${cp1.5}"
	PlaceQCoordSpace $q 1 1 0  black  "${cp1.5} ${cp2} ${c1-8+2-15}"
	PlaceQCoordSpace $q 1 1 1  white  "${cp2} ${c2-10+3-14} ${c1-8+3-14} ${c1-8+2-15}"
	PlaceQCoordSpace $q 1 2 1  black  "${c1-9+2-15} ${c1-8+2-15} ${c1-8+3-14} ${c1-9+3-14}"
	PlaceQCoordSpace $q 1 2 2  white  "${c1-9+3-14} ${c1-8+3-14} ${c1-8+2-10} \
                                           ${c2-10+4-13} ${c1-9+4-13}"
	PlaceQCoordSpace $q 1 1 2  black  "${c1-8+3-14} ${c2-10+3-14} ${c1-8+2-10}"
	PlaceQCoordSpace $q 1 0 3  black  "${c1-9+4-13} ${c2-10+4-13} $ccenter"
	;# -- seg=2
	PlaceQCoordSpace $q 2 0 0  white  "${cp2} ${cp3} ${c2-7+3-14}"
	PlaceQCoordSpace $q 2 2 1  black  "${cp2} ${c2-10+3-14} ${c2-7+3-14}"
	PlaceQCoordSpace $q 2 1 1  black  "${cp3} ${c2-7+3-11} ${c2-7+3-14}"
	PlaceQCoordSpace $q 2 0 2  white  "${c2-10+3-14} ${c2-7+3-14} ${c2-7+3-11} \
                                           ${c3-11+4-13} ${c1-8+4-13} ${c1-8+2-10}"
	PlaceQCoordSpace $q 2 2 2  black  "${c1-8+2-10} ${c1-8+4-13} ${c2-10+4-13}"
	PlaceQCoordSpace $q 2 1 2  black  "${c1-8+4-13} ${c1-8+3-11} ${c3-11+4-13}"
	PlaceQCoordSpace $q 2 0 3  white  "${c2-10+4-13} ${c1-8+4-13} ${c1-8+3-11} $ccenter"
	;# -- seg=3
	PlaceQCoordSpace $q 3 2 0  black  "${cp3} ${cp3.5} ${c3-6+4-13}"
	PlaceQCoordSpace $q 3 1 0  white  "${cp4} ${c3-6+4-12} ${c3-6+4-13} ${cp3.5}"
	PlaceQCoordSpace $q 3 1 1  black  "${c3-6+4-13} ${c3-6+4-12} ${c2-7+4-12} ${c2-7+4-13}"
	PlaceQCoordSpace $q 3 2 1  white  "${cp3} ${c3-6+4-13} ${c2-7+4-13} ${c2-7+3-11}"
	PlaceQCoordSpace $q 3 2 2  black  "${c2-7+3-11} ${c2-7+4-13} ${c3-11+4-13}"
	PlaceQCoordSpace $q 3 1 2  white  "${c2-7+4-13} ${c2-7+4-12} ${c1-8+4-12} \
                                           ${c1-8+3-11} ${c3-11+4-13}"
	PlaceQCoordSpace $q 3 0 3  black  "${c1-8+3-11} ${c1-8+4-12} $ccenter"
    }
}

proc PlaceSegmentIntersections {} {
    for {set q 0} {$q < 16} {incr q 4} {
	;# PlaceQuadrantIntersection {from1 to1 from2 to2} ...
	;# 0-8+...  , 1-9+...
	foreach b {0 1} {
	    set c [expr $b + 8]
	    PlaceQuadrantIntersection $q $b $c 2 15
	    PlaceQuadrantIntersection $q $b $c 3 14
	    PlaceQuadrantIntersection $q $b $c 4 13
	}
	;# 2-10+...
	PlaceQuadrantIntersection $q 2 10 3 14
	PlaceQuadrantIntersection $q 2 10 1 8
	PlaceQuadrantIntersection $q 2 10 4 13
    
	;# 3-11+...
	PlaceQuadrantIntersection $q 3 11 2 7
	PlaceQuadrantIntersection $q 3 11 4 13
	PlaceQuadrantIntersection $q 3 11 1 8

	;# non-center-splitting (q1)
	;# 1-8+...
	PlaceQuadrantIntersection $q 1 8 2 15
	PlaceQuadrantIntersection $q 1 8 3 14
	PlaceQuadrantIntersection $q 1 8 4 13
	;# 2-7+...
	PlaceQuadrantIntersection $q 2 7 3 14
	PlaceQuadrantIntersection $q 2 7 4 13
	;# 3-6+...
	PlaceQuadrantIntersection $q 3 6 4 13
    }
}

proc PlaceBoardSegments {} {
    ;# -- center-splitting rays
    for {set i 0} {$i < 8} {incr i} {
	ConnectPointNumbers $i [expr $i + 8]
    }
    ;# -- skip-3 lines
    for {set i 0} {$i < 16} {incr i 4} {
	;# -- skip-3 lines
	ConnectPointNumbers [expr $i + 3] [expr $i + 6]
	;# -- skip-5 lines
	ConnectPointNumbers [expr $i + 2] [expr $i + 7]
	;# -- skip-7 lines
	ConnectPointNumbers [expr $i + 1] [expr $i + 8]
    }
}

proc PlaceBoardRim {} {
  global Points
    ;# -- connect rim-points
    for {set i 0} {$i < 16} {incr i} {
	ConnectPointNumbers $i [expr $i + 1] 1
    }
}