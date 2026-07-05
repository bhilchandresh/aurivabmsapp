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
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun configureNamespace() {
        val android = extensions.findByName("android")
        if (android != null) {
            val setNamespaceMethod = android.javaClass.methods.firstOrNull { it.name == "setNamespace" }
            val getNamespaceMethod = android.javaClass.methods.firstOrNull { it.name == "getNamespace" }
            val currentNamespace = getNamespaceMethod?.invoke(android)
            
            if (setNamespaceMethod != null && currentNamespace == null) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifestText = manifestFile.readText()
                    val packageRegex = Regex("package=\"([^\"]+)\"")
                    val match = packageRegex.find(manifestText)
                    if (match != null) {
                        val packageName = match.groupValues[1]
                        setNamespaceMethod.invoke(android, packageName)
                    }
                }
            }
        }
    }

    if (state.executed) {
        configureNamespace()
    } else {
        afterEvaluate {
            configureNamespace()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
