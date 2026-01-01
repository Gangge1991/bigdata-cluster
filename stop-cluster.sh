#!/bin/bash

# 集群停止脚本

echo "=== 停止 HiveServer2 ==="
# 查找并 kill HiveServer2 进程
HIVESERVER2_PID=$(pgrep -f "org.apache.hive.service.server.HiveServer2")
if [ -n "$HIVESERVER2_PID" ]; then
    echo "正在停止 HiveServer2 (PID: $HIVESERVER2_PID)..."
    kill $HIVESERVER2_PID
    # 等待进程退出
    for i in {1..10}; do
        if ! kill -0 $HIVESERVER2_PID 2>/dev/null; then
            break
        fi
        sleep 1
    done
    if kill -0 $HIVESERVER2_PID 2>/dev/null; then
        echo "强制停止 HiveServer2..."
        kill -9 $HIVESERVER2_PID
    fi
    echo "HiveServer2 已停止"
else
    echo "未发现运行中的 HiveServer2"
fi

echo "=== 停止 Hive Metastore ==="
# 查找并 kill Hive Metastore 进程
METASTORE_PID=$(pgrep -f "org.apache.hadoop.hive.metastore.HiveMetaStore")
if [ -n "$METASTORE_PID" ]; then
    echo "正在停止 Hive Metastore (PID: $METASTORE_PID)..."
    kill $METASTORE_PID
    for i in {1..10}; do
        if ! kill -0 $METASTORE_PID 2>/dev/null; then
            break
        fi
        sleep 1
    done
    if kill -0 $METASTORE_PID 2>/dev/null; then
        echo "强制停止 Hive Metastore..."
        kill -9 $METASTORE_PID
    fi
    echo "Hive Metastore 已停止"
else
    echo "未发现运行中的 Hive Metastore"
fi

echo "=== 停止 YARN ==="
stop-yarn.sh

echo "=== 停止 HDFS ==="
# 使用长超时时间避免 kill -9 警告
HADOOP_STOP_TIMEOUT=60 stop-dfs.sh

echo "=== 集群停止完成 ==="
