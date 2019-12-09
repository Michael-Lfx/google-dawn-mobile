#
# Be sure to run `pod lib lint dawn.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'dawn'
  s.version          = '1.0.0'
  s.summary          = 'A short description of dawn.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Michael-Lfx/google-dawn-mobile'
  s.license          = { :type => 'Apache License Version 2.0', :file => 'LICENSE' }
  s.author           = { 'Michael-Lfx' => '9588926+michael-lfx@users.noreply.github.com' }
  s.source           = { :git => 'git@github.com:Michael-Lfx/google-dawn-mobile.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.exclude_files = ['**/*.md', '**/*.chromium', '**/*.gn', '**/CMakeLists.txt']
  # Workaround filenames conflict with libraries of toolchain when imports source with path.
  s.subspec 'common' do |ss|
    ss.source_files = ['src/common/*.{cpp}']
    ss.exclude_files = ['src/common/{xlib_with_undefs,windows_with_undefs,vulkan_platform}.h']
  end
  s.subspec 'dawn_native' do |ss|
    ss.source_files = ['src/{dawn_native,dawn_native/metal}/*.{h,cpp,mm}']
  end
  s.subspec 'dawn_platform' do |ss|
    ss.source_files = ['src/{dawn_platform,dawn_platform/tracing}/*.{h,cpp}']
  end
  s.subspec 'include' do |ss|
    ss.source_files = ['src/include/{dawn,dawn_native,dawn_platform}/*.{h,cpp}']
    ss.exclude_files = ['src/include/dawn_native/{D3D12Backend,NullBackend,OpenGLBackend,VulkanBackend}.h']
  end
  s.subspec 'api' do |ss|
    ss.source_files = ['out/Release/gen/src/{include/dawn,dawn,dawn_native}/*.{h,c,cpp}']
    ss.exclude_files = ['out/Release/gen/src/dawn/mock_webgpu.*']
  end
  s.subspec 'utils' do |ss|
    ss.source_files = ['src/utils/{BackendBinding,ComboRenderBundleEncoderDescriptor,ComboRenderPipelineDescriptor,MetalBinding,OSXTimer,SystemUtils,WGPUHelpers,Timer}.*']
  end   
  s.public_header_files = ['out/Release/gen/src/include/dawn/*.h',
                           'src/include/**/*.h']
  s.osx.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => ['DAWN_ENABLE_SPIR_V'],}
  s.pod_target_xcconfig = { 'CLANG_CXX_LANGUAGE_STANDARD' => 'c++14',
                            'CLANG_CXX_LIBRARY' => 'libc++',
                            'CLANG_ENABLE_OBJC_ARC' => 'NO',
                            'GCC_PREPROCESSOR_DEFINITIONS' => ['DAWN_ENABLE_BACKEND_METAL'],
                            'USER_HEADER_SEARCH_PATHS' => ['/Users/zhangyilei/Documents/google-dawn-mobile/src'],
                            'SYSTEM_HEADER_SEARCH_PATHS' => ['/Users/zhangyilei/Documents/google-dawn-mobile/src/include',
                                                             '/Users/zhangyilei/Documents/google-dawn-mobile/out/Release/gen/src']}
end
