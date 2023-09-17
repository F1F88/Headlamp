
#define BODY_NOMAGLITE 1

// 根据传入的参数创建一个 prop_dynamic_override
// 如果创建失败返回 INVALID_ENT_REFERENCE
int Models_CreateModel(int client, SectionModel model)
{
    int prop = CreateEntityByName("prop_dynamic_override");

    if( prop == -1 )
    {
        LogError("Create prop_dynamic_override failure!");
        return INVALID_ENT_REFERENCE;
    }

    DispatchKeyValue(prop,      "model",                model.path);
    DispatchKeyValue(prop,      "spawnflags",           "256");                     // Start with collision disabled
    DispatchKeyValue(prop,      "solid",                "0");                       // no solid model
    DispatchKeyValue(prop,      "CollisionGroup",       "0");                       // 为此实体设置一个碰撞组，这会更改其碰撞行为
    DispatchKeyValue(prop,      "effects",              "0");                       // 要使用的效果标志的组合

    DispatchSpawn(prop);

    SetVariantString("!activator");
    AcceptEntityInput(prop,     "SetParent",            client);
    SetVariantString(model.attachment);
    AcceptEntityInput(prop,     "SetParentAttachment");

    AcceptEntityInput(prop,     "DisableShadows");
    AcceptEntityInput(prop,     "disableshadowdepth");
    AcceptEntityInput(prop,     "disablereceiveshadows");
    AcceptEntityInput(prop,     "disableflashlight");
    AcceptEntityInput(prop,     "DisableCollision");

    SDKHook(prop,               SDKHook_SetTransmit,    Models_OnModelTransmit);    // 避免第一人称模型造成遮挡

    SetEntProp(prop,            Prop_Data,              "m_iEFlags",                0);
    SetEntProp(prop,            Prop_Data,              "m_CollisionGroup",         0x0004);
    SetEntProp(prop,            Prop_Send,              "m_nBody",                  BODY_NOMAGLITE);
    SetEntProp(prop,            Prop_Send,              "m_nModelIndex",            model.model_index);
    SetEntPropEnt(prop,         Prop_Send,              "m_hOwnerEntity",           client);
    SetEntPropFloat(prop,       Prop_Send,              "m_flModelScale",           model.scale);
    SetEntPropVector(prop,      Prop_Send,              "m_vecMins",                {0.0, 0.0, 0.0});
    SetEntPropVector(prop,      Prop_Send,              "m_vecMaxs",                {0.0, 0.0, 0.0});

    TeleportEntity(prop,        model.offset,           model.rotation);

    return EntIndexToEntRef(prop);
}

// 避免模型遮挡视线 (次函数每秒执行约 100 - 150 次)
Action Models_OnModelTransmit(int entity, int client)
{
    // 获取 entity 的拥有者
    int owner_client = NMRIH_Get_Owner_Entity(entity);
    if( owner_client == client )
    {
        // 拥有者处于第一视角, 应该忽略, 否则模型可能造成遮挡
        if( OBS_MODE_NONE == NMRIH_Get_Observer_Mode(client))
            return Plugin_Handled;
    }
    else
    {
        // 其他玩家, 处于第一视角
        if( OBS_MODE_IN_EYE == NMRIH_Get_Observer_Mode(client) )
        {
            // 观看的目标是拥有者
            if( owner_client == NMRIH_Get_Observer_Target(client) )
                return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
