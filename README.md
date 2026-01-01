# BigData Cluster
基于 Docker Compose 部署大数据开发环境，集成了 Spark、Hadoop、Hive、Zookeeper、Hbase、flink、kafka。
参考 https://github.com/luochang212/bigdata-env/tree/main/share

# docker-compose编写心得
1.可以提前下载好组件及基础镜像，这样不用每次build重新拉去镜像
2.从1到N添加组件，每一个组件单独测试，方便排查问题
3.严禁所有组件都写好了再测试

# 排查镜像问题
docker run -it --rm \
  --entrypoint /bin/sh \
  big_master:v1.0

ssh免密登录方案
- 生成一套统一的 SSH 密钥对（ id_rsa , id_rsa.pub ）。
ssh-keygen -t rsa -b 2048 -f config/id_rsa -q -N ""
- 修改 Dockerfile，改为从外部 COPY 统一的密钥进去，而不是在构建时随机生成。
- 修正 ssh_config 中的主机名匹配规则。


# 启动流程
## 1.拉取基础镜像
docker pull centos:centos7.9.2009
## 2.下载安装包
./download_packages.sh  
## 3.构建镜像
### 单个镜像构建
docker build -t big_master:v1.0 -f master_dockerfile
### 多个镜像构建
docker compose build
### 4.格式化hdfs
init-hdfs.sh
### 5.启动集群
start-cluster.sh
Hive更换Tez计算引擎
https://www.cnblogs.com/convict/p/16585375.html
spark-shell --master yarn
### 6.关闭集群
stop-cluster.sh



HDFS NameNode UI : http://localhost:9870
YARN ResourceManager UI : http://localhost:8088
- Spark Master UI : http://localhost:8080
- Spark Worker UI : http://localhost:8081 (for worker1)
- YARN NodeManager UI : http://localhost:8042
- HBase Master: http://localhost:16010
- Flink Dashboard: http://localhost:8083
Zookeeper http://localhost:8089
Spark Master UI : http://localhost:18080




我已经为您编写了 Kafka 集群的配置文件 [kafka-docker-compose.yml](file:///Users/m684621/Downloads/AAA/ITGang/bigdata-cluster/kafka-docker-compose.yml)。

### 主要配置说明
1.  **3 节点集群**：`kafka1`, `kafka2`, `kafka3`。
2.  **Zookeeper 连接**：配置连接到 `master:2181,worker1:2181,worker2:2181`。
3.  **网络集成**：加入现有的 `bigdata` 网络，确保与 Hadoop/Spark/Flink 集群互通。
4.  **高可用配置**：设置了副本因子为 3 (`KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3`)。

### 如何启动
请确保主集群（master/worker）已经启动，然后执行：

```bash
docker-compose -f kafka-docker-compose.yml up -d
```

### 验证命令
启动后，您可以创建一个测试 Topic 来验证集群状态：

```bash
# 创建 Topic
docker exec kafka1 kafka-topics --create --topic test --bootstrap-server kafka1:9092 --replication-factor 3 --partitions 3

# 查看 Topic 详情
docker exec kafka1 kafka-topics --describe --topic test --bootstrap-server kafka1:9092
```

docker-compose -f thirdparty-docker-compose.yml up -d


spark-submit --master yarn --deploy-mode cluster $SPARK_HOME/examples/src/main/python/pi.py 10



docker-compose -f thirdparty-docker-compose.yml up -d

docker exec -it doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "ALTER SYSTEM ADD BACKEND 'doris-be1:9050';"
docker exec -it doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "ALTER SYSTEM ADD BACKEND 'doris-be2:9050';"
docker exec -it doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "SHOW BACKENDS;"

