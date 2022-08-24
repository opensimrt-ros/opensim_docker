FROM mysablehats/opensim.dependencies

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

RUN	make osimCommon -j`nproc`
RUN	make osimSimulation -j`nproc`
RUN	make osimActuators -j`nproc`
RUN	make osimTools -j`nproc`
RUN	make osimAnalyses -j`nproc`
RUN	make osimMoco -j`nproc`
RUN	make osimLepton -j`nproc`
RUN	make -j`nproc`
#	ctest -j8 && \
RUN 	make -j`nproc` install 
