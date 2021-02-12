#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_bgb_fix.gsh;

// BEGIN PRECACHE
#precache( "client_fx", "zombie/fx_bgb_machine_eye_activated_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_eye_event_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_eye_rounds_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_eye_time_zmb" );

#precache( "client_fx", "zombie/fx_bgb_machine_available_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_bulb_away_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_bulb_available_zmb" );

#precache( "client_fx", "zombie/fx_bgb_machine_bulb_activated_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_bulb_event_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_bulb_rounds_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_bulb_time_zmb" );

#precache( "client_fx", "zombie/fx_bgb_machine_bulb_spark_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_smoke_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_flying_embers_down_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_flying_embers_up_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_gumball_halo_zmb" );
#precache( "client_fx", "zombie/fx_bgb_gumball_ghost_zmb" );

#precache( "client_fx", "zombie/fx_bgb_machine_flying_elec_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_light_interior_zmb" );
#precache( "client_fx", "zombie/fx_bgb_machine_light_interior_away_zmb" );
// END PRECACHE

#namespace zm_bgb_fix;


REGISTER_SYSTEM( "zm_bgb_fix", &__init__, undefined )

function __init__()
{
	clientfield::register( "zbarrier", "bgb_machine", VERSION_SHIP, 1, "int", &machine_init_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "zbarrier", "bgb_machine_state", VERSION_SHIP, 4, "int", &bgb_machine_state_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "zbarrier", "bgb_machine_limit_type", VERSION_SHIP, 4, "int", &bgb_machine_limit_type_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "zbarrier", "bgb_machine_rarity", VERSION_SHIP, 4, "int", &bgb_machine_rarity_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "toplayer", "bgb_machine_buys", VERSION_SHIP, 3, "int", &bgb_machine_buys_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

	callback::on_localplayer_spawned(&on_player_spawned);

	DEFAULT(level.bgb_machine_buys, []);
	DEFAULT(level.bgb_cached_rounds, []);
	DEFAULT(level.bgb_cached_firesale, []);

	// Allow other scripts to override the FX
	DEFAULT(level._effect[ZM_BGB_MACHINE_EYE_ACTIVATED_FX_NAME], ZM_BGB_MACHINE_EYE_ACTIVATED_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_EYE_EVENT_FX_NAME], ZM_BGB_MACHINE_EYE_EVENT_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_EYE_ROUNDS_FX_NAME], ZM_BGB_MACHINE_EYE_ROUNDS_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_EYE_TIME_FX_NAME], ZM_BGB_MACHINE_EYE_TIME_FX);

	DEFAULT(level._effect[ZM_BGB_MACHINE_AVAILABLE_FX_NAME], ZM_BGB_MACHINE_AVAILABLE_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME], ZM_BGB_MACHINE_BULB_AWAY_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME], ZM_BGB_MACHINE_BULB_AVAILABLE_FX);

	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_ACTIVATED_FX_NAME], ZM_BGB_MACHINE_BULB_ACTIVATED_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_EVENT_FX_NAME], ZM_BGB_MACHINE_BULB_EVENT_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_ROUNDS_FX_NAME], ZM_BGB_MACHINE_BULB_ROUNDS_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_TIME_FX_NAME], ZM_BGB_MACHINE_BULB_TIME_FX);

	DEFAULT(level._effect[ZM_BGB_MACHINE_BULB_SPARK_FX_NAME], ZM_BGB_MACHINE_BULB_SPARK_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_SMOKE_FX_NAME], ZM_BGB_MACHINE_SMOKE_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_FLYING_EMBERS_UP_FX_NAME], ZM_BGB_MACHINE_FLYING_EMBERS_UP_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_FLYING_EMBERS_DOWN_FX_NAME], ZM_BGB_MACHINE_FLYING_EMBERS_DOWN_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_GUMBALL_HALO_FX_NAME], ZM_BGB_MACHINE_GUMBALL_HALO_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_GUMBALL_GHOST_FX_NAME], ZM_BGB_MACHINE_GUMBALL_GHOST_FX);

	DEFAULT(level._effect[ZM_BGB_MACHINE_FLYING_ELEC_FX_NAME], ZM_BGB_MACHINE_FLYING_ELEC_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], ZM_BGB_MACHINE_LIGHT_INTERIOR_FX);
	DEFAULT(level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX_NAME], ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX);
}

