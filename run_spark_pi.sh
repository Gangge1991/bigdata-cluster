#!/bin/bash
echo "Running Spark Pi example on the cluster..."
docker exec -it master /opt/spark/bin/spark-submit \
  --class org.apache.spark.examples.SparkPi \
  --master spark://master:7077 \
  --deploy-mode client \
  --executor-memory 512M \
  --total-executor-cores 2 \
  /opt/spark/examples/jars/spark-examples_2.13-3.5.7.jar \
  100
