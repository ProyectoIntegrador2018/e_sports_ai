# How to run the bots
Find your Dota 2 installation directory, let’s call it $DOTA. Go to $DOTA\dota 2 beta\game\dota\scripts\vscripts and you will
find a bots_example directory. Make a copy of that, rename it to bots — all bots code resides inside that directory. 
If you start a practice match with bots, it should read bot scripts from that location.



## Start a Bot vs. Bot Match
Enable Dota 2 console by adding -console launching options.

For bot vs. bot match to work, the example script need to be modified. Open hero_selection.lua and you can see the script tries to select 0-4 for radiant and 5-9 for dire. However, this is only true if you are in the game. For bot vs. bot match, 0-1 is reserved (maybe for coaches?) so radiant is 2-6 and dire is 7-11.

Create a lobby (Play Dota -> Create Lobby) and edit lobby settings. Choose Local Dev Script for Radiant and choose any difficulty except none. Also tick Enable Cheats.

Lobby Settings

Make yourself either a coach or unassigned player and start the match.

* [Demo Image](http://image.prntscr.com/image/9d92bc777a52417e9300edf1d8682409.png)