function private on_player_spawned( localClientNum )
{
	DEFAULT(level.bgb_machine_buys[localClientNum], 0);
	DEFAULT(level.bgb_cached_rounds[localClientNum], 1);
	DEFAULT(level.bgb_cached_firesale[localClientNum], 0);

	update_bgb_cost( localClientNum, level.bgb_cached_rounds[localClientNum], level.bgb_machine_buys[localClientNum], level.bgb_cached_firesale[localClientNum] );

	self thread round_monitor( localClientNum );
	self thread fire_sale_monitor( localClientNum );
}

// Initializes the machine
function private machine_init_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	if (IsDefined(self.initialized))
		return;

	self.initialized = true;

	DEFAULT( self.fx_array, [] );

	// Force stream XModels to prevent pop-in on first state change
	if (!IsDefined(level.has_force_streamed_bgb_machine_models))
	{
		n_pieces = self GetNumZBarrierPieces();
		for (i = 0; i < n_pieces; i++)
		{
			piece = self ZBarrierGetPiece(i);
			ForceStreamXModel(piece.model);
		}
		level.has_force_streamed_bgb_machine_models = true;
	}
}

// Sets the state of the ZBarrier
function private bgb_machine_state_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	self.state = newVal;
	switch(self.state)
	{
		case ZM_BGB_MACHINE_FX_STATE_CF_IDLE:
			self bgb_idle_callback( localClientNum );
			break;
		case ZM_BGB_MACHINE_FX_STATE_CF_DISPENSING:
			self bgb_dispensing_start_callback( localClientNum );
			break;
		case ZM_BGB_MACHINE_FX_STATE_CF_READY:
			self bgb_dispensing_ready_callback( localClientNum );
			break;
		case ZM_BGB_MACHINE_FX_STATE_CF_LEAVING:
			self bgb_moving_callback( localClientNum );
			break;
		case ZM_BGB_MACHINE_FX_STATE_CF_AWAY:
			self bgb_away_callback( localClientNum );
			break;
		case ZM_BGB_MACHINE_FX_STATE_CF_ARRIVING:
			self bgb_moving_callback( localClientNum );
			break;
	}
}

// Sets the limit type for the flying / dispensed gumball
function private bgb_machine_limit_type_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	switch(newVal)
	{
		case BGB_LIMIT_TYPE_ACTIVATED_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_ACTIVATED;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_ACTIVATED_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_ACTIVATED_FX_NAME];
			break;
		case BGB_LIMIT_TYPE_EVENT_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_EVENT;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_EVENT_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_EVENT_FX_NAME];
			break;
		case BGB_LIMIT_TYPE_ROUNDS_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_ROUNDS;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_ROUNDS_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_ROUNDS_FX_NAME];
			break;
		case BGB_LIMIT_TYPE_TIME_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_TIME;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_TIME_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_TIME_FX_NAME];
			break;
	}
}

// Sets the rarity of the dispensed gumball
function private bgb_machine_rarity_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	switch(newVal)
	{
		case BGB_RARITY_CLASSIC_INDEX:
			self.rarity = BGB_RARITY_CLASSIC_TAG;
			break;
		case BGB_RARITY_MEGA_INDEX:
			self.rarity = BGB_RARITY_MEGA_TAG;
			break;
		case BGB_RARITY_RARE_INDEX:
			self.rarity = BGB_RARITY_RARE_TAG;
			break;
		case BGB_RARITY_ULTRA_RARE_INDEX:
			self.rarity = BGB_RARITY_ULTRA_RARE_TAG;
			break;
		case BGB_RARITY_WHIMSICAL_INDEX:
			self.rarity = BGB_RARITY_WHIMSICAL_TAG;
			break;
	}
}

// Stores num. machine uses for calculate_cost()
function private bgb_machine_buys_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	level.bgb_machine_buys[localClientNum] = newVal;
	update_bgb_cost( localClientNum, level.bgb_cached_rounds[localClientNum], level.bgb_machine_buys[localClientNum], level.bgb_cached_firesale[localClientNum] );
}

