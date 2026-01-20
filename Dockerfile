
# 1st stage, build the app
FROM container-registry.oracle.com/java/jdk-no-fee-term:25@sha256:278ac5410f2fdd2ce05b6e10939b0981636af66f3fc06f0010b06daec601b006 as build

# Install maven
WORKDIR /usr/share
RUN set -x && \
    curl -O https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz && \
    tar -xvf apache-maven-*-bin.tar.gz  && \
    rm apache-maven-*-bin.tar.gz && \
    mv apache-maven-* maven && \
    ln -s /usr/share/maven/bin/mvn /bin/

WORKDIR /helidon

# Create a first layer to cache the "Maven World" in the local repository.
# Incremental docker builds will always resume after that, unless you update
# the pom
ADD pom.xml .
RUN mvn package -Dmaven.test.skip -Declipselink.weave.skip 

# Do the Maven build!
# Incremental docker builds will resume here when you change sources
ADD src src
RUN mvn package -DskipTests

RUN echo "done!"

# 2nd stage, build the runtime image
FROM container-registry.oracle.com/java/jdk-no-fee-term:25@sha256:278ac5410f2fdd2ce05b6e10939b0981636af66f3fc06f0010b06daec601b006
WORKDIR /helidon

# Copy the binary built in the 1st stage
COPY --from=build /helidon/target/jpow.jar ./
COPY --from=build /helidon/target/libs ./libs

CMD ["java", "-jar", "jpow.jar"]

EXPOSE 8080
