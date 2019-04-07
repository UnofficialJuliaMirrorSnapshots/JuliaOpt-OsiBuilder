# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OsiBuilder"
version = v"0.107.9"

# Collection of sources required to build OsiBuilder
sources = [
    "https://github.com/coin-or/Osi/archive/releases/0.107.9.tar.gz" =>
    "e2c8a0ee4a2a0abe7475d67f7f98230e8bfbbcb6e74487877e757c996bfd6d30",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Osi-releases-0.107.9/
update_configure_scripts
# temporary fix
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
mkdir build
cd build/
export CXXFLAGS="-std=c++11"

## STATIC BUILD START
if [ $target = "x86_64-apple-darwin14" ]; then
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-lapack-lib="-L${prefix}/lib -lcoinlapack" \
--with-blas-lib="-L${prefix}/lib -lcoinblas"
## STATIC BUILD END

## DYNAMIC BUILD START
#../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
#--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
#--with-lapack="-L${prefix}/lib -lcoinlapack" \
#--with-blas="-L${prefix}/lib -lcoinblas"
## DYNAMIC BUILD END


make -j${nproc}
make install

"""
#export LDFLAGS="-L${prefix}/lib -lCoinUtils -lcoinglpk"
#--with-glpk-lib="-L${prefix}/lib -lcoinglpk" --with-glpk-incdir="$prefix/include/coin/ThirdParty" \
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libOsi", :libOsi),
    LibraryProduct(prefix, "libOsiCommonTests", :libOsiCommonTests)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaOpt/CoinUtilsBuilder/releases/download/v2.10.14-1-static/build_CoinUtilsBuilder.v2.10.14.jl",
    "https://github.com/JuliaOpt/COINBLASBuilder/releases/download/v1.4.6-1-static/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/JuliaOpt/COINLapackBuilder/releases/download/v1.5.6-1-static/build_COINLapackBuilder.v1.5.6.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
