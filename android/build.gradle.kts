// When Android Studio's annotation extractor artifacts are preloaded locally,
// use them before remote repositories so first-time/offline builds can finish.
val codexLocalMavenRepo = System.getenv("LOCALAPPDATA")?.let {
    file("$it/AnTamPharma/maven")
}

allprojects {
    repositories {
        codexLocalMavenRepo?.takeIf { it.isDirectory }?.let {
            maven { url = uri(it) }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
