# rocblas build for Radeon Vega based GPUS

Supported GPUs

* Radeon Vega 64/56
* Radeon Pro Vega 64
* Radeon VII
* Padeon Pro Vega II
* Instinct MI25
* Instinct MI50/60

Including rocblas build on version

* rocm 6.4
* rocm 7.2

Copy the TensileLibray files to your current rocm installation folder to enable these GPUs, for example:

```
cd /tmp && curl -L https://raw.githubusercontent.com/sheldonrong/rocblas-radeon-vega/refs/heads/main/rocblas_72.tar.gz --output rocblas.tar.gz \
    && tar -xvf rocblas.tar.gz && cp /tmp/rocblas/lib/rocblas/library/TensileLibrary_*_gfx900.* /opt/rocm-7.2.0/lib/rocblas/library/ \
    && cp /tmp/rocblas/lib/rocblas/library/TensileLibrary_*_gfx906.* /opt/rocm-7.2.0/lib/rocblas/library/
```