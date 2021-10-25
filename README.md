# JAX ❤️ 🪟

alpha state...

A community supported Windows build for jax.

Currently, only CPU and CUDA 11.1 are supported. For CUDA 11.x, please install the `cuda111` package.

There will be no support for CUDA 10.x (due to incomplete cuSPARSE support on Windows) and CUDA 11.0, and will not be added in foreseeable future.

# Unstable builds

`jax` pinned a `jaxlib` package version in its `setup.py`, to install unstable
build, you must first ensure the required `jaxlib` package exists int the pacakge
index. Check it out at https://whls.blob.core.windows.net/unstable/index.html

## Use pip

```
pip install jax[cuda111] -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
```

## Install from jax source

```
pip install .[cuda111] -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
```

## The ultimate solution

You just manually select a version of `jaxlib` that you want to install. And
then install `jax` manually.

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


# How the jaxlib package is built?

<details><summary>github actions</summary>
<p>

Then how do I managed to build cuda on github actions? Github actions ci
machines do not have GPUs so that you are not supposed to run CUDA application
on it. But it is capable to build CUDA. The free windows ci machine have 14GB
disk limit and 2 cores, each job is limited to 6 hour running.

The disk limit is the only limitation here for jax.

~~The `v10.1.7z` is cuda toolkit 10.1 combined with cudnn 7.6.5.~~ The `v11.1.7z`
is cuda toolkit 11.1 combined with cudnn 8.2.2. The full package is too big to
fit into the ci machine (since there will be pip installation and build
artificts). Removing the DLLs and irrelevant files reduced the total package of
cuda installation to ~180MB before `7z` and ~70MB after `7z`. The trimmed
package make it fit into the small disk.

If you need a newer version of jaxlib. Submit a PR with jax submodule refers to
the updated commit of [google/jax](https://github.com/google/jax).

</details>


# Additional notes

For `--use-deprecated legacy-resolver`, refers to
[pip #9186](https://github.com/pypa/pip/issues/9186) and
[pip #9203](https://github.com/pypa/pip/issues/9203).
