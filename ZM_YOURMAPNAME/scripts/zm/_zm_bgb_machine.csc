#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_bgb_machine.gsh;

#precache( "client_fx", ZM_BGB_MACHINE_EYE_AWAY_FX );

#precache( "client_fx", ZM_BGB_MACHINE_EYE_ACTIVATED_FX );
#precache( "client_fx", ZM_BGB_MACHINE_EYE_EVENT_FX );
#precache( "client_fx", ZM_BGB_MACHINE_EYE_ROUNDS_FX );
#precache( "client_fx", ZM_BGB_MACHINE_EYE_TIME_FX );

#precache( "client_fx", ZM_BGB_MACHINE_AVAILABLE_FX );
#precache( "client_fx", ZM_BGB_MACHINE_BULB_AWAY_FX );
#precache( "client_fx", ZM_BGB_MACHINE_BULB_AVAILABLE_FX );

#precache( "client_fx", ZM_BGB_MACHINE_BULB_ACTIVATED_FX );
#precache( "client_fx", ZM_BGB_MACHINE_BULB_EVENT_FX );
#precache( "client_fx", ZM_BGB_MACHINE_BULB_ROUNDS_FX );
#precache( "client_fx", ZM_BGB_MACHINE_BULB_TIME_FX );

#precache( "client_fx", ZM_BGB_MACHINE_BULB_SPARK_FX );
#precache( "client_fx", ZM_BGB_MACHINE_SMOKE_FX );
#precache( "client_fx", ZM_BGB_MACHINE_FLYING_EMBERS_DOWN_FX );
#precache( "client_fx", ZM_BGB_MACHINE_FLYING_EMBERS_UP_FX );

#precache( "client_fx", ZM_BGB_MACHINE_GUMBALL_HALO_FX );
#precache( "client_fx", ZM_BGB_MACHINE_GUMBALL_GHOST_FX );

#precache( "client_fx", ZM_BGB_MACHINE_FLYING_ELEC_FX );
#precache( "client_fx", ZM_BGB_MACHINE_LIGHT_INTERIOR_FX );
#precache( "client_fx", ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX );

#namespace bgb_machine;


REGISTER_SYSTEM( "bgb_machine", &__init__, undefined )

function __init__()
{
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_CF_NAME, VERSION_SHIP, 1, "int", &machine_init_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_FX_STATE_CF_NAME, VERSION_SHIP, 3, "int", &bgb_machine_state_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_LIMIT_TYPE_CF_NAME, VERSION_SHIP, 2, "int", &bgb_machine_limit_type_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "zbarrier", ZM_BGB_MACHINE_RARITY_CF_NAME, VERSION_SHIP, 3, "int", &bgb_machine_rarity_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );
	clientfield::register( "toplayer", ZM_BGB_MACHINE_PLAYER_BUYS_CF_NAME, VERSION_SHIP, 3, "int", &bgb_machine_buys_callback, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

    // We need to register this clientfield for the original machine script as it gets set by zm\_zm_bgb.gsc
    clientfield::register( "toplayer", ZM_BGB_MACHINE_LEGACY_CF_NAME, VERSION_SHIP, 3, "int", undefined, !CF_HOST_ONLY, !CF_CALLBACK_ZERO_ON_NEW_ENT );

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
	self thread play_bgb_machine_roars( localClientNum );
}

// Initializes the machine
function private machine_init_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	if (IS_TRUE(self.initialized))
		return;

	DEFAULT( level.bgb_machine_zbarriers, [] );
	array::add(level.bgb_machine_zbarriers, self);

	// Default rarity and limit_type to CF zero value as clientfield will not callback on zero initially
	DEFAULT( self.rarity, BGB_RARITY_CLASSIC_TAG );
	DEFAULT( self.limit_type, BGB_LIMIT_TYPE_ACTIVATED_TAG );

	DEFAULT( self.fx_array, [] );

	self.initialized = true;

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
			self.limit_type = BGB_LIMIT_TYPE_ACTIVATED_TAG;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_ACTIVATED_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_ACTIVATED_FX_NAME];
			break;
		case BGB_LIMIT_TYPE_EVENT_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_EVENT_TAG;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_EVENT_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_EVENT_FX_NAME];
			break;
		case BGB_LIMIT_TYPE_ROUNDS_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_ROUNDS_TAG;
			self.limit_type_fx = level._effect[ZM_BGB_MACHINE_BULB_ROUNDS_FX_NAME];
			self.eye_fx = level._effect[ZM_BGB_MACHINE_EYE_ROUNDS_FX_NAME];
			break;
		case BGB_LIMIT_TYPE_TIME_INDEX:
			self.limit_type = BGB_LIMIT_TYPE_TIME_TAG;
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

