# todo: different time signatures, proc to add measures (generally rethink drawing
# measures), add option to add custom names to keys for use as tracks.
# also add relative/ absolute grid option
set measures 50.0
set basecwidth [expr $measures * 125]
set basecheight 2048
set cheight $basecheight
set cwidth $basecwidth
# This is a global state variable for everything:
# bit positions: 0 is mode, 1 is canvas drag, 2 is inside note, 3 is note 
# selected, 4 is note resizing, 5 is left/right resize, 6 is cursor black/ blue
set xgrid 0.125
# ygrid is boolean:
set ygrid 1
set nlength 0.5

# testing canvas + scrollbars
tk::canvas .c -scrollregion "0 0 1000 1000" -yscrollcommand ".v set" -width 800 -height 800 -xscrollcommand ".h set" -bg blue -highlightthickness 0
ttk::scrollbar .h -orient horizontal -command ".c xview"
ttk::scrollbar .v -orient vertical -command ".c yview"
grid .c -sticky nwes -column 0 -row 0
grid .h -row 1 -column 0 -sticky ew
grid .v -row 0 -column 1 -sticky ns
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1



#create frame and window for "mega" widget
ttk::frame .c.test -width 400 -height 400
.c create window 100 150 -anchor nw -window .c.test

#create widgets for testing
ttk::checkbutton .c.ygrid -text "ygrid on/off" -variable ygrid
.c create window 50 20 -anchor nw -window .c.ygrid
ttk::button .c.delete -text "delete notes" -command delete_notes
.c create window 500 20 -anchor nw -window .c.delete
ttk::labelframe .c.scaleframe -text "xgrid value (in 1/8th notes)"
ttk::radiobutton .c.scaleframe.s1 -variable xgrid -value 0.0 -text off
ttk::radiobutton .c.scaleframe.s2 -variable xgrid -value 0.0625 -text "1/16"
ttk::radiobutton .c.scaleframe.s3 -variable xgrid -value 0.125 -text "1/8"
ttk::radiobutton .c.scaleframe.s4 -variable xgrid -value 0.25 -text "1/4"
ttk::radiobutton .c.scaleframe.s5 -variable xgrid -value 0.5 -text "1/2"
ttk::radiobutton .c.scaleframe.s6 -variable xgrid -value 1.0 -text "1"
.c create window 200 20 -anchor nw -window .c.scaleframe
grid .c.scaleframe.s1 .c.scaleframe.s2 .c.scaleframe.s3 .c.scaleframe.s4 .c.scaleframe.s5 .c.scaleframe.s6
ttk::labelframe .c.lengthframe -text "default note length (when clicked)"
ttk::radiobutton .c.lengthframe.s2 -variable nlength -value 0.0625 -text "1/16"
ttk::radiobutton .c.lengthframe.s3 -variable nlength -value 0.125 -text "1/8"
ttk::radiobutton .c.lengthframe.s4 -variable nlength -value 0.25 -text "1/4"
ttk::radiobutton .c.lengthframe.s5 -variable nlength -value 0.5 -text "1/2"
ttk::radiobutton .c.lengthframe.s6 -variable nlength -value 1.0 -text "1"
.c create window 200 70 -anchor nw -window .c.lengthframe
grid .c.lengthframe.s2 .c.lengthframe.s3 .c.lengthframe.s4 .c.lengthframe.s5 .c.lengthframe.s6
#create ruler, velocity, and keyboard canvases
tk::canvas .c.test.rule -scrollregion [list 0 0 $cwidth 50] -highlightthickness 0 -bg red -height 50
tk::canvas .c.test.kb -scrollregion [list 0 0 50 $cheight] -highlightthickness 0 -bg green -width 50
#tk::canvas .c.test.vel -scrollregion "0 0 5000 50" -highlightthickness 0 -bg purple -height 50

#create buttons
ttk::frame .c.test.buttons -width 50 -height 50
ttk::button .c.test.buttons.editmode -text draw -width 6 -command editmode
ttk::button .c.test.buttons.selectmode -text sel -width 6 -command selmode

