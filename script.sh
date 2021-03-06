#!/bin/bash

#Get versions from user:
echo "Insert version number or hit enter for the latest version"
echo "Insert Prometheus version:"
read prometheus
echo "Insert Node exporter version:"
read node
echo "Insert Grafana version:"
read grafana
echo "Insert Prometheus Retention in hours:"
read storageretention

#Check if user inserted a version:
if [ -z "$prometheus" ] 
  then
    prometheus="latest"
fi
if [ -z "$node" ]
  then
    node="latest"
fi  
if [ -z "$grafana" ]
  then
    grafana="latest"
fi
if [ -z "$storageretention" ]
  then
    storageretention="10"
fi

#Create docker-compose file with user versions:
echo "version: '3.3'
services:
  node-exporter:
    image: prom/node-exporter:$node
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - '9100:9100'
    network_mode: host
  prometheus:
    image: prom/prometheus:$prometheus
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=${storageretention}h'
    ports:
      - '9090:9090'
    network_mode: host
  grafana:
    image: grafana/grafana-enterprise:$grafana
    container_name: grafana
    restart: unless-stopped
    ports:
      - '3000:3000'
    network_mode: host
    depends_on:
      - prometheus
    volumes:
      - ./grafana/grafana.ini:/etc/grafana/grafana.ini" > docker-compose.yml


#Run docker compose:
docker-compose -f docker-compose.yml up -d

#Copy grafana datasource config:
docker cp grafana/data.yml grafana:/etc/grafana/provisioning/datasources/data.yml

#Copy grafana dashboard file:
docker cp grafana/node.json grafana:/etc/grafana/provisioning/dashboards/node.json

#Copy grafana dashboard config:
docker cp grafana/dashboard.yml grafana:/etc/grafana/provisioning/dashboards/dashbord.yml

#Restart grafana docker:
docker restart /grafana

echo "Setting up dockers is done please procceed to grafana at http://localhost:3000"