// Stores number of player machine uses for determine_cost()
function private bgb_machine_buys_callback( localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump )
{
	level.bgb_machine_buys[localClientNum] = newVal;
	update_bgb_cost( localClientNum, level.bgb_cached_rounds[localClientNum], level.bgb_machine_buys[localClientNum], level.bgb_cached_firesale[localClientNum] );
}

// Stores round number for determine_cost()
function private round_monitor( localClientNum )
{
	self notify("kill_bgb_round_monitor");
	self endon("kill_bgb_round_monitor");
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

// Stores fire sale state for determine_cost()
function private fire_sale_monitor( localClientNum )
{
	self notify("kill_bgb_fire_sale_monitor");
	self endon("kill_bgb_fire_sale_monitor");
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

// Plays the roar sound effect occasionally when the player approaches a machine
function private play_bgb_machine_roars(localClientNum)
{
	self endon("entityshutdown");

	tell_distance_sqr = SQR(ZM_BGB_MACHINE_AUDIO_TELL_DISTANCE);
	for(;;)
	{
		if ( IsDefined(level.bgb_machine_zbarriers) )
		{
			foreach (zbarrier in level.bgb_machine_zbarriers)
			{
				if ( DistanceSquared(self.origin, zbarrier.origin) <= tell_distance_sqr && Abs(self.origin[2] - zbarrier.origin[2]) < ZM_BGB_MACHINE_AUDIO_TELL_HEIGHT_THRESHOLD )
				{
					wait_time = RandomIntRange(1, 4);
					util::server_wait( localClientNum, wait_time );
					zbarrier PlaySound(localClientNum, "zmb_bgb_lionhead_roar");
					util::server_wait( localClientNum, ZM_BGB_MACHINE_AUDIO_TELL_COOLDOWN );
					break;
				}
			}
		}
		util::server_wait( localClientNum, 1 );
	}
}

// Updates the CFILL string
function private update_bgb_cost( localClientNum, rounds, buys, firesale )
{
	cost = determine_cost( localClientNum, rounds, buys, firesale);
	SetBGBCost(localClientNum, cost);
}

// Should mirror the cost function in GSC
function determine_cost( localClientNum, rounds, buys, firesale )
{
	// Treyarch's original cost function
	round_bracket = Int(Floor(rounds / 10.0));
	round_bracket = Min(round_bracket, 10);
	
	if (firesale)
		base_cost = 10;
	else
		base_cost = ZM_BGB_MACHINE_COST;
	
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
	give_gumball_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX);
	flying_gumball_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_FLYING_GUMBALLS_PIECE_INDEX);
		
	tag_location = "tag_gumball_"+self.limit_type+"_"+self.rarity;
	
	give_gumball_piece HidePart(localClientNum, "tag_gumballs", "p7_zm_zod_bubblegum_machine_lion_head_gumball", true);
	give_gumball_piece ShowPart(localClientNum, tag_location, "p7_zm_zod_bubblegum_machine_lion_head_gumball", true);
	
	limit_type_array = Array(BGB_LIMIT_TYPE_ACTIVATED_TAG, BGB_LIMIT_TYPE_EVENT_TAG, BGB_LIMIT_TYPE_ROUNDS_TAG, BGB_LIMIT_TYPE_TIME_TAG);
	
	flying_gumball_piece HidePart(localClientNum, "tag_gumballs", "p7_zm_zod_bubblegum_machine_gumballs_flying", true);
	
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
		
		flying_gumball_piece ShowPart(localClientNum, tag_location, "p7_zm_zod_bubblegum_machine_gumballs_flying", true);
	}
}

// Handles playing most FX
function private bgb_play_fx( localClientNum, piece, fx_location, fx_name, array_index )
{
	// Can use a custom array index name instead of just fx_location
	DEFAULT(array_index, fx_location);

	if (IsDefined(self.fx_array[array_index]))
	{
		DeleteFX( localClientNum, self.fx_array[array_index] );
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
	foreach ( fx in self.fx_array )
	{
		DeleteFX( localClientNum, fx );
	}
	self.fx_array = [];
}

function private play_sound_on_top_light( localClientNum, alias )
{
	base_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);
	origin = base_piece GetTagOrigin("tag_fx_light_top_jnt");
	PlaySound( localClientNum, alias, origin );
}

