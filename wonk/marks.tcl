# -*- Mode: Tcl -*-
#
#             File: marks.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game
#                   procs for explicit marking (development only!)


;# ------ Placement: Points
proc MarkPlacePoint {point name {markit 0}} {
    global Points
    set Points($name) $point
    ;# let's see what we're doing...
    if {$markit} {
    	LabelPoint $point $name "nw" "point"
      ;# MarkPoint $point "$name point"
    }
}

;# ------- marking procs: points
proc MarkPoint {point args} {
    eval "MarkCoords [lindex $point 0] [lindex $point 1]" $args
}
proc MarkCoords {x y {tags "point mark"} {canvs .c}} {
    $canvs create oval \
	[expr $x - 5]  [expr $y - 5] \
	[expr $x + 5]  [expr $y + 5] \
	-tags [concat $tags "point mark"] -outline blue
}

;# ------- marking procs: segments
proc MarkSegment {fromPoint toPoint args} {
    eval "MarkLine \
            [lindex $fromPoint 0] [lindex $fromPoint 1] \
            [lindex $toPoint 0]   [lindex $toPoint 1]" \
	$args
}
;# ------- marking procs: lines
proc MarkLine {fromX fromY toX toY {tags "line mark"} {canvs .c}} {
    $canvs create line \
	$fromX $fromY \
	$toX   $toY \
	-tags [concat $tags "line mark"] ;# -fill blue ;#-stipple gray25
}
;# ------- marking procs: labels
proc MarkLabelPoint {point args} {
    eval "MarkLabelCoords [lindex $point 0] [lindex $point 1]" $args
}
proc MarkLabelCoords {x y labeltext {anchor "center"} {tags "label mark"} {canvs .c} {fill red}} {
    $canvs create text \
	$x $y -anchor $anchor -text $labeltext -tags [concat $tags "label mark"] -fill $fill
}
;# ------ Mark&Label procs: points
proc LabelPoint {point args} {
    eval "LabelCoords [lindex $point 0] [lindex $point 1]" $args
}
;# ------ Mark&Label procs: coords
proc LabelCoords {x y labeltag {anchor "nw"} {othertags "labelpoint mark"} {canvs .c}} {
    return [list \
		[MarkCoords $x $y "$labeltag $othertags" $canvs] \
		[MarkLabelCoords  $x $y $labeltag $anchor "$labeltag $othertags" $canvs] ]
}

;# ------ marking procs: spaces
proc MarkNamedSpace {name {tags "space mark"} {canvs .c}} {
    set color [$canvs itemcget $name -fill]
    eval "MarkLabelCoords" [NamedSpaceCenter $name] "{$name}" "center" "{$tags}" "$canvs" "red"
}
;# ------ marking procs: spaces
proc MarkSpace {seg skew tier {tags "space mark"} {canvs .c}} {
    MarkNamedSpace [NameSpace $seg $skew $tier] $tags $canvs
}


;# ------ Marking procs: vectors
proc MarkVector {x y angle {hyp ""} {tags "vector mark"} {canvs .c}} {
    set vPoint [VectorPoint $x $y $angle $hyp]
    $canvs create line \
	$x                 $y \
	[lindex $vPoint 0] [lindex $vPoint 1] \
	-tags [concat $tags "vector mark"] -arrow last ;# -fill green
}


;# ------ Show: Points
proc ShowPoint {pointname {tags "point mark"} {labelit 1}} {
    global Points
    if {$labelit} {
	LabelPoint $Points($pointname) $pointname "nw" $tags
    } else {
	MarkPoint $Points($pointname) [concat $tags $pointname "point mark"]
    }
}
;# ------ Show: BasePoints
proc ShowBase {} {
    for {set i 0} {$i < 16} {incr i} {
	;# "real" base-points
	ShowPoint p$i "base point" 1
	;# midpoints
	if {$i % 2 == 1} {
	    ShowPoint p${i}.5 "mid point" 0
	}
    }
}
;# ------ Hide: any/everything
proc Hide {name} {
    .c delete withtag $name
}
proc HideSegment {name} { Hide $name }
proc HidePoint {name} { Hide $name }
