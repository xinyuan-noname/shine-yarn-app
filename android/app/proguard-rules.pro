# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Keep native method names (for plugins)
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep serializable classes (if any)
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep custom Application class if you have one
-keep public class com.example.shine.MyApplication extends android.app.Application

# 如果使用了 WebView，请取消下面注释
# -keepclassmembers class fqcn.of.javascript.interface.for.webview {
#    public *;
# }