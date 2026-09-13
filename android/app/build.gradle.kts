plugins {
    id("com.android.application")
    id("kotlin-android")
    // أي إضافات أخرى لديك هنا
}

android {
    namespace = "com.example.flutter_app" // أو اسم حزمة تطبيقك الحالي
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.flutter_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}