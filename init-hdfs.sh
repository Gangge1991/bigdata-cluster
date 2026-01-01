#!/bin/bash

# HDFS 初始化脚本
# 用于首次启动前的 NameNode 格式化和基础目录创建

set -e


ensure_hosts_entry() {
    local host="$1"
    local ip=""
    local tmp_hosts="/tmp/hosts.$$"

    if command -v getent >/dev/null 2>&1; then
        ip="$(getent hosts "$host" | awk '{print $1}' | head -n 1)"
    fi

    if [ -z "$ip" ] && command -v ping >/dev/null 2>&1; then
        ip="$(ping -c 1 -W 1 "$host" 2>/dev/null | awk -F'[()]' '/PING/{print $2}' | head -n 1)"
    fi

    if [ -z "$ip" ]; then
        echo "警告: 无法解析 $host 的 IP，跳过写入 /etc/hosts"
        return 0
    fi

    if [ -f /etc/hosts ]; then
        grep -vE "[[:space:]]$host([[:space:]]|$)" /etc/hosts > "$tmp_hosts" || true
    else
        : > "$tmp_hosts"
    fi
    echo "$ip $host" >> "$tmp_hosts"
    cat "$tmp_hosts" > /etc/hosts
    rm -f "$tmp_hosts"
}

ensure_hosts_entry master
ensure_hosts_entry worker1
ensure_hosts_entry worker2

sync_hosts_to_node() {
    local node="$1"
    local max_retries=20
    local i=1

    while [ $i -le $max_retries ]; do
        if ssh -o ConnectTimeout=2 "$node" true >/dev/null 2>&1; then
            if scp -q /etc/hosts "$node":/etc/hosts >/dev/null 2>&1; then
                return 0
            fi
            if ssh -o ConnectTimeout=2 "$node" "cat > /etc/hosts" < /etc/hosts >/dev/null 2>&1; then
                return 0
            fi
        fi
        i=$((i + 1))
        sleep 1
    done

    echo "警告: /etc/hosts 同步到 $node 失败，继续执行后续步骤"
    return 0
}

sync_hosts_to_node worker1
sync_hosts_to_node worker2

# 1. 确定 Hadoop 路径
if [ -z "$HADOOP_HOME" ]; then
    if [ -d "/opt/hadoop" ]; then
        export HADOOP_HOME="/opt/hadoop"
    elif [ -d "/opt/hadoop" ]; then
        export HADOOP_HOME="/opt/hadoop"
    else
        echo "错误: 未找到 Hadoop 安装路径，请设置 HADOOP_HOME"
        exit 1
    fi
fi

export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
# export HADOOP_STOP_TIMEOUT="${HADOOP_STOP_TIMEOUT:-30}"
# 强制覆盖 HADOOP_STOP_TIMEOUT，确保生效
HADOOP_STOP_TIMEOUT=60
export HADOOP_STOP_TIMEOUT


NAMENODE_DIR="/root/hdfs/namenode"

echo "=== 开始 HDFS 初始化 ==="
echo "HADOOP_HOME: $HADOOP_HOME"

# 2. 检查并格式化 NameNode
if [ -f "$NAMENODE_DIR/current/VERSION" ]; then
    echo "警告: NameNode 目录 ($NAMENODE_DIR) 似乎已经格式化过。"
    echo "跳过格式化步骤。"
else
    echo "NameNode 未格式化，正在执行格式化..."
    # 确保父目录存在
    mkdir -p "$NAMENODE_DIR"
    
    # 格式化
    hdfs namenode -format -nonInteractive
    
    if [ $? -eq 0 ]; then
        echo "NameNode 格式化成功。"
    else
        echo "错误: NameNode 格式化失败。"
        exit 1
    fi
fi

# 3. 启动 HDFS (为了创建目录)
echo "正在启动 HDFS 以创建基础目录..."
if start-dfs.sh; then
    echo "HDFS 启动成功。"
else
    echo "错误: HDFS 启动失败。"
    exit 1
fi

# 等待安全模式结束
echo "等待 NameNode 退出安全模式..."
hdfs dfsadmin -safemode wait


sleep 10
# 等待 DataNode 注册
# echo "等待 DataNode 注册 (最长等待 120 秒)..."
# for i in {1..60}; do
#     live_datanodes=$(hdfs dfsadmin -report | grep "Live datanodes" | awk -F': ' '{print $2}' | awk -F' ' '{print $1}')
#     if [[ "$live_datanodes" -ge 1 ]]; then
#         echo "检测到 $live_datanodes 个活跃 DataNode，继续..."
#         break
#     fi
#     echo "当前活跃 DataNode: ${live_datanodes:-0}，等待中... ($i/60)"
#     sleep 2
# done

# 4. 创建基础目录
echo "正在创建 HDFS 目录结构..."

# 创建 /tmp (所有用户可写)
hdfs dfs -mkdir -p /tmp
hdfs dfs -chmod 777 /tmp
echo "已创建: /tmp (权限 777)"

# 创建 Hive 仓库目录
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod 777 /user/hive/warehouse
echo "已创建: /user/hive/warehouse (权限 777)"

# 创建 Spark 日志目录
hdfs dfs -mkdir -p /spark-logs
hdfs dfs -chmod 777 /spark-logs
echo "已创建: /spark-logs (权限 777)"

# 创建 Tez 目录并上传包
hdfs dfs -mkdir -p /apps/tez
hdfs dfs -put /opt/tez/tez.tar.gz /apps/tez/
hdfs dfs -chmod -R 755 /apps/tez
echo "已上传 Tez 包到 /apps/tez"

# 创建 Spark Jars 目录并上传归档文件
echo "正在创建 Spark Jars 归档文件..."
jar cv0f /opt/spark/spark-jars.zip -C /opt/spark/jars/ .
hdfs dfs -mkdir -p /apps/spark
hdfs dfs -put /opt/spark/spark-jars.zip /apps/spark/
hdfs dfs -chmod -R 755 /apps/spark
echo "已上传 Spark Jars 归档到 /apps/spark"

# 创建用户目录
hdfs dfs -mkdir -p /user/root
echo "已创建: /user/root"

# 5. 初始化 Hive Metastore Schema
echo "=== 初始化 Hive Metastore Schema ==="
if schematool -dbType mysql -info >/dev/null 2>&1; then
    echo "Hive Metastore Schema 似乎已经初始化。"
else
    echo "正在初始化 Hive Metastore Schema..."
    schematool -dbType mysql -initSchema
    if [ $? -eq 0 ]; then
        echo "Hive Metastore Schema 初始化成功。"
    else
        echo "警告: Hive Metastore Schema 初始化失败，请检查 MySQL 连接或配置。"
        # 这里不退出，因为可能是重复初始化报错
    fi
fi

# 6. 停止 HDFS
echo "初始化操作完成，正在停止 HDFS..."
# 显式传递超时时间给 stop-dfs.sh
HADOOP_STOP_TIMEOUT=60 stop-dfs.sh

echo "=== HDFS 初始化脚本执行完毕 ==="
