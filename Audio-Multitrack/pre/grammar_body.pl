# i'm a comment!

read: command(s)
command: fail
end: /\s*$/ 
#end: /\s*;\s*/ 
end: ';' 
help: _help end { print "hello_from your command line gramar\n"; 1 }
help: _help dd end { print "hello_from your command line gramar\n"; 1 }
fail: 'f' end { print "your command line gramar will get a zero\n"; 0 }

new_project: _new_project name end {
	::load_project( 
		name => ::remove_spaces($item{name}),
		create => 1,
	);
	print "created project: $::project_name\n";

}

load_project: _load_project name end {
	my $untested = ::remove_spaces($item{name});
	print ("Project $untested does not exist\n"), return
	unless -d ::join_path ::wav_dir(), $untested; 
	::load_project( name => ::remove_spaces($item{name}) );
	::setup_transport() and ::connect_transport();

	print "loaded project: $::project_name\n";
}
save_state: _save_state name(?) end { 
	::save_state( $item{name} ); 
	print "saved state as $item{name}\n";
	}
get_state: _get_state name(?) end {
 	::load_project( 
 		name => $::project_name,
 		settings => $item{name}
 		);
 #	print "set state:  $item{name}\n";
 	}

add_track: _add_track name channel(s?) end { 
	carp ("track name already in use: $item{name}\n"),
		return if $::Track::track_names{$item{name}}; 
	::add_track($item{name}); 
	print "added track $item{name}\n";
}
# add_track: _add_track name(s) end { 
#  	map { ::add_track $_ } @{ $item{name} };
#  	1;
#  }
 

generate: _generate end { ::setup_transport(); 1 }

setup: _setup end { 
	::setup_transport() and ::connect_transport(); 1 }

connect: _connect end { ::connect_transport(); 1 }

disconnect: _disconnect end { ::disconnect_transport(); 1 }

## we reach here

renew_engine: _renew_engine end { ::new_engine(); 1  }

start: _start end { ::start_transport(); 1}
stop: _stop end { ::stop_transport(); 1}


show_setup: _show_setup end { 	

	::Text::show_tracks ( ::Track::all );
}

show_track: _show_track end {
	::Text::show_tracks($::select_track);
}
show_track: _show_track name end { 
 	::Text::show_tracks( $::tn{$item{name}} ) if $::tn{$item{name}}
}
show_track: _show_track dd end {  
	::Text::show_tracks( $::ti[$item{dd}] ) if $::ti[$item{dd}]
}
	
	# print "name: $item{name}\nnumber: $item{dd}\n";
# print ("unknown track\n"), return 
# 		if $item{dd}   and ! $::ti[$item{dd}]
# 		or $item{name} and ! $::tn{$item{name}};
# 
# 	map { 	push @::format_fields,  
# 			$_->n,
# 			$_->active,
# 			$_->name,
# 			$_->rw,
# 			$_->rec_status,
# 			($_->ch_r or 1),
# 			($_->ch_m or 1),
# 
# 		} ($::tn{$item{name}} or $::ti[item{dd}] or $::select_track;
# 		
# 	write; # using format at end of file UI.pm
# 	1;
#}

group_rec: _group_rec end { $::tracker->set( rw => 'REC') }
group_mon: _group_mon end  { $::tracker->set( rw => 'MON') }
group_off: _group_mute end { $::tracker->set(rw => 'OFF') }

mixdown: _mixdown end { $::mixdown_track->set(rw => 'REC')}
mixplay: _mixplay end { $::mixdown_track->set(rw => 'MON');
						$::tracker->set(rw => 'OFF');
}
mixoff:  _mixoff  end { $::mixdown_track->set(rw => 'OFF');
						$::tracker->set(rw => 'MON')}



mix: 'mix' end {1}

norm: 'norm' end {1}

record: 'record' end {} # set to Tracker-Record 

exit: 'exit' end { ::save_state($::state_store_file); exit; }


channel: r | m

r: 'r' dd  {	
				$::select_track->set(ch_r => $item{dd});
				$::ch_r = $item{dd};
				
				}
m: 'm' dd  {	
				$::select_track->set(ch_m => $item{dd}) ;
				$::ch_m = $item{dd};
				print "Output switched to channel $::ch_m\n";
				
				}

off: 'off' end {$::select_track->set(rw => 'OFF'); }
rec: 'rec' end {$::select_track->set(rw => 'REC'); }
mon: 'mon' end {$::select_track->set(rw => 'MON'); }


last: ('last' | '$' ) 

dd: /\d+/

name: /\w+/


wav: name { $::select_track = $::tn{$item{name}} if $::tn{$item{name}}  }

set_version: _set_version dd end { $::select_track->set(active => $item{dd})}
 
vol: _vol dd end { $::copp{ $::select_track->vol }->[0] = $item{dd}; 
				::sync_effect_param( $::select_track->vol, 0);
} 
vol: _vol '+' dd end { $::copp{ $::select_track->vol }->[0] += $item{dd};
				::sync_effect_param( $::select_track->vol, 0);
} 
vol: _vol '-' dd end { $::copp{ $::select_track->vol }->[0] -= $item{dd} ;
				::sync_effect_param( $::select_track->vol, 0);
} 
vol: _vol end { print $::copp{$::select_track->vol}[0], $/ }

cut: _cut end { $::copp{ $::select_track->vol }->[0] = 0;
				::sync_effect_param( $::select_track->vol, 0);
}

unity: _unity end { $::copp{ $::select_track->vol }->[0] = 100;
				::sync_effect_param( $::select_track->vol, 0);
}

pan: _pan dd end { $::copp{ $::select_track->pan }->[0] = $item{dd};
				::sync_effect_param( $::select_track->pan, 0);

} 
pan: _pan '+' dd end { $::copp{ $::select_track->pan }->[0] += $item{dd} ;
				::sync_effect_param( $::select_track->pan, 0);
} 
pan: _pan '-' dd end { $::copp{ $::select_track->pan }->[0] -= $item{dd} ;
				::sync_effect_param( $::select_track->pan, 0);
} 
pan: _pan end { print $::copp{$::select_track->pan}[0], $/ }
 
pan_right: _pan_right   end { $::copp{ $::select_track->pan }->[0] = 100;
				::sync_effect_param( $::select_track->pan, 0);
}
pan_left:  _pan_left    end { $::copp{ $::select_track->pan }->[0] = 0; 
				::sync_effect_param( $::select_track->pan, 0);
}
pan_center: _pan_center end { $::copp{ $::select_track->pan }->[0] = 50   ;
				::sync_effect_param( $::select_track->pan, 0);
}
pan_back:  _pan_back end {}

list_marks: _list_marks end {'TODO' }

remove_mark: _remove_mark end {'TODO' }

mark: _mark end { }

next_mark: _next_mark end {}

previous_mark: _previous_mark end {}

mark_loop: _mark_loop end {}

name_mark: _name_mark end {}

list_marks: _list_marks end {}

show_effects: _show_effects end {}

add_effect: _add_effect '-' name ':' dd(s? /,/)  end { 
	my %p = (
		chain => $::select_track->n,
		values => @{$item{dd}},
		type => $item{name},
		);
	::add_effect( \%p );
}

fx: '-' name ':' parameter(s? /,/)  

group_version: _group_version dd end { $::tracker->set( version => $item{dd} )}

list_versions: _list_versions end { 
	print join " ", @{$::select_track->versions}, $/;
}
