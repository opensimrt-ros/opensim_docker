ARG USE_N_CORES
FROM ros:noetic-ros-base AS dependencies
##Remove to trigger new build action
ARG USE_N_CORES

#print(" \\\n\t".join(sorted(set(a.replace("\\","").replace("\n","").split()[1:])))) ## remove the [1:] part if you copied it properly. this is to remove the install bit!

RUN 	apt-get update && \
	apt-get install --yes --install-recommends \ 
	autoconf \
	bison \
	byacc \
	build-essential \
	clang-3.6 \
	cmake-curses-gui \
	curl \
	freeglut3-dev \
	gcc \
	g++ \
	gfortran \
	git \
	libatlas-base-dev \
	libcurl4-openssl-dev \
	liblapack-dev \
	liblapacke-dev \
	libmetis-dev \
	libpcre2-dev \
	libpcre3 \
	libpcre3-dev \
	libssl-dev \
	libtool \
	libxi-dev \
	libxmu-dev \
	net-tools \
	openjdk-8-jdk \
	patch \
	pkg-config \
	python3-dev \
	python3-numpy \
	software-properties-common \
	wget \
	zlib1g-dev 

#ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

WORKDIR /usr/src
ENV CMAKE_VERSION=3.15.0
RUN 	git clone -b v$CMAKE_VERSION https://gitlab.kitware.com/cmake/cmake.git cmake && \
	cd cmake && \
	./bootstrap --system-curl && \
	make && \
	make install

RUN 	rm -f /usr/bin/cc /usr/bin/c++ && \
	ln -s /usr/bin/clang-3.6 /usr/bin/cc && \
	ln -s /usr/bin/clang++-3.6 /usr/bin/c++

WORKDIR /usr/src
ENV OPENSIM_INSTALL_DIR=/usr/local
#ENV OPENSIM_REPO=https://github.com/mitkof6/opensim-core.git
ENV OPENSIM_REPO=https://github.com/opensim-org/opensim-core.git
#ENV OPENSIM_BRANCH=bindings_timestepper
ENV OPENSIM_BRANCH=main
RUN 	git clone -b $OPENSIM_BRANCH $OPENSIM_REPO --shallow-since=2022 && cd opensim-core && git checkout 292147cee958a21a6af7d4c684c4e6645d3022ee && cd ..
RUN	cmake /usr/src/opensim-core/dependencies/ \
      		-DCMAKE_INSTALL_PREFIX='/opt/dependencies' \
      		-DCMAKE_BUILD_TYPE=RelWithDebInfo && \ 
	make -j$USE_N_CORES 

ENV SWIG_VERSION=4.1.1
RUN wget https://github.com/swig/swig/archive/refs/tags/v${SWIG_VERSION}.tar.gz && \
    tar xzf v$SWIG_VERSION.tar.gz && \
    cd swig-$SWIG_VERSION/ && \
    ./autogen.sh

WORKDIR /usr/src/swig-${SWIG_VERSION}

RUN ./configure --prefix=/usr/local && \
    make clean && make && make install

ENV SWIG_PATH=/usr/local/bin/swig

ENV SWIG_DIR=/usr/local/bin
ENV SWIG_EXECUTABLE=/usr/local/bin/swig
#ENV DESTDIR=$OPENSIM_INSTALL_DIR #idk about this.

####move this to it's own thing, it is interposed here
#https://coin-or.github.io/Ipopt/INSTALL.html
#these guys recommend that I get a compatible blas, so maybe this can use cublas
ENV IPOPTDIR=/usr/src/Ipopt
RUN 	git clone https://github.com/coin-or/Ipopt.git $IPOPTDIR && cd $IPOPTDIR && git checkout e10e5c738605f0525a50cbdaa624d56378986c77 

WORKDIR $IPOPTDIR
RUN 	git clone https://github.com/coin-or-tools/ThirdParty-HSL.git && cd ThirdParty-HSL && git checkout 4f8da755c38411738745d1fbe9866a67836ad8ae && cd ..
WORKDIR $IPOPTDIR/ThirdParty-HSL 
ENV COIN_ARCH=coinhsl-archive-2021.05.05
ADD ./$COIN_ARCH.tar.gz $IPOPTDIR/ThirdParty-HSL  
#RUN tar -xvf $COIN_ARCH.tar.gz && 
RUN ln -s $COIN_ARCH coinhsl
WORKDIR $IPOPTDIR/ThirdParty-HSL/$COIN_ARCH
RUN bash && ./configure && \
	make && make install
WORKDIR $IPOPTDIR/ThirdParty-HSL/
RUN bash && ./configure && \
	make && make install


WORKDIR $IPOPTDIR/build
# i don't want to deal with java right now and neither with hsl. hsl seems simple enough, but I'd rather avoid it, until i really need it
RUN bash $IPOPTDIR/configure --disable-java --disable-linear-solver-loader && \
	make test && make install
	#make && make install
#####################################################
#RUN apt-get install coinor-libipopt-dev gcc g++ gfortran git cmake liblapack-dev pkg-config --install-recommends -y
##I need casadi, so 
WORKDIR /usr/src

##so casadi is big and my network is complaining when downloading this. trying this dirty fix. If something else fails to fetch you can try putting this on the top of the dockerfile
RUN git config --global http.postBuffer 1048576000 && \
	git config --global http.lowSpeedLimit 0 && \
	git config --global http.lowSpeedTime 999999 
RUN git clone https://github.com/casadi/casadi.git -b main casadi && cd casadi && git checkout 81bbcd37d9aa69e53cae7164e5c5c06c5f8529ee
WORKDIR /opt/casadi/
RUN cmake -DWITH_PYTHON=ON /usr/src/casadi && make && make install

FROM dependencies AS stage2

ARG USE_N_CORES
WORKDIR /opt/opensim-core
RUN 	cmake /usr/src/opensim-core \
	      -DCMAKE_INSTALL_PREFIX=$OPENSIM_INSTALL_DIR \
	      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	      -DOPENSIM_DEPENDENCIES_DIR="/opt/dependencies" \
	      -DBUILD_PYTHON_WRAPPING=ON \
	      -DOPENSIM_PYTHON_VERSION=3 \
	      -DBUILD_JAVA_WRAPPING=OFF \
	      -DWITH_BTK=ON \
	      -DOPENSIM_WITH_TROPTER=OFF
#-Dcasadi_DIR=/opensim_build/casadi/cmake
	      #no java?

FROM stage2 AS stage3

ARG USE_N_CORES
ENV PYTHONPATH=/usr/local/lib/python3.6/site-packages/
RUN	make osimCommon -j$USE_N_CORES &&\
	make osimSimulation -j$USE_N_CORES &&\
	make osimActuators -j$USE_N_CORES &&\
	make osimTools -j$USE_N_CORES &&\
	make osimAnalyses -j$USE_N_CORES &&\
	make osimMoco -j$USE_N_CORES &&\
	make osimLepton -j$USE_N_CORES

	RUN	make -j2
#	ctest -j8 && \
RUN 	make -j$USE_N_CORES install 