#create canvas, sizegrip, and scrollbars for midi editing region (inframe)
ttk::frame .c.test.inframe
#grid propagate .c.test.inframe 0
grid propagate .c.test 0
ttk::scrollbar .c.test.inframe.h -orient horizontal -command {scrollh}
ttk::scrollbar .c.test.inframe.v -orient vertical -command {scrollv}
tk::canvas .c.test.inframe.canvas -scrollregion [list 0 0 $cwidth $cheight] -xscrollcommand ".c.test.inframe.h set" -yscrollcommand ".c.test.inframe.v set" -highlightthickness 0 -bg yellow

# blank frames for offsetting scrollbars with grid, later maybe have these be zoom controls
#ttk::frame .c.test.blankh -width [.c.test.inframe.v cget -width] -height 50
canvas .c.test.blankv -height [.c.test.inframe.h cget -width] -width 50 -bg orange -highlightthickness 0
canvas .c.test.blankh -width [.c.test.inframe.h cget -width] -height 50 -bg orange -highlightthickness 0

tk::canvas .c.test.inframe.sz -scrollregion "0 0 [.c.test.inframe.h cget -width] [.c.test.inframe.v cget -width]" -highlightthickness 0 -bg purple -width [.c.test.inframe.h cget -width] -height [.c.test.inframe.v cget -width] -cursor bottom_right_corner


# grid everything todo: change sizegrip line to scale right
.c.test.inframe.sz create line 2 10 10 2 -fill white
grid .c.test.rule -column 1 -row 0 -sticky we
grid .c.test.kb -column 0 -row 1 -sticky ns
#grid .c.test.vel -column 1 -row 2 -sticky w
grid .c.test.buttons -column 0 -row 0 -sticky nsew
grid .c.test.buttons.editmode -column 0 -row 0 -sticky nsew
grid .c.test.buttons.selectmode -column 0 -row 1 -sticky nsew
grid propagate .c.test.buttons 0
grid columnconfigure .c.test.buttons 0 -weight 1
grid rowconfigure .c.test.buttons 0 -weight 0
grid rowconfigure .c.test.buttons 1 -weight 0
grid .c.test.blankh -column 2 -row 0 -sticky ne
grid .c.test.blankv -column 0 -row 2 -sticky sw

# inframe stuff
grid .c.test.inframe -column 1 -row 1 -sticky nwes -columnspan 2 -rowspan 2
grid .c.test.inframe.canvas -column 0 -row 0 -sticky nwes
grid rowconfigure .c.test.inframe 0 -weight 1
grid columnconfigure .c.test.inframe 0 -weight 1

grid .c.test.inframe.v -column 1 -row 0 -sticky ns
grid .c.test.inframe.h -column 0 -row 1 -sticky ew
grid .c.test.inframe.sz -column 1 -row 1 -sticky se

grid rowconfigure .c.test 1 -weight 1
grid rowconfigure .c.test 0 -weight 0
grid columnconfigure .c.test 1 -weight 1
grid columnconfigure .c.test 0 -weight 0
grid columnconfigure .c.test 2 -weight 0

proc drawrule {} {
	global cwidth
	global cheight
	global measures
	set multiple [expr $cwidth / $measures]
	for {set i 1} {$i < $measures} {incr i} {
		.c.test.rule create line [expr $i * $multiple] 20 [expr $i * $multiple] 50 -fill blue
		.c.test.rule create text [expr $i * $multiple] 10 -text $i -fill blue
		.c.test.inframe.canvas create line [expr $i * $multiple] 0 [expr $i * $multiple] $cheight -fill blue -tags bg -state disabled
	}
	set depth 5
	for {set i 1} {$i < $depth} {incr i} {
		
		for {set j 0} {$j < [expr $measures * [expr 2**[expr $i - 1]]]} {incr j} {
			set xpos [expr $multiple / 2.0 + $j * $multiple]
			.c.test.rule create line $xpos [expr $i * 30.0 / [expr $depth + 1] + 20] $xpos 50 -fill blue
		}
		set multiple [expr $multiple / 2.0]
	}
}

