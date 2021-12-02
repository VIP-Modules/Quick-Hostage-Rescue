#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <vip_core>

public Plugin:myinfo =
{
	name = "[VIP] Quick Hostage Rescue",
	author = "R1KO",
	version = "1.1"
};

static const String:g_sFeature[] = "QHR";

new bool:g_bEnabled = false;

public OnPluginStart() 
{ 
	HookEvent("hostage_follows", Event_HostageFollows);

	if(VIP_IsVIPLoaded())
	{
		VIP_OnVIPLoaded();
	}
}

public OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
}

public VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, _, _, _, OnDrawItem);
}

public OnDrawItem(iClient, const String:sFeatureName[], iStyle)
{
	return g_bEnabled ? iStyle:ITEMDRAW_RAWLINE;
}

public OnMapStart()
{
	decl String:sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));

	if (strncmp(sMap, "workshop", 8) == 0)
	{
		strcopy(sMap, sizeof(sMap), sMap[19]);
	}

	g_bEnabled = (strncmp(sMap, "cs_", 3) == 0);
	
	if(g_bEnabled)
	{
		HookEvent("hostage_follows", Event_HostageFollows);
		PrecacheModel("models/props/cs_office/vending_machine.mdl", true);
	}
}

public OnMapEnd()
{
	if(g_bEnabled)
	{
		UnhookEvent("hostage_follows", Event_HostageFollows);
	}
}

public Event_HostageFollows(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (VIP_IsClientVIP(iClient) && VIP_IsClientFeatureUse(iClient, g_sFeature))
	{
		new hostage = GetEventInt(hEvent, "hostage");
		if (hostage > 0 && IsValidEntity(hostage))
		{
			new iEntity = CreateEntityByName("func_hostage_rescue");
			decl Float:fOrigin[3];
			GetEntPropVector(hostage, Prop_Send, "m_vecOrigin", fOrigin);
			DispatchSpawn(iEntity);
			ActivateEntity(iEntity);
			SetEntityModel(iEntity, "models/props/cs_office/vending_machine.mdl");
			SetEntPropVector(iEntity, Prop_Send, "m_vecMins", Float:{-100.0, -100.0, -10.0});
			SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", Float:{100.0, 100.0, 100.0});
			SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
			SetEntProp(iEntity, Prop_Send, "m_fEffects", GetEntProp(iEntity, Prop_Send, "m_fEffects") | 32);
			TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(iEntity, "Enable");
			SetEntityMoveType(hostage, MOVETYPE_FLY);
			TeleportEntity(hostage, fOrigin, NULL_VECTOR, fOrigin);
			SetVariantString("OnUser1 !self:kill::0.2:1");
			AcceptEntityInput(iEntity, "AddOutput");
			AcceptEntityInput(iEntity, "FireUser1");
		}
	}
}