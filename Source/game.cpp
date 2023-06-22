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

}

void Game::Start()
{
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