proc addmeasures {} {
	
}

proc drawkeys {} { 
	global cheight
	global cwidth
	set multiple [expr $cheight / 128.0]
	font create Kbfont -family Helvetica -size "-10"
	for {set i 0} {$i < 128} {incr i} {
		set j [expr $i % 12 ]
		set k [expr $i / 12 - 2 ]
		switch $j {
			0 - 
			5 {.c.test.kb create line 0 [expr $cheight - $i * $multiple] 50 [expr $cheight - $i * $multiple] -fill purple}
			1 -
			3 -
			6 -
			8 -
			10 {.c.test.kb create rectangle 0 [expr $cheight - ($i + 1) * $multiple] 49 [expr $cheight - $i * $multiple] -fill grey}
			default {}
		}
		#[lindex {C C D D E F F G G A A B} $j]
		.c.test.kb create text 25 [expr $cheight - $i * $multiple - $multiple / 2.0] -font Kbfont -text "[lindex {C C# D D# E F F# G G# A A# B} $j]$k"
		.c.test.inframe.canvas create line 0 [expr $i * $multiple] $cwidth [expr $i * $multiple] -fill grey -tags bg -state disabled
	}
}

# scrolling procs
proc scrollh {args} {
	{*}[linsert $args 0 .c.test.inframe.canvas xview]
	{*}[linsert $args 0 .c.test.rule xview]
}

proc scrollv {args} {
	eval [linsert $args 0 .c.test.inframe.canvas yview]
	eval [linsert $args 0 .c.test.kb yview]
}
# mode changing
proc selmode {} {
	global state
	set state 1
	.c.test.inframe.canvas configure -cursor hand1
}

proc editmode {} {
	global state
	set state 0
	.c.test.inframe.canvas itemconfigure selected -fill black
	.c.test.inframe.canvas dtag selected selected
	.c.test.inframe.canvas configure -cursor pencil
}

proc delete_notes {} {
	.c.test.inframe.canvas delete notes
}

proc noteenter {} {
	global state
	if {[checkbits 11 1]} {
		if {[.c.test.inframe.canvas itemcget current -fill] == "black"} {
			set state [setbit 6]
		} else {
			set state [unsetbit 6]
		}
		.c.test.inframe.canvas itemconfigure current -fill purple
		set state [setbit 2]
	}
}

proc noteleave {} {
	global state
	if {[checkbits 11 1]} {
		if {[checkbits 64 64]} {
			.c.test.inframe.canvas itemconfigure current -fill black
		} else {
			.c.test.inframe.canvas itemconfigure current -fill blue
		}
		set state [unsetbit 2]
		.c.test.inframe.canvas configure -cursor hand1
	}	
}

proc bindmotion {id} {
	.c.test.inframe.canvas bind $id <Motion> {notemotion %x}
}

proc notemotion {x} {
	global state
	if {[checkbits 11 1]} {
		set coords [.c.test.inframe.canvas coords current]
		set xpos [.c.test.inframe.canvas canvasx $x]
		set leftside [lindex $coords 0]
		set rightside [lindex $coords 1]
		if {$xpos > [lindex $coords 0] && $xpos < [expr [lindex $coords 0] + 10]} {
			.c.test.inframe.canvas configure -cursor left_side
		} elseif {$xpos > [expr [lindex $coords 2] - 10] && $xpos < [lindex $coords 2]} {
			.c.test.inframe.canvas configure -cursor right_side
		} else {
			.c.test.inframe.canvas configure -cursor hand1
		}
	}
}
			

