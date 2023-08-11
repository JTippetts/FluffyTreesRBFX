#pragma once

#include <Urho3D/Engine/Application.h>
#include <Urho3D/Scene/Scene.h>
#include <Urho3D/Scene/Node.h>

#include <vector>
#include "skyandweather.h"

// All Urho3D classes reside in namespace Urho3D
using namespace Urho3D;

class Game : public Application
{
	URHO3D_OBJECT(Game, Application);

public:
	explicit Game(Context* context);

	void Setup() override;
	void Start() override;
	void Stop() override;

private:
	SharedPtr<Scene> scene_;
	SharedPtr<SkyAndWeather> skyandweather_;

	void SetWindowTitleAndIcon();
	void CreateConsoleAndDebugHud();
	void HandleKeyDown(StringHash eventType, VariantMap& eventData);
	void HandleKeyUp(StringHash eventType, VariantMap& eventData);
	void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData);

	void HandleUpdate(StringHash eventType, VariantMap& eventData);

	float time_{ 0 };
	float totaltime_{ 0 };
	Matrix3 moonTransform_;

	struct WeatherState
	{
		float cirrus_{ 0 };
		float cumulus_{ 0 };
		float cumulusbright_{ 1 };
	};

	WeatherState currentweather_, nextweather_;
	float weathertime_{ 1 }, weatherinterval_{ 1 };
};
