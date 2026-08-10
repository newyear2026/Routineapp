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
    // home_widget 의존성이 너무 최신으로 해석되면
    // compileSdk 37 / JVM 11 요구로 빌드가 깨지므로 고정한다.
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.glance:glance:1.1.1")
            force("androidx.glance:glance-appwidget:1.1.1")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
            force("androidx.work:work-runtime-ktx:2.9.1")
            force("androidx.work:work-runtime:2.9.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
