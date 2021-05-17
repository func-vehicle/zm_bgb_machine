#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_equipment;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_unitrigger;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;

#insert scripts\zm\_zm_utility.gsh;

#insert scripts\zm\_zm_bgb_machine.gsh;

#precache( "triggerstring", "ZOMBIE_BGB_MACHINE_OFFERING" );
#precache( "triggerstring", "ZOMBIE_BGB_MACHINE_COMEBACK" );
#precache( "triggerstring", "ZOMBIE_BGB_MACHINE_AVAILABLE" );
#precache( "triggerstring", "ZOMBIE_BGB_MACHINE_AVAILABLE_CFILL" );

#namespace bgb_machine;


REGISTER_SYSTEM_EX( "bgb_machine", &__init__, &__main__, undefined )

function __init__()
{
	callback::on_connect(&on_player_connect);
	
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_CF_NAME, VERSION_SHIP, 1, "int" );
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_FX_STATE_CF_NAME, VERSION_SHIP, 3, "int" );
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_LIMIT_TYPE_CF_NAME, VERSION_SHIP, 2, "int" );
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_RARITY_CF_NAME, VERSION_SHIP, 3, "int" );
	clientfield::register( "toplayer", ZM_BGB_MACHINE_PLAYER_BUYS_CF_NAME, VERSION_SHIP, 3, "int" );

	// We need to register this clientfield for the original machine script as it gets set by zm\_zm_bgb.gsc
	clientfield::register( "toplayer", ZM_BGB_MACHINE_LEGACY_CF_NAME, VERSION_SHIP, 3, "int" );
}

function __main__()
{
	DEFAULT(level.bgb_zbarrier_state_func, &process_bgb_zbarrier_state);

	// Number of active BGB machines (-1 means all machines, and they won't move)
	if ( !IsDefined(level.num_active_bgb_machines) )
	{
		level.num_active_bgb_machines = -1;
	}
	else if ( level.num_active_bgb_machines >= level.bgb_machines_fix.size || level.num_active_bgb_machines < 0 )
	{
		level.num_active_bgb_machines = -1;
	}
	
	// Disable movement of BGB machines
	DEFAULT(level.disable_bgb_machines_moving, false);
	
	// Remove BGBs that only function in coop if solo
	DEFAULT(level.remove_coop_bgbs_in_solo, true);
	
	// Use player's BGB pack
	DEFAULT(level.use_players_bgb_pack, false);

	// Load BGBs from CSV
	setup_bgbs();

	// Set up the BGB machines
	level.bgb_machines_fix = struct::get_array( "bgb_machine_use", "targetname" );
	bgb_machine_init();
	
	if ( zm_utility::is_Classic() && level.enable_magic )
	{
		thread fire_sale_listener();

		WAIT_SERVER_FRAME;  // Wait for initialization stage to end so we can toggle client fields

		foreach (machine in level.bgb_machines_fix)
		{
			machine.zbarrier clientfield::set(ZM_BGB_MACHINE_CF_NAME, 1);
			machine.zbarrier thread set_bgb_zbarrier_state("away");
		}

		// Activate the BGB machines after small delay
		level flag::wait_till( "initial_blackscreen_passed" );
		wait(3.0);
		
		level.active_bgb_machines = [];
		initial_machines = [];
		
		if (level.num_active_bgb_machines == -1)
		{
			// Enable every BGB machine
			initial_machines = level.bgb_machines_fix;
		}
		else
		{
			// Enable some BGB machines
			machines_with_flag = [];
			machines_without_flag = [];
			
			// Separate machines with initial flag from those without after randomizing array
			foreach (machine in array::randomize(level.bgb_machines_fix) )
			{
				if ( IsDefined(machine.script_string) )
				{
					array::add(machines_with_flag, machine);
				}
				else
				{
					array::add(machines_without_flag, machine);
				}
			}
			
			// Combine arrays, machines with flag have priority
			random_prioritized_machines = ArrayCombine(machines_with_flag, machines_without_flag, true, false);
			
			// Add to initial array
			for (i = 0; i < level.num_active_bgb_machines; i++)
			{
				machine = random_prioritized_machines[i];
				array::add(initial_machines, machine);
			}
		}
		
		// Activate machines in inital array
		foreach (machine in initial_machines)
		{
			array::add(level.active_bgb_machines, machine);
			machine.zbarrier thread set_bgb_zbarrier_state("arriving");
			machine.active = true;
		}
	}
}

