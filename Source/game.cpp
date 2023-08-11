#include "game.h"

// https://kelvinvanhoorn.com/2022/03/17/skybox-tutorial-part-1/

#include <Urho3D/Engine/Application.h>
#include <Urho3D/Graphics/Camera.h>
#include <Urho3D/UI/Cursor.h>
#include <Urho3D/Engine/Engine.h>
#include <Urho3D/Engine/EngineDefs.h>
#include <Urho3D/IO/FileSystem.h>
#include <Urho3D/Graphics/Graphics.h>
#include <Urho3D/Input/Input.h>
#include <Urho3D/Input/InputEvents.h>
#include <Urho3D/Graphics/Renderer.h>
#include <Urho3D/Resource/ResourceCache.h>
#include <Urho3D/Scene/Scene.h>
#include <Urho3D/Scene/SceneEvents.h>
#include <Urho3D/Graphics/Texture2D.h>
#include <Urho3D/Core/Timer.h>
#include <Urho3D/UI/UI.h>
#include <Urho3D/Resource/XMLFile.h>
#include <Urho3D/IO/Log.h>
#include <Urho3D/Container/Str.h>
#include <Urho3D/Graphics/Octree.h>
#include <Urho3D/Graphics/StaticModel.h>
#include <Urho3D/Graphics/Model.h>
#include <Urho3D/Resource/Image.h>
#include <Urho3D/Resource/XMLFile.h>
#include <Urho3D/Resource/XMLElement.h>
#include <Urho3D/Resource/JSONFile.h>
#include <Urho3D/Resource/JSONValue.h>
#include <Urho3D/Scene/Scene.h>
#include <Urho3D/Scene/Node.h>
#include <Urho3D/Graphics/Light.h>
#include <Urho3D/Graphics/Material.h>
#include <Urho3D/Graphics/Zone.h>
#include <Urho3D/Graphics/Skybox.h>
#include <Urho3D/Math/Random.h>
#include <Urho3D/Graphics/Terrain.h>

#include "registercomponents.h"
#include "Components/editingcamera.h"

#define WINDOW_WIDTH 1024
#define WINDOW_HEIGHT 768

Game::Game(Context* context) :
    Application(context)
{
}

void Game::Setup()
{
    // Modify engine startup parameters
	GetSubsystem<FileSystem>()->Delete(GetSubsystem<FileSystem>()->GetAppPreferencesDir("urho3d", "logs") + GetTypeName() + ".log");
    engineParameters_[EP_ORGANIZATION_NAME] = "JTippetts";
    engineParameters_[EP_APPLICATION_NAME] = "Fluffy Trees";
    engineParameters_[EP_WINDOW_TITLE] = GetTypeName();
    engineParameters_[EP_LOG_NAME]     = GetSubsystem<FileSystem>()->GetAppPreferencesDir("urho3d", "logs") + GetTypeName() + ".log";
    engineParameters_[EP_FULL_SCREEN]  = false;
    engineParameters_[EP_HEADLESS]     = false;
    engineParameters_[EP_SOUND]        = true;
	engineParameters_[EP_LOG_LEVEL]     = LOG_DEBUG;
	engineParameters_[EP_WINDOW_MAXIMIZE] = true;
	engineParameters_[EP_WINDOW_RESIZABLE] = true;
    //engineParameters_[EP_SHADER_LOG_SOURCES] = true;
    engineParameters_[EP_CONFIG_NAME] = "";

    // Construct a search path to find the resource prefix with two entries:
    // The first entry is an empty path which will be substituted with program/bin directory -- this entry is for binary when it is still in build tree
    // The second and third entries are possible relative paths from the installed program/bin directory to the asset directory -- these entries are for binary when it is in the Urho3D SDK installation location
    if (!engineParameters_.contains(EP_RESOURCE_PREFIX_PATHS))
        engineParameters_[EP_RESOURCE_PREFIX_PATHS] = ";../share/Resources;../share/Urho3D/Resources";

    RegisterComponents(context_);
}

