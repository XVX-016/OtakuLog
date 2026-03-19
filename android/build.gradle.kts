import com.android.build.gradle.LibraryExtension
import java.util.regex.Pattern

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
    plugins.withId("com.android.library") {
        extensions.findByType(LibraryExtension::class.java)?.let { extension ->
            val compileSdk = extension.compileSdk
            if (compileSdk == null || compileSdk < 34) {
                extension.compileSdk = 34
            }
            if (extension.namespace.isNullOrBlank()) {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val manifest = manifestFile.readText()
                    val matcher = Pattern.compile("package\\s*=\\s*\"([^\"]+)\"").matcher(manifest)
                    if (matcher.find()) {
                        extension.namespace = matcher.group(1)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