function bgb_machine_init()
{
	for ( i = 0; i < level.bgb_machines_fix.size; i++ )
	{
		level.bgb_machines_fix[i] get_machine_pieces();
		
		level.bgb_machines_fix[i].use_count = 0;
		level.bgb_machines_fix[i].active = false;
		level.bgb_machines_fix[i].fire_sale = false;
	}
	
	array::thread_all( level.bgb_machines_fix, &bgb_machine_think );
}

function get_machine_pieces()
{
	min_distance = undefined;
	closest_zbarrier = undefined;
	
	zbarrier_noteworthy = self.script_noteworthy + "_zbarrier";
	zbarriers = GetEntArray( zbarrier_noteworthy, "script_noteworthy" );
	
	foreach (zbarrier in zbarriers)
	{
		distance = Distance2DSquared(self.origin, zbarrier.origin);
		if ( !IsDefined(min_distance) )
		{
			closest_zbarrier = zbarrier;
			min_distance = distance;
		}
		else if (distance < min_distance)
		{
			closest_zbarrier = zbarrier;
			min_distance = distance;
		}
	}
	
	self.zbarrier = closest_zbarrier;
	
	self.unitrigger_stub = SpawnStruct();
	self.unitrigger_stub.origin = self.origin;
	self.unitrigger_stub.angles = self.angles;
	self.unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
	self.unitrigger_stub.script_width = 45;
	self.unitrigger_stub.script_height = 72;
	self.unitrigger_stub.script_length = 45;
	self.unitrigger_stub.trigger_target = self;
	
	zm_unitrigger::unitrigger_force_per_player_triggers(self.unitrigger_stub, true);
	self.unitrigger_stub.prompt_and_visibility_func = &machinetrigger_update_prompt;
	
	self.zbarrier.owner = self;
}

function machinetrigger_update_prompt( player )
{
	can_use = self machinestub_update_prompt( player );
	if ( IsDefined(self.hint_string) )
	{
		if ( IsDefined(self.hint_parm1) )
			self SetHintString( self.hint_string, self.hint_parm1 );
		else
			self SetHintString( self.hint_string );
	}
	return can_use;
}

function machinestub_update_prompt( player )
{
	if (!self trigger_visible_to_player( player ))
		return false;
	
	cost = self.stub.trigger_target determine_cost(player);
	
	if (self.stub.trigger_target.bgb_string == "take")
	{
		self SetCursorHint( "HINT_BGB", self.stub.trigger_target.bgb_chosen.stat_index );
		self.hint_string = &"ZOMBIE_BGB_MACHINE_OFFERING";
	}
	else if (cost === false)
	{
		self SetCursorHint( "HINT_NOICON" );
		self.hint_string = &"ZOMBIE_BGB_MACHINE_COMEBACK";
	}
	else
	{
		self SetCursorHint( "HINT_NOICON" );
		// NO CFILL
		//self.hint_parm1 = cost;
		//self.hint_string = &"ZOMBIE_BGB_MACHINE_AVAILABLE";
		// CFILL
		self.hint_string = &"ZOMBIE_BGB_MACHINE_AVAILABLE_CFILL";
	}
	
	return true;
}