void Game::Start()
{
    SubscribeToEvent("KeyDown", URHO3D_HANDLER(Game, HandleKeyDown));
    SubscribeToEvent("KeyUp", URHO3D_HANDLER(Game, HandleKeyUp));
    SubscribeToEvent("Update", URHO3D_HANDLER(Game, HandleUpdate));

    
    context_->RegisterSubsystem(new SkyAndWeather(context_));
    SkyAndWeather* sky = GetSubsystem<SkyAndWeather>();
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    scene_ = MakeShared<Scene>(context_);

    scene_->CreateComponent<Octree>();

    
    sky->AddMaterial(cache->GetResource<Material>("Materials/Terrain4.xml"));
    // Setup terrain
    Node* tnode = scene_->CreateChild("Terrain");
    Terrain* terrain = tnode->CreateComponent<Terrain>();

    Image* hmap = cache->GetResource<Image>("Textures/elevation.png");
 
    terrain->SetHeightMap(hmap);
    terrain->SetMaterial(cache->GetResource<Material>("Materials/Terrain4.xml"));
    terrain->SetCastShadows(true);
    

    Node* node = scene_->CreateChild("CameraNode");
    EditingCamera* camera = node->CreateComponent<EditingCamera>();
    camera->SetCameraBounds(Vector2(-200, -200), Vector2(200, 200));
    camera->SetScrollSpeed(32.0f);
    camera->SetMaxFollow(600.f);
    camera->SetFarClip(600.f);

    Node* skyNode = scene_->CreateChild("Sky");
    skyNode->SetScale(500.0f); // The scale actually does not matter
    auto* skybox = skyNode->CreateComponent<Skybox>();
    skybox->SetModel(cache->GetResource<Model>("Models/Icosphere.mdl"));
    skybox->SetMaterial(cache->GetResource<Material>("Materials/Skybox.xml"));
    sky->AddMaterial(cache->GetResource<Material>("Materials/Skybox.xml"));


    /*for (unsigned i = 0; i < 6; ++i)
    {
        node = scene_->CreateChild("TreeNode");

        if (i % 2 == 0)
        {
            StaticModel* model = node->CreateComponent<StaticModel>();
            model->SetModel(cache->GetResource<Model>("Models/TreeTrunk.mdl"));
            model->SetMaterial(cache->GetResource<Material>("Materials/Brown.xml"));

            model = node->CreateComponent<StaticModel>();
            model->SetModel(cache->GetResource<Model>("Models/TreeCrown.mdl"));
            model->SetMaterial(cache->GetResource<Material>("Materials/TreeCrown.xml"));
        }
        else
        {
            StaticModel* model = node->CreateComponent<StaticModel>();
            model->SetModel(cache->GetResource<Model>("Models/Tree2Trunk.mdl"));
            model->SetMaterial(cache->GetResource<Material>("Materials/Brown.xml"));

            model = node->CreateComponent<StaticModel>();
            model->SetModel(cache->GetResource<Model>("Models/Tree2Crown.mdl"));
            model->SetMaterial(cache->GetResource<Material>("Materials/TreeCrown.xml"));
        }

        node->SetPosition(Vector3((float)i*20.f, 0, 0));
        node->SetRotation(Quaternion((float)i * 30.f, Vector3(0, 1, 0)));
    }*/

    node = scene_->CreateChild("LightNode");
    Zone* zone = node->CreateComponent<Zone>();
    zone->SetAmbientBrightness(0.25f);
    zone->SetAmbientColor(Color(0.5, 0.5, 0.75));
    zone->SetBoundingBox(BoundingBox(-10000, 10000));
    zone->SetFogStart(400.f);
    zone->SetFogEnd(600.f);
    zone->SetFogColor(Color(0.25f, 0.25f, 0.35f));

    Light* light = node->CreateComponent<Light>();
    light->SetLightType(LIGHT_DIRECTIONAL);
    node->SetDirection(Vector3(1.5, -1.5, 3.5));

    node = scene_->CreateChild("BackLightNode");
    light = node->CreateComponent<Light>();
    light->SetLightType(LIGHT_DIRECTIONAL);
    light->SetColor(Color(0.125, 0.125, 0.25));
    node->SetDirection(Vector3(-1.5, 1.5, -3.5));
}

void Game::Stop()
{
    engine_->DumpResources(true);
}

