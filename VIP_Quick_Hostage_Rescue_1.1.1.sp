#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <vip_core>

public Plugin myinfo =
{
	name = "[VIP] Quick Hostage Rescue", 
	author = "R1KO, babka68", 
	description = "Позволяет VIP-игрокам моментально спасать заложников.", 
	version = "1.1.1", 
	url = "https://hlmod.ru/ https://vk.com/zakazserver68"
};

static const char g_szFeature[] = "QHR";

bool g_bEnabled = false;

public void OnPluginStart()
{
	if (VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public void OnPluginEnd()
{
	if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_szFeature);
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_szFeature, BOOL, _, _, _, OnDrawItem);
}

public int OnDrawItem(int iClient, const char[] szFeatureName, int iStyle)
{
	return g_bEnabled ? iStyle : ITEMDRAW_RAWLINE;
}

public void OnMapStart()
{
	char map[128];
	GetCurrentMap(map, sizeof(map));
	
	if (!strncmp(map, "workshop", 8))
	{
		strcopy(map, sizeof(map), map[19]);
	}
	
	g_bEnabled = !strncmp(map, "cs_", 3);

	static bool bHooked;
	
	if (g_bEnabled)
	{
		PrecacheModel("models/props/cs_office/vending_machine.mdl", true);

		if (!bHooked)
		{
			HookEvent("hostage_follows", Event_HostageFollows);
			bHooked = true;
		}
	}
	else if (bHooked)
	{
		UnhookEvent("hostage_follows", Event_HostageFollows);
		bHooked = false;
	}
}

public void Event_HostageFollows(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if (!VIP_IsClientVIP(iClient) || !VIP_IsClientFeatureUse(iClient, g_szFeature))
	{
		return;
	}

	int iHostage = hEvent.GetInt("hostage");
	if (iHostage < MaxClients || !IsValidEntity(iHostage))
	{
		return;
	}
			
	int iEntity = CreateEntityByName("func_hostage_rescue");
	float origin[3], mins[3] =  { -100.0, -100.0, -10.0 }, maxs[3] =  { 100.0, 100.0, 100.0 };
	
	GetEntPropVector(iHostage, Prop_Send, "m_vecOrigin", origin);
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	SetEntityModel(iEntity, "models/props/cs_office/vending_machine.mdl");
	SetEntPropVector(iEntity, Prop_Send, "m_vecMins", mins);
	SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", maxs);
	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
	SetEntProp(iEntity, Prop_Send, "m_fEffects", GetEntProp(iEntity, Prop_Send, "m_fEffects") | 32);
	TeleportEntity(iEntity, origin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "Enable");
	SetEntityMoveType(iHostage, MOVETYPE_FLY);
	TeleportEntity(iHostage, origin, NULL_VECTOR, origin);
	SetVariantString("OnUser1 !self:kill::0.2:1");
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser1");
}