proc offscroll {x y} {
	set cbounds [viewunits]
	set markx ""
	set marky ""
	set scrollin 0
	if {$x > [lindex $cbounds 0]} {
		set markx [lindex $cbounds 0]
		set scrollin 1
	} elseif {$x < 0} {
		set markx 0
		set scrollin 1
	} else {
		set markx $x
	}
	if {$y > [lindex $cbounds 1]} {
		set marky [lindex $cbounds 1]
		set scrollin 1
	} elseif {$y < 0} {
		set marky 0
		set scrollin 1
	} else {
		set marky $y
	}
	if {$scrollin} {
		.c.test.inframe.canvas scan mark $x $y
		.c.test.kb scan mark 50 $y
		.c.test.rule scan mark $x 50
		.c.test.inframe.canvas scan dragto $markx $marky 1
		.c.test.kb scan dragto 50 $marky 1
		.c.test.rule scan dragto $markx 50 1
	}
}

proc canvasview {} {
    global cwidth
    global cheight
    set xview  [.c.test.inframe.canvas xview]
    set yview  [.c.test.inframe.canvas yview]
    
	set xstart [expr {int([lindex $xview 0] * $cwidth)}]
    set xend   [expr {int([lindex $xview 1] * $cwidth)}]

    set ystart [expr {int([lindex $yview 0] * $cheight)}]
    set yend   [expr {int([lindex $yview 1] * $cheight)}] 
    return [list $xstart $xend $ystart $yend]
}

proc scaley {amnt} {
	global cheight
	global cwidth
	global basecheight
	set amnt [expr $amnt * $basecheight / $cheight]
	set ycoord [.c.test.inframe.canvas yview]
	set ynewdif [expr ([lindex $ycoord 1] - [lindex $ycoord 0]) * (1 - (1.0 / $amnt)) / 2.0]
	set ycoord [expr [lindex $ycoord 0] + $ynewdif]
	.c.test.inframe.canvas scale all 0 0 1.0 $amnt
	.c.test.kb scale all 0 0 1.0 $amnt
	set cheight [expr $amnt * $cheight]
	.c.test.inframe.canvas configure -scrollregion [list 0 0 $cwidth $cheight]
	.c.test.kb configure -scrollregion [list 0 0 50 $cheight]
	scrollv moveto $ycoord
}

proc scalex {amnt} {
	global cwidth
	global cheight
	global basecwidth
	set amnt [expr $amnt * $basecwidth / $cwidth]
	set xcoord [.c.test.inframe.canvas xview]
	set xnewdif [expr ([lindex $xcoord 1] - [lindex $xcoord 0]) * (1 - (1.0 / $amnt)) / 2.0]
	set xcoord [expr [lindex $xcoord 0] + $xnewdif]
	.c.test.inframe.canvas scale all 0 0 $amnt 1.0
	.c.test.rule scale all 0 0 $amnt 1.0
	set cwidth [expr $amnt * $cwidth]
	.c.test.inframe.canvas configure -scrollregion [list 0 0 $cwidth $cheight]
	.c.test.rule configure -scrollregion [list 0 0 $cwidth 50]
	scrollh moveto $xcoord
}

proc viewunits {} {
	global cwidth
	global cheight
	
	set xview [.c.test.inframe.canvas xview]
	set yview [.c.test.inframe.canvas yview]
	
	set xdif [expr {int(([lindex $xview 1] - [lindex $xview 0]) * $cwidth)}]
	set ydif [expr {int(([lindex $yview 1] - [lindex $yview 0]) * $cheight)}]
	
	return [list $xdif $ydif]
}

proc checkbits {i j} {
	global state
	return [expr ($state & $i) == $j]
}

proc setbit {bit} {
	global state
	return [expr ($state | (1 << $bit))]
}

proc unsetbit {bit} {
	global state
	return [expr ($state & ~(1 << $bit))]
}

# setup
proc midedit_setup {} {
	drawrule
	drawkeys
	.c.test.inframe.canvas create rect 0 0 10 10 -fill "" -tags selbox -state hidden
	.c.test.blankh create line 0 25 [.c.test.inframe.v cget -width] 25 -tags zoomline
	.c.test.blankv create line 25 0 25 [.c.test.inframe.h cget -width] -tags zoomline
	editmode
}

