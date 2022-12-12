param(
    [Parameter(Mandatory = $true)]
    [String]$bazel_path,

    # [Parameter(Mandatory = $true)]
    # [String]$conda_env,

    [Parameter(Mandatory = $true)]
    [ValidateSet('11.2', '11.1', '10.1')]
    $cuda_version,

    [Parameter(Mandatory = $false)]
    [String]$cuda_prefix = "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA"
)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path) functions.ps1)
$ErrorActionPreference = "Stop"

# path for patch.exe and realpath.exe
$msys2_path = "C:\msys64\usr\bin"

switch ($cuda_version) {
    '11.2' {
        $cudnn_version = '8.2.2'
    }
    '11.1' {
        $cudnn_version = '8.2.2'
    }
}

$cuda_version = [System.Version]$cuda_version
$cudnn_version = [System.Version]$cudnn_version

$cuda_path = "$cuda_prefix/v$cuda_version"
$cudnn_path = $cuda_path

[System.Collections.ArrayList]$new_path = `
    'C:\Windows\System32', `
    'C:\Windows', `
    'C:\Windows\System32\Wbem', `
    'C:\Windows\System32\WindowsPowerShell\v1.0'

Push-Environment
Push-Location

try {
    # https://github.com/tensorflow/tensorflow/blob/9e2743271dd09609e8726edaffdd7c6762d3bf05/third_party/gpus/find_cuda_config.py#L26-L33
    # and tf 2.0 release note
    if ($cuda_path -eq $cudnn_path) {
        # https://github.com/tensorflow/tensorflow/issues/51040
        $env:TF_CUDA_PATHS="$cuda_path"
    }
    else {
        $env:TF_CUDA_PATHS="$cuda_path,$cudnn_path"
    }

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
        --enable_cuda `
        --cuda_version="$cuda_version" `
        --cuda_path="$cuda_path" `
        --cudnn_version="$cudnn_version" `
        --cudnn_path="$cudnn_path" `
        --bazel_path="$bazel_path" `
        --bazel_startup_options="--output_user_root=D:/bzl_out"

    if ($LASTEXITCODE -ne 0) {
        throw "last command exit with $LASTEXITCODE"
    }

    if ((ls dist).Count -ne 1) {
        throw "number of whl files != 1"
    }
    $name = (ls dist)[0].Name
    $cuda_dir = "cuda$($cuda_version.Major)$($cuda_version.Minor)"
    $cuda_cudnn_tag = "cuda$($cuda_version.Major).cudnn$($cudnn_version.Major)$($cudnn_version.Minor)"
    $new_name = $name.Insert($name.IndexOf("-", $name.IndexOf("-") + 1), "+$cuda_cudnn_tag")

    mkdir "bazel-dist/$cuda_dir" -ErrorAction 0
    mv -Force "dist/$name" "bazel-dist/$cuda_dir/$new_name"
}
finally {
    Pop-Location
    Pop-Environment
}
