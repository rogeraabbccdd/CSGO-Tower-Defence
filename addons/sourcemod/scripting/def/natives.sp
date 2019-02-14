// Forwards
Handle OnEnemySpawn;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// CreateNative("Defence_AddEnemyType", Native_AddEnemyType);

	OnEnemySpawn = CreateGlobalForward("Defence_OnEnemySpawn", ET_Ignore, Param_String, Param_Cell);
}

// public int Native_AddEnemyType(Handle plugin, int numParams)
// {
// 	int len;
// 	GetNativeStringLength(1, len);
	
// 	if (len <= 0)	return false;
	
// 	char[] str = new char[len + 1];
// 	GetNativeString(1, str, len + 1);

// 	// Check we already have it or not.
// 	bool hasenemy = false;
// 	for(int i=0; i<MAXENEMYTYPE;i++)
// 	{
// 		if(StrEqual(EnemyTypeName[i], str, true))	hasenemy = true;
// 	}

// 	if(hasenemy)	return false;
// 	else
// 	{
// 		Format(EnemyTypeName[EnemyTypeCount], sizeof(EnemyTypeName[]), "%s", str);
// 		EnemyTypeCount++;
// 		return true;
// 	}
// }