# sizegrip binds
bind .c.test.inframe.sz <ButtonPress-1> {
	global prespos
	set prespos [list [expr [.c.test cget -width] - %X] [expr [.c.test cget -height] - %Y]]
	grab set .c.test.inframe.sz
}
	
bind .c.test.inframe.sz <B1-Motion> {
	global prespos 
	.c.test configure -width [expr %X + [lindex $prespos 0]] -height [expr %Y + [lindex $prespos 1]]
}

bind .c.test.inframe.sz <ButtonRelease-1> {
	grab release .c.test.inframe.sz
}

# canvas binds
bind .c.test.inframe.canvas <MouseWheel> { scrollv scroll [expr -{%D}] units }
bind .c.test.inframe.canvas <Shift-MouseWheel> { scrollh scroll [expr - {%D}] units}

bind .c.test.inframe.canvas <ButtonPress-1> {
	global prespos
	global state
	set prespos [list [.c.test.inframe.canvas canvasx %x] [.c.test.inframe.canvas canvasy %y]]
	if {[checkbits 5 5]} {
		.c.test.inframe.canvas addtag primary withtag current
		set coords [.c.test.inframe.canvas coords primary]
		set xpos [lindex $prespos 0]
		if {$xpos > [lindex $coords 0] && $xpos < [expr [lindex $coords 0] + 10]} {
			set state [setbit 4]
			set state [unsetbit 5]
			.c.test.inframe.canvas configure -cursor left_side
		} elseif {$xpos > [expr [lindex $coords 2] - 10] && $xpos < [lindex $coords 2]} {
			set state [setbit 4]
			set state [setbit 5]
			.c.test.inframe.canvas configure -cursor right_side
		} else {
			set xunit [expr $cwidth * $xgrid / $measures]
			.c.test.inframe.canvas configure -cursor hand1
			# so dragging starts in between the prespos-based grid (not on) :
			set prespos [lreplace $prespos 0 0 [expr [lindex $prespos 0] - $xunit / 2.0]]
			
		}
		if {[lsearch [.c.test.inframe.canvas gettags primary] selected] == -1} {
			set lst [.c.test.inframe.canvas find withtag selected]
			.c.test.inframe.canvas itemconfigure selected -fill black
			.c.test.inframe.canvas dtag selected selected
		}
		.c.test.inframe.canvas itemconfigure current -fill blue
		.c.test.inframe.canvas addtag selected withtag current
		.c.test.inframe.canvas raise selected notes
		set state [setbit 3]
	}
}


