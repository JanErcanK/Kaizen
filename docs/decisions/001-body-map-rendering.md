# 001 — Bound body-map raster cost during gestures

Status: implemented; physical-device verification on one affected Android model.

## Context

The body map worked in a desktop preview but stuttered and could terminate the app on a Motorola razr 60 ultra (`leap`, Android 16). A native trace pointed to the Adreno Vulkan driver during rendering. Dart-only widget tests could not reveal that driver crash.

The custom paint work also made enlargement/reduction expensive. Zoom should not allocate new shaded surfaces proportional to the entire zoomed area.

## Decision

`CachedBodyPaint` rasterizes expensive layers once per meaningful change. It caps effective pixel ratio at 2, longest edge at roughly 2,048 pixels and area at roughly 2 million pixels (rounding applies). Gestures scale the cached result. Size, pixel ratio, theme or meaningful painter changes invalidate it. Replaced and final native image handles are disposed.

Scope unrelated animation rebuilds, preserve the expanded child across its transition, and handle nested back navigation and disposal explicitly.

On Android, select Skia/OpenGL for Motorola device codename `leap` before Flutter starts. Keep this scoped to the observed device instead of changing the renderer for all users.

## Consequences

Extreme zoom can reveal finite raster resolution: a deliberate memory/rendering trade-off. Hit testing remains separate from the cached shading image.

The renderer override depends on Flutter's embedding behavior. Revisit it on Flutter and GPU-driver updates. This is a compatibility workaround, not proof that every Adreno device has the issue.

## Evidence and follow-up

Repeated expansion/zoom/back cycles succeeded on the affected phone, and the user confirmed the improvement. Regression tests cover bounded cache dimensions, refresh behavior, interactions and lifecycle disposal. This is a limited device observation, not a performance benchmark or guarantee against all native crashes.

Before release, repeat the sequence in a signed release on the affected device and another Android model. Check native crash output and memory trends, folding, rotation, background/resume and long sessions. An iPhone still needs independent verification.
