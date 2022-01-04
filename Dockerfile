FROM ubuntu:18.04
RUN 	apt-get update && \
	apt-get install git software-properties-common build-essential wget curl net-tools zlib1g-dev \
	libssl-dev libcurl4-openssl-dev \
	--yes 
#RUN     wget http://www.cmake.org/files/v3.2/cmake-3.2.2.tar.gz && \
	#tar xf cmake-3.2.2.tar.gz && \
#	cd cmake-3.2.2 && \
#	./configure && \
#	make && \
#	make install
	#apt-add-repository ppa:george-edison55/cmake-3.x && \ ##this is broken
#RUN git clone -b v3.5.2 https://cmake.org/cmake.git cmake && \
RUN git clone -b v3.5.2 https://gitlab.kitware.com/cmake/cmake.git cmake && \
	cd cmake && \
	./bootstrap --system-curl && \
	make && \
	make install



RUN	apt install libpcre3 libpcre3-dev --yes && \
	wget http://ufpr.dl.sourceforge.net/project/swig/swig/swig-3.0.12/swig-3.0.12.tar.gz && \
	tar xzf swig-3.0.12.tar.gz && \
	cd swig-3.0.12/ && \
	./configure --prefix=$HOME/swig && \
	make clean && make && make install && \
	export SWIG_PATH=$HOME/swig/bin/swig 
	# export is not the correct way, we need to make sure this works properly before trying to compile opensim

	#apt-add-repository ppa:fenics-packages/fenics-exp && \ ## also broken
	#apt-get update && \
	## there is also no jdk 7 anymore, i might need to compile it from source as well, but that I will try to avoid. java *should* be backwards compatible
RUN	apt-get install --yes \
		clang-3.6 \
		# cmake \
		cmake-curses-gui \
		freeglut3-dev \
		git	\
		liblapack-dev \
		libxi-dev \
		libxmu-dev \
		openjdk-8-jdk \ 
		python-dev \
		libatlas-base-dev  liblapacke-dev gfortran autoconf libtool patch wget pkg-config liblapack-dev libmetis-dev
#
		#swig3.0 \
RUN 	rm -f /usr/bin/cc /usr/bin/c++ && \
	ln -s /usr/bin/clang-3.6 /usr/bin/cc && \
	ln -s /usr/bin/clang++-3.6 /usr/bin/c++

ENV SWIG_PATH=$HOME/swig/bin/swig 
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN 	git clone https://github.com/opensim-org/opensim-core.git
WORKDIR	opensim_dependencies_build
RUN	cmake ../opensim-core/dependencies/ \
      		-DCMAKE_INSTALL_PREFIX='~/opensim_dependencies_install' \
      		-DCMAKE_BUILD_TYPE=RelWithDebInfo && \ 
	make -j12
#RUN apt install 
WORKDIR opensim_build

#RUN 	mkdir opensim_build && \
#	cd opensim_build && \
#	cmake ../opensim-core \
#	      -DCMAKE_INSTALL_PREFIX="~/opensim_install" \
#	      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
#	      -DOPENSIM_DEPENDENCIES_DIR="~/opensim_dependencies_install" \
#	      -DBUILD_PYTHON_WRAPPING=ON \
#	      -DBUILD_JAVA_WRAPPING=ON \
#	      -DWITH_BTK=ON && \
#	make -j8 && \
#	ctest -j8 && \
#	make -j8 install 
