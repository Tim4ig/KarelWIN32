$ErrorActionPreference = "Stop"

$originalDir = Get-Location

$tempDir = "$originalDir/temp"
$outIncDir = "$originalDir/out/inc"
$outBinDir = "$originalDir/out/bin"
$outTestDir = "$originalDir/out/test"

$pdcursesIncDir = "$tempDir/PDCurses"
$pdcursesBuildDir = "$tempDir/PDCurses/wincon"

$karelIncDir = "$tempDir/karel-the-robot/include"
$karelSrcDir = "$tempDir/karel-the-robot/src"
$karelBuildDir = "$tempDir/karel-the-robot/build"

$pdcursesRepo = "git@github.com:wmcbrine/PDCurses.git"
$karelRepo = "git@git.kpi.fei.tuke.sk:kpi/karel-the-robot.git"

function PrepareDirs {
    if(-not (Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory
    }
    if(-not (Test-Path $outIncDir)) {
        New-Item -Path $outIncDir -ItemType Directory
        New-Item -Path $outIncDir/karel -ItemType Directory
        New-Item -Path $outIncDir/pdcurses -ItemType Directory
    }
    if(-not (Test-Path $outBinDir)) {
        New-Item -Path $outBinDir -ItemType Directory
    }
    
    if(-not (Test-Path $outTestDir)) {
        New-Item -Path $outTestDir -ItemType Directory
        New-Item -Path $outTestDir/build -ItemType Directory
    }

    Set-Location -Path $tempDir
    
    try {
        & git clone $pdcursesRepo
        & git clone $karelRepo
    } catch {
        Write-Error "Cant clone git repos: $_"
    }

    if(-not (Test-Path $karelBuildDir)) {
        New-Item -Path $karelBuildDir -ItemType Directory
    }

    Set-Location -Path $originalDir
}

function CompileCurses {
    Set-Location -Path $pdcursesBuildDir

    try {
        & mingw32-make INFOEX=N
    } catch {
        Write-Error "Build failed: $_"
    }

    Copy-Item -Path $pdcursesBuildDir/pdcurses.a -Destination $outBinDir/libpdcurses.a
    Copy-Item -Path $pdcursesIncDir/*.h -Destination $outIncDir/pdcurses
    Set-Location -Path $originalDir
}

function FixKarel {
    Set-Location -Path $karelSrcDir
    function RemoveEvilHeaders {
        param (
            [string]$file
        )

        $pattern = @(
            "#include <libintl.h>",
            "#include <unistd.h>"
        )

        $content = Get-Content -Path $file
        ($pattern | ForEach-Object { $content = $content.Replace($_, " ") })
        $content | Set-Content -Path $file
    }
    
    function RemoveEvilLocale {
        param (
            [string]$file
        )

        $pattern = @(
            "#define _(STRING) gettext(STRING)"
        )

        $content = Get-Content -Path $file
        ($pattern | ForEach-Object { $content = $content.Replace($_, "#define _(STRING) (STRING)") })
        $content | Set-Content -Path $file
    }

    function AddEvilFix {
        param (
            [string]$file
        )

        $fix = "#include `"Windows.h`"`n#define usleep(s) Sleep(s / 1000)`n"
        
        $content = Get-Content -Path $file -Raw
        $content = $fix + $content
        $content | Set-Content -Path $file
    }

    RemoveEvilHeaders -file karel.c
    RemoveEvilHeaders -file internals.c
    RemoveEvilLocale -file karel.c
    RemoveEvilLocale -file internals.c
    AddEvilFix -file internals.c
    Set-Location $originalDir
}

function CompileKarel {
    Set-Location $karelBuildDir

    $cmake = @'
        cmake_minimum_required(VERSION 3.27)
        project(karel C)

        set(CMAKE_C_STANDARD 11)
        set(CMAKE_C_STANDARD_REQUIRED ON)

        include_directories("include")
        include_directories("../../out/inc/pdcurses")

        link_directories("../../out/bin")

        add_library(${PROJECT_NAME} STATIC "src/karel.c" "src/superkarel.c" "src/internals.c")

        target_link_libraries(${PROJECT_NAME} pdcurses)
'@

    $cmake | Set-Content -Path "../CMakeLists.txt"

    try {
        & cmake -G "MinGW Makefiles" ..
        & cmake --build .
    }
    catch {
        Write-Error "Build failed: $_"
    }

    Copy-Item -Path $karelBuildDir/*.a -Destination $outBinDir
    Copy-Item -Path $karelIncDir/*.h -Destination $outIncDir/karel
    Copy-Item -Path $karelIncDir/../doc/examples/* -Destination $outTestDir
    Set-Location -Path $originalDir
}

function BuildTest {
    Set-Location $outTestDir/build

    $cmake = @'
        cmake_minimum_required(VERSION 3.27)
        project(test C)

        set(CMAKE_C_STANDARD 11)
        set(CMAKE_C_STANDARD_REQUIRED on)

        include_directories("../inc/karel")
        link_directories("../bin")

        add_executable(${PROJECT_NAME} "stairs.c")
        target_link_libraries(${PROJECT_NAME} karel pdcurses)
'@

    $cmake | Set-Content -Path "../CMakeLists.txt"

    try {
        & cmake -G "MinGW Makefiles" ..
        & cmake --build .
    }
    catch {
        Write-Error "Build failed: $_"
    }

    Copy-Item -Path "../stairs.kw" -Destination .
    ./test
    Set-Location -Path $originalDir
}

function Main {
    PrepareDirs
    CompileCurses
    FixKarel
    CompileKarel
    BuildTest
    Remove-Item -Path $tempDir -Recurse -Force
}

Main
