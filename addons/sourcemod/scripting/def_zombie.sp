#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <kento_defence>

#define TYPE "zombie"
#define MODEL "models/player/zombie.mdl"

public Plugin myinfo =
{
	name = "[CS:GO] Tower Defence: Zombie",
	author = "Kento",
	version = "1.0",
	description = "Zombie enemy for Tower Defence mod",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart() 
{
	Defence_AddEnemyType(TYPE);
}

public Action Defence_OnEnemySpawn(char [] name, int enemy)
{
	if(StrEqual(TYPE, name))
	{
		SetEntityModel(enemy, "models/chicken/chicken.mdl");
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}