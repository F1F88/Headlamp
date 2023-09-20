
enum
{
    OBS_MODE_NONE = 0,
    OBS_MODE_IN_EYE = 4,    // First Person
    OBS_MODE_CHASE,         // Third Person
    OBS_MODE_POI,           // Third Person but no player name and health ?
    OBS_MODE_FREE,          // Free
}

enum
{
    G_HasFlashlight,        // 是否拥有手电筒
    G_HasWalkieTalkie,      // 是否拥有对讲机

    G_Total
}

enum
{
    O_OwnerEntity,          // 实体拥有者
    O_ObserverMode,         // 观察模式
    O_ObserverTarget,       // 观察的目标
    O_ActiveWeapon,         // 当前武器

    O_Total
};

int     g_offset[O_Total];

Handle  g_game_data[G_Total];


stock bool NMRIH_LoadOffset(char[] error, int err_max)
{
    if( (g_offset[O_OwnerEntity]    = FindSendPropInfo("CDynamicProp", "m_hOwnerEntity")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CDynamicProp::m_hOwnerEntity'!");
        return false;
    }
    if( (g_offset[O_ObserverMode]   = FindSendPropInfo("CNMRiH_Player", "m_iObserverMode")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::m_iObserverMode'!");
        return false;
    }
    if( (g_offset[O_ObserverTarget] = FindSendPropInfo("CNMRiH_Player", "m_hObserverTarget")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::m_hObserverTarget'!");
        return false;
    }
    if( (g_offset[O_ActiveWeapon]   = FindSendPropInfo("CNMRiH_Player", "m_hActiveWeapon")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::m_hActiveWeapon'!");
        return false;
    }
    return true;
}

stock void NMRIH_LoadGameData(Handle game_data)
{
    int offset = GameConfGetOffsetOrFail(game_data, "CNMRiH_Player::HasFlashlight");
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetVirtual(offset);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    g_game_data[G_HasFlashlight] = EndPrepSDKCall();

    offset = GameConfGetOffsetOrFail(game_data, "CNMRiH_Player::HasWalkieTalkie");
    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetVirtual(offset);
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    g_game_data[G_HasWalkieTalkie] = EndPrepSDKCall();
}

stock int NMRIH_Get_Owner_Entity(int entity)
{
    return GetEntDataEnt2(entity, g_offset[O_OwnerEntity])
}

stock int NMRIH_Get_Observer_Mode(int client)
{
    return GetEntData(client, g_offset[O_ObserverMode]);
}

stock int NMRIH_Get_Observer_Target(int client)
{
    return GetEntDataEnt2(client, g_offset[O_ObserverTarget]);
}

stock int NMRIH_GetActiveWeapon(int client)
{
    return GetEntDataEnt2(client, g_offset[O_ActiveWeapon]);
}

stock bool NMRIH_HasFlashlight(int client)
{
    return SDKCall(g_game_data[G_HasWalkieTalkie], client);
}

stock bool NMRIH_HasWalkieTalkie(int client)
{
    return SDKCall(g_game_data[G_HasFlashlight], client);
}

stock bool NMRIH_IsGun(char []classname)
{
    return ! strncmp(classname, "fa_", 3);
}

stock bool NMRIH_IsBowDeerHunter(char []classname)
{
    return classname[0] == 'b';                 // bow_deerhunter
}

stock bool NMRIH_IsHandGun(char []classname)
{
    if(
        ! strncmp(classname, "fa_g",   4) ||    // fa_glock17
        ! strncmp(classname, "fa_m9",  5) ||    // fa_m92fs
        ! strncmp(classname, "fa_mk",  5) ||    // fa_mkiii
        ! strncmp(classname, "fa_19",  6) ||    // fa_1911
        ! strncmp(classname, "fa_sw",  5)       // fa_sw686
    )
        return true;
    return false;
}

stock bool NMRIH_IsMAC10(char []classname)
{
    return ! strncmp(classname, "fa_ma", 5);    // fa_mac10
}

stock bool NMRIH_IsFlareGun(char []classname)
{
    return ! strncmp(classname, "tool_f", 6);   // tool_flare_gun
}

stock bool NMRIH_IsMaglite(char []classname)
{
    return ! strncmp(classname, "item_m", 6);   // item_maglite
}


/**
 * Retrieve an offset from a game conf or abort the plugin.
 */
int GameConfGetOffsetOrFail(Handle gameconf, const char[] key)
{
    int offset = GameConfGetOffset(gameconf, key);
    if (offset == -1)
    {
        CloseHandle(gameconf);
        SetFailState("Failed to read gamedata offset of %s", key);
    }
    return offset;
}
