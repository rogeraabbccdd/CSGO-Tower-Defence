/*
* Completed, - WIP , ? Need test
[ ] Towers
	[*] Config
		[*] Design config file
		[*] Load config
	[*] Spawn a bot for showing tower hp on scoreboard
	[*] Tower Particle
	[ ] HUD Text (Total Tower HP)
-----------------------------------------------------------------------------
[ ] Monsters 
Use	https://forums.alliedmods.net/showpost.php?p=2416226&postcount=43
or	http://ownageclan.com/websvn/filedetails.php?repname=war3source&path=%2FWCX_Engine_FakeNPC.sp
	[ ] Configs
		[-] Design config file
		[ ] Load config
	[ ] Monster Spawn Zones (Devzones 3rd party plugin)
	[ ] Tower Damage
		[ ] SDKHook take damage (What damagetype does monster do?)
-----------------------------------------------------------------------------
[ ] Waves
	[ ] Configs
		[ ] Design config file
		[ ] Load config
	[ ] Skybox
	[ ] Danger Wave HP+20%, ATK+20%?
	[ ] Spawn monsters
	[ ] BGM
		[ ] BGM timer for each player
		[ ] Command to change volume
		
		Planning to use BGMs
		http://www.nicovideo.jp/watch/sm26739858
		http://www.nicovideo.jp/watch/sm22481227
-----------------------------------------------------------------------------
[ ] Others
	[ ] Download
		[*] Load Config
		[*] Download
		[?] Precache
	[ ] Wave Result
		[ ] Contribute Values.
		[ ] Show icons on Top 3 Player's head, clear when next wave end.
		[ ] Overlay
	[ ] Items
		[ ] Heal Tower
		[ ] Sentry gun?
	[ ] Rewards
		[ ] Store credits?
	[ ] Sound Effects
		[ ] Count Down
		[ ] Wave Clear
-----------------------------------------------------------------------------
[ ] Ready System
-----------------------------------------------------------------------------
[ ] Ranking System
	[ ] SQL
	[ ] Stats
	[ ] Web interface
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <kento_csgocolors>
#include <clientprefs>
#include <cstrike>

#pragma newdecls required

// Teams
#define SPEC 1
#define TR 2
#define CT 3

// Tower
#define MAXTOWERS 100
float TowerPosition[MAXTOWERS][3];
int TowerHP[MAXTOWERS];
char TowerModel[MAXTOWERS][PLATFORM_MAX_PATH];
char TowerName[MAXTOWERS][PLATFORM_MAX_PATH];
int TowerCount;
int Tower[MAXTOWERS];
int TowerBot[MAXTOWERS];
int TowerRef[MAXTOWERS] = INVALID_ENT_REFERENCE;
char TowerGlow[MAXTOWERS][PLATFORM_MAX_PATH];
char TowerSmoke[MAXTOWERS][PLATFORM_MAX_PATH];
char TowerExplode[MAXTOWERS][PLATFORM_MAX_PATH];
Handle TowerBotArray;
int TowerParticle[MAXTOWERS];
int TowerParticleRef[MAXTOWERS] = INVALID_ENT_REFERENCE;

// Monsters
#define MAXMONSTERS 100
int MonCount;
char MonName[MAXMONSTERS][PLATFORM_MAX_PATH];
char MonModel[MAXMONSTERS][PLATFORM_MAX_PATH];
int MonHP[MAXMONSTERS];

// Includes
#include <defence/configs>
#include <defence/towers>
#include <defence/waves>

public Plugin myinfo =
{
	name = "[CS:GO] Tower Defence",
	author = "Kento",
	version = "1.0",
	description = "Gamemode from Phantasy Star Online 2",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart() 
{
	//HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	RegConsoleCmd("sm_test", CMD_Test, "Start Tower Defence");
	
	// Teams
	AddCommandListener(Command_Join, "jointeam");
	
	TowerBotArray = CreateArray();
}

public void OnConfigsExecuted()
{
	// mp_warmuptime		"300"
	// mp_warmup_pausetimer		"1"
	// mp_death_drop_gun 0
}

public void OnMapStart() 
{
	LoadMapConfig();
	DownloadFiles();
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	SpawnTowers();
}

public Action Command_Join(int client, const char[] command, int argc)
{
	char sJoining[8];
	GetCmdArg(1, sJoining, sizeof(sJoining));
	int iJoining = StringToInt(sJoining);
	// int iTeam = GetClientTeam(client);
	
	// T is for monsters
	if(iJoining == CS_TEAM_T)	return Plugin_Handled;
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public Action Hook_SetTransmit(int iEntity, int iClient)
{
	setFlags(iEntity);
}

void setFlags(int edict)
{
    if (GetEdictFlags(edict) & FL_EDICT_ALWAYS)
    {
        SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
    }
}

public Action CMD_Test(int client, int args)
{
	
}