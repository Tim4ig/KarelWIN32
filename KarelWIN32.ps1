param(
    [string]$platform
)

$global:platform = $platform

function KarelInstall {
    $version = "0.1"

    $originalDir = Get-Location

    $tempDir = "$originalDir/temp"
    $outDir = "$originalDir/out"

    $outIncDir = "$outDir/inc"
    $outBinDir = "$outDir/bin"
    $outTestDir = "$outDir/test"

    $pdcursesIncDir = "$tempDir/PDCurses"
    $pdcursesBuildDir = "$tempDir/PDCurses/wincon"

    $karelIncDir = "$tempDir/karel-the-robot/include"
    $karelSrcDir = "$tempDir/karel-the-robot/src"
    $karelBuildDir = "$tempDir/karel-the-robot/build"

    $pdcursesRepo = "git@github.com:wmcbrine/PDCurses.git"
    $karelRepo = "git@git.kpi.fei.tuke.sk:kpi/karel-the-robot.git"

    function FatalError {
        param(
            [string]$message
        )

        Write-Host $message -ForegroundColor Red
        exit 1
    }

    function PrepareDirs {
        $dirsToCreate = @(
            $tempDir,
            $outIncDir,
            "$outIncDir/karel",
            "$outIncDir/pdcurses",
            $outBinDir,
            "$outTestDir",
            "$outTestDir/build"
        )
    
        foreach ($dir in $dirsToCreate) {
            if (-not (Test-Path $dir)) {
                New-Item -Path $dir -ItemType Directory > Nul
                Write-Host "Created directory: $dir"
            }
        }
    }

    function CloneDeps {
        Set-Location -Path $tempDir

        Write-Host "Сlonning: $pdcursesRepo"
        $output = (git clone $pdcursesRepo *>&1)
        if ($LASTEXITCODE -ne 0) {
            FatalError -message "Error clone: $pdcursesRepo`n$output"
        }
    
        Write-Host "Сlonning: $karelRepo"
        $output = (git clone $karelRepo *>&1)
        if ($LASTEXITCODE -ne 0) {
            FatalError -message "Error clone: $karelRepo`n$output"
        }

        if (-not (Test-Path $karelBuildDir)) {
            New-Item -Path $karelBuildDir -ItemType Directory > Nul
            Write-Host "Created directory: $karelBuildDir"
        }

        Set-Location -Path $originalDir
    }

    function FixKarel {
        Set-Location -Path $karelSrcDir
        function RemoveEvilHeaders {
            param (
                [string]$file
            )

            $patterns = @(
                "#include <libintl.h>",
                "#include <unistd.h>"
            )

            $content = Get-Content -Path $file
            foreach ($pattern in $patterns) { $content = $content.Replace($pattern, " ") }
            $content | Set-Content -Path $file
        }
    
        function RemoveEvilLocale {
            param (
                [string]$file
            )

            $patterns = @(
                "#define _(STRING) gettext(STRING)"
            )

            $content = Get-Content -Path $file
            foreach ($pattern in $patterns) { $content = $content.Replace($pattern, "#define _(STRING) (STRING)") }
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

        try {
            Write-Host "Fixing karel library for build"
            RemoveEvilHeaders -file karel.c
            RemoveEvilHeaders -file internals.c
            RemoveEvilLocale -file karel.c
            RemoveEvilLocale -file internals.c
            AddEvilFix -file internals.c
        }
        catch {
            FatalError -message "Cant fix karel!!!!"
        }

        Set-Location $originalDir
    }
    
    function Build {
        function BuildCurses {
            Set-Location -Path $pdcursesBuildDir
            
            if ($global:platform -eq "MSVC") {
                nmake -f .\Makefile.vc
                Copy-Item -Path $pdcursesBuildDir/pdcurses.lib -Destination $outBinDir/
            } else {
                make INFOEX=N
                Copy-Item -Path $pdcursesBuildDir/pdcurses.a -Destination $outBinDir/libpdcurses.a
            }

            if ($LASTEXITCODE -ne 0) {
                FatalError -message "Build failed!"
            }
            
            Copy-Item -Path $pdcursesIncDir/*.h -Destination $outIncDir/pdcurses
            Set-Location -Path $originalDir
        }

        function BuildKarel {    
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
    
            Set-Location $karelBuildDir
            $cmake | Set-Content -Path "../CMakeLists.txt"

            if ($global:platform -eq "MSVC") {
                cmake -G "Visual Studio 17 2022" -A x64 ..
            } else {
                cmake -G "MinGW Makefiles" ..
            }
            
            if ($LASTEXITCODE -ne 0) {
                FatalError -message "Build failed!"
            }

            cmake --build .
            if ($LASTEXITCODE -ne 0) {
                FatalError -message "Build failed!"
            }
        
            Copy-Item -Path $karelBuildDir/Debug/*.lib -Destination $outBinDir/ -ErrorAction SilentlyContinue
            Copy-Item -Path $karelBuildDir/*.a -Destination $outBinDir/
            Copy-Item -Path $karelIncDir/*.h -Destination $outIncDir/karel
            Copy-Item -Path $karelIncDir/../doc/examples/* -Destination $outTestDir
            Set-Location -Path $originalDir
        }

        Write-Host "Building for $global:platform"
        Write-Host "Building curses.."
        BuildCurses
        Write-Host "Curses successfully builded!" -ForegroundColor Green
        Write-Host "Building karel"
        BuildKarel
        Write-Host "Karel successfully builded!" -ForegroundColor Green
    }

    function BuildTest {
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

        Set-Location $outTestDir/build
        $cmake | Set-Content -Path "../CMakeLists.txt"

        if ($global:platform -eq "MSVC") {
            cmake -G "Visual Studio 17 2022" -A x64 ..
        } else {
            cmake -G "MinGW Makefiles" ..
        }

        cmake --build .
        if($LASTEXITCODE -ne 0) {
            FatalError -message "Cant build test"
        }

        if ($global:platform -eq "MSVC") {
            Set-Location -Path "./Debug"
            Copy-Item -Path "../../stairs.kw" -Destination .
        } else {
            Copy-Item -Path "../stairs.kw" -Destination .
        }
        
        ./test

        Set-Location -Path $originalDir
    }

    function ValidateTools {
        param(
            [string]$platform
        )

        $requiredTools = @(
            "git",
            "cmake"
        )
    
        if ($global:platform -eq ("MSVC")) {
            $requiredTools += "nmake"
        }
    
        elseif ($global:platform -eq ("MinGW")) {
            $requiredTools += "gcc"
            $requiredTools += "make"
        }
    
        else {
            FatalError -message "Invalid platform set."
        }

        Write-Host ("Searching for required " + $global:platform + " tools..")

        foreach ($tool in $requiredTools) {
            if (Get-Command -Name $tool -ErrorAction SilentlyContinue) {
                Write-Host ($tool + " - located") -ForegroundColor Green
            }
            else {
                FatalError -message ($tool + " - cannot locate required tool")
            }
        }
    }

    function CleanUp {
        param (
            [bool]$rmOut = $false
        )

        if ((Test-Path $tempDir)) {
            Remove-Item -Path $tempDir -Recurse -Force
        }

        if ($rmOut -and (Test-Path $outDir)) {
            Remove-Item -Path $outDir -Recurse -Force
        }
    }

    function Main {
        Write-Host ("karel-install for Win32 v" + $version + " by Tim4ig")
        ValidateTools
        CleanUp -rmOut $true
        PrepareDirs
        CloneDeps
        FixKarel
        Build
        BuildTest
        CleanUp
    }

    Main
}

KarelInstall
