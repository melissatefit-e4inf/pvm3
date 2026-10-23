# Ouvre la vue Task Output si elle est fermée, et affiche son identifiant de fenêtre.
send xpvm {if {![winfo ismapped .task_output]} {viewSelect task_output {Task Output} views_menu_state_Task_Output TRUE}}
after 1500
puts [send xpvm {winfo id .task_output}]
exit
