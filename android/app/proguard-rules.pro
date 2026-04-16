# Flutter - Mantener clases esenciales
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Dart - Mantener paquetes de la app
-keep class com.novaaden.app.** { *; }
-keep class com.example.nova_aden.** { *; }

# SQLite - Mantener para persistencia
-keep class org.sqlite.** { *; }

# PDF/Printing - Mantener para reportes
-keep class com.shockwave.** { *; }
-keep class org.apache.** { *; }
-keep class printing.** { *; }

# File Picker - Mantener para respaldos
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# MultiDex
-keep class androidx.multidex.** { *; }

# Optimización de ofuscación
-optimizationpasses 5
-allowaccessmodification
-mergeinterfacesaggressive
-repackageclasses ''

# Ignorar warnings
-dontwarn org.jetbrains.**
-dontwarn kotlin.**
-dontwarn com.google.**
-dontwarn androidx.**
