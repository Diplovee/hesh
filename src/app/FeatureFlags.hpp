#pragma once

#ifndef HESH_ENABLE_ANDROID
#define HESH_ENABLE_ANDROID 0
#endif

namespace Hesh {

inline constexpr bool androidRuntimeEnabled = HESH_ENABLE_ANDROID != 0;

} // namespace Hesh
