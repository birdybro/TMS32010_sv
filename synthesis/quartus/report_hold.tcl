set script_dir [file dirname [file normalize [info script]]]
set repository_root [file normalize [file join $script_dir ../..]]
set report_dir [file join $repository_root build quartus]
file mkdir $report_dir

project_open [file join $script_dir tms32010] -revision tms32010
create_timing_netlist
read_sdc
update_timing_netlist
report_timing \
  -hold \
  -npaths 20 \
  -detail full_path \
  -file [file join $report_dir hold_paths.rpt]
delete_timing_netlist
project_close
