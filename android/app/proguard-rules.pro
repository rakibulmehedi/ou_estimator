# Flutter default optimisation keep rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Isar — keep all Isar internals so R8 doesn't strip reflection targets
-keep class com.isar.** { *; }
-keep class io.isar.** { *; }
-dontwarn com.isar.**
-dontwarn io.isar.**
