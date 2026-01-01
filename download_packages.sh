#!/bin/bash
set -e

# Directory to store packages
PKG_DIR="packages"
mkdir -p $PKG_DIR

# URLs
HADOOP_URL="https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz"
HIVE_URL="https://mirrors.huaweicloud.com/apache/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz"
SPARK_URL="https://mirrors.tuna.tsinghua.edu.cn/apache/spark/spark-3.5.7/spark-3.5.7-bin-hadoop3-scala2.13.tgz"
SCALA_URL="https://downloads.lightbend.com/scala/2.13.12/scala-2.13.12.tgz"
ZOOKEEPER_URL="https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/zookeeper-3.8.5/apache-zookeeper-3.8.5-bin.tar.gz"
TEZ_URL="https://archive.apache.org/dist/tez/0.10.3/apache-tez-0.10.3-bin.tar.gz"
MYSQL_CONNECTOR_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar"
PYTHON_URL="https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz"
HTRACE_URL="https://repo1.maven.org/maven2/org/apache/htrace/htrace-core4/4.1.0-incubating/htrace-core4-4.1.0-incubating.jar"
FLINK_URL="https://mirrors.tuna.tsinghua.edu.cn/apache/flink/flink-1.17.2/flink-1.17.2-bin-scala_2.12.tgz"
HBASE_URL="https://archive.apache.org/dist/hbase/2.5.8/hbase-2.5.8-bin.tar.gz"
# HBASE_URL="https://mirrors.tuna.tsinghua.edu.cn/apache/hbase/2.5.13/hbase-2.5.13-bin.tar.gz"

# Function to download if not exists
download_if_missing() {
    local url=$1
    local filename=$(basename "$url")
    local filepath="$PKG_DIR/$filename"

    if [ -f "$filepath" ]; then
        echo "File $filename already exists, skipping download."
    else
        echo "Downloading $filename..."
        curl -L -o "$filepath" "$url"
    fi
}

echo "Starting downloads..."
download_if_missing "$HADOOP_URL"
download_if_missing "$HIVE_URL"
download_if_missing "$SPARK_URL"
download_if_missing "$SCALA_URL"
download_if_missing "$ZOOKEEPER_URL"
download_if_missing "$TEZ_URL"
download_if_missing "$MYSQL_CONNECTOR_URL"
download_if_missing "$PYTHON_URL"
download_if_missing "$HTRACE_URL"
download_if_missing "$FLINK_URL"
download_if_missing "$HBASE_URL"

echo "All packages downloaded successfully."
