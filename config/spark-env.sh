export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export YARN_CONF_DIR=/opt/hadoop/etc/hadoop
export SPARK_DIST_CLASSPATH=$(/opt/hadoop/bin/hadoop classpath)
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export SPARK_YARN_USER_ENV="CLASSPATH=/opt/hadoop/etc/hadoop"
