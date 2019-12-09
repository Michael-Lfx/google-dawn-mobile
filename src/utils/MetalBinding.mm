// Copyright 2017 The Dawn Authors
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

#include "utils/BackendBinding.h"

#include "common/Assert.h"
#include "common/SwapChainUtils.h"
#include "dawn_native/MetalBackend.h"

#if defined(DAWN_PLATFORM_MACOS)
#    define GLFW_EXPOSE_NATIVE_COCOA
#    include "GLFW/glfw3.h"
#    include "GLFW/glfw3native.h"
#endif  // defined(DAWN_PLATFORM_MACOS)

#import <QuartzCore/CAMetalLayer.h>

namespace utils {
    class SwapChainImplMTL {
      public:
        using WSIContext = DawnWSIContextMetal;

        SwapChainImplMTL(id nsWindow) : mNsWindow(nsWindow) {
        }

        ~SwapChainImplMTL() {
            [mCurrentTexture release];
            [mCurrentDrawable release];
        }

        void Init(DawnWSIContextMetal* ctx) {
            mMtlDevice = ctx->device;
            mCommandQueue = ctx->queue;
        }

        DawnSwapChainError Configure(WGPUTextureFormat format,
                                     WGPUTextureUsage usage,
                                     uint32_t width,
                                     uint32_t height) {
            if (format != WGPUTextureFormat_BGRA8Unorm) {
                return "unsupported format";
            }
            ASSERT(width > 0);
            ASSERT(height > 0);
#if defined(DAWN_PLATFORM_MACOS)
            NSView* contentView = [mNsWindow contentView];
            [contentView setWantsLayer:YES];
#endif  // defined(DAWN_PLATFORM_MACOS)
            CGSize size = {};
            size.width = width;
            size.height = height;

#if defined(DAWN_PLATFORM_IOS)
            mLayer = [mNsWindow layer];
#elif defined(DAWN_PLATFORM_MACOS)
            mLayer = [CAMetalLayer layer];
#endif  // defined(DAWN_PLATFORM_IOS)
            [mLayer setDevice:mMtlDevice];
            [mLayer setPixelFormat:MTLPixelFormatBGRA8Unorm];
            [mLayer setDrawableSize:size];

            constexpr uint32_t kFramebufferOnlyTextureUsages =
                WGPUTextureUsage_OutputAttachment | WGPUTextureUsage_Present;
            bool hasOnlyFramebufferUsages = !(usage & (~kFramebufferOnlyTextureUsages));
            if (hasOnlyFramebufferUsages) {
                [mLayer setFramebufferOnly:YES];
            }

#if defined(DAWN_PLATFORM_MACOS)
            [contentView setLayer:mLayer];
#endif  // defined(DAWN_PLATFORM_MACOS)
            
            return DAWN_SWAP_CHAIN_NO_ERROR;
        }

        DawnSwapChainError GetNextTexture(DawnSwapChainNextTexture* nextTexture) {
            [mCurrentDrawable release];
            mCurrentDrawable = [mLayer nextDrawable];
            [mCurrentDrawable retain];

            [mCurrentTexture release];
            mCurrentTexture = mCurrentDrawable.texture;
            [mCurrentTexture retain];

            nextTexture->texture.ptr = reinterpret_cast<void*>(mCurrentTexture);

            return DAWN_SWAP_CHAIN_NO_ERROR;
        }

        DawnSwapChainError Present() {
            id<MTLCommandBuffer> commandBuffer = [mCommandQueue commandBuffer];
            [commandBuffer presentDrawable:mCurrentDrawable];
            [commandBuffer commit];

            return DAWN_SWAP_CHAIN_NO_ERROR;
        }

      private:
        id mNsWindow = nil; // It will be a subclass of UIView on iOS.
        id<MTLDevice> mMtlDevice = nil;
        id<MTLCommandQueue> mCommandQueue = nil;

        CAMetalLayer* mLayer = nullptr;
        id<CAMetalDrawable> mCurrentDrawable = nil;
        id<MTLTexture> mCurrentTexture = nil;
    };

    class MetalBinding : public BackendBinding {
      public:
        MetalBinding(GLFWwindow* window, WGPUDevice device) : BackendBinding(window, device) {
        }

        uint64_t GetSwapChainImplementation() override {
            if (mSwapchainImpl.userData == nullptr) {
                mSwapchainImpl = CreateSwapChainImplementation(
#if defined(DAWN_PLATFORM_IOS)
                    new SwapChainImplMTL((__bridge id)mWindow));
#elif defined(DAWN_PLATFORM_MACOS)
                    new SwapChainImplMTL(glfwGetCocoaWindow(mWindow)));
#else
                UNREACHABLE();
#endif  // defined(DAWN_PLATFORM_IOS)
            }
            return reinterpret_cast<uint64_t>(&mSwapchainImpl);
        }

        WGPUTextureFormat GetPreferredSwapChainTextureFormat() override {
            return WGPUTextureFormat_BGRA8Unorm;
        }

      private:
        DawnSwapChainImplementation mSwapchainImpl = {};
    };

    BackendBinding* CreateMetalBinding(GLFWwindow* window, WGPUDevice device) {
        return new MetalBinding(window, device);
    }
}