function trigger_visible_to_player(player)
{
	self SetInvisibleToPlayer(player);

	visible = true;	
	
	if ( !zm_perks::vending_trigger_can_player_use(player) )
	{
		visible = false;
	}
	else if ( IsDefined(self.stub.trigger_target.bgb_user) )
	{
		bgb_user = self.stub.trigger_target.bgb_user;
		if ( player != bgb_user || zm_utility::is_placeable_mine( bgb_user GetCurrentWeapon() ) || bgb_user zm_equipment::hacker_active())
		{
			visible = false;
		}
	}
	
	if ( !visible )
	{
		return false;
	}
	
	self SetVisibleToPlayer(player);
	return true;
}

function bgb_unitrigger_think()
{
	self endon("kill_trigger");

	for(;;)
	{
		self waittill( "trigger", player );
		self.stub.trigger_target notify("trigger", player);
	}
}

function setup_bgbs()
{
	index = 1;
	table = "gamedata/weapons/zm/zm_levelcommon_bgb.csv";
	
	row = TableLookupRow( table, index );
	while ( IsDefined( row ) )
	{
		name			= zm_weapons::checkStringValid( row[ BGB_TABLE_COL_NAME ] );
		stat_index 		= int( row[ BGB_TABLE_COL_STAT_INDEX ] );
		camo_index		= int( row[ BGB_TABLE_COL_CAMO_INDEX ] );
		limit_type		= int( row[ BGB_TABLE_COL_LIMIT_TYPE ] );
		rarity			= int( row[ BGB_TABLE_COL_RARITY ] );
		coop_only		= ( ToLower( row[ BGB_TABLE_COL_COOP_ONLY ] ) == "true" );
		weight			= float( row[ BGB_TABLE_COL_WEIGHT ] );
		
		add_zombie_bgb(name, stat_index, camo_index, limit_type, rarity, coop_only, weight);
		
		index++;
		row = TableLookupRow( table, index );
	}
	
	/#
	println("Loaded "+(index-1)+" BGBs");
	#/
}

function add_zombie_bgb(name, stat_index, camo_index, limit_type, rarity, coop_only, weight)
{
	struct = SpawnStruct();
	
	if ( !IsDefined( level.zombie_bgbs ) )
	{
		level.zombie_bgbs = [];
		level.zombie_bgbs_solo = [];
	}
	
	if (weight < 0)
		weight = 0;
	
	struct.name = name;
	struct.stat_index = stat_index;
	struct.camo_index = camo_index;
	struct.limit_type = limit_type;
	struct.rarity = rarity;
	struct.coop_only = coop_only;
	struct.weight = weight;
	
	level.zombie_bgbs[name] = struct;
	if (!coop_only)
	{
		level.zombie_bgbs_solo[name] = struct;
	}
}

