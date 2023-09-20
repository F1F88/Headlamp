

#define MAX_INT                     10
#define MAX_BOOL                    2
#define MAX_FLOAT                   16
#define MAX_COLOR                   32
#define MAX_ATTACHMENT              32
#define MODEL_PROPS_SPOTLIGHT       "models/props/barnsley/spotlight.mdl"

ConfigCache     g_configs;          // 缓存配置文件

enum struct SectionLight
{
    bool        enabled;

    char        fov[MAX_FLOAT];
    char        range[MAX_FLOAT];
    char        enableshadows[MAX_BOOL];
    char        shadowquality[MAX_INT];
    char        lightworld[MAX_INT];
    char        color[MAX_COLOR];

    char        attachment[MAX_ATTACHMENT];
    float       offset[3];
    float       rotation[3];
}

enum struct SectionModel
{
    bool        enabled;

    float       scale;
    char        path[PLATFORM_MAX_PATH];
    int         model_index;

    char        attachment[MAX_ATTACHMENT];
    float       offset[3];
    float       rotation[3];
}

enum struct ConfigCache
{
    SectionLight light;
    ArrayList    models;
}


void Configs_ParseFile()
{
    char cfg[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, cfg, sizeof(cfg), "configs/"...PLUGIN_NAME...".cfg");
    KeyValues kv = new KeyValues(PLUGIN_NAME);

    if( ! kv.ImportFromFile(cfg) )
    {
        SetFailState("Couldn't read from \"%s\"", cfg);
    }

    Configs_ParseSectionLight(kv);
    Configs_ParseSectionModels(kv);
}

void Configs_ParseSectionLight(KeyValues kv)
{
    kv.Rewind();

    if( ! kv.JumpToKey("lights") )
    {
        SetFailState("The (configs - lights section) cannot be found");
    }

    // 如果 light section 为空, 则使用默认值
    kv.GotoFirstSubKey();

    g_configs.light.enabled   = kv.GetNum("enabled", 1) == 0 ? false : true;

    kv.GetString("fov",             g_configs.light.fov,              sizeof(SectionLight::fov),              "16.0");
    kv.GetString("range",           g_configs.light.range,            sizeof(SectionLight::range),            "512.0");
    kv.GetString("enableshadows",   g_configs.light.enableshadows,    sizeof(SectionLight::enableshadows),    "0");
    kv.GetString("shadowquality",   g_configs.light.shadowquality,    sizeof(SectionLight::shadowquality),    "0");
    kv.GetString("lightworld",      g_configs.light.lightworld,       sizeof(SectionLight::lightworld),       "1");
    kv.GetString("color",           g_configs.light.color,            sizeof(SectionLight::color),            "252 240 192 192");

    kv.GetString("attachment",      g_configs.light.attachment,       sizeof(SectionLight::attachment),       "Head");
    kv.GetVector("offset",          g_configs.light.offset,           { 0.0, 0.0, 0.0 });
    kv.GetVector("rotation",        g_configs.light.rotation,         { 0.0, 0.0, 0.0 });

    kv.Rewind();
}

void Configs_ParseSectionModels(KeyValues kv)
{
    kv.Rewind();

    if( ! kv.JumpToKey("models") )
    {
        SetFailState("The (configs - models section) cannot be found");
    }

    g_configs.models.Clear();

    do
    {
        kv.GotoFirstSubKey();

        SectionModel model;

        model.enabled   = kv.GetNum("enabled", 0) == 0 ? false : true;
        model.scale     = kv.GetFloat("scale", 1.0);
        kv.GetString("path",            model.path,             sizeof(SectionModel::path),             MODEL_PROPS_SPOTLIGHT);
        kv.GetString("attachment",      model.attachment,       sizeof(SectionModel::attachment),       "Head");
        kv.GetVector("offset",          model.offset,           { 0.0, 0.0, 0.0 });
        kv.GetVector("rotation",        model.rotation,         { 0.0, 0.0, 0.0 });

        model.model_index = PrecacheModel(model.path);

        g_configs.models.PushArray(model, sizeof(SectionModel));
    }
    while( kv.GotoNextKey() );

    kv.Rewind();
}