void Game::SetWindowTitleAndIcon()
{
    ResourceCache* cache = GetSubsystem<ResourceCache>();
    Graphics* graphics = GetSubsystem<Graphics>();
    Image* icon = cache->GetResource<Image>("Textures/UrhoIcon.png");
    graphics->SetWindowIcon(icon);
    graphics->SetWindowTitle("Fluffy Trees.");
}

void Game::CreateConsoleAndDebugHud()
{
    
}

void Game::HandleKeyUp(StringHash eventType, VariantMap& eventData)
{
    using namespace KeyUp;

	#ifndef EMSCRIPTEN
    int key = eventData[P_KEY].GetInt();
    // Close console (if open) or exit when ESC is pressed
    if (key == KEY_ESCAPE)
    {
       SendEvent(StringHash("Shutdown"));
		engine_->Exit();
    }
	#endif
}

void Game::HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    using namespace KeyDown;

    int key = eventData[P_KEY].GetInt();

    if (key == KEY_PRINTSCREEN)
    {
        Graphics* graphics = GetSubsystem<Graphics>();
        Image screenshot(context_);
        graphics->TakeScreenShot(screenshot);
        screenshot.SavePNG(GetSubsystem<FileSystem>()->GetProgramDir() + "Screenshot_" +
            Time::GetTimeStamp().replaced(':', '_').replaced('.', '_').replaced(' ', '_') + ".png");
    }
}

void Game::HandlePostRenderUpdate(StringHash eventType, VariantMap &eventData)
{

}

void Game::HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    static StringHash TimeStep("TimeStep"), CameraSetPosition("CameraSetPosition"), position("position");
    float dt = eventData[TimeStep].GetFloat();

    auto cache = GetSubsystem<ResourceCache>();

    time_ += dt;
    if (time_ > 3.f) time_ = 0.f;
    totaltime_ += dt*0.1f;

    weathertime_ -= dt;

    float blend = (time_ - 1.5f) / 1.5f;
    blend = fabs(blend);
    
    Material* skymat = cache->GetResource<Material>("Materials/Skybox.xml");
    Matrix3 sunTransform;
    sunTransform.FromAngleAxis(totaltime_ * 12.f, Vector3(0, 0, 1));

    moonTransform_.FromAngleAxis(totaltime_ * 12.f + 180.f, Vector3(1, 0.0, 0));
   //skymat->SetShaderParameter("SunDir", Variant(sunTransform.Column(0)));
   //skymat->SetShaderParameter("MoonDir", Variant(moonTransform_.Column(2)));
    Matrix3 invmoon;
    //invmoon.FromAngleAxis(-(totaltime_ * 12.f + 180.f), Vector3(1, 0, 0));
    invmoon = moonTransform_.Inverse();
   //skymat->SetShaderParameter("MoonTransform", Variant(invmoon));

    auto rnd = []()->float
    {
        return Rand() / 32767.f;
    };

    if (weathertime_ <= 0.0f)
    {
        currentweather_ = nextweather_;
        nextweather_.cirrus_ = rnd() * 1.5f;
        nextweather_.cumulus_ = rnd() * 2.f;
        nextweather_.cumulusbright_ = 1.f + rnd() * 1.f;
        weathertime_ = rnd() * 3.f + 1.f;
        weatherinterval_ = weathertime_;
    }

    float t = weathertime_ / weatherinterval_;
    t = std::min(1.f, std::max(0.f, 1.f - t));
    float cirrus = currentweather_.cirrus_ + t * (nextweather_.cirrus_ - currentweather_.cirrus_);
    float cumulus = currentweather_.cumulus_ + t * (nextweather_.cumulus_ - currentweather_.cumulus_);
    float cumulusbright = currentweather_.cumulusbright_ + t * (nextweather_.cumulusbright_ - currentweather_.cumulusbright_);

    //skymat->SetShaderParameter("Cirrus", Variant(cirrus));
    //skymat->SetShaderParameter("Cumulus", Variant(cumulus));
    //skymat->SetShaderParameter("CumulusBright", Variant(cumulusbright));
    //skymat->SetShaderParameter("CloudTime", Variant(totaltime_));
    skymat->SetShaderParameter("CloudData", Variant(Vector4(cirrus, cumulus, cumulusbright, totaltime_*0.5f)));
}


URHO3D_DEFINE_APPLICATION_MAIN(Game)