bind .c.test.inframe.canvas <B1-Motion> {
	global prespos
	global curpos
	global state
	global measures
	global xgrid
	global cwidth
	global cheight
	set curpos [list %x %y]
	if {[checkbits 2 0]} {
		if {[checkbits 1 1]} {
			#begin selection box
			if {[checkbits 8 0]} {
				.c.test.inframe.canvas itemconfigure selbox -state normal
			}
		} else {
			set xunit [expr $cwidth * $xgrid / $measures]
			set xpos [lindex $prespos 0]
			set ypos [lindex $prespos 1]
			set yunit [expr $cheight / 128.0]
			if {$ygrid} {
				set ypos [expr $ypos - fmod($ypos, $yunit)]
			} else {
				set ypos [expr $ypos - [expr $yunit / 2]]
			}
			if {$xunit != 0} {
				set xpos [expr $xpos - fmod($xpos, $xunit)]
			}
			set id [.c.test.inframe.canvas create rect $xpos $ypos $xpos [expr $ypos + $yunit] -fill black -outline white -tags "notes primary"]
			# how do I get a literal %x into the arguments? I don't know what I'm doing
			bindmotion $id
			.c.test.inframe.canvas bind $id <Leave> {noteleave}
			.c.test.inframe.canvas bind $id <Enter> {noteenter}
			.c.test.inframe.canvas lower $id selbox
		}
		# somthing is being dragged
		set state [setbit 1]
		
	}
	if {[checkbits 1 1]} {
		if {[checkbits 8 8]} {
			if {[checkbits 16 16]} {
				set xunit [expr $cwidth * $xgrid / $measures]
				set xpos [.c.test.inframe.canvas canvasx %x]
				if {$xunit != 0} {
					set xpos [expr $xpos - fmod($xpos, $xunit)]
				}
				if {[checkbits 32 32]} {
					# set is to the right, unset to the left
					
					set notedifx [expr $xpos + $xunit - [lindex [.c.test.inframe.canvas coords primary] 2]]
					foreach c [.c.test.inframe.canvas find withtag selected] {
						set xpos [expr max([lindex [.c.test.inframe.canvas coords $c] 2] + $notedifx, [lindex [.c.test.inframe.canvas coords $c] 0] + $xunit)]
						.c.test.inframe.canvas coords $c [lreplace [.c.test.inframe.canvas coords $c] 2 2 $xpos]
					}
				} else {
					set notedifx [expr $xpos - [lindex [.c.test.inframe.canvas coords primary] 0]]
					
					foreach c [.c.test.inframe.canvas find withtag selected] {
						set xpos [expr min([lindex [.c.test.inframe.canvas coords $c] 0] + $notedifx, [lindex [.c.test.inframe.canvas coords $c] 2] - $xunit)]
						.c.test.inframe.canvas coords $c [lreplace [.c.test.inframe.canvas coords $c] 0 0 $xpos]
					}
				}
			} else {
				#move selected notes
				set xunit [expr $cwidth * $xgrid / $measures]
				set xpos [expr [.c.test.inframe.canvas canvasx %x] - [lindex $prespos 0]]
				set ypos [expr [.c.test.inframe.canvas canvasy %y] - [lindex $prespos 1]]
				set yunit [expr $cheight / 128.0]
				if {$ygrid} {
					set ypos [expr $ypos + $yunit / 2]
					if {$ypos < 0} {
						set ypos [expr $ypos - $yunit - fmod($ypos, $yunit)]
					} else {
						set ypos [expr $ypos - fmod($ypos, $yunit)]
					}
				}
				if {$xunit != 0} {
					if {$xpos < 0} {
						set xpos [expr $xpos - $xunit - fmod($xpos, $xunit)]
					} else {
						set xpos [expr $xpos - fmod($xpos, $xunit)]
					}
				}
				if {$xpos != [lindex $prespos 0]} {
					set prespos [lreplace $prespos 0 0 [expr $xpos + [lindex $prespos 0]]]
				}
				if {$ypos != [lindex $prespos 1]} {
					set prespos [lreplace $prespos 1 1 [expr $ypos + [lindex $prespos 1]]]
				}
				.c.test.inframe.canvas move selected $xpos $ypos
			}
		} else {
			#move selection box
			.c.test.inframe.canvas coords selbox [concat $prespos [.c.test.inframe.canvas canvasx %x] [.c.test.inframe.canvas canvasy %y]]
			# this is stupid: having to add the tags then remove the background
			# lines and selection box from the selection
			.c.test.inframe.canvas itemconfigure selected -fill black	
			.c.test.inframe.canvas dtag all selected
			.c.test.inframe.canvas addtag selected overlapping {*}[.c.test.inframe.canvas coords selbox]
			.c.test.inframe.canvas dtag bg selected
			.c.test.inframe.canvas dtag selbox selected
			.c.test.inframe.canvas itemconfigure selected -fill blue
		}
	} else {
		# keep drawing the note
		set xunit [expr $cwidth * $xgrid / $measures]
		set xpos [.c.test.inframe.canvas canvasx %x]
		if {$xunit != 0} {
			set xpos [expr $xpos + $xunit - fmod($xpos, $xunit)]
		}
		set xpos [expr max($xpos, [lindex [.c.test.inframe.canvas coords primary] 0] + $xunit)]
		.c.test.inframe.canvas coords primary [lreplace [.c.test.inframe.canvas coords primary] 2 2 $xpos]
	}
}

