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
// Some plugin subprojects pin an older compileSdk (file_picker → 34)
// while others' AARs demand 36+; lift every Android subproject to one
// compileSdk so AAR metadata checks pass. compileSdk only raises the
// APIs available at compile time — minSdk/targetSdk are untouched.
// MUST be registered before the evaluationDependsOn(":app") block below,
// which forces evaluation immediately.
subprojects {
    fun liftCompileSdk() {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            ?.compileSdkVersion(36)
    }
    if (state.executed) liftCompileSdk() else afterEvaluate { liftCompileSdk() }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
