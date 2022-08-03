FROM ubuntu:18.04

##Remove to trigger new build action

#print(" \\\n\t".join(sorted(set(a.replace("\\","").replace("\n","").split()[1:])))) ## remove the [1:] part if you copied it properly. this is to remove the install bit!

RUN 	apt-get update && \
	apt-get install --yes \ 
	autoconf \
	build-essential \
	clang-3.6 \
	cmake-curses-gui \
	curl \
	freeglut3-dev \
	gfortran \
	git \
	libatlas-base-dev \
	libcurl4-openssl-dev \
	liblapack-dev \
	liblapacke-dev \
	libmetis-dev \
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

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

ENV CMAKE_VERSION=3.15.0
RUN 	git clone -b v$CMAKE_VERSION https://gitlab.kitware.com/cmake/cmake.git cmake && \
	cd cmake && \
	./bootstrap --system-curl && \
	make && \
	make install

RUN 	rm -f /usr/bin/cc /usr/bin/c++ && \
	ln -s /usr/bin/clang-3.6 /usr/bin/cc && \
	ln -s /usr/bin/clang++-3.6 /usr/bin/c++

ENV OPENSIM_INSTALL_DIR=/root/opensim_install
#ENV OPENSIM_REPO=https://github.com/mitkof6/opensim-core.git
ENV OPENSIM_REPO=https://github.com/opensim-org/opensim-core.git
#ENV OPENSIM_BRANCH=bindings_timestepper
ENV OPENSIM_BRANCH=master
RUN 	git clone -b $OPENSIM_BRANCH $OPENSIM_REPO
WORKDIR	opensim_dependencies_build
RUN	cmake ../opensim-core/dependencies/ \
      		-DCMAKE_INSTALL_PREFIX='~/opensim_dependencies_install' \
      		-DCMAKE_BUILD_TYPE=RelWithDebInfo && \ 
	make -j12 

WORKDIR /opensim_build

ENV SWIG_VERSION=4.0.2
RUN	wget http://ufpr.dl.sourceforge.net/project/swig/swig/swig-$SWIG_VERSION/swig-$SWIG_VERSION.tar.gz && \
	tar xzf swig-$SWIG_VERSION.tar.gz && \
	cd swig-$SWIG_VERSION/ && \
	./configure --prefix=$HOME/swig && \
	make clean && make && make install
ENV SWIG_PATH=$HOME/swig/bin/swig

ENV PATH=$PATH:/root/swig/bin/
ENV SWIG_DIR=/root/swig/bin
ENV SWIG_EXECUTABLE=/root/swig/bin/swig
#ENV DESTDIR=$OPENSIM_INSTALL_DIR #idk about this.

#get casadi? will this work?
#RUN wget https://github.com/casadi/casadi/releases/download/3.5.5/casadi-linux-py36-v3.5.5-64bit.tar.gz && \
#	tar -xvf casadi-linux-py36-v3.5.5-64bit.tar.gz

#ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opensim_build/casadi

####move this to it's own thing, it is interposed here
#https://coin-or.github.io/Ipopt/INSTALL.html
#these guys recommend that I get a compatible blas, so maybe this can use cublas
#ENV IPOPTDIR=/Ipopt
#RUN 	git clone https://github.com/coin-or/Ipopt.git $IPOPTDIR 

#RUN 	git clone https://github.com/coin-or-tools/ThirdParty-HSL.git && \
#	cd ThirdParty-HSL && \
#	./configure && \
#	make && make install
	
#WORKDIR $IPOPTDIR/build
# i don't want to deal with java right now and neither with hsl. hsl seems simple enough, but I'd rather avoid it, until i really need it
#RUN 	$IPOPTDIR/configure --disable-java --disable-linear-solver-loader && \
#	make && make install
	#&& make test && make install
#####################################################
RUN apt-get install coinor-libipopt-dev gcc g++ gfortran git cmake liblapack-dev pkg-config --install-recommends -y
RUN git clone https://github.com/casadi/casadi.git -b master casadi
WORKDIR casadi/build 
RUN cmake -DWITH_PYTHON=ON .. && make && make install

##I need casadi, so 

WORKDIR /opensim_build
RUN 	cmake ../opensim-core \
	      -DCMAKE_INSTALL_PREFIX=$OPENSIM_INSTALL_DIR \
	      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	      -DOPENSIM_DEPENDENCIES_DIR="~/opensim_dependencies_install" \
	      -DBUILD_PYTHON_WRAPPING=ON \
	      -DOPENSIM_PYTHON_VERSION=3 \
	      -DBUILD_JAVA_WRAPPING=OFF \
	      -DWITH_BTK=ON \
	      -DOPENSIM_WITH_TROPTER=OFF #\
	      #-Dcasadi_DIR=/opensim_build/casadi/cmake
	      #no java?

#RUN apt-get install libjpeg62-turbo tzdata-java initscripts libsctp1

ENV PYTHONPATH=/root/opensim_install/lib/python3.6/site-packages/

WORKDIR /opensim_build
RUN	make -j12
#	ctest -j8 && \
#	cd /root/opensim_install/lib/python3.6/site-packages/
RUN 	make -j8 install 
