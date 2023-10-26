#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <multicolors>

#pragma semicolon 1
#pragma newdecls required


#undef  MAXPLAYERS
#define MAXPLAYERS                          9

#define SOUND_FLASHLIGHT_ON                 "weapons/tools/flashlight/flashlight_on2.wav"
#define SOUND_FLASHLIGHT_OFF                "weapons/tools/flashlight/flashlight_off2.wav"

#define PLUGIN_NAME                         "Headlamp"
#define PLUGIN_VERSION                      "v1.0.2"
#define PLUGIN_DESCRIPTION                  "Create a headlamp for the user to use for lighting"
#define PREFIX_CV                           "sm_headlamp"
#define PREFIX_PHRASES_FILE                 PLUGIN_NAME


public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = "F1F88",
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = "https://github.com/F1F88/"
};


// #include "Headlamp/ConVar.sp"
#include "Headlamp/NMRIH_Stock.sp"
#include "Headlamp/Configs.sp"
#include "Headlamp/Light.sp"
#include "Headlamp/Models.sp"


enum struct ClientData
{
    bool        enabled;
    int         light_ref;
    ArrayList   models_ref;
}

ClientData      g_client_data[MAXPLAYERS + 1];      // 存储客户开启头灯所使用的实体引用



public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if( ! NMRIH_LoadOffset(error, err_max) )
        return APLRes_Failure;

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations(PREFIX_PHRASES_FILE...".phrases");

    CreateConVar(PREFIX_CV..."_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY | FCVAR_DONTRECORD);
    // ConVar_Load();

    Handle game_data = new GameData(PLUGIN_NAME...".games");
    if( game_data == INVALID_HANDLE )
		SetFailState("Failed to load gamedata");

    NMRIH_LoadGameData(game_data);

    // AutoExecConfig(true, PLUGIN_NAME);

    RegConsoleCmd("sm_hl",          CMD_Toggle_Headlamp,    "Toggle headlamp");
    RegConsoleCmd("sm_headlamp",    CMD_Toggle_Headlamp,    "Toggle headlamp");

    HookEvent("player_death",       On_player_death,        EventHookMode_Post);
    HookEvent("player_extracted",   On_player_extracted,    EventHookMode_Post);

    g_configs.models = new ArrayList(sizeof(SectionModel));

    for(int client=1; client<=MaxClients; ++client)
    {
        if( IsClientInGame(client) )
        {
            OnClientPutInServer(client);
        }
    }
}

public void OnConfigsExecuted()
{
    Configs_ParseFile();
    PrecacheSound(SOUND_FLASHLIGHT_ON);
    PrecacheSound(SOUND_FLASHLIGHT_OFF);
}

public void OnPluginEnd()
{
    for(int client=1; client<=MaxClients; ++client)
    {
        RemoveLightAndModels(client);
    }
}

// ========================================================================================================================================================================

public void OnClientPutInServer(int client)
{
    g_client_data[client].enabled = false;
    g_client_data[client].models_ref = new ArrayList();

    SDKHook(client, SDKHook_WeaponDropPost,     On_WeaponDropPost);
    SDKHook(client, SDKHook_WeaponSwitchPost,   On_WeaponSwitchPost);
}

public void OnClientDisconnect(int client)
{
    RemoveLightAndModels(client);
    delete g_client_data[client].models_ref;
}

void On_player_death(Event event, const char[] name, bool dontBroadcast)
{
    RemoveLightAndModels( GetClientOfUserId( event.GetInt("userid") ) );
}

void On_player_extracted(Event event, const char[] name, bool dontBroadcast)
{
    RemoveLightAndModels( event.GetInt("player_id") );
}

//
void On_WeaponDropPost(int client, int weapon)
{
    if( g_client_data[client].enabled && ! CanTurnOnHeadlamp(client) )
    {
        TurnOffHeadlamp(client);
    }
}

// 参数 weapon 为切换后的武器
void On_WeaponSwitchPost(int client, int weapon)
{
    int light_entity = EntRefToEntIndex( g_client_data[client].light_ref );
    if( ! IsValidEntity( light_entity ) )
        return ;

    // 如果玩家拥有光源, 则需要在切换武器时修正角度
    // Todo: 通过配置文件来控制修正角度
    NMRIH_Correction_Light_Rotation(light_entity, weapon);
}

// ========================================================================================================================================================================