bind .c.test.inframe.canvas <ButtonRelease-1> {
	global state
	global nlength
	global cwidth
	global cheight
	global noteslct
	if {[checkbits 1 1]} {
		if {[checkbits 2 2]} {
			if {[checkbits 8 8]} {
				set state 1
				set coords [.c.test.inframe.canvas coords primary]
				if {%x > [lindex $coords 0] && %x < [lindex $coords 2] && %y > [lindex $coords 1] && %y < [lindex $coords 3]} {
					.c.test.inframe.canvas dtag primary primary
					noteenter
				} else {
					noteleave
					.c.test.inframe.canvas dtag primary primary
				}
			} else {
				.c.test.inframe.canvas itemconfigure selbox -state hidden
				set state 1
			}
		} else {
			if {[checkbits 8 8]} {
				set state 1
				set coords [.c.test.inframe.canvas coords primary]
				if {%x > [lindex $coords 0] && %x < [lindex $coords 2] && %y > [lindex $coords 1] && %y < [lindex $coords 3]} {
					.c.test.inframe.canvas dtag primary primary
					noteenter
				} else {
					noteleave
					.c.test.inframe.canvas dtag primary primary
				}
			} else {
				.c.test.inframe.canvas itemconfigure selected -fill black
				.c.test.inframe.canvas dtag selected selected
				set state 1
			}
		}
	} else {
		if {[checkbits 2 2]} {
			.c.test.inframe.canvas dtag primary primary
			set state 0
		} else {
			set xpos [lindex $prespos 0]
			set notelength [expr $cwidth * $nlength / $measures]
			set xunit [expr $cwidth * $xgrid / $measures]
			if {$xunit != 0} {
				set notestart [expr $xpos - fmod($xpos, $xunit)]
			} else {
				set notestart $xpos
			}
			set ypos [lindex $prespos 1]
			set yunit [expr $cheight / 128.0]
			if {$ygrid} {
				set ypos [expr $ypos - fmod($ypos, $yunit)]
			} else {
				set ypos [expr $ypos - [expr $yunit / 2]]
			}
			set id [.c.test.inframe.canvas create rect $notestart $ypos [expr $notestart + $notelength] [expr $ypos + $yunit] -fill black -outline white -tags notes]
			bindmotion $id
			.c.test.inframe.canvas bind $id <Leave> {noteleave}
			.c.test.inframe.canvas bind $id <Enter> {noteenter}
			.c.test.inframe.canvas lower $id selbox
			set state 0
		}
	}
}

bind .c.test.inframe.canvas <BackSpace> {
	.c.test.inframe.canvas delete selected

}

bind .c.test.inframe.canvas <Delete> {
	bind .c.test.inframe.canvas <BackSpace>
}

# callbacks? for offscreen scrolling

bind .c.test.inframe.canvas <Leave> {
	global curpos
	if {[checkbits 2 2]} {
		offscroll {*}$curpos
		after 50 {event generate .c.test.inframe.canvas <Leave>}
	}
}

bind .c.test.inframe.canvas <Enter> {
	if {[checkbits 2 2]} {
		after cancel {event generate .c.test.inframe.canvas <Leave>}
	}
	focus .c.test.inframe.canvas
}

midedit_setup

bind .c.test.blankh <B1-Motion> {
	zoomy %y
}
bind .c.test.blankh <ButtonPress> {
	zoomy %y
}

bind .c.test.blankv <B1-Motion> {
	zoomx %x
}
bind .c.test.blankv <ButtonPress> {
	zoomx %x
}

proc zoomy {y} {
	if {$y > 50} {
		set y 50
	} elseif { $y < 0 } {
		set y 0
	}
	scaley [expr $y / 50.0 * 2 + 0.5]
	.c.test.blankh coords zoomline 0 $y [.c.test.inframe.v cget -width] $y
}

proc zoomx {x} {
	if {$x > 50} {
		set x 50
	} elseif { $x < 0 } {
		set x 0
	}
	scalex [expr (50 - $x) / 50.0 * 2 + 0.5]
	.c.test.blankv coords zoomline $x 0 $x [.c.test.inframe.h cget -width]
}