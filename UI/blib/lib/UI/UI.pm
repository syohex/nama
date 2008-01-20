package UI;
use 5.008;
use strict;
no strict qw(subs);
use warnings;
our $VERSION = '0.01';
use lib "$ENV{HOME}/build/flow/UI/lib"; 
use lib qw(. ..);
use IO::All;
use Carp;
use Cwd;
use Tk;
use Storable; 
use Getopt::Std;
use Audio::Ecasound;
use Parse::RecDescent;
use Data::YAML::Writer;
use Data::YAML::Reader;

## Definitions ##

# 'our' declaration: all packages in the file will see the following
# variables. 


use constant (REC => 'rec',
			  MON => 'mon',
			  MUTE => 'mute');


our (
	### 
	$ui, # object providing class behavior for graphic/text functions

	@persistent_vars, # a set of variables we save
					  	# as one big config file
	@effects_static_vars,	# the list of which variables to store and retrieve
	@effects_dynamic_vars,		# same for all chain operators
	@global_vars,    # contained in config file
	@config_vars,    # contained in config file
	@status_vars,    # we will dump them for diagnostic use
	%abbreviations, # for replacements in config files

	$globals,		# yaml assignments for @global_vars
					# for appending to config file
	
	$ecasound_globals, #  Command line switches XX check

	$default,		# the default configuration file
					# as distinct from custom file
					# in a project directory, or a 
					# master in .ecmd root.
					
	$oids,			# serialized (YAML) form of @oids

	$raw_to_disk_format,
	$mix_to_disk_format,
	$mixer_out_format,
	
	$mixname, 		# 'mix' for the mixer track display
	$yw,			# yaml writer object
	$yr,			# yaml writer object
	%state_c_ops, 	# intermediate copy for storage/retrieval
	$effects_cache_file, # where we keep info on Ecasound
					# and LADSPA effects, presets, etc.
	
	$ecasound, 		# the name to invoke, but I don't think
					# we invoke by name, that's why i have these
					# libraries

	$grammar, 		# filled by Grammar.pm
	$parser,		# for the objected created by Parse::RecDescent
	%iam_cmd,		# for identifying IAM commands in user input
	@ecmd_commands,# array of commands my functions provide
	%ecmd_commands,# as hash as well
	$wav_dir,	# each project will get a directory here
	                # and one .ecmd directory, also with 
	
					# /wav_dir/project_dir/vocal_1.wav
					# /wav_dir/.flow/project_dir
	$state_store_file,	# filename for storing @persistent_vars
	$chain_setup_file, # Ecasound uses this 

	$tk_input_channels,# this many radiobuttons appear
	                # on the menubutton
	%cfg,        # 'config' information as hash
					# or Config.pm
	%devices, 		# alias to data in %cfg
	%opts,          # command line options (set by command stub)
	%oid_status,    # state information for the chain templates
	$clock_id,		# for the Tk event system
	$use_monitor_version_for_mixdown, # sync mixdown version numbers
	              	# to selected track versions 
	$select_track,	 # the currently active track -- for Text UI
	@format_fields, # data for replies to text commands

	$project,		# Tk types project name here
	$project_name,	# Official project name
	$i, 			# index for incrementing track numbers
	$t,				# index for incrementing track groups
	%state_c,		# data for Track object, except effects
	%state_t,		# data for track groups (takes)
	%take,			# which group a track number belongs to 
	@takes,			# we collect them here
	%alias,			# key: name value: take number
	%chain,


	### for effects

	$cop_id, 		# chain operator id, that how we create, 
					# store, find them, adjust them, and destroy them,
					# per track or per project?
	%cops,			 # chain operators stored here
	%copp,			# their parameters for effect update
	%track_names,	# to know if they are taken
	@effects,		# static effects information (parameters, hints, etc.)
	%effect_i,		# an index
	@ladspa_sorted, # ld
	%effects_ladspa,# an index
	$e,				# the name of the variable holding
					# the Ecasound engine object.
					
	$last_version,  # to know where the next recording should start
	$monitor_version,# which global version we are currently using
	%e_bound,		# for displaying hundreds of effects in groups
	@marks,			# where we want to come back tto
	$unit,			# multiples of seconds or minutes
	$markers_armed, # two states forth the markers
	%old_vol,		# a copy of volume settings, for muting
	$length,		# maximum duration of the recording/playback if known
	$jack_on,		# whether we use device jack_alsa

## for &make_io_lists
#
	@monitor,		# tracks that will playback
	@record,		# tracks thatwill record
	@mute,			# tracks we'll exclude from chain setup
	@all_chains,	# all that will be a part of our setup
	@input_chains,	# we sort them in input chains and output chains
	@output_chains,

	%subst,			# alias, substitutions for the config file
	$tkeca_effects_data,	# original tcl code, actually

	### Widgets
	
	$mw, 			# main window
	$ew, 			# effects window
	$canvas, 		# to lay out the effects window

	# each part of the main window gets its own frame
	# to control the layout better

	$load_frame,
	$add_frame,
	$take_frame,
	$time_frame,
	$clock_frame,
	$oid_frame,
	$track_frame,
	$effect_frame,
	$iam_frame,
	$perl_eval_frame,
	$transport_frame,

	## collected widgets (i may need to destroy them)

	@widget_t, # widgets for displaying track groups (busses!)
	%widget_c, # for chains (tracks)
	%widget_e, # for effects
	@widget_o, # for templates (oids) 
	%widget_o, # 

	@global_version_buttons, # to set the same version for
						  	#	all tracks
	@time_marks,	# how different from @marks?
					# one is widgets one is the data
	$time_step,
	$clock, 		# displays clock
	$setup_length,  # displays runing time

	$project_label,	# project name
	$take_label,	# bus name

	$sn_label,		# project load/save/quit	
	$sn_text,
	$sn_load,
	$sn_load_nostate,
	$sn_new,
	$sn_quit,

	### A separate box for entering IAM (and other) commands
	$iam_label,
	$iam_text,
	$iam_execute,
	$iam_error,

	# add track gui
	#
	$build_track_label,
	$build_track_text,
	$build_track_add,
	$build_track_rec_label,
	$build_track_rec_text,
	$build_track_mon_label,
	$build_track_mon_text,

	$build_new_take,

	# transport controls
	
	$transport_label,
	$transport_setup_and_connect,
	$transport_setup,
	$transport_connect,
	$transport_disconnect,
	$transport_new,
	$transport_start,
	$transport_stop,

	$iam,    # unused
	$old_bg, # initial background color.


	$loopa,  # loopback nodes 
	$loopb,  
	$mixchain, # name of my mix track: 'mix'
	$mixchain_aux, # an extra node due to name conflict

	@oids,	# output templates, are applied to the
			# chains collected previously
			# the results are grouped as
			# input, output and intermediate sections

	%inputs,
	%outputs,
	%post_input,
	%pre_output,

	$ladspa_sample_rate,	# used as LADSPA effect parameter fixed at 44100

	$track_name,	# received from Tk text input form
	$ch_r,			# this too, recording channel assignment
	$ch_m,			# monitoring channel assignment


	%L,	# for effects
	%M,
	$debug,				# debug level flags for diagnostics
	$debug2,			# for subroutine names as execute
	$debug3,			# for reference passing diagnostics
	 					#    where the &see_ref() call is
						#    used
						
	$OUT,				# filehandle for Text mode print
	$commands,	# ref created from commands.plus

	$save_id, # text variable
	$sn_save_text,# text entry widget
	$sn_save,	# button to save settings
	$sn_recall,	# button to recall settings
	$sn_dump,  # button to dump status

);
 


@global_vars = qw(
						$mixname
						$effects_cache_file
						$ladspa_sample_rate
						$state_store_file
						$chain_setup_file
						%alias 			   
						$tk_input_channels
						$use_monitor_version_for_mixdown 
						$unit								);
						
@config_vars = qw(
						%abbreviations
						%devices
						$ecasound_globals
						$mix_to_disk_format
						$raw_to_disk_format
						$mixer_out_format
						$wav_dir 				);
						
						

@persistent_vars = qw(

						$monitor_version
						$last_version 
						%track_names 	
						%state_c 		
						%state_t 		
						%cops 			
						$cop_id 		
						%copp 			
						@all_chains 	
						$i 				
						$t 				
						%take 			
						@takes 			
						%chain 			
						@marks			
						$unit			
						%oid_status		
						%old_vol		
						$jack_on 			);
					 
@effects_static_vars = qw(

						@effects		
						%effect_i	
						%e_bound
						@ladspa_sorted
						%effects_ladspa		 );


@effects_dynamic_vars = qw(

						%state_c_ops
						%cops    
						$cop_id     
						%copp   
						@marks 	
						$unit				);



@status_vars = qw(

						%state_c
						%state_t
						%copp
						%cops
						%post_input
						%pre_output   
						%inputs
						%outputs      );




$debug3 = 0; # qualified routines get local $debug = $debug 3;
$debug2 = 1;
$debug = 1;

## The names of two helper loopback devices:

$loopa = 'loop,111';
$loopb = 'loop,222';

$mixchain = 1; 
$mixchain_aux = 'MixDown'; # used for playing back mixes
                           # when chain 1 is active

$mixname = 'mix';
$unit = 1;
$effects_cache_file = 'effects_cache.storable';
$state_store_file = 'State';
$chain_setup_file = 'project.ecs';
$tk_input_channels = 10;
$use_monitor_version_for_mixdown = 1;
%alias = (1 => 'Mixdown', 2 => 'Tracker');
$ladspa_sample_rate = 44100; # temporary setting
$jack_on = 0;

## Load my modules

use UI::Assign qw(:all);
use UI::Iam;    
use UI::Tkeca_effects; 

print remove_spaces("bulwinkle is a...");
## Class and Object definitions for package 'UI'

our @ISA; # no anscestors
use UI::Object qw(mode);

## The following methods belong to the root class

sub hello {"superclass hello"}

sub new { my $class = shift; return bless {@_}, $class }

use Carp;
sub wav_dir { $wav_dir };  # we agree to hereinafter use &wav_dir
sub config_file { "config.yml" }
sub ecmd_dir { join_path(wav_dir, ".ecmd") }
sub this_wav_dir {$project_name and join_path(wav_dir, $project_name)
								or wav_dir
}
sub project_dir  {$project_name and join_path(ecmd_dir, $project_name)
								or wav_dir

}
#sub this_wav_dir {$project_name and join_path(wav_dir, $project_name) }
#sub project_dir  {$project_name and join_path(ecmd_dir, $project_name) }

sub sc { print join $/, "STATE_C", yaml_out( \%state_c); }
sub status_vars {
	serialize -class => 'UI', -vars => \@status_vars;
}
sub config_vars {
	serialize -class => 'UI', -vars => \@config_vars;
}

sub discard_object {
	shift @_ if (ref $_[0]) =~ /UI/; # discard_object
	@_;
}
sub prepare {  

	local $debug = $debug3;

	$debug2 and print "&prepare\n";

    $yw = Data::YAML::Writer->new;
    $yr = Data::YAML::Reader->new;

	$debug and print ("\%opts\n======\n", yaml_out(\%opts)); ; 

	my $create = $opts{c} ? 1 : 0;

	$ecasound  = $ENV{ECASOUND} ? $ENV{ECASOUND} : q(ecasound);

	## now i should read .ecmdrc
	## should have .ecmd holding files.
	
	## but for me, i am really really happy to read my 
	# internal ones. 
	
	read_config(); # sets $wav_dir
	#print "raw to disk format: $raw_to_disk_format\n";
	#print config_vars(); exit;

	$opts{d} and $wav_dir = $opts{d};

	-d $wav_dir or croak

	("wav_dir: '$wav_dir' not found, invoke using -d option ");


	# TODO
	# Tie mixdown version suffix to global monitor version 

	new_engine();
	#initialize_oids();
	prepare_static_effects_data() unless $opts{e};
	#print "keys effect_i: ", join " ", keys %effect_i;
	#map{ print "i: $_, code: $effect_i{$_}->{code}\n" } keys %effect_i;
	#die "no keys";	
	$debug and print "wav_dir: ", wav_dir(), $/;
	$debug and print "this_wav_dir: ", this_wav_dir(), $/;
	$debug and print "project_dir: ", project_dir() , $/;
	1;	
}

sub eval_iam {
	local $debug = $debug3;
	$debug2 and print "&eval_iam\n";
	my $command = shift;
	$debug and print "iam command: $command\n";
	my $result = $e->eci($command);
	$debug and print "$result\n" unless $command =~ /register/;
	my $errmsg = $e->errmsg();
	# $errmsg and carp("IAM WARN: ",$errmsg), 
	# not needed ecasound prints error on STDOUT
	$e->errmsg('');
	$result;
}
## configuration file

sub global_config{
	my $config = join_path( &ecmd_dir, &config_file );
	-f $config and io($config)->all;
}
sub project_config {
	&project_dir or return;
	my $config = join_path( &project_dir, &config_file );
	-f $config and io($config)->all;
}
sub config { strip_all( &project_config or &global_config or $default) }

sub read_config {
	$debug2 and print "&read_config\n";
	local $debug = $debug3;
	#print &config; exit;
	%cfg = %{  $yr->read(config())  };
	#print yaml_out( $cfg{abbreviations}); exit;
	*subst = \%{ $cfg{abbreviations} }; # alias
#	*devices = \%{ $cfg{devices} }; # alias
	#print yaml_out( \%subst ); exit;
	walk_tree(\%cfg);
	walk_tree(\%cfg); # second pass completes substitutions
	#print yaml_out( \%cfg ); die "HEREEE";
	#print ("doing nothing") if $a eq $b eq $c; exit;
	assign_var( \%cfg, @config_vars); 
	$mixname eq 'mix' or die" bad mixname: $mixname";
	#print "mixname: $mixname\n"; exit;
	#print yaml_out( \%devices ); die "HEREEE";

}
sub walk_tree {
	#$debug2 and print "&walk_tree\n";
	my $ref = shift;
	map { substitute($ref, $_) } 
		grep {$_ ne q(abbreviations)} 
			keys %{ $ref };
}
sub substitute{
	my ($parent, $key)  = @_;
	my $val = $parent->{$key};
	#$debug and print qq(key: $key val: $val\n);
	ref $val and walk_tree($val)
		or map{$parent->{$key} =~ s/$_/$subst{$_}/} keys %subst;
}
## project handling

