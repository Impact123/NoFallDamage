#include <sourcemod>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <updater>

#pragma semicolon 1



#define PLUGIN_VERSION "0.6.2"



// Lateload
new bool:g_bLateLoaded;


// Enabled Cvar
new Handle:g_hEnabled;
new bool:g_bEnabled;


// Version
new Handle:g_hVersion;


// Teamfilter
new Handle:g_hTeamFilter;
new g_iTeamFilter;


// ClientFilter
new Handle:g_hClientFilter;
new g_iClientFilter;



// Updater
#define UPDATER_URL "http://plugins.gugyclan.eu/nofalldamage_sdkhooks/nofalldamage_sdkhooks.txt"



public Plugin:myinfo = 
{
	name = "No Fall Damage v2",
	author = "Impact",
	description = "Prevents players from taking damage by falling to the ground",
	version = PLUGIN_VERSION,
	url = "http://gugyclan.eu"
}





public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}





public OnPluginStart()
{
	g_hVersion      = CreateConVar("sm_nofalldamage_version", PLUGIN_VERSION, "Version of this plugin (Not changeable)", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled      = CreateConVar("sm_nofalldamage_enabled", "1", "Whether or not this plugin is enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hTeamFilter   = CreateConVar("sm_nofalldamage_teamfilter", "0", "Team that should be protected from falldamage, 0 = Any, 2 = RED, 3 = BLUE", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hClientFilter = CreateConVar("sm_nofalldamage_clientfilter", "0", "Clients that should be protected from falldamage, 0 = Any, 1 = Only Admins", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	
	g_bEnabled      = GetConVarBool(g_hEnabled);
	g_iTeamFilter   = GetConVarInt(g_hTeamFilter);
	g_iClientFilter = GetConVarInt(g_hClientFilter);
	
	
	SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	
	
	HookConVarChange(g_hEnabled, OnCvarChanged);
	HookConVarChange(g_hVersion, OnCvarChanged);
	HookConVarChange(g_hTeamFilter, OnCvarChanged);
	HookConVarChange(g_hClientFilter, OnCvarChanged);
	
	
	// LateLoad;
	if(g_bLateLoaded)
	{
		for(new i; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}





public OnAllPluginsLoaded()
{
    if(LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATER_URL);
    }
}





public OnLibraryAdded(const String:name[])
{
    if(StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATER_URL);
    }
}






public OnCvarChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == g_hEnabled)
	{
		g_bEnabled = GetConVarBool(g_hEnabled);
	}
	else if(convar == g_hTeamFilter)
	{
		g_iTeamFilter = GetConVarInt(g_hTeamFilter);
	}
	else if(convar == g_hClientFilter)
	{
		g_iClientFilter = GetConVarInt(g_hClientFilter);
	}
	else if(convar == g_hVersion)
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION, false, false);
	}
}





public OnClientPostAdminCheck(client)
{
	if(IsClientValid(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}





public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(g_bEnabled)
	{
		// We first check if damage is falldamage and then check the others
		if(damagetype & DMG_FALL)
		{
			// Teamfilter
			if(g_iTeamFilter < 1 || g_iTeamFilter > 1 && GetClientTeam(client) == g_iTeamFilter)
			{
				// Clientfilter
				if(g_iClientFilter == 0 || g_iClientFilter == 1 && CheckCommandAccess(client, "sm_nofalldamage_immune", ADMFLAG_GENERIC, false))
				{
					return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}





stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}

