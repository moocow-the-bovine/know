;# ------- marking procs: points
proc MarkPoint {point args} {
    eval "MarkCoords [lindex $point 0] [lindex $point 1]" $args
}
proc MarkCoords {x y {tags "point"} {canvs .c}} {
    $canvs create oval \
	[OffsetX [expr $x - 5]]  [OffsetY [expr $y - 5]] \
	[OffsetX [expr $x + 5]]  [OffsetY [expr $y + 5]] \
	-tags $tags -outline blue
}

;# ------- marking procs: segments
proc MarkSegment {fromPoint toPoint args} {
    eval "MarkLine \
            [lindex $fromPoint 0] [lindex $fromPoint 1] \
            [lindex $toPoint 0]   [lindex $toPoint 1]" \
	$args
}
;# ------- marking procs: lines
proc MarkLine {fromX fromY toX toY {tags "line"} {canvs .c}} {
    $canvs create line \
	[OffsetX $fromX] [OffsetY $fromY] \
	[OffsetX   $toX] [OffsetY   $toY] \
	-tags $tags ;# -fill blue ;#-stipple gray25
}
;# ------- marking procs: labels
proc MarkLabelPoint {point args} {
    eval "MarkLabelCoords [lindex $point 0] [lindex $point 1]" $args
}
proc MarkLabelCoords {x y labeltext {anchor "center"} {tags "label"} {canvs .c}} {
    $canvs create text \
	[OffsetX $x] [OffsetY $y] \
	-anchor $anchor -text $labeltext -tags [concat $tags "label"] -fill red
}
;# ------ Mark&Label procs: points
proc LabelPoint {point args} {
    eval "LabelCoords [lindex $point 0] [lindex $point 1]" $args
}
;# ------ Mark&Label procs: coords
proc LabelCoords {x y labeltag {anchor "nw"} {othertags "labelpoint"} {canvs .c}} {
    return [list \
		[MarkCoords $x $y "$labeltag $othertags" $canvs] \
		[MarkLabelCoords  $x $y $labeltag $anchor "$labeltag $othertags" $canvs] ]
}

;# ------ Show: Points
proc ShowPoint {pointname} {
    global Points
    LabelPoint $Points($pointname) $pointname
}
;# ------ Show: BasePoints
proc ShowBase {} {
    for {set i 0} {$i < 16} {incr i} {ShowPoint p$i}
}
;# ------ Show: Segments
;#proc ShowSegment {segname} {
#   global Segments
#   eval MarkLine [concat $Segments($segname) "{$segname segment}"]
#}
;# ------ Hide: any/everything
proc Hide {name} {
    .c delete withtag $name
}
proc HideSegment {name} { Hide $name }
proc HidePoint {name} { Hide $name }

;# ------ marking procs: vectors
proc MarkVector {x y angle {hyp ""} {tags "vector"} {canvs .c}} {
    set vPoint [VectorPoint $x $y $angle $hyp]
    $canvs create line \
	[OffsetX $x]        [OffsetY $y] \
	[OffsetX [lindex $vPoint 0]]  [OffsetY [lindex $vPoint 1]] \
	-tags $tags -arrow last ;# -fill green
}

;# ----- Calculation: Line-Equations (segment-based)
proc SegmentEquation {segmentName} {
    global Segments
    eval CoordEquation $Segments($segmentName)
}

;# ----- Placement: Intersections (name-based) [obsolete]
proc PlaceSegIntersection {eqnname1 eqnname2 {intersectname ""} {markit 1} {canvs .c}} {
    global Equations
    if {$intersectname == ""} {
	set intersectname "$eqnname1+$eqnname2"
    }
    PlaceEqnIntersection \
	$Equations($eqnname1) $Equations($eqnname2) \
	$intersectname $markit $canvs
}
;# ----- Placement: Spaces (number(ID)+quadrant-based) [obsolete]
proc PlaceQuadrantSpace {quadrant seg skew tier color pointIDList} {
    set adjustedList {}
    foreach pointID $pointIDList {
	lappend adjustedList [QuadrantAdjust $quadrant $pointID]
    }
    PlaceNumberSpace [expr $seg+$quadrant] $skew $tier $color $adjustedList
}
;# ----- Placement: Spaces (number(ID)-based) [obsolete]
proc PlaceNumberSpace {seg skew tier color pointIDList} {
    set coordList {}
    foreach pointID $pointIDList {
	eval "lappend coordList" [PointCoords $pointID]
    }
    PlaceCoordSpace [NameSpace $seg $skew $tier] $color $coordList
}


