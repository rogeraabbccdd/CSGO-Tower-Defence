void SpawnTowers()
{
	int entity;
	for (int i = 0; i < TowerCount; i++)
	{
		entity  = EntRefToEntIndex(TowerRef[i]);
		if(entity != INVALID_ENT_REFERENCE && IsValidEdict(entity) && entity != 0)
		{
			AcceptEntityInput(entity, "Kill");
			TowerRef[i] = INVALID_ENT_REFERENCE;
		}
		
		Tower[i] = CreateEntityByName("prop_dynamic_override");
		
		char name[512];
		Format(name, sizeof(name), "Tower%d", i);
		
		SetEntityModel(Tower[i], TowerModel[i]);
		SetEntPropString(Tower[i], Prop_Data, "m_iName", TowerName[i]);
		SetEntProp(Tower[i], Prop_Send, "m_nBody", 0);
		
		// Collision
		SetEntProp(Tower[i], Prop_Data, "m_CollisionGroup", 8);
		SetEntProp(Tower[i], Prop_Data, "m_usSolidFlags", 152);
		SetEntProp(Tower[i], Prop_Data, "m_nSolidType", 6);
		
		// Glow
		SetEntProp(Tower[i], Prop_Send, "m_bShouldGlow", true, true);
		SetEntPropFloat(Tower[i], Prop_Send, "m_flGlowMaxDist", 10000000.0);
		if(!StrEqual(TowerGlow[i], "unknown"))	SetGlowColor(Tower[i], TowerGlow[i]);
		
		TowerRef[i] = EntIndexToEntRef(Tower[i]);
		
		DispatchSpawn(Tower[i]);
		TeleportEntity(Tower[i], TowerPosition[i], NULL_VECTOR, NULL_VECTOR);
		
		// Dmg and health
		SetEntProp(Tower[i], Prop_Data, "m_takedamage", 2, 1);
		SetEntProp(Tower[i], Prop_Data, "m_iHealth", TowerHP[i]);
		
		SDKHook(Tower[i], SDKHook_OnTakeDamage, OnTowerDamage);

		// Spawn a bot for showing tower health on scoreboard
		if(!IsValidClient(TowerBot[i]))
		{
			TowerBot[i] = CreateFakeClient(TowerName[i]);
				
			PushArrayCell(TowerBotArray, GetClientUserId(TowerBot[i]));

			// Player team is CT
			ChangeClientTeam(TowerBot[i], CT);
			
			CS_RespawnPlayer(TowerBot[i]);
			
			SetEntityModel(TowerBot[i], "models/chicken/chicken.mdl");
			SetEntityMoveType(TowerBot[i], MOVETYPE_NONE);
			
			TeleportEntity(TowerBot[i], TowerPosition[i], NULL_VECTOR, NULL_VECTOR);
			
			CS_SetClientClanTag(TowerBot[i], "TOWER");
			CS_SetClientContributionScore(TowerBot[i], TowerHP[i]);
		}
		else
		{
			SetEntityModel(TowerBot[i], "models/chicken/chicken.mdl");
			SetEntityMoveType(TowerBot[i], MOVETYPE_NONE);
			
			TeleportEntity(TowerBot[i], TowerPosition[i], NULL_VECTOR, NULL_VECTOR);
			
			CS_SetClientClanTag(TowerBot[i], "TOWER");
			CS_SetClientContributionScore(TowerBot[i], TowerHP[i]);
		}
	}
}

/*	
	Copy from 
	https://github.com/Franc1sco/Franug-Glow-Buttons/blob/master/glow_buttons.sp 
*/
stock void SetGlowColor(int entity, const char[] color)
{
    char colorbuffers[3][4];
    ExplodeString(color, " ", colorbuffers, sizeof(colorbuffers), sizeof(colorbuffers[]));
    int colors[4];
    for (int i = 0; i < 3; i++)
        colors[i] = StringToInt(colorbuffers[i]);
    colors[3] = 255; // Set alpha
    SetVariantColor(colors);
    AcceptEntityInput(entity, "SetGlowColor");
}  

public Action OnTowerDamage (int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	char sdamage[8];
	int idamage = RoundToZero(damage);
	IntToString(idamage, sdamage, sizeof(sdamage));
	
	int health = GetEntProp(victim, Prop_Data, "m_iHealth");
	int health2 = health - idamage;
	
	PrintToChatAll("%d", damagetype);
	
	if(idamage > health)
	{
		int towerid = FindTowerByEnt(victim);
		if(towerid != -1)	CS_SetClientContributionScore(TowerBot[towerid], 0);
		TowerDestroy(towerid);
	}
	else
	{	
		int towerid = FindTowerByEnt(victim);
		if(towerid != -1)	CS_SetClientContributionScore(TowerBot[towerid], health2);
		
		// Create smoke when hp is lower than 50%
		if(health2 <= (TowerHP[towerid] * 0.5) && !StrEqual(TowerSmoke[towerid], ""))
		{
			int entity = EntRefToEntIndex(TowerParticleRef[towerid]);
			
			if(entity != INVALID_ENT_REFERENCE && IsValidEdict(entity) && entity != 0)	return;
			
			TowerParticle[towerid] = CreateEntityByName("info_particle_system");
		
			DispatchKeyValue(TowerParticle[towerid], "start_active", "1");
			DispatchKeyValue(TowerParticle[towerid], "effect_name", TowerSmoke[towerid]);
			DispatchSpawn(TowerParticle[towerid]);
	
			TeleportEntity(TowerParticle[towerid], TowerPosition[towerid], NULL_VECTOR, NULL_VECTOR);
			SetVariantString("!activator");	
			AcceptEntityInput(TowerParticle[towerid], "SetParent", Tower[towerid], TowerParticle[towerid], 0);	
			ActivateEntity(TowerParticle[towerid]);
			TowerParticleRef[towerid] = EntIndexToEntRef(TowerParticle[towerid]);
			AcceptEntityInput(TowerParticle[towerid], "Start");
		}
	}
}  

void TowerDestroy(int id)
{
	// Slay Bot for showing kill
	ForcePlayerSuicide(TowerBot[id]);

	if(!StrEqual(TowerExplode[id], ""))
	{	
		PrintToChatAll("explode, %s", TowerExplode[id]);
		
		// Create explode particle
		int entity = EntRefToEntIndex(TowerParticleRef[id]);
		if(entity != INVALID_ENT_REFERENCE && IsValidEdict(entity) && entity != 0)
		{
			AcceptEntityInput(entity, "DestroyImmediately");
			AcceptEntityInput(entity, "Kill");
			TowerParticleRef[id] = INVALID_ENT_REFERENCE;
		}
	
		TowerParticle[id] = CreateEntityByName("info_particle_system");
	
		DispatchKeyValue(TowerParticle[id], "start_active", "1");
		DispatchKeyValue(TowerParticle[id], "effect_name", TowerExplode[id]);
		DispatchSpawn(TowerParticle[id]);
	
		TeleportEntity(TowerParticle[id], TowerPosition[id], NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(TowerParticle[id]);
		AcceptEntityInput(TowerParticle[id], "Start");
		TowerParticleRef[id] = EntIndexToEntRef(TowerParticle[id]);
	}
}

int FindTowerByEnt(int entity)
{
	int returnid = -1;
	
	for (int i = 0; i < TowerCount; i++)
	{
		if (entity == Tower[i])	returnid = i; break;
	}
	
	return returnid;
}