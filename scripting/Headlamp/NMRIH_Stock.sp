
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
    O_OwnerEntity,      // 实体拥有者
    O_ObserverMode,     // 观察模式
    O_ObserverTarget,   // 观察的目标
    O_ActiveWeapon,     // 当前武器
    O_HasWalkieTalkie,  // 是否拥有对讲机

    O_Total
};

int g_offset[O_Total];


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
    if( (g_offset[O_HasWalkieTalkie] = FindSendPropInfo("CNMRiH_Player", "m_bTalkingWalkie")) < 1 )
    {
        strcopy(error, err_max,     "Can't find offset 'CNMRiH_Player::m_bTalkingWalkie'!");
        return false;
    }
    return true;
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
    return RunEntVScriptBool(client, "HasFlashlight()");
}

stock bool NMRIH_HasWalkieTalkie(int client)
{
    return RunEntVScriptBool(client, "HasWalkieTalkie()");
    // ! now work
    // return GetEntData(client, g_offset[O_HasWalkieTalkie], 1) == 1;
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
