import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            freeCompilerArgs.addAll("-Xlint:-options", "-Xlint:deprecation", "-Xlint:unchecked")
        }
    }
    project.tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }

    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            // Force compileSdkVersion to 36 for all subprojects to support Java 17 and latest dependencies
            val setCompileSdk = androidExt.javaClass.methods.find { it.name == "setCompileSdk" || it.name == "compileSdk" }
            try {
                setCompileSdk?.invoke(androidExt, 36)
            } catch (e: Exception) {
                // Fallback for older AGP versions if necessary
                androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(androidExt, 36)
            }

            val compileOptions = androidExt.javaClass.getMethod("getCompileOptions").invoke(androidExt)
            compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
            compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
