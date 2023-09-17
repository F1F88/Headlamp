

// 根据传入的参数创建一个 env_projectedtexture
// 如果创建失败返回 INVALID_ENT_REFERENCE
int Light_CreateLight(int client, SectionLight light)
{
    int entity = CreateEntityByName("env_projectedtexture");

    if( entity == -1 )
    {
        LogError("Create env_projectedtexture failure!");
        return INVALID_ENT_REFERENCE;
    }

    DispatchKeyValue(entity,    "lightfov",             light.fov);                 // 纹理投影到的视场锥体/棱锥体
    DispatchKeyValue(entity,    "nearz",                "16.0");                    // 比此距离近的物体不会接收到来自投影的光
    DispatchKeyValue(entity,    "farz",                 light.range);               // 比此距离远的物体不会接收到投影发出的光
    DispatchKeyValue(entity,    "enableshadows",        light.enableshadows);       // 是否开启投射出来的阴影. 0 = no, 1 = yes.
    DispatchKeyValue(entity,    "shadowquality",        light.shadowquality);       // 阴影质量. 0: 低 (锐利的、像素化的阴影) | 1: 高 (边缘平滑的阴影)
    DispatchKeyValue(entity,    "lightworld",           light.lightworld);          // 是否影响世界上的静态几何. 0 = no, 1 = yes.
    DispatchKeyValue(entity,    "lightcolor",           light.color);               // 光的颜色和强度 (与 light 相比，该实体具有不同的亮度规则。最好从 10000 开始，亮度等级为 5-10)
    DispatchKeyValue(entity,    "spawnflags",           "3");                       // 始终更新, 用于移动光源
    // DispatchKeyValue(entity,    "effects",              "129");                     // 要使用的效果标志的组合
    // DispatchKeyValue(entity,    "textureframe",         light.textureframe);        // 材质帧数

    DispatchSpawn(entity);

    SetVariantString("!activator");
    AcceptEntityInput(entity,   "SetParent",            client);
    SetVariantString(light.attachment);
    AcceptEntityInput(entity,   "SetParentAttachment");

    AcceptEntityInput(entity, "TurnOn");

    SetEntPropEnt(entity,       Prop_Send,              "m_hOwnerEntity",           client);
    SetEntPropVector(entity,    Prop_Send,              "m_vecMins",                {0.0, 0.0, 0.0});
    SetEntPropVector(entity,    Prop_Send,              "m_vecMaxs",                {0.0, 0.0, 0.0});

    TeleportEntity(entity, light.offset, light.rotation);

    return EntIndexToEntRef(entity);
}

