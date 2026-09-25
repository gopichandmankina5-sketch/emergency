# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt

# React Native standard keep rules
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep React Native NativeModules & Annotations
-keepclassmembers class * {
  @com.facebook.react.bridge.ReactMethod <methods>;
  @com.facebook.react.uimanager.annotations.ReactProp <methods>;
  @com.facebook.react.uimanager.annotations.ReactPropGroup <methods>;
}
-keep class * implements com.facebook.react.bridge.NativeModule { *; }
-keep class * implements com.facebook.react.bridge.JavaScriptModule { *; }
-keep class * implements com.facebook.react.bridge.ReactPackage { *; }
-keep class com.facebook.react.bridge.WritableMap { *; }
-keep class com.facebook.react.bridge.ReadableMap { *; }
-keep class com.facebook.react.bridge.WritableArray { *; }
-keep class com.facebook.react.bridge.ReadableArray { *; }
-keep class com.facebook.react.bridge.Promise { *; }
-keep class com.facebook.react.bridge.Callback { *; }
-keep class com.facebook.react.turbomodule.** { *; }

# react-native-reanimated
-keep class com.swmansion.reanimated.** { *; }

# Expo Modules Core & Expo Kotlin Modules reflection
-keep class expo.modules.** { *; }
-keep class expo.modules.kotlin.** { *; }
-keep class * extends expo.modules.kotlin.modules.Module { *; }
-keep class * extends expo.modules.kotlin.objects.ObjectDefinitionBuilder { *; }
-keepclassmembers class * extends expo.modules.kotlin.modules.Module {
  public <init>(...);
}

# Firebase & Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# React Native Async Storage & Maps
-keep class com.reactnativecommunity.asyncstorage.** { *; }
-keep class com.rnmaps.maps.** { *; }
-keep class com.airbnb.android.react.maps.** { *; }

# Suppress missing class warnings for optional transitives
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn expo.modules.**
-dontwarn com.facebook.react.**
-dontwarn javax.annotation.**
