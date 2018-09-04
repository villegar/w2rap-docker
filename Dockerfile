FROM centos

LABEL name="W2RAP Pipeline" \
    author="Roberto Villegas-Diaz" \
    maintainer="Roberto.VillegasDiaz@sdstate.edu"

RUN yum -y install git wget xz which && \
    yum -y install bzip2 bzip2-devel make cmake file && \
    yum -y install texi2html texinfo && \ 
    yum -y install autoconf automake libtool gnuplot && \
    yum -y install zlib zlib-devel lzma lzma-devel && \
    yum -y install gcc gcc-c++ libgcc glibc-devel glibc-headers
#RUN yum -y group install "Development Tools"

RUN mkdir -p /opt && \
    cd /opt && \
    rm -rf /opt/*
# --- Installing GCC ---
ENV GCC_VER="5.5.0"
WORKDIR /opt
RUN wget --quiet -4 https://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz && \
    tar -xzf gcc-${GCC_VER}.tar.gz && \
    cd gcc-${GCC_VER} && \
    ./contrib/download_prerequisites && \
    mkdir build && \
    cd build && \
    ../configure \
        --prefix=/usr \
        --disable-multilib \
        --enable-languages=c,c++,fortran \
        --enable-libstdcxx-threads \
        --enable-libstdcxx-time \
        --enable-shared \
        --enable-__cxa_atexit \
        --disable-libunwind-exceptions \
        --disable-libada \
        --host x86_64-redhat-linux-gnu \
        --build x86_64-redhat-linux-gnu \
        --with-default-libstdcxx-abi=gcc4-compatible
RUN cd /opt/gcc-${GCC_VER}/build && make -j4
RUN cd /opt/gcc-${GCC_VER}/build && make install

# Register new libraries with `ldconfig`
RUN echo "/usr/local/lib64" > usrLocalLib64.conf && \
    mv usrLocalLib64.conf /etc/ld.so.conf.d/ && \
    ldconfig

# Clean out all the garbage
RUN rm -rf /opt/gcc-${GCC_VER} && rm -rf ~/tests && rm -rf *.tar.gz

# --- Installing Anaconda ---
RUN echo 'export PATH=/opt/conda3/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh -O /opt/anaconda.sh && \
    /bin/bash /opt/anaconda.sh -b -p /opt/conda3 && \
    rm /opt/anaconda.sh

# --- Installing Miniconda ---
#RUN echo 'export PATH=/opt/conda3/bin:$PATH' > /etc/profile.d/conda.sh && \
#    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /opt/miniconda.sh && \
#    /bin/bash /opt/miniconda.sh -b -p /opt/conda3 && \
#    rm /opt/miniconda.sh
ENV PATH="/opt/conda3/bin:${PATH}"
RUN conda install numpy scipy matplotlib sphinx
RUN conda config --add channels r && \
    conda config --add channels defaults && \
    conda config --add channels conda-forge && \
    conda config --add channels bioconda

# --- Installing KAT (K-mer Analysis Toolkit) ---
RUN conda install kat
WORKDIR /opt

# --- Installing w2rap-contigger ---
RUN export CC=$(which gcc)
RUN export CXX=$(which g++)
RUN git clone https://github.com/gonzalogacc/w2rap-contigger.git && \
    cd w2rap-contigger && \
    cmake -D CMAKE_CXX_COMPILER=g++ .  && \
    make -j 16
ENV PATH="/opt/w2rap-contigger/bin:${PATH}"
RUN which w2rap-contigger && w2rap-contigger --version

# --- Installing BWA (Burrows-Wheeler Aligner) ---
RUN conda install -c bioconda bwa
RUN which bwa

# --- Installing FLASh (Fast Length Adjustment of Short reads) ---
RUN conda install -c bioconda flash
RUN which flash && flash --version

# --- Installing NextClip (Nextera Long Mate Pair analysis and processing tool) ---
RUN conda install -c conda-forge texlive-core
RUN conda install -c r r-base 
RUN which R && R --version
WORKDIR /opt
RUN wget --quiet -4 https://github.com/richardmleggett/nextclip/archive/NextClip_v1.3.1.tar.gz && \
    tar -xzf NextClip_v1.3.1.tar.gz && \
    cd nextclip-NextClip_v1.3.1 && \
    make && \
    mkdir -p /opt/NextClip/1.3.1 && \
    cp -rav ./bin /opt/NextClip/1.3.1 && \
    cp -rav ./scripts /opt/NextClip/1.3.1 && \
    cp -rav ./include /opt/NextClip/1.3.1 && \
    cd /opt && rm -rf *.tar.gz && rm -rf nextclip-NextClip_v1.3.1
ENV PATH="/opt/NextClip/1.3.1/bin:/opt/NextClip/1.3.1/scripts:$PATH"

# --- Installing ABySS ---
RUN conda install -c bioconda abyss

# --- Installing FastQC ---
RUN conda install -c bioconda fastqc
#RUN which fastqc && fastqc --version

# --- Installing BUSCO ---
RUN conda install -c bioconda busco
#RUN which busco && busco --version
#RUN conda list

# --- Installing QUAST ---
RUN conda install -c bioconda quast
#RUN conda install -c bioconda quast_libs
#RUN quast-download-manta
#RUN quast-download-blastdb
#RUN which quast && quast --version