function bgb_machine_think()
{
	self endon("kill_bgb_machine_think");

	player = undefined;
	self.bgb_user = undefined;
	self.bgb_string = "buy";
	
	for(;;)
	{
		// BGB machine idle
		self waittill( "trigger", player );
		if (player == level)
			continue;
		
		// Player interacts with machine
		cost = self determine_cost(player);
		if (cost === false)
			continue;
		
		if ( !player zm_score::can_player_purchase( cost ) )
		{
			zm_utility::play_sound_at_pos("no_purchase", self.origin);
			player zm_audio::create_and_play_dialog( "general", "outofmoney" );
			continue;
		}
		
		// Player has bought a BGB
		self.bgb_user = player;
		thread zm_unitrigger::unregister_unitrigger(self.unitrigger_stub);
		self.use_count++;
		
		player.bgb_machine_use_count++;
		player clientfield::set_to_player(ZM_BGB_MACHINE_PLAYER_BUYS_CF_NAME, player.bgb_machine_use_count);
		player zm_score::minus_to_player_score( cost );
		
		// Decide the BGB to give
		self.bgb_chosen = determine_bgb(player);
		
		// Begin dispensing
		self.zbarrier thread set_bgb_zbarrier_state("dispense");
		
		self.zbarrier waittill("dispensed");
		
		// BGB ready to be taken
		self.bgb_string = "take";
		thread zm_unitrigger::register_static_unitrigger(self.unitrigger_stub, &bgb_unitrigger_think);
		
		reason = self util::waittill_any_timeout( 5.5, "trigger" );
		if (reason == "trigger")
		{
			// The BGB was taken by the player
			self.zbarrier thread set_bgb_zbarrier_state("bgb_taken");
			player thread give_bgb_with_animation(self.bgb_chosen.name);
		}
		
		// Wait until dispense related animations are complete
		thread zm_unitrigger::unregister_unitrigger(self.unitrigger_stub);
		self.zbarrier waittill("dispense_complete");
		
		// Don't count as a use for this machine during fire sale
		if (self.fire_sale)
			self.use_count--;
		
		// Reset variables
		self.zbarrier thread set_bgb_zbarrier_state("idle");
		player = undefined;
		self.bgb_user = undefined;
		self.bgb_string = "buy";
		
		if (!level.zombie_vars["zombie_powerup_fire_sale_on"])
		{
			self.fire_sale = false;
		}
		
		// Determine if BGB machine should move
		if (!self.active && !level.zombie_vars["zombie_powerup_fire_sale_on"])
		{
			self.zbarrier thread set_bgb_zbarrier_state("leaving");
			self.use_count = 0;
		}
		else if ( self bgb_machine_should_move() )
		{
			self thread bgb_machine_move();
		}
		else
		{
			wait(0.5);
			thread zm_unitrigger::register_static_unitrigger(self.unitrigger_stub, &bgb_unitrigger_think);
		}
	}
}

function private on_player_connect()
{
	self.bgb_machine_use_count = 0;
	self thread reset_on_new_round();
}

// Reset BGB machine uses at start of new round
function private reset_on_new_round()
{
	self endon("disconnect");
	
	for(;;)
	{
		level waittill( "between_round_over" );
		self.bgb_machine_use_count = 0;
		self clientfield::set_to_player(ZM_BGB_MACHINE_PLAYER_BUYS_CF_NAME, 0);
	}
}

// Determines cost of machine (false = reached round limit)
// Should mirror the cost function in CSC if using CFILL
function determine_cost(player)
{
	// Treyarch's original cost function
	round_bracket = Int(Floor(level.round_number / 10.0));
	round_bracket = Min(round_bracket, 10);
	
	if (level.zombie_vars["zombie_powerup_fire_sale_on"])
		base_cost = 10;
	else
		base_cost = ZM_BGB_MACHINE_COST;
	
	switch(player.bgb_machine_use_count)
	{
		case 0:
			cost = base_cost;
			break;
		case 1:
			cost = Int( base_cost + 1000 * pow(2, round_bracket) );
			break;
		case 2:
			cost = Int( 500 + base_cost + 1000 * pow(2, round_bracket + 1) );
			break;
		default:
			cost = false;
			break;
	}
	
	return cost;
}

// Determines the BGB the player will receive
function determine_bgb(player)
{
	if (level.use_players_bgb_pack)
	{
        // Default this just in case, but should be already initialized by zm\_zm_bgb.gsc
        DEFAULT( player.bgb_pack, player GetBubbleGumPack() );

		// Treyarch's 5 BGB cycle using player's pack
		if ( !IsDefined(player.bgb_pack_randomized) || player.bgb_pack_randomized.size == 0 )
		{
			player.bgb_pack_randomized = array::randomize( player.bgb_pack );
		}
		
		key = array::pop_front(player.bgb_pack_randomized);
	}
	else
	{
		// Random BGB from pool (weighted)
		arr = level.zombie_bgbs;
		players = GetPlayers();
		if (players.size == 1 && level.remove_coop_bgbs_in_solo)
		{
			arr = level.zombie_bgbs_solo;
		}
		
		sigma_weight = 0;
		foreach (bgb in GetArrayKeys(arr))
		{
			sigma_weight += arr[bgb].weight;
		}
		
		rng = RandomFloatRange(0, sigma_weight);
		running_total = 0;
		foreach (bgb in GetArrayKeys(arr))
		{
			running_total += arr[bgb].weight;
			if (running_total > rng)
			{
				key = bgb;
				break;
			}
		}
	}
	return level.zombie_bgbs[key];
}

