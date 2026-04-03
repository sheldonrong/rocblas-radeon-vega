#!/usr/bin/env bash
set -Eeuo pipefail

ROCBLAS_BRANCH="${ROCBLAS_BRANCH:-release/rocm-rel-6.4}"
REPO_URL="${REPO_URL:-https://github.com/ROCm/rocBLAS.git}"
SRC_ROOT="${SRC_ROOT:-$HOME/src/rocblas-6.4-gfx900-gfx906}"
INSTALL_PREFIX="${INSTALL_PREFIX:-/opt/custom_rocm/rocblas}"
GPU_TARGETS="gfx900;gfx906"
BUILD_TYPE="${BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(nproc)}"

msg()  { printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"; }
die()  { printf '\n[%s] ERROR: %s\n' "$(date '+%F %T')" "$*" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

need_cmd git
need_cmd cmake
need_cmd python3

export ROCM_PATH="${ROCM_PATH:-/opt/rocm}"
export PATH="$ROCM_PATH/bin:$ROCM_PATH/lib/llvm/bin:$PATH"

if command -v "$ROCM_PATH/bin/amdclang++" >/dev/null 2>&1; then
  CXX_COMPILER="$ROCM_PATH/bin/amdclang++"
elif command -v "$ROCM_PATH/lib/llvm/bin/amdclang++" >/dev/null 2>&1; then
  CXX_COMPILER="$ROCM_PATH/lib/llvm/bin/amdclang++"
elif command -v amdclang++ >/dev/null 2>&1; then
  CXX_COMPILER="$(command -v amdclang++)"
else
  die "amdclang++ not found"
fi

if command -v "$ROCM_PATH/bin/hipcc" >/dev/null 2>&1; then
  HIPCC_BIN="$ROCM_PATH/bin/hipcc"
elif command -v hipcc >/dev/null 2>&1; then
  HIPCC_BIN="$(command -v hipcc)"
else
  die "hipcc not found"
fi

# Match the target list exactly, per rocBLAS guidance
export HCC_AMDGPU_TARGET="gfx900,gfx906"

mkdir -p "$SRC_ROOT"
cd "$SRC_ROOT"

if [[ ! -d rocBLAS/.git ]]; then
  git clone --branch "$ROCBLAS_BRANCH" --depth 1 "$REPO_URL" rocBLAS
else
  git -C rocBLAS fetch --depth 1 origin "$ROCBLAS_BRANCH"
  git -C rocBLAS checkout "$ROCBLAS_BRANCH"
  git -C rocBLAS pull --ff-only || true
fi

cd "$SRC_ROOT/rocBLAS"

# Important: remove any helper-script build state
rm -rf build

mkdir -p build/manual-gfx900-gfx906
cd build/manual-gfx900-gfx906

cmake ../.. \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
  -DCMAKE_PREFIX_PATH="$ROCM_PATH" \
  -DCMAKE_CXX_COMPILER="$CXX_COMPILER" \
  -DHIP_HIPCC_EXECUTABLE="$HIPCC_BIN" \
  -DGPU_TARGETS="$GPU_TARGETS" \
  -DAMDGPU_TARGETS="$GPU_TARGETS" \
  -DBUILD_CLIENTS_TESTS=OFF \
  -DBUILD_CLIENTS_BENCHMARKS=OFF \
  -DBUILD_CLIENTS_SAMPLES=OFF \
  -DBUILD_SHARED_LIBS=ON

echo
echo "=== cache check ==="
grep -E 'GPU_TARGETS|AMDGPU_TARGETS|CMAKE_INSTALL_PREFIX' CMakeCache.txt || true

# Hard fail if cache is wrong
grep -q 'GPU_TARGETS:.*gfx900;gfx906' CMakeCache.txt || { echo "GPU_TARGETS not narrowed"; exit 1; }

cmake --build . --parallel "$JOBS"
sudo mkdir -p "$INSTALL_PREFIX"
sudo cmake --install .

echo
echo "=== installed files ==="
find "$INSTALL_PREFIX" -type f | grep -Ei 'librocblas|TensileLibrary|gfx900|gfx906|hsaco|\.co' || true