# -*- Mode: Tcl -*-
#
#             File: menus.tcl
#           Author: Bryan Jurish (moocow@ling.uni-potsdam.de)
# Copyright Policy: GPL
#      Description: tcl/tk interface to wonk<->know board game
#                   menus, etc.


;# ----------------- Menus
;# Menubar
frame .mbar -relief raised -bd 2
menubutton .mbar.game -text Game -underline 0       -menu .mbar.game.menu
menubutton .mbar.options -text Options -underline 0 -menu .mbar.options.menu
menubutton .mbar.help -text Help -underline 0       -menu .mbar.help.menu
pack .mbar.game .mbar.options -side left
pack .mbar.help -side right

;# Menubar submenus
menu .mbar.game.menu ;# game
.mbar.game.menu add command -label "New" -command "PlaceNewGame"
.mbar.game.menu add command -label "Open" -state disabled
.mbar.game.menu add command -label "Save" -state disabled
.mbar.game.menu add command -label "Save As" -state disabled
.mbar.game.menu add separator
.mbar.game.menu add command -label "Exit" -command "destroy ."
menu .mbar.options.menu ;# options
.mbar.options.menu add command -label "Client" -state disabled
.mbar.options.menu add command -label "Server" -state disabled
menu .mbar.help.menu ;# help
.mbar.help.menu add command -label "About" -command ShowAboutDialog

