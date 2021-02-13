# Customizable Gobblegum Machine
This repo contains a recreation of the Gobblegum machine from Call of Duty: Black Ops III since the raw files were not provided to us by Treyarch.

### Features
1. You can choose your own pool of gums to be in the machine. You aren't limited to just 5, and the user doesn't even need to have any of the respective Gobblegum.  
2. You can set the weight of each Gobblegum, which determines the chance that it is randomly picked when the player uses the machine.  
3. You can change how many machines are active at once, which brings back the old functionally where Gobblegum machines would move after a certain number of uses.
This makes the players have to move around more rather than just sticking to their favourite machine location. You can also modify the number of uses before they
move. Also, all machines will temporarily become active during a fire sale.
4. You can change the pricing model to whatever you want.

## Installation
Drag the contents of zm_yourmapname into your map's folder inside usermaps, and the contents of the prefabs folder to wherever you want to store the prefabs
(I would recommend `<root>/map_source/_prefabs/custom`).

### Including files

In your zm_levelname.gsc file, add this line to the top of the file:  
```
#using scripts\zm\_zm_bgb_fix;
```  
In your zm_levelname.csc file, again add this line to the top of the file:  
```
#using scripts\zm\_zm_bgb_fix;
```  
In your zm_levelname.zone file, add these lines: 
```
stringtable,gamedata/weapons/zm/zm_levelcommon_bgb.csv

scriptparsetree,scripts/zm/_zm_bgb_fix.gsc
scriptparsetree,scripts/zm/_zm_bgb_fix.csc
scriptparsetree,scripts/zm/_zm_bgb_machine.gsc
scriptparsetree,scripts/zm/_zm_bgb_machine.csc
```
Finally, you'll need to comment out lines 354 and 355 in `<root>/zone_source/all/assetlist/zm_patch.csv`. It should look like this:
```
//scriptparsetree,scripts/zm/_zm_bgb_machine.csc
//scriptparsetree,scripts/zm/_zm_bgb_machine.gsc
```

### Placing the Prefabs in Radiant
Open the Prefab Browser, and then navigate to the folder you placed the prefabs in earlier. There are two prefabs available. One is vending_bgb_fix_struct.map,
and the other is vending_bgb_fix_initial_struct.map. The initial struct designates that Gobblegum machine as an initial spot. Initial spots have priority in being
chosen over non-initial spots at the start of a game if a limited number of machines are set to be active.

Drag one of them onto your map to place it. Unfortunately there is still no preview model for the machine, so use the slanted top of the clip brush to orient the
prefab correctly. The downward slanted side is the side that faces toward the player.

If you have any Treyarch Gobblegum machines on your map already, select them and change their 'model' KVP entry to use one of mine instead.

### Customization
By default, every Gobblegum is available in the pool. However, in solo, the player will not get Gobblegums that only function in coop. Also, every Gobblegum machine
will be active, so they'll function like they have since March 2016.

To change the pool of available Gobblegums, you need to edit the zm_levelcommon_bgb.csv file, located in `<root>/usermaps/zm_yourmapname/gamedata/weapons/zm`. This
is the same location as the weapons table if you have customized the weapons in the box.

In this file, you can alter the weight of Gobblegums. The weight is the last column. To put it simply, a higher weight relative to others means a higher chance of
being selected. A weight of 0 means the machine will never pick that Gobblegum (it is essentially removed). You can use decimal numbers.

There are some other options I have made available. To change these, we are going to set the values in your map’s .gsc file, in main(). These need to go before any
wait statements to ensure they are set in time.

The first option is the number of active machines. By default, this is -1, meaning that every machine is active. This is the behaviour that has been in-game since
March 2016. You can set this to 1 for example by adding the line `level.num_active_bgb_machines = 1;` Then only one Gobblegum machine will be active at a time.
When there are fewer active machines then spots on the map, random machines will be chosen to be active at the start of the match. Machines using the initial prefab
have priority in this random selection over the regular ones. The machines will automatically move to a vacant spot after 3 uses.

The other main option makes the machines use the player’s Gobblegum pack over the csv. You can set this with `level.use_players_bgb_pack = true;` This replicates
the behaviour of the default machines, but the player will never run out of Megas. You can use this in conjunction with the moving machine behaviour.

You can also disable the machines from moving using `level.disable_bgb_machines_moving = true;`

If you want to give solo players the same Gobblegums as in coop (including the ones that are useless to solo players), use `level.remove_coop_bgbs_in_solo = false;`

For other settings, like the pricing model and uses before moving, you'll need to edit _zm_bgb_fix.gsc. The pricing function is called `determine_cost(player)`.
In short, this function needs to return the calculated cost (an int), or false if the player is not allowed to buy a Gobblegum (ie. has hit limit for this round).
This function is then mirrored in _zm_bgb_fix.csc with some slight differences.

The function that determines whether the machine should move is called `bgb_machine_should_move()`. This function returns true if the machine is supposed to move,
and false if it isn't. By default, it moves after 3 non-fire sale uses.

The function that determines which gumball the player will get is `determine_bgb(player)`. It should return an entry from `level.zombie_bgbs`, which is indexed by
the Gobblegum name (first column of the Gobblegum table).

## Contributing
Pull requests are welcome.

## Credits
Scobalula - Cerberus  
DTZxPorter - Wraith  
Niknokinater, Green Donut - Testing
