# Zoome la vue Space-Time sur l'étendue des barres de tâches (hors ligne de temps verticale).
set r [send xpvm {
  set x1 1e9; set x2 -1e9
  foreach id [$ST_C find all] {
    set c [$ST_C coords $id]
    if {[llength $c] < 4} continue
    if {[string compare [$ST_C type $id] text] == 0} continue
    set ty [$ST_C type $id]
    # ignore les lignes verticales (curseur de temps)
    if {[string compare $ty line] == 0 && [lindex $c 0] == [lindex $c 2]} continue
    foreach {x y} $c { if {$x < $x1} {set x1 $x}; if {$x > $x2} {set x2 $x} }
  }
  set off [expr {[$ST_C canvasx 0]}]
  list $x1 $x2 $off
}]
puts "etendue : $r"
foreach {x1 x2 off} $r break
set a [expr {int($x1 - $off) - 2}]; set b [expr {int($x2 - $off) + 2}]
send xpvm "canvas_handle ST zoom_press $a 40; canvas_handle ST zoom_motion $b 40; canvas_handle ST zoom_release $b 40"
exit
