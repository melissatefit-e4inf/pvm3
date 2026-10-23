# Usage : wish xpvm_run.tcl <commande> <ntasks>
# Lance la commande avec traçage dans l'XPVM ouvert.
set cmd [lindex $argv 0]; set nt [lindex $argv 1]
send xpvm {set spawn_flags_trace ON}
send xpvm "\$SP.cmd_entry delete 0 end; \$SP.cmd_entry insert 0 {$cmd}"
send xpvm "\$SP.ntasks_entry delete 0 end; \$SP.ntasks_entry insert 0 $nt"
send xpvm {do_spawn fresh}
exit
