# Version 1.0: Initial release
# --------------------------------------------------------------------------------------------------------------

FROM acrth01seanshared01.azurecr.io/sag/jvm/zulu:8.40.0.20.20200724 as base

MAINTAINER AIA

USER 1000

# __instance_name: If user want to copy the specific instance content to image, they can specifiy here. Default instance name is 'umserver'
ARG __instance_name=umserver

MAINTAINER AIA

# Environment variables
ENV INSTANCE_NAME=$__instance_name 
ENV UM_HOME=$SAG_HOME/UniversalMessaging
ENV PORT=9001 \
    DATA_DIR=$UM_HOME/server/$INSTANCE_NAME/data \
    LOG_DIR=$UM_HOME/server/$INSTANCE_NAME/logs \ 
    LIC_DIR=$UM_HOME/server/$INSTANCE_NAME/licence \ 
    USERS_DIR=$SAG_HOME/common/conf \
    SERVER_COMMON_CONF_FILE=Server_Common.conf \
    TOOLS_DIR=$UM_HOME/tools

# Create the required folders (data, logs, licence and tools) as these are not going to be copied from the installation, but will be needed at runtime
RUN mkdir -p $DATA_DIR $LOG_DIR $LIC_DIR $TOOLS_DIR && chown 1000:1000 $DATA_DIR && chown 1000:1000 $LOG_DIR && chown 1000:1000 $LIC_DIR && chown 1000:1000 $TOOLS_DIR
RUN mkdir -p $SAG_HOME/common && chown 1000:1000 $SAG_HOME/common

COPY --chown=1000:1000 ./jvm/jvm/ $SAG_HOME/jvm/jvm/
ENV PATH=$SAG_HOME:$SAG_HOME/jvm/jvm:$PATH

# Copy the required binaries from installation to image
COPY --chown=1000:1000 ./common/bin/ $SAG_HOME/common/bin/
COPY --chown=1000:1000 ./common/lib/ $SAG_HOME/common/lib/
COPY --chown=1000:1000 ./common/conf/users.txt $USERS_DIR/users.txt
COPY --chown=1000:1000 ./UniversalMessaging/server/$INSTANCE_NAME/bin $UM_HOME/server/$INSTANCE_NAME/bin
COPY --chown=1000:1000 ./UniversalMessaging/lib/ $UM_HOME/lib/
COPY --chown=1000:1000 ./UniversalMessaging/classes/ $UM_HOME/classes/
COPY --chown=1000:1000 ./UniversalMessaging/tools/runner/ $TOOLS_DIR/runner/

# Copy the entry point script
COPY --chown=1000:1000 ./umstart.sh $SAG_HOME/umstart.sh

# Change permissions for entry point script 
RUN chmod u+x $SAG_HOME/umstart.sh

# Move the licence file to Universal Messaging licence folder
COPY --chown=1000:1000 ./UniversalMessaging/server/$INSTANCE_NAME/licence.xml $LIC_DIR/licence.xml

# Copy the configure.sh which contains all the build time configuration changes
COPY --chown=1000:1000 ./configure.sh $SAG_HOME/configure.sh

# Change the work directory, where the entry point script is present.
WORKDIR $SAG_HOME

# Change the permissions to configure.sh and run it
RUN chmod u+x $SAG_HOME/configure.sh ;\
    $SAG_HOME/configure.sh

# Add the runUMTool path, so we can run this tool directly from docker exec command
ENV PATH=$TOOLS_DIR/runner/:$PATH

# Create the Persistent storage for data directory, logs directory, licence directory and users directory
VOLUME [ "$DATA_DIR", "$LOG_DIR", "$LIC_DIR", "$USERS_DIR" ]


ENTRYPOINT umstart.sh

EXPOSE $PORT
