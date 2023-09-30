param(
    [Parameter(Position=0, Mandatory = $true)]
    [ValidateSet('cpu', 'cuda')]
    [String]$build_type,

    [Parameter(Mandatory = $false)]
    [String]$bazel_path = "bazel",

    [Parameter(Mandatory = $false)]
    [int]$bazel_jobs = -1,

    [Parameter(Mandatory = $false)]
    [String]$conda_env = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet('12.1', '11.8')]
    [String]$cuda_version = "12.1",

    [Parameter(Mandatory = $false)]
    [String]$cuda_prefix = "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA",

    [Parameter(Mandatory = $false)]
    [String]$bazel_output_root = "C:/bazel_output_root",

    [Parameter(Mandatory = $false)]
    [ValidateSet("2022", "2019")]
    [String]$vs_version = "",

    [Parameter(Mandatory = $false)]
    [String]$bazel_vc_full_version = "",

    [Parameter(Mandatory = $false)]
    [String]$xla_submodule = (Join-Path $PSScriptRoot xla),

    [Parameter(Mandatory = $false)]
    [String]$triton_submodule = (Join-Path $PSScriptRoot triton),

    # For CI to avoid full rebuild when changing python version
    [switch]$symlink_python
)

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path) functions.ps1)
$ErrorActionPreference = "Stop"

# path for patch.exe and realpath.exe
$msys2_path = "C:\msys64\usr\bin"

switch ($cuda_version) {
    '12.1' {
        $cudnn_version = '8.9.1'
    }
    '11.8' {
        $cudnn_version = '8.6.0'
    }
}

$cuda_path = "$cuda_prefix/v$cuda_version"
$cudnn_path = $cuda_path

if ($xla_submodule -ne (Join-Path $PSScriptRoot xla)) {
    $xla_submodule = Resolve-Path $xla_submodule
}

if ($triton_submodule -ne (Join-Path $PSScriptRoot triton)) {
    $triton_submodule = Resolve-Path $triton_submodule
}

[System.Collections.ArrayList]$new_path = `
    'C:\tools', `
    'C:\Program Files\Git\cmd', `
    'C:\Windows\System32', `
    'C:\Windows', `
    'C:\Windows\System32\Wbem', `
    'C:\Windows\System32\WindowsPowerShell\v1.0'

Push-Environment
Push-Location

try {
    if ($cuda_path -eq $cudnn_path) {
        $env:TF_CUDA_PATHS="$cuda_path"
    }
    else {
        $env:TF_CUDA_PATHS="$cuda_path,$cudnn_path"
    }

    # insert your path here
    $new_path.Insert(0, "$msys2_path")

    # bring github actions python into path
    if ($env:pythonLocation) {
        $new_path.Insert(0, "$env:pythonLocation")
        $new_path.Insert(0, "$env:pythonLocation/Scripts")
    }

    $env:PATH = $new_path -join ";"

    if ($vs_version -ne "") {
        Set-VSEnv $vs_version
    }
    if ($bazel_vc_full_version -ne "") {
        $env:BAZEL_VC_FULL_VERSION = $bazel_vc_full_version
    }

    # bring conda python into environment, this supersede MSYS2's python and
    # maybe VS's python
    if ($conda_env -ne "") {
        conda activate $conda_env
    }

    echo 'try-import %workspace%/../windows_configure.bazelrc' > .bazelrc.user

    if ($bazel_jobs -gt 0) {
        echo "build --jobs=${bazel_jobs}" >> .bazelrc.user
    }

    if (Test-Path $xla_submodule) {
        Write-Host -ForegroundColor Yellow "Use xla submodule " $xla_submodule
        echo ('build:windows --override_repository=xla=' + $xla_submodule.Replace("\", "/")) >> .bazelrc.user
    }

    if (Test-Path $triton_submodule) {
        Write-Host -ForegroundColor Yellow "Use triton submodule " $triton_submodule
        echo ('build:windows --override_repository=triton=' + $triton_submodule.Replace("\", "/")) >> .bazelrc.user
    }

    $python_bin_path = ""
    if ($symlink_python) {
        $python_symlined_home = Join-Path $PSScriptRoot python_symlinked
        Remove-Item $python_symlined_home -Force -ErrorAction 0
        New-Item -Type SymbolicLink $python_symlined_home -Target (Split-Path (Get-Command python).Source) -Force
        $new_path.Insert(0, $python_symlined_home)

        $python_bin_path = Join-Path $python_symlined_home python.exe

        # We use it to trigger the repository rule when python is changed
        $python_lib_path = (Get-Item $python_symlined_home).Target.Replace("\", "/")
        Write-Host -ForegroundColor Yellow "Use PYTHON_LIB_PATH " $python_lib_path
        echo ('build:windows --repo_env PYTHON_LIB_PATH="' + $python_lib_path + '"') >> .bazelrc.user
    }

    # NOTE: In case it is needed to debug a build failure, run `bazel --output_user_root=$bazel_output_root <you cmds>`
    if ($build_type -eq 'cpu') {
        python .\build\build.py `
            --python_bin_path="$python_bin_path" `
            --noenable_cuda `
            --bazel_path="$bazel_path" `
            --bazel_startup_options="--output_user_root=$bazel_output_root"
    } elseif ($build_type -eq 'cuda') {
        python .\build\build.py `
            --python_bin_path="$python_bin_path" `
            --enable_cuda `
            --cuda_version="$cuda_version" `
            --cuda_path="$cuda_path" `
            --cudnn_version="$cudnn_version" `
            --cudnn_path="$cudnn_path" `
            --bazel_path="$bazel_path" `
            --bazel_startup_options="--output_user_root=$bazel_output_root"
    }

    if ($LASTEXITCODE -ne 0) {
        throw "last command exit with $LASTEXITCODE"
    }

    if ((ls dist).Count -ne 1) {
        throw "number of whl files != 1"
    }

    $name = (ls dist)[0].Name

    if ($build_type -eq 'cpu') {
        mkdir "bazel-dist/cpu" -ErrorAction 0
        mv -Force "dist/$name" "bazel-dist/cpu/$name"
        Write-Host -ForegroundColor Yellow "Moved dist/$name to bazel-dist/cpu/$name"
    } elseif ($build_type -eq 'cuda') {
        $cuda_ver = [System.Version]$cuda_version
        $cudnn_ver = [System.Version]$cudnn_version
        $cuda_dir = "cuda$($cuda_ver.Major)$($cuda_ver.Minor)"
        $cuda_cudnn_tag = "cuda$($cuda_ver.Major).cudnn$($cudnn_ver.Major)$($cudnn_ver.Minor)"
        $new_name = $name.Insert($name.IndexOf("-", $name.IndexOf("-") + 1), "+$cuda_cudnn_tag")

        mkdir "bazel-dist/$cuda_dir" -ErrorAction 0
        mv -Force "dist/$name" "bazel-dist/$cuda_dir/$new_name"
        Write-Host -ForegroundColor Yellow "Move dist/$name to bazel-dist/$cuda_dir/$new_name"
    }
}
finally {
    Pop-Location
    Pop-Environment
}