// Stores round number for calculate_cost()
function private round_monitor( localClientNum )
{
	self notify("bgb_round_monitor_singleton");
	self endon("bgb_round_monitor_singleton");
	self endon("entityshutdown");

	for(;;)
	{
		rounds = GetRoundsPlayed(localClientNum);
		if (rounds != level.bgb_cached_rounds[localClientNum])
		{
			level.bgb_cached_rounds[localClientNum] = rounds;
			update_bgb_cost( localClientNum, level.bgb_cached_rounds[localClientNum], level.bgb_machine_buys[localClientNum], level.bgb_cached_firesale[localClientNum] );
		}
		wait(1);
	}
}

// Stores fire sale state for calculate_cost()
function private fire_sale_monitor( localClientNum )
{
	self notify("bgb_fire_sale_monitor_singleton");
	self endon("bgb_fire_sale_monitor_singleton");
	self endon("entityshutdown");

	for(;;)
	{
		self waittill("powerup", powerup, state);
		if (powerup == "powerup_fire_sale")
		{
			if (state > 0)
				state = 1;
			
			if (state != level.bgb_cached_firesale[localClientNum])
			{
				level.bgb_cached_firesale[localClientNum] = state;
				update_bgb_cost( localClientNum, level.bgb_cached_rounds[localClientNum], level.bgb_machine_buys[localClientNum], level.bgb_cached_firesale[localClientNum] );
			}
		}
	}
}

// Updates the CFILL string
function private update_bgb_cost( localClientNum, rounds, buys, firesale )
{
	cost = calculate_cost( localClientNum, rounds, buys, firesale);
	SetBGBCost(localClientNum, cost);
}

// Should mirror the cost function in GSC
function calculate_cost( localClientNum, rounds, buys, firesale )
{
	// Treyarch's original cost function
	round_bracket = Int(Floor(rounds / 10.0));
	round_bracket = Min(round_bracket, 10);
	
	if (firesale)
		base_cost = 10;
	else
		base_cost = 500;
	
	switch(buys)
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
			cost = 0;
			break;
	}
	
	return cost;
}

// Sets lion gumball and flying gumballs to correct type / rarity
function bgb_set_models( localClientNum )
{
	dispensed_gumball_model = self ZBarrierGetPiece(2);
	flying_gumball_model = self ZBarrierGetPiece(4);
		
	tag_location = "tag_gumball_"+self.limit_type+"_"+self.rarity;
	
	dispensed_gumball_model HidePart(localClientNum, "tag_gumballs", "p7_zm_zod_bubblegum_machine_lion_head_gumball", true);
	
	dispensed_gumball_model ShowPart(localClientNum, tag_location, "p7_zm_zod_bubblegum_machine_lion_head_gumball", true);
	
	limit_type_array = Array(BGB_LIMIT_TYPE_ACTIVATED, BGB_LIMIT_TYPE_EVENT, BGB_LIMIT_TYPE_ROUNDS, BGB_LIMIT_TYPE_TIME);
	
	flying_gumball_model HidePart(localClientNum, "tag_gumballs", "p7_zm_zod_bubblegum_machine_gumballs_flying", true);
	
	for (i = 0; i < 10; i++)
	{
		if (i == 0)
		{
			// The gumball that flies to the mouth
			random_type = self.limit_type;
		}
		else
		{
			// Other gumballs that fly around
			random_type = array::random( limit_type_array );
		}
		
		tag_location = "tag_gumball_"+random_type+"_"+i;
		
		flying_gumball_model ShowPart(localClientNum, tag_location, "p7_zm_zod_bubblegum_machine_gumballs_flying", true);
	}
}

// Handles playing most FX
function private bgb_play_fx( localClientNum, piece, fx_location, fx_name, array_index )
{
	// Can use a custom array index name instead of just fx_location
	DEFAULT(array_index, fx_location);

	if (IsDefined(self.fx_array[array_index]))
	{
		DeleteFX( localClientNum, self.fx_array[fx_location] );
		self.fx_array[array_index] = undefined;
	}

	if (IsDefined(fx_name))
	{
		self.fx_array[array_index] = PlayFXOnTag( localClientNum, fx_name, piece, fx_location );
	}
}

// Deletes FX created via bgb_play_fx()
function private bgb_cleanup_all_fx( localClientNum )
{
	foreach( fx in self.fx_array )
	{
		DeleteFX( localClientNum, fx );
	}
	self.fx_array = [];
}

function private play_sound_on_top_light( localClientNum, alias )
{
	piece = self ZBarrierGetPiece(5);
	origin = piece GetTagOrigin("tag_fx_light_top_jnt");
	playsound(localClientNum, alias, origin);
}

