// Copyright 2019 The Dawn Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <gtest/gtest.h>

#include "dawn/dawn_proc.h"
#include "dawn_native/Instance.h"
#include "dawn_native/null/DeviceNull.h"
#include "dawn_wire/WireClient.h"
#include "utils/TerribleCommandBuffer.h"

namespace {

    // libdawn_wire and libdawn_native contain duplicated code for the handling of GetProcAddress
    // so we run the tests against both implementations. This enum is used as a test parameters to
    // know which implementation to test.
    enum class DawnFlavor {
        Native,
        Wire,
    };

    std::ostream& operator<<(std::ostream& stream, DawnFlavor flavor) {
        switch (flavor) {
            case DawnFlavor::Native:
                stream << "dawn_native";
                break;

            case DawnFlavor::Wire:
                stream << "dawn_wire";
                break;

            default:
                UNREACHABLE();
                break;
        }
        return stream;
    }

    class GetProcAddressTests : public testing::TestWithParam<DawnFlavor> {
      public:
        GetProcAddressTests()
            : testing::TestWithParam<DawnFlavor>(),
              mNativeInstance(),
              mNativeAdapter(&mNativeInstance) {
        }

        void SetUp() override {
            switch (GetParam()) {
                case DawnFlavor::Native: {
                    mDevice = dawn::Device::Acquire(
                        reinterpret_cast<DawnDevice>(mNativeAdapter.CreateDevice(nullptr)));
                    mProcs = dawn_native::GetProcs();
                    break;
                }

                case DawnFlavor::Wire: {
                    mC2sBuf = std::make_unique<utils::TerribleCommandBuffer>();

                    dawn_wire::WireClientDescriptor clientDesc = {};
                    clientDesc.serializer = mC2sBuf.get();
                    mWireClient = std::make_unique<dawn_wire::WireClient>(clientDesc);

                    mDevice = dawn::Device::Acquire(mWireClient->GetDevice());
                    mProcs = mWireClient->GetProcs();
                    break;
                }

                default:
                    UNREACHABLE();
                    break;
            }

            dawnProcSetProcs(&mProcs);
        }

        void TearDown() override {
            // Destroy the device before freeing the instance or the wire client in the destructor
            mDevice = dawn::Device();
        }

      protected:
        dawn_native::InstanceBase mNativeInstance;
        dawn_native::null::Adapter mNativeAdapter;

        std::unique_ptr<utils::TerribleCommandBuffer> mC2sBuf;
        std::unique_ptr<dawn_wire::WireClient> mWireClient;

        dawn::Device mDevice;
        DawnProcTable mProcs;
    };

    // Test GetProcAddress with and without devices on some valid examples
    TEST_P(GetProcAddressTests, ValidExamples) {
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "dawnDeviceCreateBuffer"),
                  reinterpret_cast<DawnProc>(mProcs.deviceCreateBuffer));
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "dawnDeviceCreateBuffer"),
                  reinterpret_cast<DawnProc>(mProcs.deviceCreateBuffer));
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "dawnQueueSubmit"),
                  reinterpret_cast<DawnProc>(mProcs.queueSubmit));
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "dawnQueueSubmit"),
                  reinterpret_cast<DawnProc>(mProcs.queueSubmit));
    }

    // Test GetProcAddress with and without devices on nullptr procName
    TEST_P(GetProcAddressTests, Nullptr) {
        ASSERT_EQ(mProcs.getProcAddress(nullptr, nullptr), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), nullptr), nullptr);
    }

    // Test GetProcAddress with and without devices on some invalid
    TEST_P(GetProcAddressTests, InvalidExamples) {
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "dawnDeviceDoSomething"), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "dawnDeviceDoSomething"), nullptr);

        // Trigger the condition where lower_bound will return the end of the procMap.
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "zzzzzzz"), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "zzzzzzz"), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "ZZ"), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "ZZ"), nullptr);

        // Some more potential corner cases.
        ASSERT_EQ(mProcs.getProcAddress(nullptr, ""), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), ""), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "0"), nullptr);
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "0"), nullptr);
    }

    // Test that GetProcAddress supports itself: it is handled specially because it is a
    // freestanding function and not a method on an object.
    TEST_P(GetProcAddressTests, GetProcAddressItself) {
        ASSERT_EQ(mProcs.getProcAddress(nullptr, "dawnGetProcAddress"),
                  reinterpret_cast<DawnProc>(mProcs.getProcAddress));
        ASSERT_EQ(mProcs.getProcAddress(mDevice.Get(), "dawnGetProcAddress"),
                  reinterpret_cast<DawnProc>(mProcs.getProcAddress));
    }

    INSTANTIATE_TEST_SUITE_P(,
                             GetProcAddressTests,
                             testing::Values(DawnFlavor::Native, DawnFlavor::Wire),
                             testing::PrintToStringParamName());

    TEST(GetProcAddressInternalTests, CheckDawnNativeProcMapOrder) {
        std::vector<const char*> names = dawn_native::GetProcMapNamesForTesting();
        for (size_t i = 1; i < names.size(); i++) {
            ASSERT_LT(std::string(names[i - 1]), std::string(names[i]));
        }
    }

    TEST(GetProcAddressInternalTests, CheckDawnWireClientProcMapOrder) {
        std::vector<const char*> names = dawn_wire::client::GetProcMapNamesForTesting();
        for (size_t i = 1; i < names.size(); i++) {
            ASSERT_LT(std::string(names[i - 1]), std::string(names[i]));
        }
    }
}  // anonymous namespace