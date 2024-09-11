FROM ros:noetic-ros-base AS dependencies

##Remove to trigger new build action

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
RUN 	git clone -b $OPENSIM_BRANCH $OPENSIM_REPO
RUN	cmake /usr/src/opensim-core/dependencies/ \
      		-DCMAKE_INSTALL_PREFIX='/opt/dependencies' \
      		-DCMAKE_BUILD_TYPE=RelWithDebInfo && \ 
	make -j12 

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

#get casadi? will this work?
#RUN wget https://github.com/casadi/casadi/releases/download/3.5.5/casadi-linux-py36-v3.5.5-64bit.tar.gz && \
#	tar -xvf casadi-linux-py36-v3.5.5-64bit.tar.gz

#ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opensim_build/casadi

####move this to it's own thing, it is interposed here
#https://coin-or.github.io/Ipopt/INSTALL.html
#these guys recommend that I get a compatible blas, so maybe this can use cublas
ENV IPOPTDIR=/usr/src/Ipopt
RUN 	git clone https://github.com/coin-or/Ipopt.git $IPOPTDIR 

WORKDIR $IPOPTDIR
RUN 	git clone https://github.com/coin-or-tools/ThirdParty-HSL.git
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
RUN git clone https://github.com/casadi/casadi.git -b main casadi
WORKDIR /opt/casadi/
RUN cmake -DWITH_PYTHON=ON /usr/src/casadi && make && make install

FROM dependencies as stage2

WORKDIR /opt/opensim-core
RUN 	cmake /usr/src/opensim-core \
	      -DCMAKE_INSTALL_PREFIX=$OPENSIM_INSTALL_DIR \
	      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	      -DOPENSIM_DEPENDENCIES_DIR="/opt/dependencies" \
	      -DBUILD_PYTHON_WRAPPING=ON \
	      -DOPENSIM_PYTHON_VERSION=3 \
	      -DBUILD_JAVA_WRAPPING=OFF \
	      -DWITH_BTK=ON \
	      -DOPENSIM_WITH_TROPTER=OFF #\
      #-Dcasadi_DIR=/opensim_build/casadi/cmake
	      #no java?

#RUN apt-get install libjpeg62-turbo tzdata-java initscripts libsctp1

ENV PYTHONPATH=/usr/local/lib/python3.6/site-packages/

RUN	make osimCommon -j`nproc` &&\
	make osimSimulation -j`nproc` &&\
	make osimActuators -j`nproc` &&\
	make osimTools -j`nproc` &&\
	make osimAnalyses -j`nproc` &&\
	make osimMoco -j`nproc` &&\
	make osimLepton -j`nproc`

RUN	make -j`nproc`
#	ctest -j8 && \
RUN 	make -j`nproc` install 



