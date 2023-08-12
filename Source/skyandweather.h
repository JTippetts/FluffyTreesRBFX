#pragma once

#include <Urho3D/Core/Object.h>
#include <Urho3D/Core/Context.h>
#include <Urho3D/Math/Matrix3.h>
#include <Urho3D/Graphics/Material.h>
#include <Urho3D/Graphics/Light.h>
#include <Urho3D/Scene/Scene.h>
#include <Urho3D/Scene/Node.h>

using namespace Urho3D;

class SkyAndWeather : public Object
{
	URHO3D_OBJECT(SkyAndWeather, Object);
public:
	SkyAndWeather(Context* context);
	~SkyAndWeather() override = default;

	void AddMaterial(Material* mat);

	void SetupLights(Scene* scene);


protected:
	Matrix3 sunTransform_;
	Matrix3 moonTransform_;
	ea::vector<WeakPtr<Material>> materials_;
	Node* sunlightnode_{ nullptr };
	Node* moonlightnode_{ nullptr };
	Light* sunlight_{ nullptr };
	Light* moonlight_{ nullptr };

	// Time constants
	float hoursPerDay_{ 24.f };
	int daysPerYear_{ 365 };
	float planetTilt_{ 23.44f };
	float moonOrbitalPeriod_{ 29.5f };
	float moonOrbitalInclination_{ 5.14f };

	// Variables
	float timeOfDay_{ 0.f };
	float latitude_{ 0.f };
	int dayOfYear_{ 0 };
	float timeScale_{ 1.f };
	float cloudTime_{ 0.f };
	float cloudTimeScale_{ 1.f };

	float sunBrightness_{ 1.f };
	float moonBrightness_{ 1.f };

	void CalculateTransforms();
	void UpdateMaterials();

	void HandleUpdate(StringHash eventType, VariantMap& eventData);
};
