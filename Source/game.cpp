#include "game.h"

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
    engineParameters_[EP_WINDOW_TITLE] = GetTypeName();
    engineParameters_[EP_LOG_NAME]     = GetSubsystem<FileSystem>()->GetAppPreferencesDir("urho3d", "logs") + GetTypeName() + ".log";
    engineParameters_[EP_FULL_SCREEN]  = false;
    engineParameters_[EP_HEADLESS]     = false;
    engineParameters_[EP_SOUND]        = true;
	engineParameters_[EP_LOG_LEVEL]     = LOG_DEBUG;
	engineParameters_[EP_WINDOW_WIDTH] = WINDOW_WIDTH;
	engineParameters_[EP_WINDOW_HEIGHT] = WINDOW_HEIGHT;
	engineParameters_[EP_WINDOW_MAXIMIZE] = true;
	engineParameters_[EP_WINDOW_RESIZABLE] = true;

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

    ResourceCache* cache = GetSubsystem<ResourceCache>();
    scene_ = MakeShared<Scene>(context_);

    scene_->CreateComponent<Octree>();

    Node* node = scene_->CreateChild("CameraNode");
    EditingCamera* camera = node->CreateComponent<EditingCamera>();
    camera->SetCameraBounds(Vector2(-200, -200), Vector2(200, 200));
    camera->SetScrollSpeed(32.0f);
    camera->SetMaxFollow(600.f);

    node = scene_->CreateChild("TreeNode");
    StaticModel* model = node->CreateComponent<StaticModel>();
    model->SetModel(cache->GetResource<Model>("Models/TreeTrunk.mdl"));
    model->SetMaterial(cache->GetResource<Material>("Materials/White.xml"));

    model = node->CreateComponent<StaticModel>();
    model->SetModel(cache->GetResource<Model>("Models/TreeCrown.mdl"));
    model->SetMaterial(cache->GetResource<Material>("Materials/TreeCrown.xml"));

    node = scene_->CreateChild("LightNode");
    Zone* zone = node->CreateComponent<Zone>();
    zone->SetAmbientBrightness(0.25f);
    zone->SetAmbientColor(Color(0.5, 0.5, 0.75));
    zone->SetBoundingBox(BoundingBox(-100, 100));
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

void Game::HandleUpdate(StringHash eventType, VariantMap &eventData)
{
	static StringHash TimeStep("TimeStep"), CameraSetPosition("CameraSetPosition"), position("position");
	float dt=eventData[TimeStep].GetFloat();
	
}


URHO3D_DEFINE_APPLICATION_MAIN(Game)
