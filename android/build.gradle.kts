


allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build artifacts to the root build directory so Flutter can find them
rootProject.layout.buildDirectory.set(rootProject.layout.projectDirectory.dir("../build"))
subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}
