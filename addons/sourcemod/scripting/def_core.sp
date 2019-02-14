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
[ ] Enemies 
	[-] Natives for 3rd praty plugin (Call when spawn)
-----------------------------------------------------------------------------
[ ] Waves
	[*] Configs
		[*] Design config file
		[*] Load config
	[ ] Skybox
	[ ] Danger Wave HP+20%, ATK+20%?
	[-] Spawn enemies
	[ ] BGM
		[ ] BGM timer for each player
		[ ] Command to change volume
		
		Planning to use BGMs
		http://www.nicovideo.jp/watch/sm26739858
		http://www.nicovideo.jp/watch/sm22481227

	[ ] Overlays
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

// Waves
#define MAXBIGWAVE 10
#define MAXSMALLWAVE 10
#define MAXENEMYINWAVE 10
int WaveBigs = 1;
int WaveSmalls[MAXBIGWAVE] = 1;
char WaveBGM1[MAXBIGWAVE][PLATFORM_MAX_PATH];
char WaveBGM2[MAXBIGWAVE][PLATFORM_MAX_PATH];
float WaveTime[MAXBIGWAVE];
float WaveDelay[MAXBIGWAVE];
int WaveEnemys[MAXBIGWAVE][MAXSMALLWAVE];
int WaveEnemysCount[MAXBIGWAVE][MAXSMALLWAVE];
char WaveEnemyZone[MAXBIGWAVE][MAXSMALLWAVE][MAXENEMYINWAVE][PLATFORM_MAX_PATH];
int WaveEnemyCount[MAXBIGWAVE][MAXSMALLWAVE][MAXENEMYINWAVE];
char WaveEnemyName[MAXBIGWAVE][MAXSMALLWAVE][MAXENEMYINWAVE][PLATFORM_MAX_PATH];
int WaveNowBig;
int WaveNowSmall;

// Enemy
Handle EnemyArray;

// Includes
#include <kento_defence>
#include "def/configs.sp"
#include "def/towers.sp"
#include "def/waves.sp"
#include "def/natives.sp"
#include <devzones>

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
	EnemyArray =  CreateArray();
}

public void OnConfigsExecuted()
{
	
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
	if(IsFakeClient(client))	return Plugin_Handled;
	
	char sJoining[8];
	GetCmdArg(1, sJoining, sizeof(sJoining));
	int iJoining = StringToInt(sJoining)
	
	// T is for enemies
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
	WaveNowBig = 1;
	WaveNowSmall = 1;

	PrintToChatAll("small: %d", WaveSmalls[WaveNowBig]);
	PrintToChatAll("WaveEnemys: %d", WaveEnemys[WaveNowBig][WaveNowSmall]);

	int bot = WaveEnemysCount[WaveNowBig][WaveNowSmall] + TowerCount;
	ServerCommand("bot_quota %d", bot);
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("mp_limitteams 0");

	// loop all type
	for(int i=0;i<WaveEnemys[WaveNowBig][WaveNowSmall];i++)
	{
		PrintToChatAll("WaveEnemyCount: %d", WaveEnemyCount[WaveNowBig][WaveNowSmall][i]);

		// spawn count
		for(int j=0;j<WaveEnemyCount[WaveNowBig][WaveNowSmall][i]; j++)
		{
			PrintToChatAll("Zone: %s", WaveEnemyZone[WaveNowBig][WaveNowSmall][j]);

			int enemy = CreateFakeClient("xXx_Enemy_1337_xXx");
			PrintToChatAll("%d", GetClientUserId(enemy));
			PushArrayCell(EnemyArray, GetClientUserId(enemy));
					
			ChangeClientTeam(enemy, TR);
			CS_RespawnPlayer(enemy);
			
			float position[3];
			if(Zone_GetZonePosition(WaveEnemyZone[WaveNowBig][WaveNowSmall][j], false, position))
				TeleportEntity(enemy, position, NULL_VECTOR, NULL_VECTOR);

			// Call forward
			Call_StartForward(OnEnemySpawn);
			Call_PushString(WaveEnemyName[WaveNowBig][WaveNowSmall][i]);
			Call_PushCell(enemy);
			Call_Finish();
		}
	}
}