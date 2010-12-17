# alignDBGUI_ui.pm --
#
# UI generated by GUI Builder Build 219949 on 2006-09-23 22:34:37 from:
#    E:/wq/Scripts/alignDB/gui/alignDBGUI.ui
# THIS IS AN AUTOGENERATED FILE AND SHOULD NOT BE EDITED.
# The associated callback file should be modified instead.
#

# Declare the package for this dialog
package alignDBGUI;

use vars qw( $server $port $username $password $target_taxon_id $target_name $query_taxon_id $query_name $db $axt_dir $realign $insert_gc $insert_dG $insert_segment $axt_threshold $process_align $process_indel $process_isw $process_snp $process_window $ensembl_db $stat_file $run $sum_threshold $graph_file $graph_ensembl_db $parallel );
use Tk;
use Tk::Menu;

# alignDBGUI::ui --
#
# ARGS:
#   root     the parent window for this form
#
sub alignDBGUI::ui {
    our($root) = @_;


    # Widget Initialization
    our($_labelframe_db) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Database",
    );
    our($_labelframe_init) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Initiation",
    );
    our($_labelframe_dir) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Generation",
    );
    our($_labelframe_anno) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Annotation",
    );
    our($_labelframe_slippage) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Indel Slippage",
    );
    our($_labelframe_stat) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Statistics",
    );
    our($_labelframe_graph) = $root->Labelframe(
	-font => 'Tahoma 10',
	-text => "Graphics",
    );
    our($_label_title) = $root->Label(
	-activeforeground => "#009900",
	-font => 'Tahoma 10 bold',
	-foreground => "#009900",
	-relief => "ridge",
	-text => "alignDB GUI",
    );
    our($_label_server) = $root->Label(
	-font => 'Tahoma 10',
	-text => "server:",
    );
    our($_entry_server) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-takefocus => 0,
	-textvariable => \$server,
	-width => 15,
    );
    our($_label_port) = $root->Label(
	-font => 'Tahoma 10',
	-text => "port:",
    );
    our($_entry_port) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-takefocus => 0,
	-textvariable => \$port,
	-width => 4,
    );
    our($_label_username) = $root->Label(
	-font => 'Tahoma 10',
	-text => "username:",
    );
    our($_entry_username) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-takefocus => 0,
	-textvariable => \$username,
	-width => 8,
    );
    our($_label_password) = $root->Label(
	-font => 'Tahoma 10',
	-text => "password:",
    );
    our($_entry_password) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-takefocus => 0,
	-textvariable => \$password,
	-width => 8,
    );
    our($_label_target_taxon_id) = $root->Label(
	-font => 'Tahoma 10',
	-text => "target id:",
    );
    our($_entry_target_taxon_id) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$target_taxon_id,
	-width => 8,
    );
    our($_label_target_name) = $root->Label(
	-font => 'Tahoma 10',
	-text => "name:",
    );
    our($_entry_target_name) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$target_name,
	-width => 8,
    );
    our($_button_load_target) = $root->Button(
	-borderwidth => 0,
	-font => 'Tahoma 8',
	-relief => "flat",
	-takefocus => 0,
	-text => " ",
    );
    our($_label_query_taxon_id) = $root->Label(
	-font => 'Tahoma 10',
	-text => "query id:",
    );
    our($_entry_query_taxon_id) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$query_taxon_id,
	-width => 8,
    );
    our($_label_query_name) = $root->Label(
	-font => 'Tahoma 10',
	-text => "name:",
    );
    our($_entry_query_name) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$query_name,
	-width => 8,
    );
    our($_button_load_query) = $root->Button(
	-borderwidth => 0,
	-font => 'Tahoma 8',
	-relief => "flat",
	-takefocus => 0,
	-text => " ",
    );
    our($_label_db) = $root->Label(
	-font => 'Tahoma 10',
	-text => "db name:",
    );
    our($_entry_db_name) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$db,
	-width => 18,
    );
    our($_button_auto_db_name) = $root->Button(
	-borderwidth => 0,
	-font => 'Tahoma 8',
	-relief => "flat",
	-takefocus => 0,
	-text => " ",
    );
    our($_button_init_alignDB) = $root->Button(
	-activeforeground => "#000099",
	-font => 'Tahoma 9 bold',
	-text => "Init. alignDB",
	-width => 12,
    );
    our($_label_axt_dir) = $root->Label(
	-font => 'Tahoma 10',
	-text => ".axt dir:",
    );
    our($_entry_axt_dir) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$axt_dir,
	-width => 18,
    );
    our($_button_open_axt_dir) = $root->Button(
	-borderwidth => 0,
	-font => 'Tahoma 8',
	-relief => "flat",
	-takefocus => 0,
	-text => " ",
    );
    our($_checkbutton_realign) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "realign",
	-variable => \$realign,
    );
    our($_checkbutton_insert_gc) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "GC",
	-variable => \$insert_gc,
    );
    our($_checkbutton_insert_dG) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "dG",
	-variable => \$insert_dG,
    );
    our($_checkbutton_insert_segment) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "seg.",
	-variable => \$insert_segment,
    );
    our($_label_threshold) = $root->Label(
	-font => 'Tahoma 10',
	-text => "threshold:",
    );
    our($_entry_axt_threshold) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$axt_threshold,
	-width => 10,
    );
    our($_button_gen_alignDB) = $root->Button(
	-activeforeground => "#000099",
	-font => 'Tahoma 9 bold',
	-text => "Gen. alignDB",
	-width => 12,
    );
    our($_checkbutton_process_align) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "align",
	-variable => \$process_align,
	-width => 4,
    );
    our($_checkbutton_process_indel) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "indel",
	-variable => \$process_indel,
	-width => 4,
    );
    our($_checkbutton_process_isw) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "isw",
	-variable => \$process_isw,
	-width => 2,
    );
    our($_checkbutton_process_snp) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "snp",
	-variable => \$process_snp,
	-width => 2,
    );
    our($_checkbutton_process_window) = $root->Checkbutton(
	-font => 'Tahoma 10',
	-takefocus => 0,
	-text => "window",
	-variable => \$process_window,
	-width => 6,
    );
    our($_label_ensembl) = $root->Label(
	-font => 'Tahoma 10',
	-text => "ensembl:",
    );
    our($_entry_ensembl) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$ensembl_db,
	-width => 10,
    );
    our($_button_update_feature) = $root->Button(
	-activeforeground => "#000099",
	-font => 'Tahoma 9 bold',
	-text => "Upd. feature",
	-width => 12,
    );
    our($_button_update_indel_slippage) = $root->Button(
	-activeforeground => "#000099",
	-font => 'Tahoma 9 bold',
	-text => "Upd. slippage",
	-width => 12,
    );
    our($_label_stat_file) = $root->Label(
	-font => 'Tahoma 10',
	-text => "stat file:",
    );
    our($_entry_stat_file) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$stat_file,
    );
    our($_button_auto_stat_name) = $root->Button(
	-borderwidth => 0,
	-font => 'Tahoma 8',
	-relief => "flat",
	-takefocus => 0,
	-text => " ",
    );
    our($_label_run) = $root->Label(
	-font => 'Tahoma 10',
	-text => "run:",
    );
    our($_entry_run) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$run,
    );
    our($_label_sum_threshold) = $root->Label(
	-font => 'Tahoma 10',
	-text => "threshold:",
    );
    our($_entry_sum_threshold) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$sum_threshold,
	-width => 10,
    );
    our($_button_gene_stat_file) = $root->Button(
	-activeforeground => "#000099",
	-font => 'Tahoma 9 bold',
	-text => "Gene. stat",
	-width => 12,
    );
    our($_label_graph_file) = $root->Label(
	-font => 'Tahoma 10',
	-text => "graph file:",
    );
    our($_entry_graph_file) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-relief => "solid",
	-textvariable => \$graph_file,
    );
    our($_button_auto_graph_name) = $root->Button(
	-borderwidth => 0,
	-font => 'Tahoma 8',
	-relief => "flat",
	-takefocus => 0,
	-text => " ",
    );
    our($_label_graph_ensembl) = $root->Label(
	-font => 'Tahoma 10',
	-text => "ensembl:",
    );
    our($_entry_graph_ensembl) = $root->Entry(
	-background => "#cccccc",
	-borderwidth => 0,
	-font => '{Courier New} 10',
	-foreground => "#000000",
	-relief => "solid",
	-textvariable => \$graph_ensembl_db,
	-width => 10,
    );
    our($_button_gene_graph_file) = $root->Button(
	-activeforeground => "#000099",
	-font => 'Tahoma 9 bold',
	-text => "Gene. graph",
	-width => 12,
    );
    our($_button_about) = $root->Button(
	-font => 'Tahoma 8',
	-relief => "ridge",
	-takefocus => 0,
	-text => " ",
    );
    our($_entry_parallel) = $root->Entry(
	-background => "#cccccc",
	-font => '{Courier New} 10',
	-relief => "flat",
	-textvariable => \$parallel,
	-width => 0,
    );
    our($_label_parallel) = $root->Label(
	-font => 'Tahoma 10',
	-text => "par.:",
    );

    # widget commands

    $_entry_server->configure(
	-invalidcommand => \&_entry_server_invalidcommand
    );
    $_entry_server->configure(
	-validatecommand => \&_entry_server_validatecommand
    );
    $_entry_server->configure(
	-xscrollcommand => \&_entry_server_xscrollcommand
    );
    $_entry_port->configure(
	-invalidcommand => \&_entry_port_invalidcommand
    );
    $_entry_port->configure(
	-validatecommand => \&_entry_port_validatecommand
    );
    $_entry_port->configure(
	-xscrollcommand => \&_entry_port_xscrollcommand
    );
    $_entry_username->configure(
	-invalidcommand => \&_entry_username_invalidcommand
    );
    $_entry_username->configure(
	-validatecommand => \&_entry_username_validatecommand
    );
    $_entry_username->configure(
	-xscrollcommand => \&_entry_username_xscrollcommand
    );
    $_entry_password->configure(
	-invalidcommand => \&_entry_password_invalidcommand
    );
    $_entry_password->configure(
	-validatecommand => \&_entry_password_validatecommand
    );
    $_entry_password->configure(
	-xscrollcommand => \&_entry_password_xscrollcommand
    );
    $_entry_target_taxon_id->configure(
	-invalidcommand => \&_entry_target_taxon_id_invalidcommand
    );
    $_entry_target_taxon_id->configure(
	-validatecommand => \&_entry_target_taxon_id_validatecommand
    );
    $_entry_target_taxon_id->configure(
	-xscrollcommand => \&_entry_target_taxon_id_xscrollcommand
    );
    $_entry_target_name->configure(
	-invalidcommand => \&_entry_target_name_invalidcommand
    );
    $_entry_target_name->configure(
	-validatecommand => \&_entry_target_name_validatecommand
    );
    $_entry_target_name->configure(
	-xscrollcommand => \&_entry_target_name_xscrollcommand
    );
    $_button_load_target->configure(
	-command => \&_button_load_target_command
    );
    $_entry_query_taxon_id->configure(
	-invalidcommand => \&_entry_query_taxon_id_invalidcommand
    );
    $_entry_query_taxon_id->configure(
	-validatecommand => \&_entry_query_taxon_id_validatecommand
    );
    $_entry_query_taxon_id->configure(
	-xscrollcommand => \&_entry_query_taxon_id_xscrollcommand
    );
    $_entry_query_name->configure(
	-invalidcommand => \&_entry_query_name_invalidcommand
    );
    $_entry_query_name->configure(
	-validatecommand => \&_entry_query_name_validatecommand
    );
    $_entry_query_name->configure(
	-xscrollcommand => \&_entry_query_name_xscrollcommand
    );
    $_button_load_query->configure(
	-command => \&_button_load_query_command
    );
    $_entry_db_name->configure(
	-invalidcommand => \&_entry_db_name_invalidcommand
    );
    $_entry_db_name->configure(
	-validatecommand => \&_entry_db_name_validatecommand
    );
    $_entry_db_name->configure(
	-xscrollcommand => \&_entry_db_name_xscrollcommand
    );
    $_button_auto_db_name->configure(
	-command => sub {$db = "$target_name" . "vs" . "$query_name"}
    );
    $_button_init_alignDB->configure(
	-command => \&_button_init_alignDB_command
    );
    $_entry_axt_dir->configure(
	-invalidcommand => \&_entry_axt_dir_invalidcommand
    );
    $_entry_axt_dir->configure(
	-validatecommand => \&_entry_axt_dir_validatecommand
    );
    $_entry_axt_dir->configure(
	-xscrollcommand => \&_entry_axt_dir_xscrollcommand
    );
    $_button_open_axt_dir->configure(
	-command => \&_button_open_axt_dir_command
    );
    $_checkbutton_realign->configure(
	-command => \&_checkbutton_realign_command
    );
    $_checkbutton_insert_gc->configure(
	-command => \&_checkbutton_insert_gc_command
    );
    $_checkbutton_insert_dG->configure(
	-command => \&_checkbutton_insert_dG_command
    );
    $_checkbutton_insert_segment->configure(
	-command => \&_checkbutton_insert_segment_command
    );
    $_entry_axt_threshold->configure(
	-invalidcommand => \&_entry_axt_threshold_invalidcommand
    );
    $_entry_axt_threshold->configure(
	-validatecommand => \&_entry_axt_threshold_validatecommand
    );
    $_entry_axt_threshold->configure(
	-xscrollcommand => \&_entry_axt_threshold_xscrollcommand
    );
    $_button_gen_alignDB->configure(
	-command => \&_button_gen_alignDB_command
    );
    $_checkbutton_process_align->configure(
	-command => \&_checkbutton_process_align_command
    );
    $_checkbutton_process_indel->configure(
	-command => \&_checkbutton_process_indel_command
    );
    $_checkbutton_process_isw->configure(
	-command => \&_checkbutton_process_isw_command
    );
    $_checkbutton_process_snp->configure(
	-command => \&_checkbutton_process_snp_command
    );
    $_checkbutton_process_window->configure(
	-command => \&_checkbutton_process_window_command
    );
    $_entry_ensembl->configure(
	-invalidcommand => \&_entry_ensembl_invalidcommand
    );
    $_entry_ensembl->configure(
	-validatecommand => \&_entry_ensembl_validatecommand
    );
    $_entry_ensembl->configure(
	-xscrollcommand => \&_entry_ensembl_xscrollcommand
    );
    $_button_update_feature->configure(
	-command => \&_button_update_feature_command
    );
    $_button_update_indel_slippage->configure(
	-command => \&_button_update_indel_slippage_command
    );
    $_entry_stat_file->configure(
	-invalidcommand => \&_entry_stat_file_invalidcommand
    );
    $_entry_stat_file->configure(
	-validatecommand => \&_entry_stat_file_validatecommand
    );
    $_entry_stat_file->configure(
	-xscrollcommand => \&_entry_stat_file_xscrollcommand
    );
    $_button_auto_stat_name->configure(
	-command => sub { $stat_file = "$RealBin/../$db.auto.xls" }
    );
    $_entry_run->configure(
	-invalidcommand => \&_entry_run_invalidcommand
    );
    $_entry_run->configure(
	-validatecommand => \&_entry_run_validatecommand
    );
    $_entry_run->configure(
	-xscrollcommand => \&_entry_run_xscrollcommand
    );
    $_entry_sum_threshold->configure(
	-invalidcommand => \&_entry_sum_threshold_invalidcommand
    );
    $_entry_sum_threshold->configure(
	-validatecommand => \&_entry_sum_threshold_validatecommand
    );
    $_entry_sum_threshold->configure(
	-xscrollcommand => \&_entry_sum_threshold_xscrollcommand
    );
    $_button_gene_stat_file->configure(
	-command => \&_button_gene_stat_file_command
    );
    $_entry_graph_file->configure(
	-invalidcommand => \&_entry_graph_file_invalidcommand
    );
    $_entry_graph_file->configure(
	-validatecommand => \&_entry_graph_file_validatecommand
    );
    $_entry_graph_file->configure(
	-xscrollcommand => \&_entry_graph_file_xscrollcommand
    );
    $_button_auto_graph_name->configure(
	-command => sub { $graph_file = "$RealBin/../$db.png" }
    );
    $_entry_graph_ensembl->configure(
	-invalidcommand => \&_entry_graph_ensembl_invalidcommand
    );
    $_entry_graph_ensembl->configure(
	-validatecommand => \&_entry_graph_ensembl_validatecommand
    );
    $_entry_graph_ensembl->configure(
	-xscrollcommand => \&_entry_graph_ensembl_xscrollcommand
    );
    $_button_gene_graph_file->configure(
	-command => \&_button_gene_graph_file_command
    );
    $_button_about->configure(
	-command => \&_button_about_command
    );
    $_entry_parallel->configure(
	-invalidcommand => \&_entry_parallel_invalidcommand
    );
    $_entry_parallel->configure(
	-validatecommand => \&_entry_parallel_validatecommand
    );
    $_entry_parallel->configure(
	-xscrollcommand => \&_entry_parallel_xscrollcommand
    );


    # Geometry Management
    $_labelframe_db->grid(
	-in     => $root,
	-column => 1,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "news"
    );
    $_labelframe_init->grid(
	-in     => $root,
	-column => 1,
	-row    => 3,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 2,
	-sticky => "news"
    );
    $_labelframe_dir->grid(
	-in     => $root,
	-column => 1,
	-row    => 5,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 2,
	-sticky => "news"
    );
    $_labelframe_anno->grid(
	-in     => $root,
	-column => 2,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "news"
    );
    $_labelframe_slippage->grid(
	-in     => $root,
	-column => 2,
	-row    => 3,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "news"
    );
    $_labelframe_stat->grid(
	-in     => $root,
	-column => 2,
	-row    => 4,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 2,
	-sticky => "news"
    );
    $_labelframe_graph->grid(
	-in     => $root,
	-column => 2,
	-row    => 6,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "news"
    );
    $_label_title->grid(
	-in     => $root,
	-column => 1,
	-row    => 1,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "nsew"
    );
    $_label_server->grid(
	-in     => $_labelframe_db,
	-column => 1,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_server->grid(
	-in     => $_labelframe_db,
	-column => 2,
	-row    => 1,
	-columnspan => 3,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_label_port->grid(
	-in     => $_labelframe_db,
	-column => 5,
	-row    => 1,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_port->grid(
	-in     => $_labelframe_db,
	-column => 7,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_username->grid(
	-in     => $_labelframe_db,
	-column => 1,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_username->grid(
	-in     => $_labelframe_db,
	-column => 3,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_password->grid(
	-in     => $_labelframe_db,
	-column => 4,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_password->grid(
	-in     => $_labelframe_db,
	-column => 6,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_target_taxon_id->grid(
	-in     => $_labelframe_init,
	-column => 1,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_target_taxon_id->grid(
	-in     => $_labelframe_init,
	-column => 2,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_target_name->grid(
	-in     => $_labelframe_init,
	-column => 3,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_target_name->grid(
	-in     => $_labelframe_init,
	-column => 4,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_button_load_target->grid(
	-in     => $_labelframe_init,
	-column => 5,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_query_taxon_id->grid(
	-in     => $_labelframe_init,
	-column => 1,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_query_taxon_id->grid(
	-in     => $_labelframe_init,
	-column => 2,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_query_name->grid(
	-in     => $_labelframe_init,
	-column => 3,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_query_name->grid(
	-in     => $_labelframe_init,
	-column => 4,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_button_load_query->grid(
	-in     => $_labelframe_init,
	-column => 5,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_db->grid(
	-in     => $_labelframe_init,
	-column => 1,
	-row    => 3,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_db_name->grid(
	-in     => $_labelframe_init,
	-column => 2,
	-row    => 3,
	-columnspan => 3,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_button_auto_db_name->grid(
	-in     => $_labelframe_init,
	-column => 5,
	-row    => 3,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_button_init_alignDB->grid(
	-in     => $_labelframe_init,
	-column => 1,
	-row    => 4,
	-columnspan => 5,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_axt_dir->grid(
	-in     => $_labelframe_dir,
	-column => 1,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_axt_dir->grid(
	-in     => $_labelframe_dir,
	-column => 2,
	-row    => 1,
	-columnspan => 4,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_button_open_axt_dir->grid(
	-in     => $_labelframe_dir,
	-column => 6,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_checkbutton_realign->grid(
	-in     => $_labelframe_dir,
	-column => 1,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_insert_gc->grid(
	-in     => $_labelframe_dir,
	-column => 2,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_insert_dG->grid(
	-in     => $_labelframe_dir,
	-column => 3,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_insert_segment->grid(
	-in     => $_labelframe_dir,
	-column => 4,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_label_threshold->grid(
	-in     => $_labelframe_dir,
	-column => 1,
	-row    => 3,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_axt_threshold->grid(
	-in     => $_labelframe_dir,
	-column => 2,
	-row    => 3,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_button_gen_alignDB->grid(
	-in     => $_labelframe_dir,
	-column => 4,
	-row    => 3,
	-columnspan => 3,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_checkbutton_process_align->grid(
	-in     => $_labelframe_anno,
	-column => 1,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_process_indel->grid(
	-in     => $_labelframe_anno,
	-column => 2,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_process_isw->grid(
	-in     => $_labelframe_anno,
	-column => 3,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_process_snp->grid(
	-in     => $_labelframe_anno,
	-column => 4,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_checkbutton_process_window->grid(
	-in     => $_labelframe_anno,
	-column => 5,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_label_ensembl->grid(
	-in     => $_labelframe_anno,
	-column => 1,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_ensembl->grid(
	-in     => $_labelframe_anno,
	-column => 2,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_button_update_feature->grid(
	-in     => $_labelframe_anno,
	-column => 4,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_button_update_indel_slippage->grid(
	-in     => $_labelframe_slippage,
	-column => 1,
	-row    => 1,
	-columnspan => 3,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_stat_file->grid(
	-in     => $_labelframe_stat,
	-column => 1,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_stat_file->grid(
	-in     => $_labelframe_stat,
	-column => 2,
	-row    => 1,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_button_auto_stat_name->grid(
	-in     => $_labelframe_stat,
	-column => 4,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_run->grid(
	-in     => $_labelframe_stat,
	-column => 1,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_run->grid(
	-in     => $_labelframe_stat,
	-column => 2,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_sum_threshold->grid(
	-in     => $_labelframe_stat,
	-column => 1,
	-row    => 3,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_sum_threshold->grid(
	-in     => $_labelframe_stat,
	-column => 2,
	-row    => 3,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_button_gene_stat_file->grid(
	-in     => $_labelframe_stat,
	-column => 3,
	-row    => 3,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_graph_file->grid(
	-in     => $_labelframe_graph,
	-column => 1,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_graph_file->grid(
	-in     => $_labelframe_graph,
	-column => 2,
	-row    => 1,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_button_auto_graph_name->grid(
	-in     => $_labelframe_graph,
	-column => 4,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_label_graph_ensembl->grid(
	-in     => $_labelframe_graph,
	-column => 1,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_entry_graph_ensembl->grid(
	-in     => $_labelframe_graph,
	-column => 2,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "w"
    );
    $_button_gene_graph_file->grid(
	-in     => $_labelframe_graph,
	-column => 3,
	-row    => 2,
	-columnspan => 2,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );
    $_button_about->grid(
	-in     => $root,
	-column => 3,
	-row    => 1,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => ""
    );
    $_entry_parallel->grid(
	-in     => $_labelframe_dir,
	-column => 6,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "ew"
    );
    $_label_parallel->grid(
	-in     => $_labelframe_dir,
	-column => 5,
	-row    => 2,
	-columnspan => 1,
	-ipadx => 0,
	-ipady => 0,
	-padx => 0,
	-pady => 0,
	-rowspan => 1,
	-sticky => "e"
    );


    # Resize Behavior
    $root->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $root->gridRowconfigure(2, -weight => 0, -minsize => 40, -pad => 0);
    $root->gridRowconfigure(3, -weight => 0, -minsize => 40, -pad => 0);
    $root->gridRowconfigure(4, -weight => 0, -minsize => 12, -pad => 0);
    $root->gridRowconfigure(5, -weight => 0, -minsize => 2, -pad => 0);
    $root->gridRowconfigure(6, -weight => 0, -minsize => 2, -pad => 0);
    $root->gridColumnconfigure(1, -weight => 1, -minsize => 2, -pad => 0);
    $root->gridColumnconfigure(2, -weight => 1, -minsize => 107, -pad => 0);
    $root->gridColumnconfigure(3, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridRowconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridColumnconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridColumnconfigure(2, -weight => 0, -minsize => 12, -pad => 0);
    $_labelframe_db->gridColumnconfigure(3, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridColumnconfigure(4, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridColumnconfigure(5, -weight => 1, -minsize => 7, -pad => 0);
    $_labelframe_db->gridColumnconfigure(6, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_db->gridColumnconfigure(7, -weight => 1, -minsize => 2, -pad => 0);
    $_labelframe_init->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_init->gridRowconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_init->gridRowconfigure(3, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_init->gridRowconfigure(4, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_init->gridColumnconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_init->gridColumnconfigure(2, -weight => 0, -minsize => 40, -pad => 0);
    $_labelframe_init->gridColumnconfigure(3, -weight => 0, -minsize => 40, -pad => 0);
    $_labelframe_init->gridColumnconfigure(4, -weight => 1, -minsize => 2, -pad => 0);
    $_labelframe_init->gridColumnconfigure(5, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridRowconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridRowconfigure(3, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridColumnconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridColumnconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridColumnconfigure(3, -weight => 0, -minsize => 29, -pad => 0);
    $_labelframe_dir->gridColumnconfigure(4, -weight => 1, -minsize => 2, -pad => 0);
    $_labelframe_dir->gridColumnconfigure(5, -weight => 0, -minsize => 41, -pad => 0);
    $_labelframe_dir->gridColumnconfigure(6, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_anno->gridRowconfigure(1, -weight => 0, -minsize => 26, -pad => 0);
    $_labelframe_anno->gridRowconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_anno->gridColumnconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_anno->gridColumnconfigure(2, -weight => 0, -minsize => 12, -pad => 0);
    $_labelframe_anno->gridColumnconfigure(3, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_anno->gridColumnconfigure(4, -weight => 0, -minsize => 21, -pad => 0);
    $_labelframe_anno->gridColumnconfigure(5, -weight => 1, -minsize => 27, -pad => 0);
    $_labelframe_slippage->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_slippage->gridColumnconfigure(1, -weight => 0, -minsize => 34, -pad => 0);
    $_labelframe_slippage->gridColumnconfigure(2, -weight => 1, -minsize => 40, -pad => 0);
    $_labelframe_slippage->gridColumnconfigure(3, -weight => 0, -minsize => 40, -pad => 0);
    $_labelframe_stat->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_stat->gridRowconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_stat->gridRowconfigure(3, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_stat->gridColumnconfigure(1, -weight => 0, -minsize => 40, -pad => 0);
    $_labelframe_stat->gridColumnconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_stat->gridColumnconfigure(3, -weight => 1, -minsize => 4, -pad => 0);
    $_labelframe_stat->gridColumnconfigure(4, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_graph->gridRowconfigure(1, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_graph->gridRowconfigure(2, -weight => 0, -minsize => 2, -pad => 0);
    $_labelframe_graph->gridColumnconfigure(1, -weight => 0, -minsize => 40, -pad => 0);
    $_labelframe_graph->gridColumnconfigure(2, -weight => 0, -minsize => 33, -pad => 0);
    $_labelframe_graph->gridColumnconfigure(3, -weight => 1, -minsize => 2, -pad => 0);
    $_labelframe_graph->gridColumnconfigure(4, -weight => 0, -minsize => 2, -pad => 0);
}

1;
