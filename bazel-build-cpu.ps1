param(
    [Parameter(Mandatory = $true)]
    [String]$bazel_path
)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path) functions.ps1)
$ErrorActionPreference = "Stop"

# path for patch.exe and realpath.exe
$msys2_path = "C:\msys64\usr\bin"

[System.Collections.ArrayList]$new_path = `
    'C:\Windows\System32', `
    'C:\Windows', `
    'C:\Windows\System32\Wbem', `
    'C:\Windows\System32\WindowsPowerShell\v1.0'

Push-Environment
Push-Location

try {
    # insert your path here
    $new_path.Insert(0, 'C:\Program Files\Git\cmd')
    $new_path.Insert(0, 'C:\tools\bazelisk')
    $new_path.Insert(0, "$msys2_path")

    if ($env:pythonLocation) {
        # bring github actions python into path
        $new_path.Insert(0, "$env:pythonLocation")
        $new_path.Insert(0, "$env:pythonLocation/Scripts")
    }

    $env:PATH = $new_path -join ";"

    Set-VSEnv

    # bring conda python into environment, this supersede MSYS2's python and
    # maybe VS's python
    # conda activate $conda_env

    echo 'try-import %workspace%/../windows_configure.bazelrc' > .bazelrc.user

    mkdir ~/bzl_out -ErrorAction Continue
    New-Item -Type Junction -Target (Resolve-Path ~/bzl_out) -Path D:/bzl_out -ErrorAction Continue

    python .\build\build.py `
        --noenable_cuda `
        --bazel_path="$bazel_path" `
        --bazel_startup_options="--output_user_root=D:/bzl_out"

    if ($LASTEXITCODE -ne 0) {
        throw "last command exit with $LASTEXITCODE"
    }

    if ((ls dist).Count -ne 1) {
        throw "number of whl files != 1"
    }
    $name = (ls dist)[0].Name

    mkdir "bazel-dist/cpu" -ErrorAction 0
    mv -Force "dist/$name" "bazel-dist/cpu/$name"
}
finally {
    Pop-Location
    Pop-Environment
}