function bgb_idle_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	piece_5 = self ZBarrierGetPiece(5);

	self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], "light_interior");

	// This FX does the 115 pattern automatically
	self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_AVAILABLE_FX_TAG, level._effect[ZM_BGB_MACHINE_AVAILABLE_FX_NAME], "available");
	
	// Manual 115 pattern (timing is slightly off)
	/*for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.45 );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.45 );
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.45 );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.45 );
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.45 );
	}*/
}

function bgb_dispensing_start_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );
	
	self bgb_set_models( localClientNum );

	piece_2 = self ZBarrierGetPiece(2);
	piece_5 = self ZBarrierGetPiece(5);

	self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], "light_interior");
	
	self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_FLYING_ELEC_FX_TAG, level._effect[ZM_BGB_MACHINE_FLYING_ELEC_FX_NAME], "flying_elec");
	
	for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.2 );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.2 );
	}
}

function bgb_dispensing_ready_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	piece_2 = self ZBarrierGetPiece(2);
	piece_5 = self ZBarrierGetPiece(5);

	self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], "light_interior");

	self bgb_play_fx(localClientNum, piece_2, ZM_BGB_MACHINE_GUMBALL_HALO_FX_TAG, level._effect[ZM_BGB_MACHINE_GUMBALL_HALO_FX_NAME]);
	
	self bgb_play_fx(localClientNum, piece_2, ZM_BGB_MACHINE_EYE_FX_TAG_LEFT, self.eye_fx);
	self bgb_play_fx(localClientNum, piece_2, ZM_BGB_MACHINE_EYE_FX_TAG_RIGHT, self.eye_fx);
	
	for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_ready" );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, self.limit_type_fx);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, self.limit_type_fx);
		util::server_wait( localClientNum, 0.4 );
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.4 );
	}
}

function bgb_away_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	piece_1 = self ZBarrierGetPiece(1);

	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX_NAME], "light_interior");
	
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
}

function bgb_moving_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	piece_1 = self ZBarrierGetPiece(1);
	
	self thread bgb_moving_extra_fx( localClientNum );

	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX_NAME], "light_interior");
	
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_EYE_FX_TAG_LEFT, ZM_BGB_MACHINE_EYE_AWAY_FX);
	self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_EYE_FX_TAG_RIGHT, ZM_BGB_MACHINE_EYE_AWAY_FX);
	
	for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_leaving" );
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, piece_1, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.4 );
	}
}

function private bgb_moving_extra_fx( localClientNum )
{
	util::server_wait( localClientNum, 2.5 );

	piece_1 = self ZBarrierGetPiece(1);
	piece_5 = self ZBarrierGetPiece(5);
	
	self.fx_array["smoke"] = PlayFX( localClientNum, level._effect[ZM_BGB_MACHINE_SMOKE_FX_NAME], self.origin, AnglesToUp( self.angles ), AnglesToRight( self.angles ) );
	self thread bgb_moving_sparks( localClientNum, piece_1 );

	if (self.state == ZM_BGB_MACHINE_FX_STATE_CF_LEAVING)
	{
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_FLYING_EMBERS_FX_TAG, level._effect[ZM_BGB_MACHINE_FLYING_EMBERS_DOWN_FX_NAME], "embers");
	}
	else
	{
		self bgb_play_fx(localClientNum, piece_5, ZM_BGB_MACHINE_FLYING_EMBERS_FX_TAG, level._effect[ZM_BGB_MACHINE_FLYING_EMBERS_UP_FX_NAME], "embers");
	}
}

function private bgb_moving_sparks( localClientNum, piece )
{
	piece endon("opened");
	piece endon("closed");

	bulb_tags = Array( ZM_BGB_MACHINE_BULB_FX_TAG_TOP, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT );
	bulb_tags = Array::randomize(bulb_tags);

	for (i = 0; i < bulb_tags.size; i++)
	{
		// The bulb has a 2/3 chance of sparking
		if (RandomIntRange(0, 4))
		{
			self bgb_play_fx(localClientNum, piece, bulb_tags[i], level._effect[ZM_BGB_MACHINE_BULB_SPARK_FX_NAME], "bulb_spark_"+i);
		}
		// Wait a random short period
		wait_time = RandomFloatRange(0, 0.2);
		if (wait_time)
		{
			util::server_wait( localClientNum, wait_time );
		}
	}
}