// Determines if the BGB machine should move
function bgb_machine_should_move()
{
	if (level.num_active_bgb_machines == -1)
	{
		// Don't move if all BGB machines are active
		return false;
	}
	else if ( level.disable_bgb_machines_moving )
	{
		// Don't move if moving has been intentionally disabled
		return false;
	}
	// Move if used 3 (or more) times
	return self.use_count >= 3;
}

// Deactivates self and activates a new machine after a short delay
function bgb_machine_move()
{
	self.zbarrier thread set_bgb_zbarrier_state("leaving");
	self.use_count = 0;
	
	wait(10.0);
	
	potential_spots = array::exclude(level.bgb_machines_fix, level.active_bgb_machines);
	newly_active = array::random(potential_spots);
	
	level.active_bgb_machines = array::exclude(level.active_bgb_machines, self);
	array::add(level.active_bgb_machines, newly_active);
	if (newly_active.zbarrier.state == "away")
	{
		// If the machine is not away (fire sale), skip it
		newly_active.zbarrier thread set_bgb_zbarrier_state("arriving");
	}
	self.active = false;
	newly_active.active = true;
}

// Listen for fire sale
function private fire_sale_listener()
{
	for(;;)
	{
		level waittill( "fire_sale_on" );
		foreach (machine in level.bgb_machines_fix)
		{
			machine thread apply_fire_sale_to_machine();
		}
		level waittill( "fire_sale_off" );
		foreach (machine in level.bgb_machines_fix)
		{
			machine thread remove_fire_sale_from_machine();
		}
	}
}

function apply_fire_sale_to_machine()
{
	self.fire_sale = true;
	
	if (self.zbarrier.state == "away" || self.zbarrier.state == "leaving")
	{
		if (self.zbarrier.state == "leaving")
		{
			self.zbarrier waittill("away");
		}
		if (!level.zombie_vars["zombie_powerup_fire_sale_on"])  // Check fire sale still running
			return;
		
		self.zbarrier thread set_bgb_zbarrier_state("arriving");
	}
}

function remove_fire_sale_from_machine()
{
	// Machines that are currently in use will take care of themselves
	if (self.zbarrier.state == "idle")
	{
		self.fire_sale = false;
		if (!self.active)
		{
			thread zm_unitrigger::unregister_unitrigger(self.unitrigger_stub);
			self.zbarrier thread set_bgb_zbarrier_state("leaving");
		}
	}
}

// Play the 'eat' BGB animation and then enable BGB
function give_bgb_with_animation( bgb_name )
{
    bgb = level.zombie_bgbs[bgb_name];

	weapon = self give_bgb_weapon( bgb );
	evt = self util::waittill_any_return( "fake_death", "death", "player_downed", "weapon_change_complete", "perk_abort_drinking", "disconnect" );
	
	if ( self laststand::player_is_in_laststand() || IS_TRUE( self.intermission ) )
	{
		zm_utility::enable_player_move_states();
		return;
	}
	
	// Stop Flavor Hexed replacing taken BGB
	self notify("bgbs_consumed_hexed_users_override", bgb.name);
	
	self thread bgb::give( bgb.name );
	self take_bgb_weapon( weapon );
	
	if (bgb.limit_type == BGB_LIMIT_TYPE_ACTIVATED_INDEX)
	{
		self thread zm_audio::create_and_play_dialog("bgb", "buy");
	}
	else {
		self thread zm_audio::create_and_play_dialog("bgb", "eat");
	}
}

