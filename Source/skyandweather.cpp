#include "skyandweather.h"
#include <cmath>

SkyAndWeather::SkyAndWeather(Context* context) : Object(context)
{
	SubscribeToEvent("Update", URHO3D_HANDLER(SkyAndWeather, HandleUpdate));
}

void SkyAndWeather::AddMaterial(Material* m)
{
	// Check if already in there
	for (auto im : materials_)
	{
		if (im == m) return;
	}
	materials_.push_back(WeakPtr<Material>(m));
}

void SkyAndWeather::CalculateTransforms()
{
	float dayprogress = timeOfDay_ / hoursPerDay_;
	Matrix3 xrot;
	xrot.FromAngleAxis(dayprogress * 360.f, Vector3(1, 0, 0));

	float orbitprogress = ((float)dayOfYear_ + 193.f + dayprogress) / daysPerYear_;
	Matrix3 yrot;
	yrot.FromAngleAxis(cos(orbitprogress * 3.14159265f * 2.f) * planetTilt_, Vector3(0,1,0));

	Matrix3 zrot;
	zrot.FromAngleAxis(latitude_, Vector3(0, 0, 1));

	sunTransform_ = yrot * xrot * zrot;

	float moonorbitprogress = (fmodf((float)(dayOfYear_), moonOrbitalPeriod_) + dayprogress) / moonOrbitalPeriod_;
	xrot.FromAngleAxis((dayprogress - moonorbitprogress) * 360.f, Vector3(1, 0, 0));

	float axialtilt = moonOrbitalInclination_;
	axialtilt += planetTilt_ * sin((dayprogress * 2.f - 1.f) * M_PI);
	yrot.FromAngleAxis(axialtilt, Vector3(0, 1, 0));

	moonTransform_ = yrot * xrot * zrot;
}

void SkyAndWeather::UpdateMaterials()
{
	Matrix3 invmoon = moonTransform_.Inverse();

	auto i = materials_.begin();
	while (i != materials_.end())
	{
		WeakPtr<Material> m = *i;
		if (!m) i = materials_.erase(i);
		else
		{
			i++;
			m->SetShaderParameter("SunDir", Variant(sunTransform_.Column(2)));
			m->SetShaderParameter("MoonDir", Variant(moonTransform_.Column(2)));
			m->SetShaderParameter("MoonTransform", Variant(invmoon));
			m->SetShaderParameter("CloudData", Variant(Vector4(0, 0, 0, cloudTime_)));
		}
	}
}

void SkyAndWeather::HandleUpdate(StringHash eventType, VariantMap& eventData)
{
	float dt = eventData["TimeStep"].GetFloat();

	timeOfDay_ += dt * timeScale_;
	if (timeOfDay_ < 0.0)
	{
		timeOfDay_ += hoursPerDay_;
		dayOfYear_ -= 1;
	}
	if (timeOfDay_ > hoursPerDay_)
	{
		timeOfDay_ -= hoursPerDay_;
		dayOfYear_ += 1;
	}
	if (dayOfYear_ < 0)
	{
		dayOfYear_ += daysPerYear_;
	}
	if (dayOfYear_ > daysPerYear_)
	{
		dayOfYear_ -= daysPerYear_;
	}

	cloudTime_ += dt * cloudTimeScale_;

	CalculateTransforms();
	UpdateMaterials();
}