sub load_project {
	my %h = @_;
	$debug2 and print "&load_project\n";
	$debug and print "\$project: $project name: $h{-name} create: $h{-create}\n";
	return unless $h{-name} or $project;

	# we could be called from Tk with variable $project _or_
	# called with a hash with 'name' and 'create' fields.
	
	my $project = remove_spaces($project); # internal spaces to underscores
	$project_name = $h{-name} ? $h{-name} : $project;
	$h{-create} and 
		print ("Creating directories....\n"),
		map{create_dir($_)} &this_wav_dir, &project_dir;
# =comment 
# 	# OPEN EDITOR TODO
# 	my $new_file = join_path ($ecmd_home, $project_name, $parameters);
# 	open PARAMS, ">$new_file" or carp "couldn't open $new_file for write: $!\n";
# 	print PARAMS $configuration;
# 	close PARAMS;
# 	system "$ENV{EDITOR} $new_file" if $ENV{EDITOR};
# =cut
	read_config();
	initialize_project_data();
	remove_small_wavs(); 
	print "reached here!!!\n";
	retrieve_state( $h{-settings} ? $h{-settings} : $state_store_file) unless $opts{m} ;
	$debug and print "found ", scalar @all_chains, "chains\n";
	add_mix_track(), dig_ruins() unless scalar @all_chains;
	$ui->global_version_buttons();

}
#The mix track will always be track index 1 i.e. $state_c{$n}
# for $n = 1, And take index 1.

sub initialize_project_data {
	$debug2 and print "&initialize_project_data\n";

	return if transport_running();
	$ui->project_label_configure(
		-text => uc $project_name, 
		-background => 'lightyellow',
		); 

	# assign_var($project_init_file, @project_vars);

	$last_version = 0;
	%track_names = ();
	%state_c        = ();   #  chain related state
	%state_t        = ();   # take related state
	%cops        = ();   
	$cop_id           = "A"; # autoincrement
	%copp           = ();    # chain operator parameters, dynamic
	                        # indexed by {$id}->[$param_no]
							# and others
	%old_vol = ();

	%take        = (); # the group a chain belongs to # by chain_id
	%chain       = (); # the chain_id corresponding to a track name
	#%alias      = ();  # a way of naming takes

	@takes       = ();  
	@record		= ();
	@monitor	= ();
	@mute = (); 
	@all_chains  = (); # indices of all chains
	@input_chains = ();
	@output_chains = ();

	$i           = 0;  # chain counter
	$t           = 0;  # take counter

	%widget_c = ();
	@widget_t = ();
	%widget_e = ();
	

	# time related
	
	$markers_armed = 0;
	@marks = ();

	
	# volume settings
	
	%old_vol = ();

	# $is_armed = 0;

$ui->destroy_widgets();

increment_take();  # to 1

$ui->take_gui;

}
## track and wav file handling

sub add_track {
	@_ = discard_object(@_);
	$debug2 and print "&add_track\n";
	return 0 if transport_running();
	my $name = shift;
	if ($track_names{$name}){
		$debug and carp ("Track name in use\n");
		return 0;
	}
	$state_t{$t}->{rw} = "REC"; # enable recording for the group
	$track_names{$name}++;
	$i++; # global variable track counter
	register_track($i, $name, $ch_r, $ch_m);
	find_wavs($i);
	#set_active_version($i) if ! defined $state_c{$i}->{active};
	$track_name = $ch_m = $ch_r = undef;

	$state_c{$i}->{ops} = [] if ! defined $state_c{$i}->{ops};
	$state_c{$i}->{rw} = "REC" if ! defined $state_c{$i}->{rw};
	$ui->track_gui($i);
	$debug and print "Added new track!\n",yaml_out(\%state_c);
}
sub restore_track {
	$debug2 and print "&restore_track\n";
	@_ = discard_object(@_);
	my $n = shift;
	find_wavs($n);
	$ui->track_gui($n), $ui->refresh();
}

