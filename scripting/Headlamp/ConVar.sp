
bool cv_plugin_enabled;

void ConVar_Load()
{
    ConVar convar;
    (convar = CreateConVar(PREFIX_CV..."_enabled",          "1",    "是否启用插件", _, true, 0.0, true, 1.0)).AddChangeHook(ConVar_On_Change);
    cv_plugin_enabled = convar.BoolValue;
}

void ConVar_On_Change(ConVar convar, const char[] old_value, const char[] new_value)
{
    if ( convar == INVALID_HANDLE )
    {
        return ;
    }

    char convar_name[64];
    convar.GetName(convar_name, 64);

    if( ! strcmp(convar_name, PREFIX_CV..."_enabled") )
    {
        cv_plugin_enabled = convar.BoolValue;
    }
}
