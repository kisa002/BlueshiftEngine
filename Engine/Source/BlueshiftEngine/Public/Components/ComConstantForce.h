// Copyright(c) 2017 POLYGONTEK
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http ://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#pragma once

#include "Component.h"

BE_NAMESPACE_BEGIN

class ComConstantForce : public Component {
public:
    OBJECT_PROTOTYPE(ComConstantForce);

    ComConstantForce();
    virtual ~ComConstantForce();

    virtual bool            AllowSameComponent() const override { return true; }

    virtual void            Init() override;

    virtual void            Update() override;

protected:
    void                    PropertyChanged(const char *classname, const char *propName);

    Vec3                    force;
    Vec3                    torque;
};

BE_NAMESPACE_END
