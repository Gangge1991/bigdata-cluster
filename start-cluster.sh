#!/bin/bash


# Worker 节点启动脚本 - 稳健版本
set -e  # 遇到错误立即退出

echo "=== 启动 Hadoop 服务 ==="
if ! /opt/hadoop/sbin/start-dfs.sh; then
    echo "错误: HDFS 启动失败"
    exit 1
fi

if ! /opt/hadoop/sbin/start-yarn.sh; then
    echo "错误: YARN 启动失败"
    exit 1
fi


echo "=== 等待 Hadoop 服务就绪 ==="
# 动态等待 HDFS 就绪
HDFS_READY=false
for i in {1..30}; do
    if hdfs dfsadmin -report &>/dev/null; then
        echo "HDFS 服务已就绪"
        HDFS_READY=true
        break
    fi
    echo "等待 HDFS 服务启动... ($i/30)"
    sleep 2
done

if [ "$HDFS_READY" = false ]; then
    echo "错误: HDFS 服务启动超时，请检查配置和日志"
    exit 1
fi



# 检查 YARN 是否就绪
YARN_READY=false
for i in {1..15}; do
    if yarn node -list &>/dev/null; then
        echo "YARN 服务已就绪"
        YARN_READY=true
        break
    fi
    echo "等待 YARN 服务启动... ($i/15)"
    sleep 2
done

if [ "$YARN_READY" = false ]; then
    echo "错误: YARN 服务启动超时，请检查配置和日志"
    exit 1
fi

echo "=== 启动 Hive Metastore 服务 ==="
hive --service metastore > /var/log/hive-metastore.log 2>&1 &
METASTORE_PID=$!


# 等待并检查 Metastore 是否成功启动
sleep 10
if kill -0 $METASTORE_PID 2>/dev/null; then
    echo "Hive Metastore 启动成功 (PID: $METASTORE_PID)"
else
    echo "Hive Metastore 启动失败，查看日志："
    cat /var/log/hive-metastore.log
    exit 1
fi


echo "=== 启动 HiveServer2 ==="
hiveserver2 > /var/log/hiveserver2.log 2>&1 &
HIVESERVER2_PID=$!

# 等待并检查 HiveServer2 是否成功启动
sleep 10
if kill -0 $HIVESERVER2_PID 2>/dev/null; then
    echo "HiveServer2 启动成功 (PID: $HIVESERVER2_PID)"
else
    echo "HiveServer2 启动失败，查看日志："
    cat /var/log/hiveserver2.log
    exit 1
fi

echo "=== 启动 HBase 服务 ==="
if /opt/hbase/bin/start-hbase.sh; then
    echo "HBase 启动成功"
else
    echo "HBase 启动失败"
fi

echo "=== 启动 Flink 服务 ==="
if /opt/flink/bin/start-cluster.sh; then
    echo "Flink 启动成功"
else
    echo "Flink 启动失败"
fi

echo "=== 启动 Spark 服务 ==="
/opt/spark/sbin/start-master.sh
/opt/spark/sbin/start-workers.sh

# 创建 Spark History Server 日志目录
hdfs dfs -mkdir -p /spark-logs

echo "=== 启动 Spark History Server ==="
/opt/spark/sbin/start-history-server.sh


echo "=== 所有服务启动完成 ==="
echo "Metastore PID: $METASTORE_PID"
echo "HiveServer2 PID: $HIVESERVER2_PID"