// Give the 'eat' BGB weapon to the player
function give_bgb_weapon( bgb )
{
	self zm_utility::increment_is_drinking();
	
	self zm_utility::disable_player_move_states(true);

	original_weapon = self GetCurrentWeapon();
	
	bgb_weapon = GetWeapon("zombie_bgb_grab");
	bgb_weapon = self GetBuildKitWeapon(bgb_weapon, false);
	weapon_options = self GetBuildKitWeaponOptions(bgb_weapon, bgb.camo_index);
	acvi = self GetBuildKitAttachmentCosmeticVariantIndexes( bgb_weapon, false );
	
	self GiveWeapon( bgb_weapon, weapon_options, acvi );
	self SwitchToWeapon( bgb_weapon );
	self PlaySound("zmb_bgb_powerup_default");

	return original_weapon;
}

// Take the 'eat' BGB weapon from the player
function take_bgb_weapon( original_weapon )
{
	self endon( "perk_abort_drinking" );

	Assert( !original_weapon.isPerkBottle );
	Assert( original_weapon != level.weaponReviveTool );

	self zm_utility::enable_player_move_states();
	
	weapon = GetWeapon("zombie_bgb_grab");
	
	if ( self laststand::player_is_in_laststand() || IS_TRUE( self.intermission ) )
	{
		self TakeWeapon(weapon);
		return;
	}

	self TakeWeapon(weapon);

	if ( self zm_utility::is_multiple_drinking() )
	{
		self zm_utility::decrement_is_drinking();
		return;
	}
	else if ( original_weapon != level.weaponNone && !zm_utility::is_placeable_mine( original_weapon ) && !zm_equipment::is_equipment_that_blocks_purchase( original_weapon ) )
	{
		self zm_weapons::switch_back_primary_weapon( original_weapon );
		if ( zm_utility::is_melee_weapon( original_weapon ) )
		{
			self zm_utility::decrement_is_drinking();
			return;
		}
	}
	else 
	{
		self zm_weapons::switch_back_primary_weapon();
	}

	self waittill( "weapon_change_complete" );
	
	if ( !self laststand::player_is_in_laststand() && !IS_TRUE( self.intermission ) )
	{
		self zm_utility::decrement_is_drinking();
	}
}

function set_bgb_zbarrier_state(state)
{
	for (i = 0; i < self GetNumZBarrierPieces(); i++)
	{
		self HideZBarrierPiece(i);
	}
	self notify("zbarrier_state_change");
	
	self [[ level.bgb_zbarrier_state_func ]](state);
}

function process_bgb_zbarrier_state(state)
{
	self notify(state);
	self.state = state;
	switch(state)
	{
		case "away":
			self ShowZBarrierPiece(ZM_BGB_MACHINE_AWAY_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);
			self thread bgb_away();
			break;
		case "arriving":
			self ShowZBarrierPiece(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX);
			self thread bgb_fill_machine();
			break;
		case "idle":
			self ShowZBarrierPiece(ZM_BGB_MACHINE_AWAY_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);
			self thread bgb_idle();
			break;
		case "dispense":
			self ShowZBarrierPiece(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_FLYING_GUMBALLS_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);
			self thread bgb_dispense();
			break;
		case "bgb_taken":
			self ShowZBarrierPiece(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);
			self thread bgb_taken();
			break;
		case "leaving":
			self ShowZBarrierPiece(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX);
			self ShowZBarrierPiece(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX);
			self thread bgb_empty_machine();
			break;
		default:
            if ( IsDefined(level.custom_bgb_machine_state_handler) )
			{
				self [[ level.custom_bgb_machine_state_handler ]]( state );
			}
			break;
	}
}

// Machine is disabled, idle
function bgb_away()
{
	self endon("zbarrier_state_change");

	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_AWAY );
	self SetZBarrierPieceState(ZM_BGB_MACHINE_BASE_PIECE_INDEX, "closed");
	
	for(;;)
	{
		// Play rare idle animations!
		wait( RandomFloatRange(180, 1800) );
		self SetZBarrierPieceState(ZM_BGB_MACHINE_AWAY_PIECE_INDEX, "opening");
		wait( RandomFloatRange(180, 1800) );
		self SetZBarrierPieceState(ZM_BGB_MACHINE_AWAY_PIECE_INDEX, "closing");
	}
}