sub dig_ruins { 

	# only if there are no tracks , 
	# we exclude the mixchain
	#
	
	$debug2 and print "&dig_ruins";

	if ( ! grep { $_ ne $mixchain and $_ ne $project_name} keys %state_c ) {  # there are no tracks yet

		# look for wave files
		
		my $d = this_wav_dir();
		opendir WAV, $d or carp "couldn't open $d: $!";

		# remove version numbers
		
		my @wavs = grep{s/(_\d+)?\.wav//i} readdir WAV;

		$debug and print "tracks found: @wavs\n";

		map{add_track($_)}@wavs;

	}
}

sub remove_small_wavs {
	$debug2 and print "&remove_small_wavs\n";
	# left by a recording chainsetup that is 
	# connected by not started

	my $a = this_wav_dir();
	my $cmd = qq(find $a  -name '*.wav' -size 44c);
	$debug and print $cmd; 
	my @wavs = split "\n",qx($cmd);
	#map {system qq(ls -l $_ ) } @wavs; exit;
	map { print ($_, "\n") if -s == 44 } @wavs; 
	map { unlink $_ if -s == 44 } @wavs; 
}

sub add_volume_control {
	my $n = shift;
	
	my $vol_id = cop_add({
				chain => $n, 
				type => 'ea',
				cop_id => $state_c{$n}->{vol}, # often undefined
				});
	
	$state_c{$n}->{vol} = $vol_id;  # save the id for next time
}
sub add_pan_control {
	my $n = shift;
	
	my $vol_id = cop_add({
				chain => $n, 
				type => 'epp',
				cop_id => $state_c{$n}->{pan}, # often undefined
				});
	
	$state_c{$n}->{pan} = $vol_id;  # save the id for next time
}
## version functions

sub set_active_version {
	my $n = shift;
	$debug and print "chain $n: versions: @{$state_c{$n}->{versions}}\n";    
		$state_c{$n}->{active} = $state_c{$n}->{versions}->[-1] 
			if $state_c{$n}->{versions};    
		$debug and print "active version, chain $n: $state_c{$n}->{active}\n\n";
}

sub mon_vert {
	my $ver = shift;
	return if $ver == $monitor_version;
	# store @{ $state_c{$ver}{ops} }
	# store %copp
	# remove effects  and use $ver's set if there are effects for $v
	$monitor_version = $ver;
	$ui->refresh();
}
## chain setup generation

sub really_recording {  # returns filename stubs

#	scalar @record  # doesn't include mixdown track
	print join "\n", "", ,"file recorded:", keys %{$outputs{file}}; # includes mixdown
	keys %{$outputs{file}}; # includes mixdown
}

=comment


			# TODO no channel copy for stereo input files
            # such as version 1 backing.wav

			# n.b. no signal multiplier needed with current Ecasound
			
=cut


=comment    

%inputs
  |----->device-->$devname-->[ chain_id, chain_id,... ]
  |----->file---->$filename->[ chain_id, chain_id,... ]
  |----->bus1---->loop_id--->[ chain_id, chain_id,... ]
  |----->cooked-->loop_id--->[ chain_id, chain_id,... ]
  |_____>mixed___>loop_id___>[ chain_id, chain_id,... ]

%outputs
  |----->device-->$devname-->[ chain_id, chain_id,... ]
  |----->file---->$key**---->[ chain_id, chain_id,... ]
  |----->bus1---->loop_id--->[ chain_id, chain_id,... ]
  |----->cooked-->loop_id--->[ chain_id, chain_id,... ]
  |_____>mixed___>loop_id___>[ chain_id, chain_id,... ]

  ** consists of full path to the file ($filename) followed
  by a space, followed the output format specification.

=cut
sub write_chains {
	$debug2 and print "&write_chains\n";

	# $bus->apply;
	# $mixer->apply;
	# $ui->write_chains

	# we can assume that %inputs and %outputs will have the
	# same lowest-level keys
	#
	my @buses = grep { $_ ne 'file' and $_ ne 'device' } keys %inputs;
	
	### Setting devices as inputs (used by i.e. rec_setup)
	
	for my $dev (keys %{ $inputs{device} } ){

		$debug and print "dev: $dev\n";
		push  @input_chains, 
		join " ", "-a:" . (join ",", @{ $inputs{device}->{$dev} }),
			"-f:" .  $devices{$dev}->{input_format},
			"-i:" .  $devices{$dev}->{ecasound_id}, 
	}
	#####  Setting devices as outputs
	#
	for my $dev ( keys %{ $outputs{device} }){
			push @output_chains, join " ",
				"-a:" . (join "," , @{ $outputs{device}->{$dev} }),
				"-f:" . $devices{$dev}->{output_format},
				"-o:". $devices{$dev}->{ecasound_id};
	}
	### Setting loops as inputs 

	for my $bus( @buses ){ # i.e. 'mixed', 'cooked'
		for my $loop ( keys %{ $inputs{$bus} }){
			push  @input_chains, 
			join " ", 
				"-a:" . (join ",", @{ $inputs{$bus}->{$loop} }),
				"-i:$loop";
		}
	}
	### Setting loops as outputs 

	for my $bus( @buses ){ # i.e. 'mixed', 'cooked'
		for my $loop ( keys %{ $outputs{$bus} }){
			push  @output_chains, 
			join " ", 
				"-a:" . (join ",", @{ $outputs{$bus}->{$loop} }),
				"-o:$loop";
		}
	}
	##### Setting files as inputs (used by mon_setup)

	for my $full_path (keys %{ $inputs{file} } ) {
		$debug and print "monitor input file: $full_path\n";
		my $chain_ids = join ",",@{ $inputs{file}->{$full_path} };
		push @input_chains, join ( " ",
					"-a:".$chain_ids,
			 		"-i:".$full_path,

	   );
 	}
	##### Setting files as outputs (used by rec_file and mix)

	for my $key ( keys %{ $outputs{file} } ){
		my ($full_path, $format) = split " ", $key;
		$debug and print "record output file: $full_path\n";
		my $chain_ids = join ",",@{ $outputs{file}->{$key} };
		
		push @output_chains, join ( " ",
			 "-a:".$chain_ids,
			 "-f:".$format,
			 "-o:".$full_path,
		 );
			 
			 
	}

	# $debug and print "\%state_c\n================\n", yaml_out(\%state_c);
	# $debug and print "\%state_t\n================\n",  yaml_out(\%state_t);
							
		
	## write general options
	
	my $ecs_file = "# ecasound chainsetup file\n\n\n";
	$ecs_file   .= "# general\n\n";
	$ecs_file   .= $ecasound_globals;
	$ecs_file   .= "\n\n\n# audio inputs\n\n";
	$ecs_file   .= join "\n", sort @input_chains;
	$ecs_file   .= "\n\n# post-input processing\n\n";
	$ecs_file   .= join "\n", sort map{ "-a:$_ $post_input{$_}"} keys %post_input;
	$ecs_file   .= "\n\n# pre-output processing\n\n";
	$ecs_file   .= join "\n", sort map{ "-a:$_ $pre_output{$_}"} keys %pre_output;
	$ecs_file   .= "\n\n# audio outputs\n\n";
	$ecs_file   .= join "\n", sort @output_chains, "\n";
	
	$debug and print "ECS:\n",$ecs_file;
	my $sf = join_path(&project_dir, $chain_setup_file);
	open ECS, ">$sf" or croak "can't open file $sf:  $!\n";
	print ECS $ecs_file;
	close ECS;
}
sub new_wav_name {
	# used to name output file
	my $stub = shift;
	my $version;
	if (@record) {  # we are recording an audio input
		$version = new_version(); # even mix track
	}
	else { # we are only mixing
		$version = $stub eq $mixname  # mix track 
			? ($use_monitor_version_for_mixdown 
					? $monitor_version 
					: $state_c{1}->{versions}->[-1] + 1
				)
			: new_version();
	}
	join_path(this_wav_dir,	"$stub\_$version.wav");
}
sub output_format {
	my $stub = shift;
	$stub eq $project_name or $stub eq $mixname
		? $mix_to_disk_format
		: $mixer_out_format
}
## templates for generating chains

sub initialize_rules {
 }
sub initialize_oids {
	local $debug = $debug3;
	$debug2 and print "&initialize_oids\n";

@oids = @{ $yr->read($oids) };


# these are templates for building chains
map {	
	my $name = $_;
	map{ 		defined $_->{$name} 
					and $_->{$name} =~ /(&)(.+)/ 
					and $_->{$name} = \&$2 
	} @oids; 
} qw( post_input pre_output);
#map{ $_->{post_input} =~ /(&)(.+)/ and $_->{post_input} = \&{ $2 } } @oids; 
#map{ $_->{pre_output} =~ /(&)(.+)/ and $_->{pre_output} = \&{ $2 } } @oids; 


$debug and print "rec_setup $oids[-1]->{input}\n";

	# oid settings
	
	map{ $oid_status{$_->{name}} = $_->{default} eq 'on' ? 1 : 0 } @oids;
	$debug and print yaml_out(\%oid_status); 

}
sub mono_to_stereo { " -erc:1,2 " }

sub pre_multi {
	$debug2 and print "&pre_multi\n";
	my $n = shift;
	$debug and print "track: $n\n";
	return if ! defined $state_c{$n}->{ch_m} or $state_c{$n}{ch_m} == 1;
	route(2,$state_c{$n}->{ch_m}); # stereo signal
}
sub convert_to_jack {
	map{ $_->{input} = q(jack)} grep{ $_->{name} =~ /rec_/ } @oids;	
	map{ $_->{output} = q(jack)} grep{ $_->{name} =~ /live|multi|stereo/ } @oids;	
}
sub convert_to_alsa { initialize_oids }

## transport functions

sub load_ecs {
		my $project_file = join_path(&project_dir , $chain_setup_file);
		eval_iam("cs-remove $project_file");
		eval_iam("cs-load ". $project_file);
		$debug and map{print "$_\n\n"}map{$e->eci($_)} qw(cs es fs st ctrl-status);
}
sub new_engine { 
	system qq(killall $ecasound);
	sleep 1;
	system qq(killall -9 $ecasound);
	$e = Audio::Ecasound->new();
}
sub setup_transport {
	$debug2 and print "&setup_transport\n";
	collect_chains();
	make_io_lists();
	#map{ eliminate_loops($_) } @all_chains;
	#print "minus loops\n \%inputs\n================\n", yaml_out(\%inputs);
	#print "\%outputs\n================\n", yaml_out(\%outputs);
	write_chains();
}
sub connect_transport {
	load_ecs(); 
	carp("Invalid chain setup, cannot arm transport.\n"),return unless eval_iam("cs-is-valid");
	find_op_offsets(); 
	apply_ops();
	eval_iam('cs-connect');
	carp("Invalid chain setup, cannot arm transport.\n"), return 
		unless eval_iam("engine-status") eq 'not started' ;
	eval_iam('engine-launch');
	carp("Invalid chain setup, cannot arm transport.\n"), return
		unless eval_iam("engine-status") eq 'stopped' ;
	$length = eval_iam('cs-get-length'); 
	$ui->length_display(-text => colonize($length));
	eval_iam("cs-set-length $length") unless @record;
	$ui->clock_config(-text => colonize(0));
	print eval_iam("fs");
	$ui->flash_ready();
	
}
sub start_transport { 
	$debug2 and print "&start_transport\n";
	carp("Invalid chain setup, aborting start.\n"),return unless eval_iam("cs-is-valid");
	eval_iam('start');
	sleep 1; # time for engine
	start_clock();
}
sub stop_transport { 
	$debug2 and print "&stop_transport\n"; $e->eci('stop');
	$ui->project_label_configure(-background => $old_bg);
	# what if we are recording
}
sub transport_running {
#	$debug2 and print "&transport_running\n";
	 $e->eci('engine-status') eq 'running' ;
}
sub disconnect_transport {
	return if transport_running();
	eval_iam('cs-disconnect') }


sub toggle_unit {
	if ($unit == 1){
		$unit = 60;
		
	} else{ $unit = 1; }
}
sub show_unit { $time_step->configure(
	-text => ($unit == 1 ? 'Sec' : 'Min') 
)}
## clock and clock-refresh functions ##
#

sub start_clock {
	$clock_id = $clock->repeat(1000, \&refresh_clock);
}
sub restart_clock {
	eval q($clock_id->cancel);
	start_clock();
}
sub refresh_clock{
	update_clock();
	my $status = eval_iam('engine-status');
	return if $status eq 'running' ;
	$clock_id->cancel;
	$ui->project_label_configure(-background => $old_bg);
	if ($status eq 'error') { new_engine();
		&connect_transport unless &really_recording; 
	}
	elsif ($status eq 'finished') {
		&connect_transport unless &really_recording; 
	}
	else { # status: stopped, not started, undefined
	&rec_cleanup if &really_recording();
	}

}
## recording head positioning

sub to_start { 
	return if really_recording();
	eval_iam(qq(cs-set-position 0));
	restart_clock();
}
sub to_end { 
	# ten seconds shy of end
	return if really_recording();
	my $end = eval_iam(qq(cs-get-length)) - 10 ;  
	eval_iam(qq(cs-set-position $end));
	restart_clock();
} 
sub jump {
	$debug2 and print "&jump\n";
	return if really_recording();
	my $delta = shift;
	my $here = eval_iam(qq(getpos));
	$debug and print "delta: $delta\nhere: $here\nunit: $unit\n\n";
	my $new_pos = $here + $delta * $unit;
	$new_pos = $new_pos < $length ? $new_pos : $length - 10;
	# eval_iam("setpos $new_pos");
	my $cmd = "setpos $new_pos";
	$e->eci("setpos $new_pos");
	print "$cmd\n";
	restart_clock();
}
## post-recording functions

sub rec_cleanup {
	$debug2 and print "&rec_cleanup\n";
	$debug and print "I was recording!\n";
 	my @k = really_recording();
	disconnect_transport();
	my $recorded = 0;
 	for my $k (@k) {   
 		my ($n) = $outputs{file}{$k}[-1] =~ m/(\d+)/; 
 		my $test_wav = new_wav_name($k);
		$debug and print "new wave name for $k: ", new_wav_name($k), "\n";
 		my ($v) = ($test_wav =~ /_(\d+)\.wav$/); # #01 regex error, fixed
		$debug and print "n: $n\nv: $v\n";
		$debug and print "testing for $test_wav\n";
		if (-e $test_wav) {
			if (-s $test_wav > 44100) { # 0.5s x 16 bits x 44100/s
				find_wavs($n);
				$state_c{$n}->{active} = $state_c{$n}->{versions}->[-1]; # XXX
				update_version_button($n, $v);
			$recorded++;
			}
			else { unlink $test_wav }
		}
	}
	my $mixed = scalar ( grep{ $_ eq $project_name or $_ eq $mixname} @k );
	$debug and print "recorded: $recorded mixed: $mixed\n";
	if ( ($recorded -  $mixed) >= 1) {
			# i.e. there are first time recorded tracks
			$ui->update_master_version_button();
			$state_t{ $state_t{active} }->{rw} = "MON";
			setup_transport();
			connect_transport();
			$ui->refresh();
	}
		
} 
## effect functions
sub add_effect {
	
	$debug2 and print "&add_effect\n";
	
	my %p 			= %{shift()};
	my $n 			= $p{chain};
	my $code 			= $p{type};
	my $parent_id = $p{parent_id};  
	my $id		= $p{cop_id};   # initiates restore
	my $parameter		= $p{parameter}; 
	my $i = $effect_i{$code};

	return if $id eq $state_c{$n}->{vol} or
	          $id eq $state_c{$n}->{pan};   # skip these effects 
			   								# already created in add_track

	$id = cop_add(\%p); 
	my %pp = ( %p, cop_id => $id); # replace chainop id
	add_effect_gui(\%pp);
	apply_op($id) if eval_iam("cs-is-valid");

}

sub add_effect_gui {
		$debug2 and print "&add_effect_gui\n";
		@_ = discard_object(@_);
		my %p 			= %{shift()};
		my $n 			= $p{chain};
		my $code 			= $p{type};
		my $parent_id = $p{parent_id};  
		my $id		= $p{cop_id};   # initiates restore
		my $parameter		= $p{parameter}; 
		my $i = $effect_i{$code};

		$debug and print yaml_out(\%p);

		$debug and print "cop_id: $id, parent_id: $parent_id\n";
		# $id is determined by cop_add, which will return the
		# existing cop_id if supplied

		# check display format, may be 'scale' 'field' or 'hidden'
		
		my $display_type = $cops{$id}->{display}; # individual setting
		defined $display_type or $display_type = $effects[$i]->{display}; # template
		$debug and print "display type: $display_type\n";

		return if $display_type eq q(hidden);

		my $frame ;
		if ( ! $parent_id ){ # independent effect
			$frame = $widget_c{$n}->{parents}->Frame->pack(
				-side => 'left', 
				-anchor => 'nw',)
		} else {                 # controller
			$frame = $widget_c{$n}->{children}->Frame->pack(
				-side => 'top', 
				-anchor => 'nw')
		}

		no warnings;
		$widget_e{$id} = $frame; 
		# we need a separate frame so title can be long

		# here add menu items for Add Controller, and Remove

		my $parentage = $effects[ $effect_i{ $cops{$parent_id}->{type}} ]
			->{name};
		$parentage and $parentage .=  " - ";
		$debug and print "parentage: $parentage\n";
		my $eff = $frame->Menubutton(
			-text => $parentage. $effects[$i]->{name}, -tearoff => 0,);
		use warnings;

		$eff->AddItems([
			'command' => "Remove",
			-command => sub { remove_effect($id) }
		]);
		$eff->grid();
		my @labels;
		my @sliders;

		# make widgets

		for my $p (0..$effects[$i]->{count} - 1 ) {
		my @items;
		#$debug and print "p_first: $p_first, p_last: $p_last\n";
		for my $j ($e_bound{ctrl}{a}..$e_bound{ctrl}{z}) {   
			push @items, 				
				[ 'command' => $effects[$j]->{name},
					-command => sub { add_effect ({
							parent_id => $id,
							chain => $n,
							parameter  => $p,
							type => $effects[$j]->{code} } )  }
				];

		}
		push @labels, $frame->Menubutton(
				-text => $effects[$i]->{params}->[$p]->{name},
				-menuitems => [@items],
				-tearoff => 0,
		);
			$debug and print "parameter name: ",
				$effects[$i]->{params}->[$p]->{name},"\n";
			my $v =  # for argument vector 
			{	parent => \$frame,
				cop_id => $id, 
				p_num  => $p,
			};
			push @sliders,make_scale($v);
		}

		if (@sliders) {

			$sliders[0]->grid(@sliders[1..$#sliders]);
			 $labels[0]->grid(@labels[1..$#labels]);
		}
}

sub remove_effect {
	@_ = discard_object(@_);
	$debug2 and print "&remove_effect\n";
	my $id = shift;
	my $n = $cops{$id}->{chain};
		
	$debug and print "ready to remove cop_id: $id\n";

	# if i belong to someone remove their ownership of me

	if ( my $parent = $cops{$id}->{belongs_to} ) {
	$debug and print "parent $parent owns list: ", join " ",
		@{ $cops{$parent}->{owns} }, "\n";

		@{ $cops{$parent}->{owns} }  =  grep{ $_ ne $id}
		@{ $cops{$parent}->{owns} } ; 
	$debug and print "parent $parent new owns list: ", join " ",
	}

	# recursively remove children
	$debug and print "children found: ", join "|",@{$cops{$id}->{owns}},"\n";
		
	# parameter controllers are not separate ops
	map{remove_effect($_)}@{ $cops{$id}->{owns} };

	
	# remove my own cop_id from the stack
	remove_op($id), $ui->remove_effect_gui($id) unless $cops{$id}->{belongs_to};

}
sub remove_effect_gui {
	@_ = discard_object(@_);
	$debug2 and print "&remove_effect_gui\n";
	my $id = shift;
	my $n = $cops{$id}->{chain};
	$debug and print "id: $id, chain: $n\n";

	$state_c{$n}->{ops} = 
		[ grep{ $_ ne $id} @{ $state_c{ $cops{$id}->{chain} }->{ops} } ];
	$debug and print "i have widgets for these ids: ", join " ",keys %widget_e, "\n";
	$debug and print "preparing to destroy: $id\n";
	$widget_e{$id}->destroy();
	delete $widget_e{$id}; 

}

sub remove_op {

	my $id = shift;
	my $n = $cops{$id}->{chain};
	if ( $cops{$id}->{belongs_to}) { 
		return;
	}
	my $index; 
	$debug and print "ops list for chain $n: @{$state_c{$n}->{ops}}\n";
	$debug and print "operator id to remove: $id\n";
		for my $pos ( 0.. scalar @{ $state_c{$n}->{ops} } - 1  ) {
			($index = $pos), last if $state_c{$n}->{ops}->[$pos] eq $id;
		};
	$debug and print "ready to remove from chain $n, operator id $id, index $index\n";
	$debug and eval_iam ("cs");
	 eval_iam ("c-select $n");
	eval_iam ("cop-select ". ($state_c{$n}->{offset} + $index));
	eval_iam ("cop-remove");
	$debug and eval_iam ("cs");

	delete $cops{$id};
	delete $copp{$id};
}
sub cop_add {
	my %p 			= %{shift()};
	my $n 			= $p{chain};
	my $code		= $p{type};
	my $parent_id = $p{parent_id};  
	my $id		= $p{cop_id};   # causes restore behavior when present
	my $i       = $effect_i{$code};
	my $parameter	= $p{parameter};  # needed for parameter controllers
	$debug2 and print "&cop_add\n";

	return $id if $id; # do nothing if cop_id has been issued

	# make entry in %cops with chain, code, display-type, children

	$debug and print "Issuing a new cop_id for track $n: $cop_id\n";
	# from the cop_id, we may also need to know chain number and effect

	$cops{$cop_id} = {chain => $n, 
					  type => $code,
					  display => $effects[$i]->{display},
					  owns => [] };

 	cop_init ( { %p, cop_id => $cop_id} );

	if ($parent_id) {
		$debug and print "parent found: $parent_id\n";

		# store relationship
		$debug and print "parent owns" , join " ",@{ $cops{$parent_id}->{owns}}, "\n";

		push @{ $cops{$parent_id}->{owns}}, $cop_id;
		$debug and print join " ", "my attributes:", (keys %{ $cops{$cop_id} }), "\n";
		$cops{$cop_id}->{belongs_to} = $parent_id;
		$debug and print join " ", "my attributes again:", (keys %{ $cops{$cop_id} }), "\n";
		$debug and print "parameter: $parameter\n";
		$copp{$cop_id}->[0] = $parameter + 1; # set fx-param to the parameter number.
 		# find position of parent and insert child immediately afterwards

 		my $end = scalar @{ $state_c{$n}->{ops} } - 1 ; 
 		for my $i (0..$end){
 			splice ( @{$state_c{$n}->{ops}}, $i+1, 0, $cop_id ), last
 				if $state_c{$n}->{ops}->[$i] eq $parent_id
 		}
	}
	else { push @{$state_c{$n}->{ops} }, $cop_id; }

	$cop_id++; # return value then increment
}

sub cop_init {
	local $debug = $debug3;
	$debug2 and print "&cop_init\n";
	my %p = %{shift()};
	my $id = $p{cop_id};
	my $parent_id = $p{parent_id};
	my $vals_ref  = $p{vals_ref};
	local $debug = $debug3;
	$debug and print "cop__id: $id\n";

	my @vals;
	if (ref $vals_ref) {
	# untested
		@vals = @{ $vals_ref };
		$debug and print ("values supplied\n");
		@{ $copp{$id} } = @vals;
		return;
	} 
	else { 
		$debug and print "no settings found, loading defaults if present\n";
		my $i = $effect_i{ $cops{$id}->{type} };
		
		# CONTROLLER
		# don't initialize first parameter if operator has a parent
		# i.e. if operator is a controller
		#for my $p ($parent_id ? 1 : 0..$effects[$i]->{count} - 1) {
		# XXX support controller-type operators
		
		for my $p (0..$effects[$i]->{count} - 1) {
			my $default = $effects[$i]->{params}->[$p]->{default};
			push @vals, $default;
		}
		@{ $copp{$id} } = @vals;
		$debug and print "copid: $id defaults: @vals \n";
	#}

	}
}
sub effect_update {
	my ($chain, $id, $param, $val) = @_;
	$debug2 and print "&effect_update\n";
	# return if rec_status($chain) eq "MUTE"; 
	return if ! defined $state_c{$chain}->{offset}; # MIX
	return unless transport_running();
 	$debug and print join " ", @_, "\n";	

	# update Ecasound's copy of the parameter

	$debug and print "valid: ", eval_iam("cs-is-valid"), "\n";
	$param++; # so the value at $p[0] is applied to parameter 1
	my $controller; 
	for my $op (0..scalar @{ $state_c{$chain}->{ops} } - 1) {
		${ $state_c{$chain}->{ops} } [$op] eq $id and $controller = $op 
	}
	$debug and print "cop_id $id corresponds to track: $chain, controller: $controller, offset: $state_c{$chain}->{offset}\n";
	eval_iam ("c-select $chain");
	eval_iam ("cop-select ". ($state_c{$chain}->{offset} + $controller));
	eval_iam ("copp-select $param");
	eval_iam ("copp-set $val");
}
sub find_op_offsets {

=comment
	Op offsets are needed to calculate the index to an effect (chain operator).
	If reverb is added and it is the first user-added effect, the offset will
	typically include an operator for routing (which will appear in the chain
	setup file) plus operators for volume and pan, which are provided for each
	track.

	find_op_offsets reads the output of the cs command to determine
	the number of chain operators from the setup file, then adds 
	two for the volume and pan operators, to give the index offset
	for the first user effect.

	Here is the relevant line from the 'cs' command output:

		Chain "1" [selected] "Channel copy"
			
	we will count the quotes, divide by two, and subtract one (for the chain id)
	to get offset. Then we add two for volume and pan. Finally, we will
	add 1, since perl arrays (used to represent chain operators) are indexed
	starting at 0, whereas ecasound indexes operators starting at 1.

	In this example, the first user effect will have an index of 4, which
	will also be the offset needed for our start-at-zero array. 
=cut


	$debug2 and print "&find_op_offsets\n";
	eval_iam('c-select-all');
		my @op_offsets = split "\n",eval_iam("cs");
		shift @op_offsets; # remove comment line
		$debug and print join "\n\n",@op_offsets; 
		for my $output (@op_offsets){
			my $chain_id;
			($chain_id) = $output =~ m/Chain "(\w*\d+)"/;
			print "chain_id: $chain_id\n";
			next if $chain_id =~ m/\D/; # skip id's containing non-digits
										# i.e. M1
			my $quotes = $output =~ tr/"//;
			$debug and print "offset: $quotes in $output\n"; 
			$state_c{$chain_id}->{offset} = ($quotes/2 - 1) + 1; 

		}
}
sub apply_ops {  # in addition to operators in .ecs file
	local $debug = $debug3;
	$debug2 and print "&apply_ops\n";
	for my $n (@all_chains) {
	$debug and print "chain: $n, offset: $state_c{$n}->{offset}\n";
 		next if rec_status($n) eq "MUTE" and $n != 1; #MIX
		next if ! defined $state_c{$n}->{offset}; # for MIX
 		next if ! $state_c{$n}->{offset} ;
		for my $id ( @{ $state_c{$n}->{ops} } ) {
		#	next if $cops{$id}->{belongs_to}; 
		apply_op($id);
		}
	}
}
sub apply_op {
	$debug2 and print "&apply_op\n";
	local $debug = $debug3;
	my $id = shift;
	$debug and print "id: $id\n";
	my $code = $cops{$id}->{type};
	$debug and print "chain: $cops{$id}->{chain} type: $cops{$id}->{type}, code: $code\n";
	#  if code contains colon, then follow with comma (preset, LADSPA)
	#  if code contains no colon, then follow with colon (ecasound,  ctrl)
	
	$code = '-' . $code . ($code =~ /:/ ? q(,) : q(:) );
	my @vals = @{ $copp{$id} };
	$debug and print "values: @vals\n";

	# we start to build iam command

	
	my $add = "cop-add "; 
	$add .= $code . join ",", @vals;

	# if my parent has a parent then we need to append the -kx  operator

	my $dad = $cops{$id}->{belongs_to};
	$add .= " -kx" if $cops{$dad}->{belongs_to};
	$debug and print "operator:  ", $add, "\n";

	eval_iam ("c-select $cops{$id}->{chain}") 
		unless $cops{$id}->{belongs_to}; # avoid reset
	eval_iam ($add);
	$debug and print "children found: ", join ",", "|",@{$cops{$id}->{owns}},"|\n";
	map{apply_op($_)} @{ $cops{$id}->{owns} };

}
## static effects data



# @ladspa_sorted # XXX

sub prepare_static_effects_data{
	local $debug = $debug3;
	$debug2 and print "&prepare_static_effects_data\n";

	my $effects_cache = join_path(&ecmd_dir, $effects_cache_file);

	# TODO re-read effects data if ladspa or user presets are
	# newer than cache

	if (-f $effects_cache and ! $opts{s}){  
		$debug and print "found effects cache: $effects_cache\n";
		assign_var($effects_cache, @effects_static_vars);
	} else {
		local $debug = 0;
		$debug and print "reading in effects data, please wait...\n";
		read_in_effects_data(); 
		get_ladspa_hints();
		integrate_ladspa_hints();
		sort_ladspa_effects();
		serialize (
			-file => $effects_cache, 
			-vars => \@effects_static_vars,
			-class => 'UI',
			-storable => 1 ) unless $wav_dir eq '.';
	}

}
sub extract_effects_data {
	my ($lower, $upper, $regex, $separator, @lines) = @_;
	carp ("incorrect number of lines ", join ' ',$upper-$lower,scalar @lines)
		if $lower + @lines - 1 != $upper;
	$debug and print"lower: $lower upper: $upper  separator: $separator\n";
	#$debug and print "lines: ". join "\n",@lines, "\n";
	$debug and print "regex: $regex\n";
	
	for (my $j = $lower; $j <= $upper; $j++) {
		my $line = shift @lines;
	
		$line =~ /$regex/ or carp("bad effect data line: $line\n"),next;
		my ($no, $name, $id, $rest) = ($1, $2, $3, $4);
		$debug and print "Number: $no Name: $name Code: $id Rest: $rest\n";
		my @p_names = split $separator,$rest; 
		map{s/'//g}@p_names; # remove leading and trailing q(') in ladspa strings
		$debug and print "Parameter names: @p_names\n";
		$effects[$j]={};
		$effects[$j]->{number} = $no;
		$effects[$j]->{code} = $id;
		$effects[$j]->{name} = $name;
		$effects[$j]->{count} = scalar @p_names;
		$effects[$j]->{params} = [];
		$effects[$j]->{display} = qq(field);
		map{ push @{$effects[$j]->{params}}, {name => $_} } @p_names;
	}
}
sub sort_ladspa_effects {
	$debug2 and print "&sort_ladspa_effects\n";
#	print yaml_out(\%e_bound); 
	my $aa = $e_bound{ladspa}{a};
	my $zz = $e_bound{ladspa}{z};
#	print "start: $aa end $zz\n";
	map{push @ladspa_sorted, 0} ( 1 .. $aa ); # fills array slice [0..$aa-1]
	splice @ladspa_sorted, $aa, 0,
		 sort { $effects[$a]->{name} cmp $effects[$b]->{name} } ($aa .. $zz) ;
	$debug and print "sorted array length: ". scalar @ladspa_sorted, "\n";
}		
sub read_in_effects_data {

	$debug = 0;
	read_in_tkeca_effects_data();

	# read in other effects data
	
	my @ladspa = grep {! /^\w*$/ } split "\n", eval_iam("ladspa-register");
	
	# join the two lines of each entry
	my @lad = map { join " ", splice(@ladspa,0,2) } 1..@ladspa/2; 

	my @preset = grep {! /^\w*$/ } split "\n", eval_iam("preset-register");
	my @ctrl  = grep {! /^\w*$/ } split "\n", eval_iam("ctrl-register");

	# index boundaries we need to make effects list and menus

	$e_bound{ladspa}{a} = $e_bound{tkeca}{z} + 1;
	$e_bound{ladspa}{b} = $e_bound{tkeca}{z} + int(@lad/4);
	$e_bound{ladspa}{c} = $e_bound{tkeca}{z} + 2*int(@lad/4);
	$e_bound{ladspa}{d} = $e_bound{tkeca}{z} + 3*int(@lad/4);
	$e_bound{ladspa}{z} = $e_bound{tkeca}{z} + @lad;
	$e_bound{preset}{a} = $e_bound{ladspa}{z} + 1;
	$e_bound{preset}{b} = $e_bound{ladspa}{z} + int(@preset/2);
	$e_bound{preset}{z} = $e_bound{ladspa}{z} + @preset;
	$e_bound{ctrl}{a}   = $e_bound{preset}{z} + 1;
	$e_bound{ctrl}{z}   = $e_bound{preset}{z} + @ctrl;

	my $preset_re = qr/
		^(\d+) # number
		\.    # dot
		\s+   # spaces+
		(\w+) # name
		,\s*  # comma spaces* 
		-(pn:\w+)    # preset_id 
		:?     # maybe colon (if parameters)
		(.*$)  # rest
	/x;

	my $ladspa_re = qr/
		^(\d+) # number
		\.    # dot
		\s+  # spaces
		(\w.+?) # name, starting with word-char,  non-greedy
		\s+     # spaces
		-(el:\w+),? # ladspa_id maybe followed by comma
		(.*$)        # rest
	/x;

	my $ctrl_re = qr/
		^(\d+) # number
		\.     # dot
		\s+    # spaces
		(\w.+?) # name, starting with word-char,  non-greedy
		,\s*    # comma, zero or more spaces
		-(k\w+):?    # ktrl_id maybe followed by colon
		(.*$)        # rest
	/x;

	extract_effects_data(
		$e_bound{ladspa}{a},
		$e_bound{ladspa}{z},
		$ladspa_re,
		q(','),
		@lad,
	);

	extract_effects_data(
		$e_bound{preset}{a},
		$e_bound{preset}{z},
		$preset_re,
		q(,),
		@preset,
	);
	extract_effects_data(
		$e_bound{ctrl}{a},
		$e_bound{ctrl}{z},
		$ctrl_re,
		q(,),
		@ctrl,
	);



	for my $i (0..$#effects){
		no warnings;
		 $effect_i{ $effects[$i]->{code} } = $i; 
		 use warnings;
		 $debug and print "i: $i code: $effects[$i]->{code} display: $effects[$i]->{display}\n";
	}

	$debug and print "\@effects\n======\n", yaml_out(\@effects); ; 
}
sub read_in_tkeca_effects_data {

# Based on GPL code in Tkeca

# controller (effect) data format
# code|name|number_of_parameters| ( Label|scale_start|scale_end|default|resolution ) x number_of_parameters

# I left the tcl code 'as is' in the following pasted section, using regexes 
# so future updates from him can be pasted in without editing.

# divide by lines, remove stuff outside quotes, 
# then make an anonymous array of the fields of each line

	my @effects_data = 	map { [split /\|/, $_ ]  }  
						map{ s/^.*?"//; s/"\s*$//; $_} 
						split "\n",$tkeca_effects_data; 
	
	$e_bound{tkeca}{a}  = 1;
	$e_bound{tkeca}{z}  = scalar @effects_data;  

	for my $i (1..@effects_data){
		my @row = @{ shift @effects_data };
		@{$effects[$i]}{ qw(code name count) } = splice @row, 0, 3;

		# default display format

		$effects[$i]->{display} = qq(scale);

	# maps effect code (i.e. epp) to an index in array holding static effects data
	#print "effects code: $i stands for ", $effects[$i]->{code}, "\n";
	#print "count: $effects[$i]->{count}\n";

			for (1..$effects[$i]->{count}){
				my %p;
				#print join " / ",splice (@row, 0,5), "\n";
				@p{ qw(name begin end default resolution) }  =  splice @row, 0, 5;
				# print "\%p\n======\n", yaml_out(\%p);
				push @{$effects[$i]->{params}}, \%p;

			}
	}

}
sub get_ladspa_hints{
	$debug2 and print "&get_ladspa_hints\n";
	my @dirs =  split ':', $ENV{LADSPA_PATH};
	my $data = '';
	for my $dir (@dirs) {
		opendir DIR, $dir or carp qq(can't open LADSPA dir "$dir" for read: $!\n);
		my @plugins = grep{ /\.so$/ } readdir DIR;
		$data .= join "", map { `analyseplugin $_` } @plugins;
		closedir DIR;
	}
	# print $data; exit;
	my @plugin_stanzas = split "\n\n\n", $data;
	# print scalar @plugin_stanzas; exit;
	# print $data;

	# print "@plugins"; exit;
	# | perl -ne 'chomp; s/$ENV{LADSPA_PATH}//; system qq(analyseplugin $_)'
	my $ladspa_sample_rate = 44100; # for sample-rate dependent effect
	use Data::Dumper;

	my $pluginre = qr/
	Plugin\ Name: \s+ "([^"]+)" \s+
	Plugin\ Label:\s+ "([^"]+)" \s+
	[^\x00]+(?=Ports) 		# swallow maximum up to Ports
	Ports: \s+ ([^\x00]+) 	# swallow all
	/x;

	my $paramre = qr/
	"([^"]+)"   #  name inside quotes
	\s+
	(.+)        # rest
	/x;



	for my $stanza (@plugin_stanzas) {

		$stanza =~ /$pluginre/ or carp "*** couldn't match plugin stanza $stanza ***";

		my ($plugin_name, $plugin_label, $ports) = ($1, $2, $3);
		#print "$1\n$2\n$3"; exit;

		 my @lines = split "\n",$ports;
	#	print join "\n",@lines; exit;
		my @params;  # data

		my @names;
		for my $p (@lines) {
			next if $p =~ /^\s*$/;
			$p =~ /$paramre/;
			my ($name, $rest) = ($1, $2);
			my ($dir, $type, $range, $default, $hint) = split /\s*,\s*/ , $rest, 5;
			#print join "|",$dir, $type, $range, $default, $hint;
			next if $type eq q(audio);
			my %p;
			$p{name} = $name;
			$p{dir} = $dir;
			$p{hint} = $hint;
			my ($beg, $end, $default_val, $resolution) = range($name, $range, $default, $hint);
			$p{begin} = $beg;
			$p{end} = $end;
			$p{default} = $default_val;
			$p{resolution} = $resolution;
			push @params, { %p };
		}

		$plugin_label = "el:" . $plugin_label;
		$effects_ladspa {$plugin_label}->{params} = [ @params ];
		$effects_ladspa {$plugin_label}->{count} = scalar @params;
		$effects_ladspa {$plugin_label}->{display} = 'scale';
	}

	$debug and print yaml_out(\%effects_ladspa); 
}
no warnings;
sub range {
	my ($name, $range, $default, $hint) = @_; 
	my $multiplier = 1;;
	$multiplier = $ladspa_sample_rate if $range =~ s/\*srate//g;
	my ($beg, $end) = split /\s+to\s+/, $range;
	# if end is '...' set to $default + 10dB or $default * 10
	$default =~ s/default\s+//;
	$end =~ /\.{3}/ and $end = (
		$default == 0 ? 10  # '0' is probably 0db, so 0+10db
					  : $default * 10
		);
#	print "1 beg: $beg  end: $end\n";
	$beg = $beg * $multiplier;
	$end = $end * $multiplier;
#	print "2 beg: $beg  end: $end\n";

	my $resolution = ($end - $beg) / 100;
	if    ($hint =~ /integer/ ) { $resolution = 1; }
	elsif ($hint =~ /logarithmic/ ) {
		$beg = 0.0001 * $multiplier if ! $beg;
		$beg = round ( log $beg );
		$end = round ( log $end );
		$resolution = ($end - $beg) / 100;
		$default = round (log $default);
	}
	
	$resolution = d2( $resolution + 0.002) if $resolution < 1  and $resolution > 0.01;
	$resolution = dn ( $resolution, 3 ) if $resolution < 0.01;
	$resolution = int ($resolution + 0.1) if $resolution > 1 ;
	
	#print "3 beg: $beg  end: $end\n";
	($beg, $end, $default, $resolution)

}
use warnings;
sub integrate_ladspa_hints {
	map{ 
		my $i = $effect_i{$_};
		print ("$_ not found\n"), next unless $i;
		$effects[$i]->{params} = $effects_ladspa{$_}->{params};
		$effects[$i]->{display} = $effects_ladspa{$_}->{display};
	} keys %effects_ladspa;

my %L;
my %M;

map { $L{$_}++ } keys %effects_ladspa;
map { $M{$_}++ } grep {/el:/} keys %effect_i;

for my $k (keys %L) {
	$M{$k} or print "$k not found in ecasound listing\n";
}
for my $k (keys %M) {
	$L{$k} or print "$k not found in ladspa listing\n";
}


$debug and print join "\n", sort keys %effects_ladspa;
$debug and print '-' x 60, "\n";
$debug and print join "\n", grep {/el:/} sort keys %effect_i;

#print yaml_out \@effects; exit;

}
sub d2 {
	my $n = shift;
	sprintf("%.2f", $n)
}
sub dn {
	my ($n, $places) = @_;
	sprintf("%." . $places . "f", $n);
}
sub round {
	my $n = shift;
	return 0 if $n == 0;
	$n = int $n if $n > 10;
	$n = d2($n) if $n < 10;
	$n;
}
	

=comment

 ls $LADSPA_PATH | perl -ne 'chomp; s/$ENV{LADSPA_PATH}//; system qq(analyseplugin $_)'

my $ds = q(
Plugin Name: "LS Filter"
Plugin Label: "lsFilter"
Plugin Unique ID: 1908
Maker: "Steve Harris <steve@plugin.org.uk>"
Copyright: "GPL"
Must Run Real-Time: No
Has activate() Function: Yes
Has deativate() Function: No
Has run_adding() Function: Yes
Environment: Normal or Hard Real-Time
Ports:  "Filter type (0=LP, 1=BP, 2=HP)" input, control, 0 to 2, default 0, integer
        "Cutoff frequency (Hz)" input, control, 0.002*srate to 0.5*srate, default 0.0316228*srate, logarithmic
        "Resonance" input, control, 0 to 1, default 0
        "Input" input, audio
        "Output" output, audio
);
=cut
## persistent state support

sub save_state {
	$debug2 and print "&save_state\n";
	my $file = shift;
	# restore muted volume levels
	#
	my %muted;
	
	map{ $copp{ $state_c{$_}{vol} }->[0] = $old_vol{$_} ;
		 $muted{$_}++;
	#	 $ui->paint_button($widget_c{$_}{mute}, q(brown) );
		} grep { $old_vol{$_} } @all_chains;

 # old vol level has been stored, thus is muted
	$file = $file ? $file : $state_store_file;
	$file = join_path(&project_dir, $file);
		$debug and 1;
	print "filename: $file\n";

	serialize(
		-file => $file, 
		-vars => \@persistent_vars,
		-class => 'UI',
		-storable => 1,
		);

# store alsa settings

	my $result2 = system "alsactl -f $file.alsa store";
	$debug and print "alsactl store result: ", $result2 >>8, "\n";

	# now remute
	
	map{ $copp{ $state_c{$_}{vol} }->[0] = 0} 
	grep { $muted{$_}} 
	@all_chains;

}
sub assign_var {
	my ($source, @vars) = @_;
	assign_vars(
				-source => $source,
				-vars   => \@vars,
				-class => 'UI');
}
sub retrieve_state {
	$debug2 and print "&retrieve_state\n";
	my $file = shift;
	$file = $file ? $file : $state_store_file;
	$file = join_path(project_dir(), $file);
	my $yamlfile = $file;
	$yamlfile .= ".yml" unless $yamlfile =~ /yml$/;
	$file = $yamlfile if -f $yamlfile;
	! -f $file and carp("file not found: $file\n"), return;
	$debug and print "using file: $file";
	assign_var( $file, @persistent_vars );
	#print status_vars; exit;

=comment
	$debug and print ref $ref->{marks};
	 @marks = @{ $ref->{marks} };
	 print "array size ", scalar @marks;
=cut

	my $toggle_jack = $widget_o[$#widget_o];
	convert_to_jack if $jack_on;
	$ui->paint_button($toggle_jack, q(lightblue)) if $jack_on;
	$ui->refresh_oids();

	# restore mixer settings

	my $result = system "sudo alsactl -f $file.alsa restore";
	$debug and print "alsactl restore result: " , $result >> 8 , "\n";

	# restore time marker labels

	$ui->restore_time_marker_labels();
=comment
	
	map{ $time_marks[$_]->configure( 
		-text => colonize($marks[$_]),
		-background => $old_bg,
	)} 
	grep{ $marks[$_] }1..$#time_marks;
=cut

	# restore take and track guis
	
	for my $t (@takes) { 
		next if $t == 1; 
		$ui->take_gui;
	}; #
	my $did_apply = 0;
	$last_version = 0; 
	for my $n (@all_chains) { 
		$debug and print "restoring track: $n\n";
		restore_track($n) ;
		for my $id (@{$state_c{$n}->{ops}}){
			$did_apply++ 
				unless $id eq $state_c{$n}->{vol}
					or $id eq $state_c{$n}->{pan};

			
			add_effect({
						chain => $cops{$id}->{chain},
						type => $cops{$id}->{type},
						cop_id => $id,
						parent_id => $cops{$id}->{belongs_to},
						});

		# TODO if parent has a parent, i am a parameter controller controlling
		# a parameter controller, and therefore need the -kx switch
		}
	}
	$did_apply and $ui->manifest(); # $ew->deiconify();

}


sub save_effects {
	$debug2 and print "&save_effects\n";
	my $file = shift;
	
	# restore muted volume levels
	#
	my %muted;
	
	map  {$copp{ $state_c{$_}{vol} }->[0] = $old_vol{$_} ;
		  $ui->paint_button($widget_c{$_}{mute}, $old_bg ) }
	grep { $old_vol{$_} }  # old vol level stored and muted
	@all_chains;

	# we need the ops list for each track
	#
	# i dont see why, do we overwrite the effects section
	# in one of the init routines?
	# I will follow for now 12/6/07
	
	%state_c_ops = ();
	map{ 	$state_c_ops{$_} = $state_c{$_}->{ops} } @all_chains;

	# map {remove_op} @{ $state_c{$_}->{ops} }

	store_vars(
		-file => $file, 
		-vars => \@effects_dynamic_vars,
		-class => 'UI');

}

=comment
sub r {
	retrieve_effects(shift);
}

sub r5 { r("eff5") };
=cut
sub retrieve_effects {
	$debug2 and print "&retrieve_effects\n";
	my $file = shift;
	my %current_cops = %cops; # XXX why bother
	my %current_copp = %copp; # similar name!!!!
	assign_vars($file, @effects_dynamic_vars);
	my %old_copp = %copp;  # XXX why bother
	my %old_cops = %cops; 
	%cops = %current_cops;
	%copp = %current_copp; ## similar name!!


	print "\%state_c_ops\n ", yaml_out( \%state_c_ops), "\n\n";
	print "\%old_cops\n ", yaml_out( \%old_cops), "\n\n";
	print "\%old_copp\n ", yaml_out( \%old_copp), "\n\n";
#	return;

	restore_time_marker_labels();

	# remove effects except vol and pan, in which case, update vals

	map{ 	
	
		$debug and print "found chain $_: ", join " ",
		@{ $state_c{$_}->{ops} }, "\n";

		my $n = $_;
		map {	my $id = $_; 
				$debug and print "checking chain $n, id $id: ";
				
				if (	$state_c{$n}->{vol} eq $id or
						$state_c{$n}->{pan} eq $id  ){

					# do nothing
				$debug and print "is vol/pan\n";

				}
				else {
					
					$debug and print "is something else\n";
					remove_effect($id) ;
					remove_op($id)
			}

		} @{ $state_c{$_}->{ops} }
	} @all_chains;
			
	return;

	# restore ops list
	
	map{ $state_c{$_}->{ops} = $state_c_ops{$_} } @all_chains;

	# restore ops->chain mapping
	
	%cops = %old_copp;

	# add the correct copp entry for each id except vol/pan
	map{ my $n = $_;
			map {	my $id = $_; 
				if (	$state_c{$n}->{vol} eq $id or
						$state_c{$n}->{pan} eq $id  ){

					$copp{$id}->[0] = $old_copp{$id}->[0];
				}
				else {  $copp{$id} = $old_copp{$id} }

			} @{ $state_c{$_}->{ops} }
		} @all_chains;

	# apply ops
	
	my $did_apply = 0;

	for my $n (@all_chains) { 
		for my $id (@{$state_c{$n}->{ops}}){
			$did_apply++ 
				unless $id eq $state_c{$n}->{vol}
					or $id eq $state_c{$n}->{pan};

			
			add_effect({  
						chain => $cops{$id}->{chain},
						type => $cops{$id}->{type},
						cop_id => $id,
						parent_id => $cops{$id}->{belongs_to},
						});

		# TODO if parent has a parent, i am a parameter controller controlling
		# a parameter controller, and therefore need the -kx switch
		}
	}
	$did_apply and print "########## applied\n\n";
	
	# $ew->deiconify or $ew->iconify;

}

	

### end


# gui handling
use Carp;

sub project_label_configure{ 
	@_ = discard_object(@_);
	$project_label->configure( @_ ) }

sub length_display{ 
	@_ = discard_object(@_);
	$setup_length->configure(@_)};

sub clock_config { 
	@_ = discard_object(@_);
	$clock->configure( @_ )}

sub manifest { $ew->deiconify() }

sub destroy_widgets {

	map{ $_->destroy } map{ $_->children } $effect_frame;
	my @children = $take_frame->children;
	map{ $_->destroy  } @children[1..$#children];
	@children = $track_frame->children;
	map{ $_->destroy  } @children[11..$#children]; # fragile
	$state_t{active} = 1; 
}

sub init_gui {

	$debug2 and print "&init_gui\n";

### 	Tk root window layout

	$mw = MainWindow->new; 
	$mw->title("Tk Ecmd"); 
	$mw->deiconify;

	### init effect window

	$ew = $mw->Toplevel;
	$ew->title("Effect Window");
	$ew->deiconify; 
	#$ew->withdraw;

	$canvas = $ew->Scrolled('Canvas')->pack;
	$canvas->configure(
		scrollregion =>[2,2,10000,2000],
		-width => 900,
		-height => 600,	
		);
# 		scrollregion =>[2,2,10000,2000],
# 		-width => 1000,
# 		-height => 4000,	
	$effect_frame = $canvas->Frame;
	my $id = $canvas->createWindow(30,30, -window => $effect_frame,
											-anchor => 'nw');

	$project_label = $mw->Label->pack(-fill => 'both');
	$old_bg = $project_label->cget('-background');
	$time_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$transport_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$oid_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$clock_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$track_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$take_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$take_label = $take_frame->Menubutton(-text => "Group",-tearoff => 0,)->pack(-side => 'left');
		
	$add_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$perl_eval_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$iam_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
	$load_frame = $mw->Frame->pack(-side => 'bottom', -fill => 'both');
#	my $blank = $mw->Label->pack(-side => 'left');



	$sn_label = $load_frame->Label(-text => "Enter project name:")->pack(-side => 'left');
	$sn_text = $load_frame->Entry(-textvariable => \$project, -width => 45)->pack(-side => 'left');
	$sn_load = $load_frame->Button->pack(-side => 'left');;
#	$sn_load_nostate = $load_frame->Button->pack(-side => 'left');;
	$sn_new = $load_frame->Button->pack(-side => 'left');;
	$sn_quit = $load_frame->Button->pack(-side => 'left');
	$sn_save = $load_frame->Button->pack(-side => 'left');
	$sn_recall = $load_frame->Button->pack(-side => 'left');
	$save_id = "";
	my $sn_save_text = $load_frame->Entry(
									-textvariable => \$save_id,
									-width => 15
									)->pack(-side => 'left');
	$sn_dump = $load_frame->Button->pack(-side => 'left');

	$build_track_label = $add_frame->Label(-text => "Track")->pack(-side => 'left');
	$build_track_text = $add_frame->Entry(-textvariable => \$track_name, -width => 12)->pack(-side => 'left');
	$build_track_rec_label = $add_frame->Label(-text => "Rec CH")->pack(-side => 'left');
	$build_track_rec_text = $add_frame->Entry(-textvariable => \$ch_r, -width => 2)->pack(-side => 'left');
	$build_track_mon_label = $add_frame->Label(-text => "Mon CH")->pack(-side => 'left');
	$build_track_mon_text = $add_frame->Entry(-textvariable => \$ch_m, -width => 2)->pack(-side => 'left');
	$build_track_add = $add_frame->Button->pack(-side => 'left');;

	$sn_load->configure(
		-text => 'Load',
		-command => sub{ load_project(-name => remove_spaces $project_name)});
	$sn_new->configure( 
		-text => 'New',
		-command => sub{ load_project(
							-name => remove_spaces($project_name),
							-create => 1)});
	$sn_save->configure(
		-text => 'Save settings',
		-command => #sub { print "save_id: $save_id\n" });
		 sub {save_state($save_id) });
	$sn_recall->configure(
		-text => 'Recall settings',
 		-command => sub {load_project -name => $project_name, 
 										-settings => $save_id },
				);
	$sn_dump->configure(
		-text => q(Dump state),
		-command => sub{ print &status_vars });
	$sn_quit->configure(-text => "Quit",
		 -command => sub { 
				return if transport_running();
				exit;
				 }
				);


	$build_track_add->configure( 
			-text => 'Add',
			-command => sub { add_track(remove_spaces($track_name)) }
	);

=comment TAKE
	$build_new_take->configure( 
			-text => 'New Group',
			-command =>
			\&new_take, # used for mixdown

			
			);

			
=cut
	my @labels = 
		qw(Track Version Status Rec Mon Volume Cut Unity Pan Center Effects);
	my @widgets;
	map{ push @widgets, $track_frame->Label(-text => $_)  } @labels;
	$widgets[0]->grid(@widgets[1..$#widgets]);

	
	$iam_label = $iam_frame->Label(-text => "IAM Command")
		->pack(-side => 'left');;
	$iam_text = $iam_frame->Entry( 
		-textvariable => \$iam, -width => 65)
		->pack(-side => 'left');;
	$iam_execute = $iam_frame->Button(
			-text => 'Execute',
			-command => sub { print eval_iam($iam), "\n" }
		)->pack(-side => 'left');;
	my $perl_eval;
	my $perl_eval_label = $perl_eval_frame->Label(
		-text => "Perl Command")
		->pack(-side => 'left');;
	my $perl_eval_text = $perl_eval_frame->Entry(
		-textvariable => \$perl_eval, -width => 65)
		->pack(-side => 'left');;
	my $perl_eval_execute = $perl_eval_frame->Button(
			-text => 'Execute',
			-command => sub { eval $perl_eval  }
		)->pack(-side => 'left');;
		
}
sub transport_gui {
	$debug2 and print "&transport_gui\n";

	$transport_label = $transport_frame->Label(
		-text => 'TRANSPORT',
		-width => 12,
		)->pack(-side => 'left');;
	$transport_setup_and_connect  = $transport_frame->Button->pack(-side => 'left');;
	$transport_start = $transport_frame->Button->pack(-side => 'left');
	$transport_stop = $transport_frame->Button->pack(-side => 'left');
	#$transport_setup = $transport_frame->Button->pack(-side => 'left');;
	#$transport_connect = $transport_frame->Button->pack(-side => 'left');;
	$transport_disconnect = $transport_frame->Button->pack(-side => 'left');;
	$transport_new = $transport_frame->Button->pack(-side => 'left');;

	$transport_stop->configure(-text => "Stop",
	-command => sub { 
					stop_transport();
				}
		);
	$transport_start->configure(
		-text => "Start!",
		-command => sub { 
		return if transport_running();
		if ( really_recording ) {
			project_label_configure(-background => 'lightpink') 
		}
		else {
			project_label_configure(-background => 'lightgreen') 
		}
		start_transport();
				});
	$transport_setup_and_connect->configure(
			-text => 'Arm',
			-command => sub {&setup_transport; &connect_transport}
						 );
=comment
	$transport_setup->configure(
			-text => 'Generate chain setup',
			-command => \&setup_transport,
						 );
	$transport_connect->configure(
			-text => 'Connect chain setup',
			-command => \&connect_transport,
						 );
=cut
	$transport_disconnect->configure(
			-text => 'Disconnect setup',
			-command => \&disconnect_transport,
						);
	$transport_new->configure(
			-text => 'New Engine',
			-command => \&new_engine,
						 );
}
sub time_gui {
	$debug2 and print "&time_gui\n";

	my $time_label = $clock_frame->Label(
		-text => 'TIME', 
		-width => 12);
	$clock = $clock_frame->Label(
		-text => '0:00', 
		-width => 8,
		-background => 'orange',
		);
	my $length_label = $clock_frame->Label(
		-text => 'LENGTH',
		-width => 10,
		);
	$setup_length = $clock_frame->Label(
	#	-width => 8,
		);

	for my $w ($time_label, $clock, $length_label, $setup_length) {
		$w->pack(-side => 'left');	
	}

	my $mark_frame = $time_frame->Frame->pack(
		-side => 'bottom', 
		-fill => 'both');
	my $fast_frame = $time_frame->Frame->pack(
		-side => 'bottom', 
		-fill => 'both');
	# jump

	my $jump_label = $fast_frame->Label(-text => q(JUMP), -width => 12);
	my $mark_label = $mark_frame->Label(-text => q(MARK), -width => 12);
	my @pluses = (1, 5, 10, 30, 60);
	my @minuses = map{ - $_ } reverse @pluses;
	my @fw = map{ my $d = $_; $fast_frame->Button(
			-text => $d,
			-command => sub { jump($d) },
			)
		}  @pluses ;
	my @rew = map{ my $d = $_; $fast_frame->Button(
			-text => $d,
			-command => sub { jump($d) },
			)
		}  @minuses ;
	my $beg = $fast_frame->Button(
			-text => 'Beg',
			-command => \&to_start,
			);
	my $end = $fast_frame->Button(
			-text => 'End',
			-command => \&to_end,
			);

	$time_step = $fast_frame->Button( 
			-text => 'Sec',
			);
		for my $w($jump_label, @rew, $beg, $time_step, $end, @fw){
			$w->pack(-side => 'left')
		}

	$time_step->configure (-command => sub { &toggle_unit; &show_unit });

	# Marks
	
	my @label_and_arm;
	push @label_and_arm, $mark_label;	
	push @label_and_arm, $mark_frame->Button(
		-text => 'Set',
		-command => \&arm_mark,
	);
	my $marks = 20; # number of marker buttons
	my @m = (1..$marks);
	my $label = qw(A);
	map { push @time_marks, $mark_frame->Button( 
		-text => $_,
		-command => sub { mark(eval $_)},
		-background => $marks[$_] ? $old_bg : 'lightblue',
		) } @m;
	# map { $time_marks[$_]->configure( -command => sub { # mark($_)} ) } @m[1..$#m];
	for my $m (@m) {
		$time_marks[$m]->configure( -command => sub { mark($m)} )
			unless ! defined $time_marks[$m];
		
		;
	}
	#$time_marks[3]->configure( -background => 'orange' );
#	 map { $time_marks[$_]->configure(-background => 'orange')} @m;
 	for my $w (@label_and_arm, @time_marks){
 		$w->pack(-side => 'left')
 	}
#	$time_marks[0]->grid(@time_marks[@m]);

}
sub oid_gui {
	$debug2 and print "&oid_gui\n";
	my $outputs = $oid_frame->Label(-text => 'OUTPUTS', -width => 12);
	my @oid_name;
	for my $oid ( @oids ){
		# print "gui oid name: $oid->{name} status: $oid_status{$oid->{name}}\n";
		next if $oid->{name} =~ m/setup/;
		push @oid_name, $oid->{name};
		
		my $oid_button = $oid_frame->Button( 
			-text => ucfirst $oid->{name},
			-background => 
				$oid_status{$oid->{name}} ?  'AntiqueWhite' : $old_bg,
			-activebackground => 
				$oid_status{$oid->{name}} ? 'AntiqueWhite' : $old_bg
		);
		push @widget_o, $oid_button;
		$widget_o{$oid->{name}} = $oid_button;
	}
	for my $i (0..$#widget_o) {
		$widget_o[$i]->configure(
			-command => sub { 
		print "but oid name: $oid_name[$i] status: $oid_status{$oid_name[$i]}\n";
				$oid_status{$oid_name[$i]} = !  $oid_status{$oid_name[$i]};
		print "but oid name: $oid_name[$i] status: $oid_status{$oid_name[$i]}\n";
				$widget_o[$i]->configure( -background => 
					$oid_status{$oid_name[$i]} ?  'AntiqueWhite' : $old_bg ,
			-activebackground => 
					$oid_status{$oid_name[$i]} ? 'AntiqueWhite' : $old_bg
					
					);
			});
	}
	my $toggle_jack = $oid_frame->Button;
	
	$toggle_jack->configure(
		-text => q(Jack ON/OFF),
		-command => sub {
			my $color = $toggle_jack->cget( -background );
				if ($color eq q(lightblue) ){

					# jack is on, turn it off
				
					convert_to_alsa();
					paint_button($toggle_jack, $old_bg);
					$jack_on = 0;
				}
				else {

					convert_to_jack();
					paint_button($toggle_jack, q(lightblue));
					$jack_on = 1;
				}
			}
		);
	push @widget_o, $toggle_jack; # since no one else uses this array
				
		
	map { $_ -> pack(-side => 'left') } ($outputs, @widget_o);
	
}
sub paint_button {
	@_ = discard_object(@_);
	my ($button, $color) = @_;
	$button->configure(-background => $color,
						-activebackground => $color);
}
sub flash_ready {
	my $color;
		if (@record ){
			$color = 'lightpink'; # live recording
		} elsif ( &really_recording ){  # mixing only
			$color = 'yellow';
		} else {  $color = 'lightgreen'; }; # just playback

	$debug and print "flash color: $color\n";
	length_display(-background => $color);
	$clock->after(10000, 
		sub{ length_display(-background => $old_bg) }
	);
}
sub take_gui {  

	$debug2 and print "&take_gui\n";
		my $tname = $alias{$t} ? $alias{$t} : $t;
		my $name = $take_frame->Menubutton(
				-text => ucfirst $tname,
				-tearoff =>0,
			)->pack(-side => 'left');
		push @widget_t, $name;
	#$debug and print "=============\n\@widget_t\n",yaml_out(\@widget_t);
		
		if ($t != 1) { # do not add REC command for Mixdown group MIX

		$name->AddItems([
			'command' => 'REC',
			-background => $old_bg,
			-command => sub { 
				no strict qw(vars);
				defined $my_t or my $my_t = $t;
				use strict qw(vars);
				select_take ($my_t, qq(REC) );
				}
			]);
		}

		$name->AddItems([
			'command' => 'MON',
			-background => $old_bg,
			-command => sub {
				no strict qw(vars);
				defined $my_t or my $my_t = $t;
				use strict qw(vars);
				select_take($my_t, qq(MON)); 
				}
			]);
		$name->AddItems([
			'command' => 'MUTE',
			-background => $old_bg,
			-command => sub {
				no strict qw(vars);
				defined $my_t or my $my_t = $t;
				use strict qw(vars);
				select_take($my_t, qq(MUTE)); 
				}

			]);

							   
}
sub global_version_buttons {
#	( map{ $_->destroy } @global_version_buttons ) if @global_version_buttons; 
	if (defined $widget_t[1]) {
		my @children = $widget_t[1]->children;
		for (@children) {
			$_->cget(-value) and $_->destroy;
		}; # should remove menubuttons
	}
		
	@global_version_buttons = ();
	$debug and print "making global version buttons range:", join ' ',1..$last_version, " \n";
 	for my $v (undef, 1..$last_version) {
		no warnings;
		next unless grep{  grep{ $v == $_ } @{ $state_c{$_}->{versions} } }
			grep{ $_ != 1 } @all_chains; # MIX 
		use warnings;
 		push @global_version_buttons,
			$widget_t[1]->radiobutton(
				###  HARDCODED, second take widget
				-label => ($v ? $v : ''),
				-variable => \$monitor_version,
				-value => $v,
				-command => sub { 
					$state_t{2}->{rw} = "MON"; ### HARDCODED SECOND TAKE; MIX
					mon_vert($v);  # select this version
					setup_transport(); 
					connect_transport();
					refresh();
					}

 					);
 	}
}
sub track_gui { 
	$debug2 and print "&track_gui\n";
	@_ = discard_object(@_);
	my $n = shift;
	print "found index: $n\n";

	# my $j is effect index
	my ($name, $version, $rw, $ch_r, $ch_m, $vol, $mute, $solo, $unity, $pan, $center);
	my $this_take = $t; 
	my $stub = " ";
	$stub .= $state_c{$n}->{active};
	$name = $track_frame->Label(
			-text => $state_c{$n}->{file},
			-justify => 'left');
	$version = $track_frame->Menubutton( 
					-text => $stub,
					-tearoff => 0);
	for my $v (undef, @{$state_c{$n}->{versions}}) {
					$version->radiobutton(
						-label => ($v ? $v: ''),
						-variable => \$state_c{$n}->{active},
						-value => $v,
						-command => 
		sub { $version->configure(-text=> selected_version($n) ) 
	#		unless rec_status($n) eq "REC"
			}
					);
	}

	$ch_r = $track_frame->Menubutton(
					-textvariable => \$state_c{$n}->{ch_r},
					-tearoff => 0,
				);
			if ( $n != 1 ) { # for all but Mixdown track MIX
				for my $v (1..$tk_input_channels) {
					$ch_r->radiobutton(
						-label => $v,
						-variable => \$state_c{$n}->{ch_r},
						-value => $v,
						-command => sub { 
							$state_c{$n}->{rw} = "REC";
							refresh() }
				 		)
				}
			}
	$ch_m = $track_frame->Menubutton(
					-textvariable => \$state_c{$n}->{ch_m},
					-tearoff => 0,
				);
				for my $v (1..10) {
					$ch_m->radiobutton(
						-label => $v,
						-variable => \$state_c{$n}->{ch_m},
						-value => $v,
						-command => sub { 
							$state_c{$n}->{rw} = "MON";
							refresh_c($n) }
				 		)
				}
	$rw = $track_frame->Menubutton(
		-text => $state_c{$n}->{rw},
		-tearoff => 0,
	);

	my @items = (
			[ 'command' => "REC",
				-foreground => 'red',
				-command  => sub { 
					$state_c{$n}->{rw} = "REC";
					refresh();
					}
			],
			[ 'command' => "MON",
				-command  => sub { 
					$state_c{$n}->{rw} = "MON";
					refresh();
					}
			],
			[ 'command' => "MUTE", 
				-command  => sub { 
					$state_c{$n}->{rw} = "MUTE";
					refresh();
					}
			],
		);
	map{$rw->AddItems($_) unless $n == 1} @items; # MIX CONDITIONAL
	$state_c{$n}->{rw} = "MON" if $n == 1;          # MIX

 
   ## XXX general code mixed with GUI code

	# Volume

	my $p_num = 0; # needed when using parameter controllers
	my $vol_id = add_volume_control($n);


	$debug and print "vol cop_id: $vol_id\n";
	my %p = ( 	parent => \$track_frame,
			chain  => $n,
			type => 'ea',
			cop_id => $vol_id,
			p_num		=> $p_num,
			length => 300, 
			);


	 $debug and do {my %q = %p; delete $q{parent}; print
	 "=============\n%p\n",yaml_out(\%q)};

	$vol = make_scale ( \%p );
	# Mute

	$mute = $track_frame->Button(
	  		-command => sub { 
				if ($copp{$vol_id}->[0]) {  # non-zero volume
					$old_vol{$n}=$copp{$vol_id}->[0];
					$copp{$vol_id}->[0] = 0;
					effect_update($p{chain}, $p{cop_id}, $p{p_num}, 0);
					$mute->configure(-background => 'brown');
					$mute->configure(-activebackground => 'brown');
				}
				else {
					$copp{$vol_id}->[0] = $old_vol{$n};
					effect_update($p{chain}, $p{cop_id}, $p{p_num}, 
						$old_vol{$n});
					$old_vol{$n} = 0;
					$mute->configure(-background => $old_bg);
					$mute->configure(-activebackground => $old_bg);
				}
			}	
	  );


	# Unity

	$unity = $track_frame->Button(
	  		-command => sub { 
				$copp{$vol_id}->[0] = 100;
	 			effect_update($p{chain}, $p{cop_id}, $p{p_num}, 100);
			}
	  );

	  
	# Pan
	# effects code mixed with GUI code XXX
	# run on initializing the track gui

	
	my $pan_id = add_pan_control($n);
	
	$debug and print "pan cop_id: $pan_id\n";
	$p_num = 0;           # first parameter
	my %q = ( 	parent => \$track_frame,
			chain  => $n,
			type => 'epp',
			cop_id => $pan_id,
			p_num		=> $p_num,
			);
	# $debug and do { my %q = %p; delete $q{parent}; print "x=============\n%p\n",yaml_out(\%q) };
	$pan = make_scale ( \%q );

	# Center

	$center = $track_frame->Button(
	  	-command => sub { 
			$copp{$pan_id}->[0] = 50;
			effect_update($q{chain}, $q{cop_id}, $q{p_num}, 50);
		}
	  );
	
	my $effects = $effect_frame->Frame->pack(-fill => 'both');;

	# effects, held by widget_c->n->effects is the frame for
	# all effects of the track

	@{ $widget_c{$n} }{qw(name version rw ch_r ch_m mute effects)} 
		= ($name,  $version, $rw, $ch_r, $ch_m, $mute, \$effects);#a ref to the object
	#$debug and print "=============\n\%widget_c\n",yaml_out(\%widget_c);
	my $independent_effects_frame 
		= ${ $widget_c{$n}->{effects} }->Frame->pack(-fill => 'x');


	my $controllers_frame 
		= ${ $widget_c{$n}->{effects} }->Frame->pack(-fill => 'x');
	
	# parents are the independent effects
	# children are controllers for various paramters

	$widget_c{$n}->{parents} = $independent_effects_frame;

	$widget_c{$n}->{children} = $controllers_frame;
	
	$independent_effects_frame
		->Label(-text => uc $state_c{$n}->{file} )->pack(-side => 'left');

	#$debug and print( "Number: $n\n"),MainLoop if $n == 2;
	my @tags = qw( EF P1 P2 L1 L2 L3 L4 );
	my @starts =   ( $e_bound{tkeca}{a}, 
					 $e_bound{preset}{a}, 
					 $e_bound{preset}{b}, 
					 $e_bound{ladspa}{a}, 
					 $e_bound{ladspa}{b}, 
					 $e_bound{ladspa}{c}, 
					 $e_bound{ladspa}{d}, 
					);
	my @ends   =   ( $e_bound{tkeca}{z}, 
					 $e_bound{preset}{b}, 
					 $e_bound{preset}{z}, 
					 $e_bound{ladspa}{b}-1, 
					 $e_bound{ladspa}{c}-1, 
					 $e_bound{ladspa}{d}-1, 
					 $e_bound{ladspa}{z}, 
					);
	my @add_effect;

	map{push @add_effect, effect_button($n, shift @tags, shift @starts, shift @ends)} 1..@tags;
	
	$name->grid($version, $rw, $ch_r, $ch_m, $vol, $mute, $unity, $pan, $center, @add_effect);

	refresh();

	
}

sub update_version_button {
	@_ = discard_object(@_);
	my ($n, $v) = @_;
	carp ("no version provided \n") if ! $v;
	my $w = $widget_c{$n}->{version};
					$w->radiobutton(
						-label => $v,
						-variable => \$state_c{$n}->{active},
						-value => $v,
						-command => 
		sub { $widget_c{$n}->{version}->configure(-text=>$v) 
				unless rec_status($n) eq "REC" }
					);
}
sub update_master_version_button {
				$widget_t[0]->radiobutton(
						-label => $last_version,
						-variable => \$monitor_version,
						-value => $last_version,
						-command => sub { mon_vert(eval $last_version) }
					);
}


sub effect_button {
	local $debug = $debug3;
	$debug2 and print "&effect_button\n";
	my ($n, $label, $start, $end) = @_;
	$debug and print "chain $n label $label start $start end $end\n";
	my @items;
	my $widget;
	my @indices = ($start..$end);
	if ($start >= $e_bound{ladspa}{a} and $start <= $e_bound{ladspa}{z}){
		@indices = ();
		@indices = @ladspa_sorted[$start..$end];
		$debug and print "length sorted indices list: ".scalar @indices. "\n";
	$debug and print "Indices: @indices\n";
	}
		
		for my $j (@indices) { 
=comment
	if ($start >= $e_bound{ladspa}{a} and $start <= $e_bound{ladspa}{z}){
		print "adding effect: $effects[$j]->{name}\n";
		}
=cut
		push @items, 				
			[ 'command' => "$effects[$j]->{count} $effects[$j]->{name}" ,
				-command  => sub { 
					 add_effect( {chain => $n, type => $effects[$j]->{code} } ); 
					$ew->deiconify; # display effects window
					} 
			];
	}
	$widget = $track_frame->Menubutton(
		-text => $label,
		-tearoff =>0,
		-menuitems => [@items],
	);
	$widget;
}

sub make_scale {
	# my $debug = 1;
	$debug2 and print "&make_scale\n";
	my $ref = shift;
	my %p = %{$ref};
=comment
	%p contains following:
	cop_id   => operator id, to access dynamic effect params in %copp
	parent => parent widget, i.e. the frame
	p_num      => parameter number, starting at 0
	length       => length widget # optional 
=cut
	my $id = $p{cop_id};
	my $n = $cops{$id}->{chain};
	my $code = $cops{$id}->{type};
	my $p  = $p{p_num};
	my $i  = $effect_i{$code};

	$debug and print "id: $id code: $code\n";
	

	# check display format, may be text-field or hidden,

	$debug and  print "i: $i code: $effects[$i]->{code} display: $effects[$i]->{display}\n";
	my $display_type = $cops{$id}->{display};
	defined $display_type or $display_type = $effects[$i]->{display};
	$debug and print "display type: $display_type\n";
	return if $display_type eq q(hidden);


	$debug and print "to: ", $effects[$i]->{params}->[$p]->{end}, "\n";
	$debug and print "p: $p code: $code\n";

	# set display type to individually specified value if it exists
	# otherwise to the default for the controller class


	
	if 	($display_type eq q(scale) ) { 

		# return scale type controller widgets
		my $frame = ${ $p{parent} }->Frame;
			

		#return ${ $p{parent} }->Scale(
		
		my $log_display;
		
		my $controller = $frame->Scale(
			-variable => \$copp{$id}->[$p],
			-orient => 'horizontal',
			-from   =>   $effects[$i]->{params}->[$p]->{begin},
			-to   =>     $effects[$i]->{params}->[$p]->{end},
			-resolution => ($effects[$i]->{params}->[$p]->{resolution} 
				?  $effects[$i]->{params}->[$p]->{resolution}
				: abs($effects[$i]->{params}->[$p]->{end} - 
					$effects[$i]->{params}->[$p]->{begin} ) > 30 
						? 1 
						: abs($effects[$i]->{params}->[$p]->{end} - 
							$effects[$i]->{params}->[$p]->{begin} ) / 100),
		  -width => 12,
		  -length => $p{length} ? $p{length} : 100,
		  -command => sub { effect_update($n, $id, $p, $copp{$id}->[$p]) }
		  );

		# auxiliary field for logarithmic display
		no warnings;	
		if ($effects[$i]->{params}->[$p]->{hint} =~ /logarithm/) {
			my $log_display = $frame->Label(
				-text => exp $effects[$i]->{params}->[$p]->{default},
				-width => 5,
				);
			$controller->configure(
		  		-command => sub { 
					effect_update($n, $id, $p, exp $copp{$id}->[$p]);
					$log_display->configure(
						-text => $effects[$i]->{params}->[$p]->{name} =~ /hz/i
							? int exp $copp{$id}->[$p]
							: dn(exp $copp{$id}->[$p], 1)
						);
					}
				);
		$log_display->grid($controller);
		}
		else { $controller->grid; }

		return $frame;
		use warnings;

	}	

	elsif ($display_type eq q(field) ){ 

	 	# then return field type controller widget

		return ${ $p{parent} }->Entry(
			-textvariable =>\$copp{$id}->[$p],
			-width => 6,
	#		-command => sub { effect_update($n, $id, $p, $copp{$id}->[$p]) },
			# doesn't work with Entry widget
			);	

	}
	else { croak "missing or unexpected display type: $display_type" }

}
sub arm_mark { 
	if ($markers_armed) {
		$markers_armed = 0;
		map{$time_marks[$_]->configure( -background => $old_bg) unless ! $marks[$_] } 1..$#time_marks ;
	}
	else{
		$markers_armed = 1;
		map{$_->configure( -background => 'lightblue') } @time_marks[1..$#time_marks] ;
	}
}
sub colonize { # convert seconds to minutes:seconds 
	my $sec = shift;
	my $min = int ($sec / 60);
	$sec = $sec % 60;
	$sec = "0$sec" if $sec < 10;
	qq($min:$sec);
}
sub mark {

	my $marker = shift;
	# print "my marker is $_\n";
	# record without arming if marker undefined
	if ($markers_armed or ! $marks[$marker]){  
		my $here = eval_iam("cs-get-position");
		return if ! $here;
		$marks[$marker] = $here;
		my $widget = $time_marks[$marker];
		$widget->configure( 
			-text => colonize($here),
			-background => $old_bg,
		);
		if ($markers_armed){ arm_mark() } # disarm
	}
	else{ 
		return if really_recording();
		eval_iam(qq(cs-set-position $marks[$marker]));
		sleep 1;
	#	update_clock();
	#	start_clock();
	}
}

sub update_clock { 
	$ui->clock_config(-text => colonize(eval_iam('cs-get-position')));
}

### end


## refresh functions

sub refresh_t { # buses
	$debug2 and print "&refresh_t\n";
	local $debug = $debug3;
	my %take_color = (REC  => 'LightPink', 
					MON => 'AntiqueWhite',
					MUTE => $old_bg);
	collect_chains();
	my @w = $take_frame->children;
	for my $t (1..@takes){
		# skip 0th item, the label
		my $status;
		#  rec if @record entry for this take
		if ( grep{$take{$_}==$t}@record ) { 
			$debug and print "t-rec $t\n";	
			$status = "REC" } 
		# 	mon if @monitor entry
		elsif ( grep{$take{$_}==$t}@monitor )
			{ 
			$debug and print "t-mon $t\n";	
			$status = "MON" }

		else  { $status = "MUTE";
			$debug and print "t-mute $t\n";	
		
		}

	croak "some crazy status |$status|\n" if $status !~ m/rec|mon|mute/i;
		$debug and print "attempting to set $status color: ", $take_color{$status},"\n";
	$debug and print "take_frame child: $t\n";

		$w[$t]->configure(-background => $take_color{$status});
	}
}
sub refresh_c { # tracks
	local $debug = 1;
	shift @_ if (ref $_[0]) =~ /UI/; # discard object
	my $n = shift;
	$debug2 and print "&refresh_c\n";
	
	$debug and print "track: $n\n"; # rec_status: $rec_status\n";
		my $rec_status = rec_status($n);
	$debug and print "track: $n rec_status: $rec_status\n";
		$debug and print "arrived here\n";

		return unless $widget_c{$n}; # obsolete ??
		$widget_c{$n}->{rw}->configure(-text => $rec_status);
	
	if ($rec_status eq "REC") {
		$debug and print "REC! \n";

		$widget_c{$n}->{name}->configure(-background => 'lightpink');
		$widget_c{$n}->{name}->configure(-foreground => 'Black');
		$widget_c{$n}->{ch_r}->configure(-background => 'LightPink');
		$widget_c{$n}->{ch_r}->configure(-foreground => 'Black');
		$widget_c{$n}->{ch_m}->configure( -background => $old_bg);
		$widget_c{$n}->{ch_m}->configure( -foreground => 'DarkGray');
		$widget_c{$n}->{version}->configure(-text => new_version);

	}
	elsif ( $rec_status eq "MON" ) {
		$debug and print "MON! \n";

		 $widget_c{$n}->{name}->configure(-background => 'AntiqueWhite');
		 $widget_c{$n}->{name}->configure(-foreground => 'Black');
		 $widget_c{$n}->{ch_r}->configure( -background => $old_bg);
		 $widget_c{$n}->{ch_r}->configure( -foreground => 'DarkGray');
		 $widget_c{$n}->{ch_m}->configure( -background => 'AntiqueWhite');
		 $widget_c{$n}->{ch_m}->configure( -foreground => 'Black');
		$widget_c{$n}->{version}->configure(-text => selected_version($n));

		}
	elsif ( $rec_status eq "MUTE" ) {
		$debug and print "MUTE! \n";
		 $widget_c{$n}->{name}->configure(-background => $old_bg);
		 $widget_c{$n}->{ch_r}->configure( -background => $old_bg); 
		 $widget_c{$n}->{ch_r}->configure( -foreground => 'Gray');
		 $widget_c{$n}->{ch_m}->configure( -background => $old_bg); 
		$widget_c{$n}->{ch_m}->configure( -foreground => 'Gray');
		$widget_c{$n}->{version}->configure(-text => selected_version($n));
		}  
		else { carp "\$rec_status contains something unknown: $rec_status";}
}
sub refresh {  
 	$ui->refresh_t(); 
	map{ $ui->refresh_c($_) } @all_chains ;
}
sub refresh_oids{ # OUTPUT buttons
	map{ $widget_o{$_}->configure( # uses hash
			-background => 
				$oid_status{$_} ?  'AntiqueWhite' : $old_bg,
			-activebackground => 
				$oid_status{$_} ? 'AntiqueWhite' : $old_bg
			) } keys %widget_o;
}

sub restore_time_marker_labels {
	
	# restore time marker labels
	
	map{ $time_marks[$_]->configure( 
		-text => $marks[$_]
			?  colonize($marks[$_])
			:  $_,
		-background => $marks[$_]
			?  $old_bg
			: q(lightblue),
		)
	} 1..$#time_marks;

 }


### end


## The following code loads the object core of the system 
## and initiates the chain templates (rules)

use UI::Track;   

package UI::Graphical;  ## gui routines
our @ISA = 'UI';
#use Tk;
#use UI::Assign qw(:all);

## The following methods belong to the Graphical interface class

sub hello {"make a window";}
sub new { my $class = shift; return bless {@_}, $class }
sub loop {
	package UI;
	init_gui; # the main window, effect window hidden
	transport_gui;
	oid_gui;
	time_gui;
	new_take;
	new_take;
	load_project(
		-create => $opts{c},
		-name   => $project_name) if $project_name;
	setup_transport; 
	connect_transport;
	MainLoop;
}

## The following methods belong to the Text interface class

package UI::Text;
our @ISA = 'UI';
use Carp;
sub hello {"hello world!";}

## no-op graphic methods 

# those that take parameters will break!!!
# because object and procedural access get
# different parameter lists ($self being included);

sub take_gui {}
sub track_gui {}
sub refresh {}
sub refresh_t {}
sub refresh_c {}
sub flash_ready {}
sub update_master_version_button {}
sub paint_button {}
sub refresh_oids {}
sub project_label_configure{}
sub length_display{}
sub clock_display {}
sub manifest {}
sub global_version_buttons {}
sub destroy_widgets {}
sub restore_time_marker_labels {}
sub show_unit {};
sub add_effect_gui {};
sub remove_effect_gui {};

## Some of these, may be overwritten
## by definitions that follow

use Carp;
#&loop;
sub new { my $class = shift; return bless { @_ }, $class; }
sub loop {
package UI;
load_project({name => $project_name, create => $opts{c}}) if $project_name;
use Parse::RecDescent;
use Term::ReadLine;
my $term = new Term::ReadLine 'Ecmd';
my $prompt = "Enter command: ";
$OUT = $term->OUT || \*STDOUT;
my $user_input;
$parser = new Parse::RecDescent ($grammar) or croak "Bad grammar!\n";
$debug = 1;
	while (1) {
		my ($user_input) = $term->readline($prompt) ;
		$user_input =~ /^\s*$/ and next;
		$term->addhistory($user_input) ;
		my ($cmd, $predicate) = ($user_input =~ /([\w\.\-]+)(.*)/);
		$debug and print "cmd: $cmd \npredicate: $predicate\n";
		if ($cmd eq 'eval') {
			eval $predicate;
			print "\n";
			$@ and print "Perl command failed: $@\n";
		} elsif ($track_names{$cmd}) { 
			$debug and print "Track name: $cmd\n";
			$select_track = $cmd; 
			$parser->command($predicate) or print ("Returned false\n");
		} elsif ($iam_cmd{$cmd}){
			$debug and print "Found IAM command\n";
			eval_iam($user_input) ;
		} else {
			$parser->command($user_input) 
				and print("Succeeded\n") or print ("Returned false\n");

		}
	}
}

format STDOUT_TOP =
Chain Ver File            Setting Status Rec_ch Mon_ch 
=====================================================
.
format STDOUT =
@<<  @<<  @<<<<<<<<<<<<<<<  @<<<   @<<<   @<<    @<< ~~
splice @UI::format_fields, 0, 7

.
	
1;


package UI;

##  Grammar.p, source for Grammar.pm

### COMMAND LINE PARSER 

$debug2 and print "Reading grammar\n";

$UI::AUTOSTUB = 1;
$UI::RD_HINT = 1;

# rec command changes active take

$grammar = q(

command: fail
end: /\s*$/
help: _help end { print "hello_from your command line gramar\n"; 1 }
fail: 'f' end { print "your command line gramar will get a zero\n"; 0 }

new_project: _new_project name end {
	UI::load_project( 
		name => UI::remove_spaces($item{name}),
		create => 1,
	);

	1;
}

load_project: _load_project name end {
	UI::load_project( name => UI::remove_spaces($item{name}) );
	1;
}

add_track: _add_track wav channel(s?) end { 
	if ($UI::track_names{$item{wav}} ){ 
		print "Track name already in use.\n";

	} else { UI::add_track($item{wav})  }
	1;
}

generate_setup: _generate_setup end { UI::setup_transport(); 1 }

generate_and_connect_setup: _generate_and_connect_setup end { 
	UI::setup_transport() and UI::connect_transport(); 1 }

connect_setup: _connect_setup end { UI::connect_transport(); 1 }

disconnect_setup: _disconnect_setup end { UI::disconnect_transport(); 1 }

save_setup: _save_setup end { UI::save_state($UI::state_store_file); 1 }

list_marks: _list_marks end {}

show_setup: _show_setup end { 	
	map { 	push @UI::format_fields,  
			$_,
			$UI::state_c{$_}->{active},
			$UI::state_c{$_}->{file},
			$UI::state_c{$_}->{rw},
			&UI::rec_status($_),
			$UI::state_c{$_}->{ch_r},
			$UI::state_c{$_}->{ch_m},

		} sort keys %UI::state_c;
		
	write; 
	1;
}

name: /\w+/

wav: name { $UI::select_track = $item{name} }

mix: 'mix' end {1}

norm: 'norm' end {1}

record: 'record' end {} 

exit: 'exit' end { UI::save_state($UI::state_store_file); exit; }


channel: r | m

r: 'r' dd  { $UI::state_c{$UI::chain{$UI::select_track}}->{ch_r} = $item{dd} }
m: 'm' dd  { $UI::state_c{$UI::chain{$UI::select_track}}->{ch_m} = $item{dd} }


rec: 'rec' wav(s?) end { 
	map{$UI::state_c{$UI::chain{$UI::select_track}}->{rw} = "REC"} @{$item{wav}} 
}
mon: 'mon' wav(s?) end { 
	map{$UI::state_c{$UI::chain{$UI::select_track}}->{rw} = "MON"} @{$item{wav}} 
}
mute: 'mute' wav(s?) end { 
	map{$UI::state_c{$UI::chain{$UI::select_track}}->{rw} = "MUTE"} @{$item{wav}}  
}

mute: 'mute' end {$UI::state_c{$UI::chain{$UI::select_track}} = "MUTE"; }

mon: 'mon' end {$UI::state_c{$UI::chain{$UI::select_track}} = "MON"; }

rec: 'rec' end {$UI::state_c{$UI::chain{$UI::select_track}} = "REC"; }


last: ('last' | '$' ) 

dd: /\d+/



command: connect_setup
command: cut
command: disconnect_setup
command: ecasound_start
command: ecasound_stop
command: generate_and_connect_setup
command: generate_setup
command: help
command: list_all_templates
command: list_marks
command: list_templates
command: load_project
command: loop
command: mark
command: mark_loop
command: mixdown
command: mixplay
command: mon
command: monitor_channel
command: monitor_group
command: mute
command: name_mark
command: new_project
command: new_track
command: next_mark
command: pan
command: pan_back
command: pan_left
command: pan_right
command: previous_mark
command: rec
command: record_channel
command: record_group
command: renew_engine
command: save_project
command: set_version
command: show_all_templates
command: show_effects
command: show_setup
command: show_templates
command: start
command: stop
command: unity
command: vol
_connect_setup: 'connect_setup' | 'connect' | 'con'
_cut: 'cut' | 'c'
_disconnect_setup: 'disconnect_setup' | 'disconnect'
_ecasound_start: 'ecasound_start' | 'T'
_ecasound_stop: 'ecasound_stop' | 'S'
_generate_and_connect_setup: 'generate_and_connect_setup' | 'setup'
_generate_setup: 'generate_setup' | 'generate' | 'gen'
_help: 'help' | 'h'
_list_all_templates: 'list_all_templates' | 'lat'
_list_marks: 'list_marks' | 'lm'
_list_templates: 'list_templates' | 'lt'
_load_project: 'load_project' | 'load'
_loop: 'loop'
_mark: 'mark' | 'k'
_mark_loop: 'mark_loop' | 'ml'
_mixdown: 'mixdown' | 'mxd'
_mixplay: 'mixplay' | 'mxp'
_mon: 'mon'
_monitor_channel: 'monitor_channel' | 'm'
_monitor_group: 'monitor_group' | 'monitor' | 'M'
_mute: 'mute' | 'z' | 'off'
_name_mark: 'name_mark' | 'nm'
_new_project: 'new_project' | 'create'
_new_track: 'new_track' | 'new'
_next_mark: 'next_mark' | 'mf' | 'nm' | 'fm'
_pan: 'pan' | 'p'
_pan_back: 'pan_back' | 'pb'
_pan_left: 'pan_left' | 'pl'
_pan_right: 'pan_right' | 'pr'
_previous_mark: 'previous_mark' | 'mb' | 'pm' | 'bm'
_rec: 'rec'
_record_channel: 'record_channel' | 'r'
_record_group: 'record_group' | 'record' | 'R'
_renew_engine: 'renew_engine' | 'renew'
_save_project: 'save_project' | 'keep' | 'k' | 'save'
_set_version: 'set_version' | 'version' | 'n'
_show_all_templates: 'show_all_templates' | 'sat'
_show_effects: 'show_effects' | 'sfx'
_show_setup: 'show_setup' | 'show'
_show_templates: 'show_templates' | 'oids'
_start: 'start' | 't'
_stop: 'stop' | 'st'
_unity: 'unity' | 'cc'
_vol: 'vol' | 'v'
connect_setup: _connect_setup end { 1 }
cut: _cut end { 1 }
disconnect_setup: _disconnect_setup end { 1 }
ecasound_start: _ecasound_start end { 1 }
ecasound_stop: _ecasound_stop end { 1 }
generate_and_connect_setup: _generate_and_connect_setup end { 1 }
generate_setup: _generate_setup end { 1 }
help: _help end { 1 }
list_all_templates: _list_all_templates end { 1 }
list_marks: _list_marks end { 1 }
list_templates: _list_templates end { 1 }
load_project: _load_project end { 1 }
loop: _loop end { 1 }
mark: _mark end { 1 }
mark_loop: _mark_loop end { 1 }
mixdown: _mixdown end { 1 }
mixplay: _mixplay end { 1 }
mon: _mon end { 1 }
monitor_channel: _monitor_channel end { 1 }
monitor_group: _monitor_group end { 1 }
mute: _mute end { 1 }
name_mark: _name_mark end { 1 }
new_project: _new_project end { 1 }
new_track: _new_track end { 1 }
next_mark: _next_mark end { 1 }
pan: _pan end { 1 }
pan_back: _pan_back end { 1 }
pan_left: _pan_left end { 1 }
pan_right: _pan_right end { 1 }
previous_mark: _previous_mark end { 1 }
rec: _rec end { 1 }
record_channel: _record_channel end { 1 }
record_group: _record_group end { 1 }
renew_engine: _renew_engine end { 1 }
save_project: _save_project end { 1 }
set_version: _set_version end { 1 }
show_all_templates: _show_all_templates end { 1 }
show_effects: _show_effects end { 1 }
show_setup: _show_setup end { 1 }
show_templates: _show_templates end { 1 }
start: _start end { 1 }
stop: _stop end { 1 }
unity: _unity end { 1 }
vol: _vol end { 1 }
);
# we use the following settings if we can't find config files

$default = <<'FALLBACK_CONFIG';
---
wav_dir: \.
abbreviations:
  24-mono: s24_le,1,frequency
  32-10: s32_le,10,frequency
  32-12: s32_le,12,frequency
  cd-mono: s16_le,1,44100
  cd-stereo: s16_le,2,44100,i
  frequency: 44100
devices:
  jack:
    ecasound_id: jack_alsa
    input_format: 32-12
    output_format: 32-10
  multi:
    ecasound_id: alsa,ice1712
    input_format: 32-12
    output_format: 32-10
  stereo:
    ecasound_id: alsa,default
    input_format: cd-stereo
    output_format: cd-stereo
ecasound_globals: "-B auto"
mix_to_disk_format: cd-stereo
mixer_out_format: cd-stereo
raw_to_disk_format: cd-mono
...

FALLBACK_CONFIG

# the following template are used to generate chain setups.
$oids = <<'TEMPLATES';
---
-
  default: on
  id: Stereo
  name: stereo
  output: stereo
  type: mixed
-
  default: off
  id: m
  name: multi
  output: multi
  pre_output: &pre_multi
  target: MON
  type: cooked
-
  default: off
  id: L
  name: live
  output: multi
  pre_output: &pre_multi
  target: REC
  type: cooked
-
  default: off
  id: Mix
  name: mix
  output: file
  type: mixed
-
  default: on
  id: ~
  input: file
  name: mon_setup
  output: loop
  post_input: &mono_to_stereo
  target: MON
  type: raw
-
  default: on
  id: R
  input: multi
  name: rec_file
  output: file
  target: REC
  type: raw
-
  default: on
  id: J
  name: mix_setup
  output: loop,111
  target: all
  type: cooked
-
  default: on
  id: ~
  input: multi
  name: rec_setup
  output: loop
  post_input: &mono_to_stereo
  target: REC
  type: raw
...

TEMPLATES


1;
__END__

=head1 NAME

:: - Perl extensions for multitrack audio
recording and processing by Ecasound

=head1 SYNOPSIS

  use UI;

  my $ui = UI->new("tk");

		or

  my $ui = UI->new("text");

	my %options = ( 

			project => 'Night at Carnegie',
			create => 1,
			effects => 'force-reload',
			track_state   => 'ignore',     
			effect_state   => 'ignore',     
			) ;

	$ui->main(%options);

	


=head1 ABSTRACT

	Builds on the Audio::Ecasound interface to the 
	Ecasound audio processing engine to facilitate
	multitrack audio recording. Additions include:

	- Functions for generating chain setups, managing wav
	files, handling persistent configuration data.

	- Useful text-mode and Tk user interfaces

	- A foundation for high-level abstractions such 
	  as track, group, effect, mark, etc.

	Hash data structures representing system state are
	serialized to YAML and written to file. 
	The Git version control system cheaply provides 
	infrastructure for switching among various parameter
	sets. 


=head1 DESCRIPTION

Stub documentation for Audio::Ecasound::Flow, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Joel Roth, E<lt>jroth@dsl-verizon.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Joel Roth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

__END__
