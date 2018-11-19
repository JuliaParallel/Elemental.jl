#!/bin/sh
# This configuration file was taken originally from the mpi4py project
# <http://mpi4py.scipy.org/>, and then modified for Julia

set -e
set -x

MPI_IMPL="$1"
os=`uname`

case "$os" in
    Darwin)
        brew update
        brew upgrade cmake
        brew cask uninstall oclint
        brew install gcc
        case "$MPI_IMPL" in
            mpich|mpich3)
                brew install mpich
                ;;
            openmpi)
                brew install openmpi
                ;;
            *)
                echo "Unknown MPI implementation: $MPI_IMPL"
                exit 1
                ;;
        esac
    ;;

    Linux)
        sudo apt-get update -q
        case "$MPI_IMPL" in
            mpich1)
                sudo apt-get install -y mpich-shmem-bin libmpich-shmem1.0-dev
                ;;
            mpich2)
                sudo apt-get install -y mpich2 libmpich2-3 libmpich2-dev
                ;;
            mpich|mpich3)
                sudo apt-get install -y libmpich-dev mpich
                ;;
            openmpi)
                wget --no-check-certificate https://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-1.10.2.tar.gz
                tar -zxvf openmpi-1.10.2.tar.gz
                cd openmpi-1.10.2
                sh ./configure --prefix=$HOME/OpenMPI
                make -j
                sudo make install
                ;;
            *)
                echo "Unknown MPI implementation: $MPI_IMPL"
                exit 1
                ;;
        esac
        ;;

    *)
        echo "Unknown operating system: $os"
        exit 1
        ;;
esac
