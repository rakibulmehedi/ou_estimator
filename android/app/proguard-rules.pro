# Flutter default optimisation keep rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Isar Community uses dart:ffi (native .so) — not JNI/reflection.
# R8 cannot strip FFI-loaded native libraries, so no keep rules are needed.
