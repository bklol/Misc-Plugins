#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


#define MODELO "sprites/spray_bullseye2"

public OnPluginStart()
{
    RegConsoleCmd("sm_tests", MakeSpray);
}

public OnMapStart()
{
    char model[124];
    Format(model, 124, "%s.vmt", MODELO);    
    PrecacheModel(model);
    Format(model, 124, "materials/%s.vmt", MODELO);
    AddFileToDownloadsTable(model);
    Format(model, 124, "materials/%s.vtf", MODELO);
    AddFileToDownloadsTable(model);
}

public Action:MakeSpray(client, args)
{    
    decl Float:fClientEyePosition[3];
    GetClientEyePosition(client, fClientEyePosition);

    decl Float:fClientEyeViewPoint[3];
    GetPlayerEyeViewPoint(client, fClientEyeViewPoint);

    decl Float:fVector[3];
    MakeVectorFromPoints(fClientEyeViewPoint, fClientEyePosition, fVector);
    
    char buffer[124];
    decl Float:vecAng[3];
    
    GetCmdArg(1, buffer, 124);
    vecAng[0]=StringToFloat(buffer);
    
    GetCmdArg(2, buffer, 124);
     vecAng[1]=StringToFloat(buffer);
     
     GetCmdArg(3, buffer, 124);
    vecAng[2]=StringToFloat(buffer);
    
    char model[124];
    Format(model, 124, "%s.vmt", MODELO);    
    CreateSprite(client, model, fClientEyeViewPoint, vecAng, 0.5, "0", 10.0);
    return Plugin_Handled;
}

stock GetPlayerEyeViewPoint(iClient, Float:fPosition[3])
{
    decl Float:fAngles[3];
    GetClientEyeAngles(iClient, fAngles);

    decl Float:fOrigin[3];
    GetClientEyePosition(iClient, fOrigin);

    new Handle:hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    if(TR_DidHit(hTrace))
    {
        TR_GetEndPosition(fPosition, hTrace);
        CloseHandle(hTrace);
        return true;
    }
    CloseHandle(hTrace);
    return false;
}

public bool:TraceEntityFilterPlayer(iEntity, iContentsMask)
{
    return iEntity > GetMaxClients();
}

        
/*
 * CREATE SPRITE
 * 
 * @param iClient                Player to target.
 * @param String:sprite            Path to VMT File.
 * @param Float:vOrigin[3]        Location of Sprite.
 * @param Float:fAng[3]            Angles (P Y R).
 * @param Float:Scale            Size of Sprite.
 * @param String:fps            Render Speed.
 * @param Float:fLifetime        Life of Sprite. 
 */
stock CreateSprite(iClient, String:sprite[], Float:vOrigin[3], Float:fAng[3], Float:Scale, String:fps[], Float:fLifetime) 
{ 
    new String:szTemp[64];  
    Format(szTemp, sizeof(szTemp), "client%i", iClient); 
    DispatchKeyValue(iClient, "targetname", szTemp); 
    
    new ent = CreateEntityByName("env_sprite_oriented"); 
    if (IsValidEdict(ent)) 
    { 
        new String:StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "ent_sprite_oriented_%i", ent); 
        DispatchKeyValue(ent, "model", sprite); 
        DispatchKeyValue(ent, "classname", "env_sprite_oriented");
        DispatchKeyValue(ent, "spawnflags", "1");
        DispatchKeyValueFloat(ent, "scale", Scale);
        DispatchKeyValue(ent, "rendermode", "1");
        DispatchKeyValue(ent, "rendercolor", "255 255 255");
        DispatchKeyValue(ent, "framerate", fps);
        DispatchKeyValueVector(ent, "Angles", fAng);
        DispatchSpawn(ent);
        
        TeleportEntity(ent, vOrigin, fAng, NULL_VECTOR); 
        
        CreateTimer(fLifetime, RemoveParticle, ent);
    } 
}

/*
 * REMOVE PARTICLE ENT
 * 
 * @param particle        Ent to remove.
 */
public Action:RemoveParticle(Handle:timer, any:particle)
{
    if(IsValidEdict(particle))
    {
        AcceptEntityInput(particle, "Deactivate");
        AcceptEntityInput(particle, "Kill");
    }
} 