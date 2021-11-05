#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required 

// the "libraries" are where we store all the information for savelocing.
float g_fvelocity_library[1000][3];
float g_forigin_library[1000][3];
float g_feyeAngle_library[1000][3];

// the current number of savelocs on the server, this is used to teleport people to the right saveloc
int g_isaveloc_number = 0;

// the last used, or last created saveloc for a user
int g_irelevant_saveloc[MAXPLAYERS + 1];

// saves the last saveloc the client created.
int g_ilast_created_saveloc[MAXPLAYERS + 1][500];

// used to index the g_ilast_created_saveloc array
int g_icreatedlist = 0; 

// name in reference to an important part in teleprev/telenext functionality
bool g_bcanigobacknforth[MAXPLAYERS + 1]; 


public void OnPluginStart()
{
    RegConsoleCmd("sm_saveloc", Command_saveloc, "a command that creates a \"saveloc\" or checkpoint the client can teleport to with sm_tele");
    RegConsoleCmd("sm_tele", Command_tele, "a command to teleport to a \"saveloc\" or checkpoint the client has made.");
    RegConsoleCmd("sm_teleprev", teleprev, "a command to teleport you to the previous saveloc.");
    RegConsoleCmd("sm_telenext", telenext, "a command to teleport you to the next saveloc, if it exists.");
   // RegConsoleCmd("sm_settele", settele, "a command to send you to any point in the array of savelocs. made for debugging. uncomment this at your own risk...");
}

public void OnMapStart()
{
	g_isaveloc_number = 0; // reset savelocs after map changes.
	g_icreatedlist = 0;
}


public Action Command_saveloc(int client, int args)
{
	g_isaveloc_number++;
	g_icreatedlist++;
	
	switch (g_isaveloc_number)
	{
		case 998:
		{
			PrintToChat(client, "you're getting close to the saveloc limit!! the limit is 1000");
		}
		case 1000:
		{
			PrintToChat(client, "too many savelocs! savelocs have been reset.");
			g_isaveloc_number = 0;
			
			return Plugin_Handled;
		}
	}
	g_irelevant_saveloc[client] = g_isaveloc_number;
	g_ilast_created_saveloc[client][g_icreatedlist] = g_isaveloc_number;
	
	//PrintToChat(client,"last created %d", g_ilast_created_saveloc[client][g_icreatedlist]);
	//PrintToChat(client,"relevant saveloc %d", g_irelevant_saveloc[client]);

	float velocity[3];
	float eyeangles[3];
	float origin[3];
	
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, eyeangles);
	
	g_fvelocity_library[g_isaveloc_number] = velocity;
	g_forigin_library[g_isaveloc_number] = origin;
	g_feyeAngle_library[g_isaveloc_number] = eyeangles;
	
	PrintToChat(client, "created saveloc %d", g_isaveloc_number);
	
	
	
	return Plugin_Handled;
}


public Action Command_tele(int client, int args)
{
	switch (g_isaveloc_number)
	{
		case 0:
		{
			PrintToChat(client, "there are no savelocs to tele to. sm_saveloc to create one!");
			return Plugin_Handled;
		}
		default:
		switch (args)
		{
			case 0:
			{
				TeleportEntity(client, g_forigin_library[g_irelevant_saveloc[client]], g_feyeAngle_library[g_irelevant_saveloc[client]], g_fvelocity_library[g_irelevant_saveloc[client]]);
				return Plugin_Handled;	
			}
			case 1:
			{
				char arg1[4];
				GetCmdArg(1, arg1, sizeof(arg1));
				int tele_arg = StringToInt(arg1);
				if (tele_arg > g_isaveloc_number)
				{
					PrintToChat(client, "saveloc %d does not exist!", tele_arg);
					return Plugin_Handled;
				}
				g_irelevant_saveloc[client] = tele_arg;
			
				TeleportEntity(client, g_forigin_library[tele_arg], g_feyeAngle_library[tele_arg], g_fvelocity_library[tele_arg]);

				g_bcanigobacknforth[client] = false;

				return Plugin_Handled;
			}	
		}
	}
	return Plugin_Handled;
}

//all teleprev needs to do is go back one in ur previously created every time u do it.
//make a bool to know whether or not they used another teleplugin recently
public Action teleprev(int client, int args)
{	
	int prevtele;

	switch(g_bcanigobacknforth[client])
	{
		case false:
		{
			prevtele = 0;
			prevtele = g_ilast_created_saveloc[client][g_irelevant_saveloc[client] - 1];
			g_irelevant_saveloc[client] = prevtele;
			TeleportEntity(client, g_forigin_library[g_irelevant_saveloc[client]], g_feyeAngle_library[g_irelevant_saveloc[client]], g_fvelocity_library[g_irelevant_saveloc[client]]);
			PrintToChat(client, "teleported to saveloc %d", g_irelevant_saveloc[client]);
			return Plugin_Handled;
		}

		case true:
		{
			prevtele = g_ilast_created_saveloc[client][g_irelevant_saveloc[client] - 1];
			g_irelevant_saveloc[client] = prevtele;
			TeleportEntity(client, g_forigin_library[g_irelevant_saveloc[client]], g_feyeAngle_library[g_irelevant_saveloc[client]], g_fvelocity_library[g_irelevant_saveloc[client]]);
			PrintToChat(client, "teleported to saveloc %d",g_irelevant_saveloc[client]);
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}


public Action telenext(int client, int args)
{
	int nexttele;
	int check = g_irelevant_saveloc[client] + 1;
	if (check > g_isaveloc_number)
	{
		PrintToChat(client, "next saveloc not found");
		return Plugin_Handled;
	}
	else
	{
	switch(g_bcanigobacknforth[client])
	{
		case false:
		{
			nexttele = 0;
			nexttele = g_ilast_created_saveloc[client][g_irelevant_saveloc[client] + 1];
			g_irelevant_saveloc[client] = nexttele;
			TeleportEntity(client, g_forigin_library[g_irelevant_saveloc[client]], g_feyeAngle_library[g_irelevant_saveloc[client]], g_fvelocity_library[g_irelevant_saveloc[client]]);
			PrintToChat(client, "teleported to saveloc %d", g_irelevant_saveloc[client]);
			return Plugin_Handled;
		}

		case true:
		{
			nexttele = g_ilast_created_saveloc[client][g_irelevant_saveloc[client] + 1];
			g_irelevant_saveloc[client] = nexttele;
			TeleportEntity(client, g_forigin_library[g_irelevant_saveloc[client]], g_feyeAngle_library[g_irelevant_saveloc[client]], g_fvelocity_library[g_irelevant_saveloc[client]]);
			PrintToChat(client, "teleported to saveloc %d",g_irelevant_saveloc[client]);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
}



//this is for debugging.
/*
public Action settele(int client, int args)
{
	switch (args)
	{
		case 0:
		{
			PrintToChat(client, "usage, sm_settele <number>");
			return Plugin_Handled;
		}
		case 1:
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			int set_tele = StringToInt(arg1);
			
			g_isaveloc_number = set_tele;
	
			PrintToChat(client, "sent to tele %d... be careful...", g_isaveloc_number);
	
			return Plugin_Handled;
		}
		default:
		{
			PrintToChat(client, "usage, sm_settele <number>");
			return Plugin_Handled;
		}
	}
}
*/

