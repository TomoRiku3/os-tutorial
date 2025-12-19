#!/bin/bash

# Build i386-elf cross-compiler on Apple Silicon Mac
# Based on OSDev wiki instructions with Apple Silicon compatibility

set -e  # Exit on any error

# Configuration
export TARGET="i386-elf"
export PREFIX="$HOME/cross-compiler"
export PATH="$PREFIX/bin:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
echo_info "Checking prerequisites..."

if ! command -v brew &> /dev/null; then
    echo_error "Homebrew is required but not installed"
    exit 1
fi

# Install required dependencies
echo_info "Installing dependencies via Homebrew..."
brew install gmp mpfr libmpc wget

# Set up build directory
BUILD_DIR="$HOME/cross-compiler-build"
echo_info "Setting up build directory: $BUILD_DIR"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Create prefix directory
echo_info "Creating installation prefix: $PREFIX"
mkdir -p "$PREFIX"

# Download sources
echo_info "Downloading binutils..."
wget -c https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz
echo_info "Downloading GCC..."
wget -c https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz

# Extract sources
echo_info "Extracting sources..."
tar -xf binutils-2.41.tar.xz
tar -xf gcc-13.2.0.tar.xz

# Build binutils first
echo_info "Building binutils..."
mkdir -p build-binutils
cd build-binutils

../binutils-2.41/configure \
    --target=$TARGET \
    --prefix="$PREFIX" \
    --with-sysroot \
    --disable-nls \
    --disable-werror \
    --enable-interwork \
    --enable-multilib \
    --with-system-zlib \
    --build=aarch64-apple-darwin

echo_info "Compiling binutils (this may take a while)..."
make -j$(sysctl -n hw.ncpu)
make install

# Verify binutils installation
if [ -f "$PREFIX/bin/$TARGET-ld" ]; then
    echo_info "Binutils installed successfully"
else
    echo_error "Binutils installation failed"
    exit 1
fi

# Build GCC
cd "$BUILD_DIR"
echo_info "Building GCC..."

# Download GCC prerequisites
cd gcc-13.2.0
./contrib/download_prerequisites
cd ..

mkdir -p build-gcc
cd build-gcc

../gcc-13.2.0/configure \
    --target=$TARGET \
    --prefix="$PREFIX" \
    --disable-nls \
    --enable-languages=c,c++ \
    --without-headers \
    --build=aarch64-apple-darwin \
    --with-gmp=$(brew --prefix gmp) \
    --with-mpfr=$(brew --prefix mpfr) \
    --with-mpc=$(brew --prefix libmpc)

echo_info "Compiling GCC (this will take a long time - 30+ minutes)..."
make all-gcc -j$(sysctl -n hw.ncpu)
make all-target-libgcc -j$(sysctl -n hw.ncpu)
make install-gcc
make install-target-libgcc

# Verify installation
echo_info "Verifying installation..."
if [ -f "$PREFIX/bin/$TARGET-gcc" ]; then
    echo_info "GCC cross-compiler installed successfully!"
    echo_info "Location: $PREFIX/bin"
    echo_info "Add this to your PATH: export PATH=\"$PREFIX/bin:\$PATH\""
    echo ""
    echo_info "Testing compiler:"
    "$PREFIX/bin/$TARGET-gcc" --version
    echo ""
    echo_info "Available tools:"
    ls -la "$PREFIX/bin/$TARGET-"*
else
    echo_error "GCC installation failed"
    exit 1
fi

# Create environment setup script
cat > "$PREFIX/setup-env.sh" << 'EOF'
#!/bin/bash
# Add cross-compiler to PATH
export PATH="$HOME/cross-compiler/bin:$PATH"
echo "Cross-compiler environment loaded"
echo "Available tools:"
ls "$HOME/cross-compiler/bin/"
EOF

chmod +x "$PREFIX/setup-env.sh"

echo_info "Build complete!"
echo_info "To use the cross-compiler:"
echo_info "  source $PREFIX/setup-env.sh"
echo_info "  or add this to your ~/.zshrc:"
echo_info "  export PATH=\"$PREFIX/bin:\$PATH\""