;# ----- Predicate: Parallelity: Line-Equations (name-based)
proc AreParallelEqnNames {eqnName1 eqnName2} {
    global Equations
    AreParallelEqns $Equations($eqnName1) $Equations($eqnName2)
}


;# ---- Drawing: Board: Segments (frame) [incomplete]
proc PlaceBoardSegments {} {
    ;# -- skip-3 lines
    ;#ConnectPointNumbers 3 6
     #ConnectPointNumbers 7 10
     #ConnectPointNumbers 11 14
     #ConnectPointNumbers 2 15

    ;# -- skip-5 lines
    ;#ConnectPointNumbers 2 7
     #ConnectPointNumbers 6 11
     #ConnectPointNumbers 10 15
     #ConnectPointNumbers 3 14

    ;# -- skip-7 lines
    ;#ConnectPointNumbers 0 9
     #ConnectPointNumbers 1 8
     #ConnectPointNumbers 4 13
     #ConnectPointNumbers 5 12
}

;# ----- Placement: Segments (name-based) [obsolete???]
proc ConnectPoints {fromPointName toPointName {markit 1} {canvs .c}} {
    global Points
    PlaceSegment $Points($fromPointName) $Points($toPointName) \
	"$fromPointName-$toPointName" $markit $canvs
}

;# ----- Calculation&Placement: Intersections (segment-based)
;# =========> way too many of 'em !
proc PlaceSegmentIntersects {} {
    global Equations
    set EqnNames [array names Equations]
    set NumEqns [llength $EqnNames]
    for {set i1 0} {$i1 < $NumEqns - 1} {incr i1} {
	set name1 [lindex $EqnNames $i1]
	set eqn1 $Equations($name1)
	for {set i2 [expr $i1 + 1]} {$i2 < $NumEqns} {incr i2} {
	    set name2 [lindex $EqnNames $i2]
	    set eqn2 $Equations($name2)
	    if {[AreParallelEqns $eqn1 $eqn2]} { continue }
	    ;#puts "Placing Intersection: $eqn1+$eqn2"
	    PlaceEqnIntersection $eqn1 $eqn2 "$name1+$name2"
	}
    }
}