Action CMD_Toggle_Headlamp(int client, int args)
{
    if( client <= 0 || client >= MaxClients || ! IsClientInGame(client) )
    {
        ReplyToCommand(client, "["...PLUGIN_NAME..."] In-game command only.");
        return Plugin_Handled;
    }

    if( ! IsPlayerAlive(client) )
    {
        CPrintToChat(client, "%t%t", "Phrase_Chat_Prefix", "Phrase_Neew_Alive");
        return Plugin_Handled;
    }

    if( ! g_client_data[client].enabled )
    {
        if( ! CanTurnOnHeadlamp(client) )
        {
            CPrintToChat(client, "%t%t", "Phrase_Chat_Prefix", "Phrase_Neew_maglite_walkietalkie");
            return Plugin_Handled;
        }

        if( ! TurnOnHeadlamp(client) )
        {
            CPrintToChat(client, "%t%t", "Phrase_Chat_Prefix", "Phrase_TurnOn_Failure");
        }
        else
        {
            CPrintToChat(client, "%t%t", "Phrase_Chat_Prefix", "Phrase_TurnOn_Succsess");
        }
    }
    else
    {
        TurnOffHeadlamp(client);
        CPrintToChat(client, "%t%t", "Phrase_Chat_Prefix", "Phrase_TurnOff");
        return Plugin_Handled;
    }

    return Plugin_Handled;
}

bool TurnOnHeadlamp(int client)
{
    if( ! CreateLight(client) || ! CreateModels(client) )
    {
        return false;
    }

    g_client_data[client].enabled = true;

    NMRIH_Correction_Light_Rotation( EntRefToEntIndex(g_client_data[client].light_ref), NMRIH_GetActiveWeapon(client) );

    EmitSoundToClient(client, SOUND_FLASHLIGHT_ON);

    return true;
}

void TurnOffHeadlamp(int client)
{
    EmitSoundToClient(client, SOUND_FLASHLIGHT_OFF);
    RemoveLightAndModels(client);
}

// ========================================================================================================================================================================

bool CanTurnOnHeadlamp(int client)
{
    return NMRIH_HasFlashlight(client) || NMRIH_HasWalkieTalkie(client);
}

bool CreateLight(int client)
{
    int entity_ref = Light_CreateLight(client, g_configs.light);
    if( entity_ref == INVALID_ENT_REFERENCE )
    {
        return false;
    }
    g_client_data[client].light_ref = entity_ref;
    return true;
}

bool CreateModels(int client)
{
    int len = g_configs.models.Length;
    for(int i=0; i<len; ++i)
    {
        SectionModel model;
        g_configs.models.GetArray(i, model, sizeof(SectionModel));

        if( ! model.enabled )
            continue ;

        int entity_ref = Models_CreateModel(client, model);
        if( entity_ref == INVALID_ENT_REFERENCE )
        {
            RemoveLightAndModels(client);
            return false;
        }
        g_client_data[client].models_ref.Push(entity_ref);
    }
    return true;
}

// 移除插件为客户创建的所有实体, 将 headlamp switch flag 置为 false
bool RemoveLightAndModels(int client)
{
    // Light
    SafeRemoveEntity( EntRefToEntIndex( g_client_data[client].light_ref ) );

    // Models
    if( g_client_data[client].models_ref != null && g_client_data[client].models_ref != INVALID_HANDLE )
    {
        int len = g_client_data[client].models_ref.Length;
        for(int i=0; i<len; ++i)
        {
            SafeRemoveEntity( EntRefToEntIndex( g_client_data[client].models_ref.Get(i) ) );
        }
        g_client_data[client].models_ref.Clear();
    }

    g_client_data[client].enabled = false;

    return true;
}

// NMRIH 中玩家切换武器时可能导致光源角度偏移
// 此函数用于在玩家切换武器后修正光源角度
void NMRIH_Correction_Light_Rotation(int light_entity, int weapon)
{
    if( ! IsValidEntity(weapon) )
        return ;

    static char classname[32];
    GetEntityClassname(weapon, classname, sizeof(classname));

    if( NMRIH_IsGun(classname) || NMRIH_IsBowDeerHunter(classname))
    {
        if( NMRIH_IsHandGun(classname) )
        {
            TeleportEntity(light_entity, _, {20.0, -72.0, 0.0});
            return ;
        }
        TeleportEntity(light_entity, _, {25.6, -72.0, 0.0});
        return ;
    }

    // 信号枪、手电筒、MAC
    if( NMRIH_IsMaglite(classname) || NMRIH_IsFlareGun(classname) || NMRIH_IsMAC10(classname) )
    {
        TeleportEntity(light_entity, _, {20.0, -72.0, 0.0});
        return ;
    }

    TeleportEntity(light_entity, _, g_configs.light.rotation);
}

// 安全移除实体
// 避免世界、客户被移除，或无效的实体导致函数被中断
stock void SafeRemoveEntity(int entity)
{
    if( entity <= 0 )
    {
        // PrintToServer("["...PLUGIN_NAME..."] Attempted to delete world or invalid entity %d. ", entity);
        return ;
    }
    else if( entity <= MaxClients )
    {
        // PrintToServer("["...PLUGIN_NAME..."] Attempted to delete player or world entity %d. ", entity);
        return ;
    }
    else if( ! IsValidEntity(entity) )
    {
        // PrintToServer("["...PLUGIN_NAME..."] Attempted to delete a invalid entity %d. ", entity);
        return ;
    }

    RemoveEntity(entity);
}

// ========================================================================================================================================================================
