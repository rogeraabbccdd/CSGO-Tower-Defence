void LoadMapConfig()
{
	char sMapName[128], sMapName2[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	
	// Does current map string contains a "workshop" prefix at a start?
	if (strncmp(sMapName, "workshop", 8) == 0)
	{
		Format(sMapName2, sizeof(sMapName2), sMapName[19]);
	}
	else
	{
		Format(sMapName2, sizeof(sMapName2), sMapName);
	}
	
	//**********************************  Towers  **********************************//
	char Configfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Configfile, sizeof(Configfile), "configs/defense/%s/towers.cfg", sMapName2);
	
	if (!FileExists(Configfile))
	{
		SetFailState("Fatal error: Unable to open configuration file \"%s\"!", Configfile);
	}
	
	KeyValues kv = CreateKeyValues("Towers");
	kv.ImportFromFile(Configfile);
	
	if(!kv.GotoFirstSubKey())
	{
		SetFailState("Fatal error: Unable to read configuration file \"%s\"!", Configfile);
	}
	
	char pos[PLATFORM_MAX_PATH], posdata[3][PLATFORM_MAX_PATH], name[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH], 
	glow[PLATFORM_MAX_PATH], explode[PLATFORM_MAX_PATH], smoke[PLATFORM_MAX_PATH];
	
	TowerCount = 0;
	do
	{
		kv.GetSectionName(name, sizeof(name));
		kv.GetString("model", model, sizeof(model), "unknown");
		kv.GetString("position", pos, sizeof(pos), "unknown");
		
		if(!StrEqual(pos, "unknown") && !StrEqual(model, "unknown"))
		{
			strcopy(TowerName[TowerCount], sizeof(TowerName[]), name);
			strcopy(TowerModel[TowerCount], sizeof(TowerModel[]), model);
			PrecacheModel(TowerModel[TowerCount], true);
			
			ExplodeString(pos, ";", posdata, 3, 32);
			TowerPosition[TowerCount][0] = StringToFloat(posdata[0]);
			TowerPosition[TowerCount][1] = StringToFloat(posdata[1]);
			TowerPosition[TowerCount][2] = StringToFloat(posdata[2]);
			
			TowerHP[TowerCount] = kv.GetNum("hp", 3000);
			
			kv.GetString("glow", glow, sizeof(glow), "unknown");
			strcopy(TowerGlow[TowerCount], sizeof(TowerGlow[]), glow);
			
			kv.GetString("explode", explode, sizeof(explode), "");
			strcopy(TowerExplode[TowerCount], sizeof(TowerExplode[]), explode);
			
			kv.GetString("smoke", smoke, sizeof(smoke), "");
			strcopy(TowerSmoke[TowerCount], sizeof(TowerSmoke[]), smoke);
			
			TowerCount++;
		}
		else
		{
			LogError("Unable to read tower settings of %s, ignoring...", name);
		}
	} while (kv.GotoNextKey());
	
	kv.Rewind();
	
	//**********************************  Monsters  **********************************//
	
	BuildPath(Path_SM, Configfile, sizeof(Configfile), "configs/defense/%s/monsters.cfg", sMapName2);
	
	if (!FileExists(Configfile))
	{
		SetFailState("Fatal error: Unable to open configuration file \"%s\"!", Configfile);
	}
	
	kv = CreateKeyValues("Monsters");
	kv.ImportFromFile(Configfile);
	
	if(!kv.GotoFirstSubKey())
	{
		SetFailState("Fatal error: Unable to read configuration file \"%s\"!", Configfile);
	}
	
	char hp[PLATFORM_MAX_PATH];
	
	MonCount = 0;
	do
	{
		kv.GetSectionName(name, sizeof(name));
		kv.GetString("model", model, sizeof(model), "unknown");
		kv.GetString("hp", hp, sizeof(hp), "unknown");
		
		if(!StrEqual(model, "unknown") && !StrEqual(hp, "unknown"))
		{
			strcopy(MonName[MonCount], sizeof(MonName[]), name);
			strcopy(MonModel[MonCount], sizeof(MonModel[]), model);
			
			MonHP[MonCount] = kv.GetNum("hp", 100);
			PrecacheModel(MonModel[MonCount], true);
			
			MonCount++;
		}
		else
		{
			LogError("Unable to read tower settings of %s, ignoring...", name);
		}
	} while (kv.GotoNextKey());
	
	kv.Rewind();
	delete kv;
	
	//**********************************  Waves  **********************************//
	//
	//
}

void DownloadFiles()
{
	PrecacheEffect("ParticleEffect");
	
	char Configfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Configfile, sizeof(Configfile), "configs/defense/downloads.cfg");
	
	if (!FileExists(Configfile))
	{
		LogError("Unable to open download file \"%s\"!", Configfile);
		return;
	}
	
	char line[PLATFORM_MAX_PATH], line2[PLATFORM_MAX_PATH];
	Handle fileHandle = OpenFile(Configfile,"r");

	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle, line, sizeof(line)))
	{
		// Remove whitespaces and empty lines
		TrimString(line);
		ReplaceString(line, sizeof(line), " ", "", false);
	
		// Skip comments
		if (line[0] != '/')
		{
			if (FileExists(line, true))
			{
				AddFileToDownloadsTable(line);
				
				// Sound file
				if(StrContains(line, ".mp3", false))
				{	
					strcopy(line2, sizeof(line2), line);
					ReplaceStringEx(line2, sizeof(line2), "sound/", "*/");
					FakePrecacheSound(line2);
				}
				// Particle
				if(StrContains(line, ".pcf", false))	PrecacheGeneric(line, true);
				// Model
				if(StrContains(line, ".mdl", false))	PrecacheModel(line, true);
			}
		}
	}
	CloseHandle(fileHandle);
	
	// loop all tower particle
	for (int i = 0; i < TowerCount; i++)
	{
		if(!StrEqual(TowerExplode[i], ""))	PrecacheParticleEffect(TowerExplode[i]);
	}
}

// https://wiki.alliedmods.net/Csgo_quirks
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

// https://forums.alliedmods.net/showpost.php?p=2471747&postcount=4
stock void PrecacheEffect(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("EffectDispatch");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

stock void PrecacheParticleEffect(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}  