//CREATED BY: PLATINUM_DOTA2 (Pooya J.)
//EMAIL: PLATINUM.DOTA2@GMAIL.COM

#include<iostream>
#include<fstream>
#include<string>
#include<vector>

using namespace std;

const int n=21;

string  fnames[n]= {
		"laning",
		"attack",
		"roam",
		"retreat",
		"secret_shop",
		"side_shop",
		"rune",
		"push_tower_top",
		"push_tower_mid",
		"push_tower_bot",
		"defend_tower_top",
		"defend_tower_mid",
		"defend_tower_bot",
		"assemble",
		"team_roam",
		"farm",
		"defend_ally",
		"evasive_maneuvers",
		"roshan",
		"item",
		"ward"};

const int m=1;
string hnames[m]={"shredder"};//={"luna","zuus","furion","treant","keeper_of_the_light"};


void init()
{
	for (int j=0;j<m;j++)
	{
		for (int i=0;i<n;i++)
		{
			string fname=".\\HerOut\\mode_"+fnames[i]+"_"+hnames[j]+".lua";
			string gname="mode_generic_"+fnames[i];
			ofstream op;
			op.open(fname.c_str());
			op<<"-------\nrequire( GetScriptDirectory()..\"/mode_"+fnames[i]+"_generic\" )\nUtility = require(GetScriptDirectory()..\"/Utility\")\n----------\n\nfunction OnStart()\n\t"+gname+".OnStart();\nend\n\nfunction OnEnd()\n\t"+gname+".OnEnd();\nend\n\nfunction GetDesire()\n\treturn "+gname+".GetDesire();\nend\n\nfunction Think()\n\t"+gname+".Think();\nend\n\n--------\n";

			op.close();

			fname=".\\HerOut\\ability_item_usage_"+hnames[j]+".lua";
			op.open(fname.c_str());
			op<<"\nfunction AbilityUsageThink()\nend\n\nfunction CourierUsageThink()\n\tnpcBot=GetBot();\n\tif (npcBot:GetStashValue()>1000 and IsCourierAvailable()) then\n\t\tnpcBot:Action_CourierDeliver();\n\tend\nend\n";
			op.close();

			fname=".\\HerOut\\item_purchase_"+hnames[j]+".lua";
			op.open(fname.c_str());
			op<<"local tableItemsToBuy = {};\n\nfunction ItemPurchaseThink()\n\tlocal npcBot = GetBot();\n\tif ( #tableItemsToBuy == 0 ) then\n\t\tnpcBot:SetNextItemPurchaseValue( 0 );\n\t\treturn;\n\tend\n\n\tlocal sNextItem = tableItemsToBuy[1];\n\n\tnpcBot:SetNextItemPurchaseValue( GetItemCost( sNextItem ) );\n\n\tif ( npcBot:GetGold() >= GetItemCost( sNextItem ) ) then\n\t\tnpcBot:Action_PurchaseItem( sNextItem );\n\t\ttable.remove( tableItemsToBuy, 1 );\n\tend\nend";
			op.close();
		}
	}
}

int main()
{
	init();
}