function bgb_idle_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	base_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);

	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], "light_interior");

	// This FX does the 115 pattern automatically
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_AVAILABLE_FX_TAG, level._effect[ZM_BGB_MACHINE_AVAILABLE_FX_NAME], "available");
}

function bgb_dispensing_start_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );
	
	self bgb_set_models( localClientNum );

	base_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);

	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], "light_interior");
	
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_FLYING_ELEC_FX_TAG, level._effect[ZM_BGB_MACHINE_FLYING_ELEC_FX_NAME], "flying_elec");
	
	for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_click" );
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AVAILABLE_FX_NAME]);
		util::server_wait( localClientNum, 0.2 );
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.2 );
	}
}

function bgb_dispensing_ready_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	give_gumball_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_GIVE_GUMBALL_PIECE_INDEX);
	base_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);

	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_NAME], "light_interior");

	self bgb_play_fx(localClientNum, give_gumball_piece, ZM_BGB_MACHINE_GUMBALL_HALO_FX_TAG, level._effect[ZM_BGB_MACHINE_GUMBALL_HALO_FX_NAME]);
	
	self bgb_play_fx(localClientNum, give_gumball_piece, ZM_BGB_MACHINE_EYE_FX_TAG_LEFT, self.eye_fx);
	self bgb_play_fx(localClientNum, give_gumball_piece, ZM_BGB_MACHINE_EYE_FX_TAG_RIGHT, self.eye_fx);
	
	for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_ready" );
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, self.limit_type_fx);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, self.limit_type_fx);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, self.limit_type_fx);
		util::server_wait( localClientNum, 0.4 );
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.4 );
	}
}

function bgb_away_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	base_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);

	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX_NAME], "light_interior");
	
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
	self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
}

function bgb_moving_callback( localClientNum )
{
	self notify("bgb_change_state");
	self endon("bgb_change_state");
	
	self bgb_cleanup_all_fx( localClientNum );

	shake_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX);
	
	self thread bgb_moving_extra_fx( localClientNum );

	self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_LIGHT_INTERIOR_FX_TAG, level._effect[ZM_BGB_MACHINE_LIGHT_INTERIOR_AWAY_FX_NAME], "light_interior");
	
	self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_EYE_FX_TAG_LEFT, ZM_BGB_MACHINE_EYE_AWAY_FX);
	self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_EYE_FX_TAG_RIGHT, ZM_BGB_MACHINE_EYE_AWAY_FX);
	
	for(;;)
	{
		self play_sound_on_top_light( localClientNum, "zmb_bgb_machine_light_leaving" );
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, level._effect[ZM_BGB_MACHINE_BULB_AWAY_FX_NAME]);
		util::server_wait( localClientNum, 0.4 );
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_TOP, undefined);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_LEFT, undefined);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_TOP_RIGHT, undefined);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_LEFT, undefined);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_MID_RIGHT, undefined);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_LEFT, undefined);
		self bgb_play_fx(localClientNum, shake_piece, ZM_BGB_MACHINE_BULB_FX_TAG_SIDE_BTM_RIGHT, undefined);
		util::server_wait( localClientNum, 0.4 );
	}
}

function private bgb_moving_extra_fx( localClientNum )
{
	self endon("bgb_change_state");

	util::server_wait( localClientNum, 2.5 );

	shake_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_SHAKE_PIECE_INDEX);
	base_piece = self ZBarrierGetPiece(ZM_BGB_MACHINE_BASE_PIECE_INDEX);
	
	self.fx_array["smoke"] = PlayFX( localClientNum, level._effect[ZM_BGB_MACHINE_SMOKE_FX_NAME], self.origin, AnglesToUp( self.angles ), AnglesToRight( self.angles ) );
	self thread bgb_moving_sparks( localClientNum, shake_piece );

	if (self.state == ZM_BGB_MACHINE_FX_STATE_CF_LEAVING)
	{
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_FLYING_EMBERS_FX_TAG, level._effect[ZM_BGB_MACHINE_FLYING_EMBERS_DOWN_FX_NAME], "embers");
	}
	else
	{
		self bgb_play_fx(localClientNum, base_piece, ZM_BGB_MACHINE_FLYING_EMBERS_FX_TAG, level._effect[ZM_BGB_MACHINE_FLYING_EMBERS_UP_FX_NAME], "embers");
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