// Machine is moving here (shaking, filling up)
function bgb_fill_machine()
{
	self endon("zbarrier_state_change");

	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_ARRIVING );
	self SetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX, "opening");
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX) == "opening")
	{
		WAIT_SERVER_FRAME;
	}
	self SetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX, "closing");
	self SetZBarrierPieceState(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX, "opening");
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX) == "closing")
	{
		WAIT_SERVER_FRAME;
	}
	thread zm_unitrigger::register_static_unitrigger(self.owner.unitrigger_stub, &bgb_unitrigger_think);
	self thread set_bgb_zbarrier_state("idle");
}

// Machine is active, idle
function bgb_idle()
{
	self endon("zbarrier_state_change");

	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_IDLE );
	self SetZBarrierPieceState(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX, "open");
	self SetZBarrierPieceState(ZM_BGB_MACHINE_BASE_PIECE_INDEX, "closed");
}

// Gumball is dispensed and waits for user to take it
// Swallows gumball if not taken (this is part of the opening animation of the lion head)
function bgb_dispense()
{
	self endon("zbarrier_state_change");
	self endon("bgb_taken");
	
	self clientfield::set( ZM_BGB_MACHINE_LIMIT_TYPE_CF_NAME, self.owner.bgb_chosen.limit_type );
	self clientfield::set( ZM_BGB_MACHINE_RARITY_CF_NAME, self.owner.bgb_chosen.rarity );
	self SetZBarrierPieceState(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX, "open");
	state = "opening";
	if (RandomInt(2) > 0)
	{
		state = "closing";
	}
	self SetZBarrierPieceState(ZM_BGB_MACHINE_FLYING_GUMBALLS_PIECE_INDEX, state);
	self SetZBarrierPieceState(ZM_BGB_MACHINE_BASE_PIECE_INDEX, "closed");
	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_DISPENSING );
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_FLYING_GUMBALLS_PIECE_INDEX) == state)
	{
		WAIT_SERVER_FRAME;
	}
	self SetZBarrierPieceState(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX, "opening");
	wait(1.0);
	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_READY );
	self notify("dispensed");
	wait(5.5);
	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_IDLE );
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX) == "opening")
	{
		WAIT_SERVER_FRAME;
	}
	
	self notify("dispense_complete");
}

// Gumball was taken by user
function bgb_taken()
{
	self endon("zbarrier_state_change");

	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_IDLE );
	self SetZBarrierPieceState(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX, "closing");
	self SetZBarrierPieceState(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX, "open");
	self SetZBarrierPieceState(ZM_BGB_MACHINE_BASE_PIECE_INDEX, "closed");
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX) == "closing")
	{
		WAIT_SERVER_FRAME;
	}
	
	self notify("dispense_complete");
}

// Machine is leaving here (shaking, emptying)
function bgb_empty_machine()
{
	self endon("zbarrier_state_change");

	self clientfield::set( ZM_BGB_MACHINE_FX_STATE_CF_NAME, ZM_BGB_MACHINE_FX_STATE_CF_LEAVING );
	self SetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX, "opening");
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX) == "opening")
	{
		WAIT_SERVER_FRAME;
	}
	self SetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX, "closing");
	self SetZBarrierPieceState(ZM_BGB_MACHINE_STATIC_GUMBALLS_PIECE_INDEX, "closing");
	while (self GetZBarrierPieceState(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX) == "closing")
	{
		WAIT_SERVER_FRAME;
	}
	self thread set_bgb_zbarrier_state("away");
}

// Functions from the original machine script that are called by zm\_zm_powerup_fire_sale.gsc
// TODO: use these instead of our method for fire sale?
function turn_on_fire_sale() {}
function turn_off_fire_sale() {}