;# ----- Calculation: Line-Equations (name-based)
proc PointNameEquation {fromPointName toPointName} {
    global Points
    PointEquation $Points($fromPointName) $Points($toPointName)
}
;# ----- Placement: Segments (point-based)
proc PlaceSegment {fromPoint toPoint name {markit 0} {canvs .c}} {
    global Segments Equations
    if {$markit} {MarkSegment $fromPoint $toPoint "$name segment" $canvs}
    set Segments($name) "$fromPoint $toPoint"
    set Equations($name) [PointEquation $fromPoint $toPoint]
}
;# ----- Calculation: Line-Equations (segment-based)
proc SegmentEquation {segmentName} {
    global Segments
    eval CoordEquation $Segments($segmentName)
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

;# ------ Calculation: midpoints (Coordinate-based)
;#        args is a list of the form {x1 y1 x2 y2 ... xn yn}
proc MidCoords {args} {
    set midx 0.0
    set midy 0.0
    foreach {x y} $args {
	set midx [expr $midx + $x]
	set midy [expr $midy + $y]
    }
    set denom [expr [llength $args] * 0.5]
    return "[expr $midx / $denom] [expr $midy / $denom]"
}



;# ------ offset procs
proc OffsetPoint {point} {
    global defOpts
    return "[OffsetX [lindex $point 0]]
            [OffsetY [lindex $point 1]]"
}
proc OffsetX {x} {
    global OffsetX
    return [expr $x + $OffsetX]
}
proc OffsetY {y} {
    global OffsetY
    return [expr $y + $OffsetY]
}


;# -------- grid test (a la Welsh)
toplevel .t
foreach color {red orange yellow green blue purple} {
    label .t.l$color -text $color -bg white
    frame .t.f$color -background $color -width 100 -height 2
    ;# v1:
    grid .t.l$color .t.f$color
    ;# v2:
    grid .t.l$color -sticky w 
    grid .t.f$color -sticky ns
}

;# ----- Board Drawing: Space-placement [old version]
proc PlaceBoardSpaces1 {} {
    for {set q 0} {$q < 16} {incr q 4} {
	;# (skew: 2=widdershins=clockwise)
	;# PlaceQuadrantSpace quadrant seg skew tier color pointIDList
	;# -- seg=0
	PlaceQuadrantSpace $q 0 0 0 black {0 1 {1 9 2 15} {0 8 2 15}}
	PlaceQuadrantSpace $q 0 0 1 white {{0 8 2 15} {1 9 2 15} {1 9 3 14} {0 8 3 14}}
	PlaceQuadrantSpace $q 0 0 2 black {{0 8 3 14} {1 9 3 14} {1 9 4 13} {0 8 4 13}}
	PlaceQuadrantSpace $q 0 0 3 white {{0 8 4 13} {1 9 4 13} center}
	;# -- seg=1
	;#PlaceQuadrantSpace $q 1 2 0 white {1 {1 9 2 15} {1 8 2 15}}
	;#PlaceQuadrantSpace $q 1 1 0 black {1 2 {1 8 2 15}}
	PlaceQuadrantSpace $q 1 2 0 white {1 {1 9 2 15} {1 8 2 15} 1.5}
	PlaceQuadrantSpace $q 1 1 0 black {1.5 2 {1 8 2 15}}
	PlaceQuadrantSpace $q 1 1 1 white {2 {2 10 3 14} {1 8 3 14} {1 8 2 15}}
	PlaceQuadrantSpace $q 1 2 1 black {{1 9 2 15} {1 8 2 15} {1 8 3 14} {1 9 3 14}}
	PlaceQuadrantSpace $q 1 2 2 white {{1 9 3 14} {1 8 3 14} {1 8 2 10} {2 10 4 13} {1 9 4 13}}
	PlaceQuadrantSpace $q 1 1 2 black {{1 8 3 14} {2 10 3 14} {1 8 2 10}}
	PlaceQuadrantSpace $q 1 0 3 black {{1 9 4 13} {2 10 4 13} center}
	;# -- seg=2
	PlaceQuadrantSpace $q 2 0 0 white {2 3 {2 7 3 14}}
	PlaceQuadrantSpace $q 2 2 1 black {2 {2 10 3 14} {2 7 3 14}}
	PlaceQuadrantSpace $q 2 1 1 black {3 {2 7 3 11} {2 7 3 14}}
	PlaceQuadrantSpace $q 2 0 2 white {{2 10 3 14} {2 7 3 14} {2 7 3 11} \
						{3 11 4 13} {1 8 4 13} {1 8 2 10}}
	PlaceQuadrantSpace $q 2 2 2 black {{1 8 2 10} {1 8 4 13} {2 10 4 13}}
	PlaceQuadrantSpace $q 2 1 2 black {{1 8 4 13} {1 8 3 11} {3 11 4 13}}
	PlaceQuadrantSpace $q 2 0 3 white {{2 10 4 13} {1 8 4 13} {1 8 3 11} center}
	;# -- seg=3
	;#PlaceQuadrantSpace $q 3 2 0 black {3 4 {3 6 4 13}}
	;#PlaceQuadrantSpace $q 3 1 0 white {4 {3 6 4 13} {3 6 4 12}}
	PlaceQuadrantSpace $q 3 2 0 black {3 3.5 {3 6 4 13}}
	PlaceQuadrantSpace $q 3 1 0 white {4 {3 6 4 12} {3 6 4 13} 3.5}
	PlaceQuadrantSpace $q 3 1 1 black {{3 6 4 13} {3 6 4 12} {2 7 4 12} {2 7 4 13}}
	PlaceQuadrantSpace $q 3 2 1 white {3 {3 6 4 13} {2 7 4 13} {2 7 3 11}}
	PlaceQuadrantSpace $q 3 2 2 black {{2 7 3 11} {2 7 4 13} {3 11 4 13}}
	PlaceQuadrantSpace $q 3 1 2 white {{2 7 4 13} {2 7 4 12} {1 8 4 12} {1 8 3 11} {3 11 4 13}}
	PlaceQuadrantSpace $q 3 0 3 black {{1 8 3 11} {1 8 4 12} center}
    }
}


;# -------- resize test (via Configure-event)
toplevel .g
canvas .g.c -bg white -height 150 -width 150 -confine 1
pack .g.c -fill both -expand true
.g.c create rectangle 10 10 140 140 -outline blue -tags "rect"
.g.c create rectangle 20 20 130 130 -outline blue -tags "square"
bind .g <Any-Configure> "OnResizeG"
proc OnResizeG {} {
    .g.c configure -width  [winfo width .g.c]
    .g.c configure -height [winfo height .g.c]
    .g.c coords "rect" 10 10 \
	[expr [.g.c cget -width] - 10] \
	[expr [.g.c cget -height] - 10]   
}

