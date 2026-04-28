# Gson keep rules
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*


# Keep TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }

# Keep your model class (IMPORTANT)
-keep class com.example.calltrackinh.WhatsappMessage { *; }

-keepclassmembers class com.example.calltrackinh.WhatsappMessage {
    <fields>;
}
-keep class com.example.calltrackinh.** { *; }