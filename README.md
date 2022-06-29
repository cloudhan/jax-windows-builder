# JAX ❤️ 🪟

alpha state...

A community supported Windows build for jax.

Currently, only CPU and CUDA 11.1 are supported. For CUDA 11.x, please install the `cuda`/`cuda11_cudnn82` package.

# Unstable builds

Each`jax` build pinnes a concrete `jaxlib` package version in its `setup.py`. To install an unstable
build, you must first ensure the required `jaxlib` package exists in the pacakge
index. Check it out at https://whls.blob.core.windows.net/unstable/index.html

You can either install `jax` via pip (CPU only or CUDA), install `jax` from source or download the desired wheel manually.

## Install CPU only version via `pip`

```
pip install "jax[cpu]===0.3.14" -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
```

## Install `cuda111` version via `pip`

```
pip install jax[cuda111] -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
```

## Install from `jax` source

```
pip install -e .[cuda111] -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
```

## The manual solution

Select a version of `jaxlib` that you want to install. Then install `jax` manually.

```powershell
# download jaxlib from https://whls.blob.core.windows.net/unstable/index.html
pip install <jaxlib_whl>
pip install jax
```


# Stable builds

<details><summary>To be added</summary>
<p>

Check it out at https://whls.blob.core.windows.net/releases/index.html

</details>


# Additional notes

For `--use-deprecated legacy-resolver`, refers to
[pip #9186](https://github.com/pypa/pip/issues/9186) and
[pip #9203](https://github.com/pypa/pip/issues/9203).
