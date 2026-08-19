allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val setCompileSdk = android.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdk" && it.parameterCount == 1
                }
                setCompileSdk?.invoke(android, 36)

                val setCompileSdkExtension = android.javaClass.methods.firstOrNull {
                    it.name == "setCompileSdkExtension" && it.parameterCount == 1
                }
                setCompileSdkExtension?.invoke(android, 18)
            } catch (_: Exception) {
                // 部分模块可能不支持这些属性，忽略即可
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
