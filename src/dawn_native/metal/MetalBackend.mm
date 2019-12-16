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

// MetalBackend.cpp: contains the definition of symbols exported by MetalBackend.h so that they
// can be compiled twice: once export (shared library), once not exported (static library)

#include "dawn_native/MetalBackend.h"

#include "dawn_native/Texture.h"
#include "dawn_native/metal/DeviceMTL.h"

namespace dawn_native { namespace metal {

    id<MTLDevice> GetMetalDevice(WGPUDevice cDevice) {
        Device* device = reinterpret_cast<Device*>(cDevice);
        return device->GetMTLDevice();
    }

    WGPUTexture WrapIOSurface(WGPUDevice cDevice,
                              const WGPUTextureDescriptor* cDescriptor,
                              IOSurfaceRef ioSurface,
                              uint32_t plane) {
        Device* device = reinterpret_cast<Device*>(cDevice);
        const TextureDescriptor* descriptor =
            reinterpret_cast<const TextureDescriptor*>(cDescriptor);
        TextureBase* texture = device->CreateTextureWrappingIOSurface(descriptor, ioSurface, plane);
        return reinterpret_cast<WGPUTexture>(texture);
    }

    WGPUTexture WrapCVPixelBuffer(WGPUDevice cDevice,
                                  const WGPUTextureDescriptor* cDescriptor,
                                  CVPixelBufferRef pixelBuffer,
                                  uint32_t plane) {
        return WrapIOSurface(cDevice, cDescriptor, CVPixelBufferGetIOSurface(pixelBuffer), plane);
    }

    DAWN_NATIVE_EXPORT WGPUTexture WrapCVMetalTexture(WGPUDevice cDevice,
                                                      const WGPUTextureDescriptor* cDescriptor,
                                                      CVMetalTextureRef metalTexture) {
        Device* device = reinterpret_cast<Device*>(cDevice);
        const TextureDescriptor* descriptor =
            reinterpret_cast<const TextureDescriptor*>(cDescriptor);
        TextureBase* texture = device->CreateTextureWrappingCVMetalTexture(descriptor, metalTexture);
        return reinterpret_cast<WGPUTexture>(texture);
    }

    void WaitForCommandsToBeScheduled(WGPUDevice cDevice) {
        Device* device = reinterpret_cast<Device*>(cDevice);
        device->WaitForCommandsToBeScheduled();
    }

}}  // namespace dawn_native::metal
