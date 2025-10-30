allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.configureEach {
        resolutionStrategy {
            // Force explicit versions so Gradle does not perform network lookups for dynamic ranges.
            force(
                "androidx.test:runner:1.5.2",
                "androidx.test:rules:1.5.0",
                "androidx.test.espresso:espresso-core:3.5.1",
                "com.razorpay:checkout:1.6.33",
            )
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
