# JAX ❤️ 🪟

alpha state...

A community supported Windows build for jax.

Currently, only CPU and CUDA 11.1 are supported. For CUDA 11.x, please install the `cuda`/`cuda11_cudnn82` package.

# Unstable builds

`jax` pinned a `jaxlib` package version in its `setup.py`, to install unstable
build, you must first ensure the required `jaxlib` package exists in the pacakge
index. Check it out at https://whls.blob.core.windows.net/unstable/index.html

## Install CPU only version

```powershell
# See https://peps.python.org/pep-0440/#arbitrary-equality for triple `=`
pip install jaxlib===0.3.5 -f https://whls.blob.core.windows.net/unstable/index.html
```

## Use pip

```
pip install jax[cuda111] -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
```

## Install from jax source

```
pip install -e .[cuda111] -f https://whls.blob.core.windows.net/unstable/index.html --use-deprecated legacy-resolver
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


# Additional notes

For `--use-deprecated legacy-resolver`, refers to
[pip #9186](https://github.com/pypa/pip/issues/9186) and
[pip #9203](https://github.com/pypa/pip/issues/9203).
