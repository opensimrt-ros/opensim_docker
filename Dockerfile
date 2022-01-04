FROM ubuntu:18.04

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
	python-dev \
	python3-dev \
	python3-numpy \
	software-properties-common \
	wget \
	zlib1g-dev 

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

ENV CMAKE_VERSION=3.6.0
RUN 	git clone -b v$CMAKE_VERSION https://gitlab.kitware.com/cmake/cmake.git cmake && \
	cd cmake && \
	./bootstrap --system-curl && \
	make && \
	make install

ENV SWIG_VERSION=4.0.2
RUN	wget http://ufpr.dl.sourceforge.net/project/swig/swig/swig-$SWIG_VERSION/swig-$SWIG_VERSION.tar.gz && \
	tar xzf swig-$SWIG_VERSION.tar.gz && \
	cd swig-$SWIG_VERSION/ && \
	./configure --prefix=$HOME/swig && \
	make clean && make && make install
ENV SWIG_PATH=$HOME/swig/bin/swig

RUN 	rm -f /usr/bin/cc /usr/bin/c++ && \
	ln -s /usr/bin/clang-3.6 /usr/bin/cc && \
	ln -s /usr/bin/clang++-3.6 /usr/bin/c++


ENV OPENSIM_REPO=https://github.com/mitkof6/opensim-core.git
#https://github.com/opensim-org/opensim-core.git
ENV OPENSIM_BRANCH=bindings_timestepper
#master
RUN 	git clone -b $OPENSIM_BRANCH $OPENSIM_REPO
WORKDIR	opensim_dependencies_build
RUN	cmake ../opensim-core/dependencies/ \
      		-DCMAKE_INSTALL_PREFIX='~/opensim_dependencies_install' \
      		-DCMAKE_BUILD_TYPE=RelWithDebInfo && \ 
	make -j12

WORKDIR /opensim_build

ENV PATH=$PATH:/root/swig/bin/
ENV SWIG_DIR=/root/swig/bin
ENV SWIG_EXECUTABLE=/root/swig/bin/swig

RUN 	cmake ../opensim-core \
	      -DCMAKE_INSTALL_PREFIX="~/opensim_install" \
	      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	      -DOPENSIM_DEPENDENCIES_DIR="~/opensim_dependencies_install" \
	      -DBUILD_PYTHON_WRAPPING=ON \
	      -DBUILD_JAVA_WRAPPING=OFF \
	      -DWITH_BTK=ON  
	      #no java?

#RUN apt-get install libjpeg62-turbo tzdata-java initscripts libsctp1

#RUN	make -j12
#	ctest -j8 && \
#	make -j8 install 
