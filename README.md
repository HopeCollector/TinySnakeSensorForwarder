# 🐍Tiny Snake Sensor Forwarder

## 项目简介

本项目为微型生命探测机器人项目的子项目，目的在于驱动传感器并将其通过网络打包发送会远程地面站。项目设计的机器人外观为蛇型机器人，蛇头位置配备摄像头、激光雷达、IMU三种传感器设备。

通信的总体架构为发布者-订阅者架构，机器人为发布者，采集数据后进行发布，地面站是订阅者，负责接收消息。由于项目整体限制传输带宽，因此本项目除 IMU 之外的所有数据都进行了压缩处理。点云进行了一定比例的降采样，视频进行 h264 编码。

机器人使用的开发板型号为 **RaspberryPi Zero 2W**，使用基于 aarch64(armv8) Debian12(bookwarm) 的树莓派定制操作系统

## 项目文件说明

- `.devcontainer`: 用于存放基于 vscode 的容器开发配置
  - `pub`: publisher 容器配置，实际部署在机器人的开发板上
  - `sub`: subscriber 容器配置，实际部署在地面站上
- `cache`: 用于开容器的构造结果，请勿手动更改内部文件内容
- `data`: 存放测试数据
- `docker`: 存放镜像配置文件，每个镜像都有三个阶段。base 阶段安装依赖，overlay 阶段编译项目代码，dev 阶段配置开发环境
  - `publisher.Dockerfile`: 为 publisher 配置的镜像
  - `subscriber.Dockerfile`: 为 subscriber 设计的镜像
- `projs`: 存放项目代码
  - `publisher`: 发布者代码，部署在机器人上
  - `subscriber`: 订阅者代码
- `docker-compose.yml`: 服务配置文件

## 项目打包方法

使用下面的指令对项目进行打包

```shell
export projdir=$(basename $(pwd)) \
&& cd .. \
&& tar czfv tinysk-neo-air.tar.gz \
    --exclude=cache/publisher/* \
    --exclude=cache/subscriber/build/* \
    --exclude=cache/subscriber/devel/* \
    --exclude=projs/publisher/.vscode \
    --exclude=projs/publisher/.devcontainer \
    --exclude=projs/publisher/build \
     $projdir \
&& cd $projdir \
&& mv ../tinysk-neo-air.tar.gz . \
&& unset projdir
```
