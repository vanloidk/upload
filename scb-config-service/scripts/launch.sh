#!/bin/bash
#
#
SERVICE_NAME_LOG=scb-config-service
SERVICE_NAME_SYSTEMD=scb-config-service
JAR_FILE_NAME=config-service.jar
FILE_PATH_LOG=tmp
FILE_LOG=$FILE_PATH_LOG/$SERVICE_NAME_LOG.log

# ======================================================================================================================
#

MBA_MAX_MEMORY=1G
MBA_GC_TYPE=ParallelGC
VM_OPTION_LOG4J_ASYNC=-Dlog4j2.contextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector
VM_CONFIG_FILE_PARAM_SERVER=-Dconfig.file="./config/startup.conf"
VM_OPTION_CONFIG_CUSTOM_PARAMS=-Dquick-jetty.server-config.thread-pool.queu-pool-custom.min-thread=8
#VM_OPTION_CONFIG_CHILKAT_LIBS=-Djava.library.path="./bin/chilkat-9.5.0-jdk6-x64"
VM_OPTION_CONFIG_HAZELCAST=--add-modules java.se --add-exports java.base/jdk.internal.ref=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.management/sun.management=ALL-UNNAMED --add-opens jdk.management/com.sun.management.internal=ALL-UNNAMED

#VM_OPTIONS=$VM_OPTION_CONFIG_HAZELCAST
# VM_OPTIONS=$VM_OPTION_LOG4J_ASYNC
# VM_OPTIONS=$VM_OPTION_CONFIG_CHILKAT_LIBS $VM_OPTION_CONFIG_CUSTOM_PARAMS
# CONFIG_FILE=--config "./config/config.json" # after jar file name
#
# JAVA JDK/JRE optional
#export JAVA_HOME="/opt/jdk-11.0.10"
#export PATH=$JAVA_HOME/bin:$PATH
#export LD_LIBRARY_PATH=$JAVA_HOME/lib:$LD_LIBRARY_PATH
#java -version
#

# ======================================================================================================================
echo # =================================================================================================================
echo "VM_OPTIONS ::  $VM_OPTIONS"
echo "JAVA_HOME  ::  $JAVA_HOME"
echo "PATH       ::  $PATH"
java -version

if [ -z "$MBA_GC_TYPE" ]; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    # Experiments indicate ConcMarkSweepGC is better for JVM in Java 1.8;
    # G1GC is better in later Java versions.  (This only considers currently-supported versions.)
    case $JAVA_VERSION in
        1.8*)
            MBA_GC_TYPE=ConcMarkSweepGC;
            ;;
        *)
            MBA_GC_TYPE=G1GC;
            ;;
    esac
fi

if [ ! -e "$FILE_PATH_LOG" ]; then
  # Take action if $FILE_PATH_LOG exists. #
  echo "Create folder $(pwd) ${FILE_PATH_LOG}... store logs runtime start/stop"
  mkdir $FILE_PATH_LOG
fi

if [ -f "$FILE_LOG" ]; then
    mv ./$FILE_LOG $FILE_LOG"_$(date '+%Y%m%d_%H%M')"
fi


# to load logs -Djava.util.logging.config.file=config/logging.properties
# to load chilkat -Djava.library.path="/chilkat-9.5.0-jdk6-x64"
exec java -Xmx$MBA_MAX_MEMORY -XX:+Use$MBA_GC_TYPE -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./$FILE_PATH_LOG $VM_OPTIONS -Dfile.encoding=UTF-8 -jar $JAR_FILE_NAME
