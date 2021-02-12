#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#namespace bgb_machine;


REGISTER_SYSTEM("bgb_machine", &__init__, undefined)

function __init__()
{
    clientfield::register("toplayer", "zm_bgb_machine_round_buys", VERSION_SHIP, 3, "int");
}

function turn_on_fire_sale() {}
function turn_off_fire_sale() {}
