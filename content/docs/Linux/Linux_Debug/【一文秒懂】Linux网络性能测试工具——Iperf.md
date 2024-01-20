---
date: '2024-01-20T09:47:12+08:00'
title:       '【一文秒懂】Linux网络性能测试工具——Iperf'
description: ""
author:      "Donge"
image:       ""
tags:        ["Iperf", "Iperf工具", "Linux网络性能测试工具"]
categories:  ["Tech" ]
weight: 5
---

# 【一文秒懂】Linux网络性能测试工具——Iperf

**Iperf**是一个网络性能测试工具，可以测试最大`TCP`和`UDP`带宽性能，具有多种参数和UDP特性，可以根据需要调整，可以报告带宽、延迟抖动和数据包丢失。

**Iperf3**在`NLNR/DAST`开的的原始版本进行重新设计，其目标是更小、更简单的代码库，并且还提供`Iperf`所不具备的新功能，如：`nuttcp` 和`netperf`

`iperf`有`Linux,Windows,android,Mac`等版本，下面结合实际网络场景进行`iperf`工具使用的介绍

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/ac6eddc451da81cbc6990e99775d2d110924312e.jpeg)

<span style="color: red;">**确保使用`Iperf`测试的服务端和客户端都处于同一局域网内！**</span>

## 1、Iperf环境准备

**`Iperf`下载链接**：[推荐下载源码路径](https://iperf.fr/iperf-download.php#source)，[官网下载](https://iperf.fr/iperf-download.php)、[Github下载](https://github.com/esnet/iperf/releases/tag/)或者[其他地址2](https://downloads.es.net/pub/iperf/)

### 1.1 Linux源码安装Iperf

以`Ubuntu20.04`为例，下载压缩包`iperf-3.1.3.tar.gz`，解压并进入目录。

```bash
tar -zxvf iperf-3.1.3.tar.gz		#解压
cd iperf-3.1.3/						#进入解压目录
mkdir linux_install_dir				#创建安装目录
./configure	--prefix=/home/dong/WorkSpace/Program/iperf-3.1.3/linux_install_dir		#--prefix设置安装目录，即iperf3生成路径，绝对路径
make clean							#清除掉之前编译的文件，确保不影响
make								#编译
make install						#安装
```

进入`linux_install_dir/bin`安装目录，可以看到`iperf3`可执行文件。我们可以通过`readelf -h iperf3 | grep Machine`可以查看运行平台。

```bash
Machine:                           Advanced Micro Devices X86-64
```

### 1.2 Arm交叉编译Iperf

以`Arm`平台为例，解压`iperf-3.11.tar.gz`，并进入目录。

```bash
tar -zxvf iperf-3.1.3.tar.gz		#解压
cd iperf-3.1.3/						#进入解压目录
mkdir arm_install_dir				#创建安装目录

./configure --host=arm-linux-gnueabihf --prefix=/home/dong/WorkSpace/Program/iperf-3.1.3/arm_install_dir/ CFLAGS=-static# --host设置使用的编译器；	--prefix 安装目录； CFLAGS静态编译

make clean							#清除掉之前编译的文件，确保不影响
make								#编译
make install						#安装
```

进入`arm_install_dir/bin`安装目录，可以看到`iperf3`可执行文件。我们可以通过`readelf -h iperf3 | grep Machine`可以查看运行平台。

```bash
Machine:                           ARM
```

最后，将`arm_install_dir/bin`目录下的`iperf3`，拷贝到目标运行平台即可！

<span style="color: red;">**至此，`IPerf`环境搭建完毕！**</span>



## 2、指令分析

`iperf`工具是基于服务器和客户端的工作模式，通讯双方可以作为服务端和客户端进行测试。

`Iperf`与`Iperf3`命令些许有些细微的差别，下面简单介绍一下相关命令。

我们先键入`iperf3 -h`，查看命令列表

![image-20220514163159847](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202205141632015.png)

**下面对常用的命令进行分析：**

| **Server**服务端指令: |     |
| --- | --- |
| iperf -s / iperf3 -s | 启动服务，默认监听UDP，监听的默认端口为5201 |
| iperf -s -w 32M -D / iperf3 -s -D | 启动服务，-w 设置最大窗口，-D作为守护进程运行于后台 |
| iperf -i1 -u -s -p 5003 / iperf3 -s -p 5003 | 启动服务，更换监听端口为5003 |
| **Client** |     |
| iperf/iperf3 -c remotehost -i 1 -t 30 | 启动iperf客户端，remotehost为连接的IP，-i为时间间隔，-t为测试时间 |
| iperf/iperf3 -c remotehost -i 1 -t 20 -R | 功能如上，-r 为反向测试，即 remotehost -> 本机的测 |
| iperf/iperf3 -c remotehost -u -i 1 -b 200M | 启动iperf客户端，-u即测试udp，-b为最大测试带宽为200M |

- **`-d`运行双测试模式，进行上下行带宽测试**

这将使服务器端反向连接到客户端，使用-L 参数中指定的端口（或默认使用客户端连接到服务器端的端口）。

- `-P`：多线程模式，指定同时连接到服务器的数量。缺省值为1.需要客户端和服务器上的线程支持。如：`iperf -c 192.168.1.1 -P 10 -t 60`客户端同时向服务器端发起10个连接线程。
  
- `-p` ：指定服务器侦听和客户端连接的服务器端口，缺省值是5201
  
- `-w` ：设置最大窗口
  
- `-D`：作为守护进程运行于后台
  
- `-u`：使用`UDP`通信
  
- `-R`：反向测试
  
- `-i`：设置时间间隔
  
- `-t`：设置测试时间
  
- `-b`：设置最大测试带宽



## 3、Iperf测试

### 3.1 Linux平台

```
iperf3 -c 192.168.x.1 -b 200M -u -O 3 -R
```

> 说明：带宽测试通常采用UDP模式，因为能测出极限带宽、时延抖动、丢包率。在进行测试时，首先以链路理论带宽作为数据发送速率进行测试，例如，从客户端到服务器之间的链路的理论带宽为100Mbps，先用-b 100M进行测试，然后根据测试结果（包括实际带宽，时延抖动和丢包率），再以实际带宽作为数据发送速率进行测试，会发现时延抖动和丢包率比第一次好很多，重复测试几次，就能得出稳定的实际带宽

### 3.2 ARM平台

```
iperf3 -s
```

### 3.3 测试结果

```
PS F:\Develop\WIFI&BT\测试相关\测试工具\iperf-3.1.3-win64> .\iperf3.exe -c 192.168.4.234
Connecting to host 192.168.4.234, port 5201
[  4] local 192.168.4.85 port 55914 connected to 192.168.4.234 port 5201
[ ID] Interval           Transfer     Bandwidth
[  4]   0.00-1.01   sec  6.38 MBytes  53.0 Mbits/sec
[  4]   1.01-2.00   sec  5.88 MBytes  49.6 Mbits/sec
[  4]   2.00-3.01   sec  5.50 MBytes  45.6 Mbits/sec
[  4]   3.01-4.01   sec  6.00 MBytes  50.6 Mbits/sec
[  4]   4.01-5.01   sec  6.00 MBytes  50.4 Mbits/sec
[  4]   5.01-6.00   sec  6.00 MBytes  50.6 Mbits/sec
[  4]   6.00-7.01   sec  5.62 MBytes  46.7 Mbits/sec
[  4]   7.01-8.01   sec  6.25 MBytes  52.7 Mbits/sec
[  4]   8.01-9.01   sec  6.12 MBytes  51.4 Mbits/sec
[  4]   9.01-10.00  sec  6.12 MBytes  51.7 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  4]   0.00-10.00  sec  59.9 MBytes  50.2 Mbits/sec                  sender
[  4]   0.00-10.00  sec  59.9 MBytes  50.2 Mbits/sec                  receiver

iperf Done.
```



## 4、总结

1. **PC和模组确保在同一个局域网内**
2. PC运行`iperf3 -s`作为服务器，模组运行`iperf3 -c 192.168.x.x -b 200M -u -O 3` 作为客户端，测试上行带宽，看`sender`
3. 模组运行`iperf3 -s`作为服务器，PC运行`iperf3 -c 192.168.x.x -b 200M -u -O 3` 作为客户端，测试下行带宽，看`receiver`



## 5、推荐网站

\[1\]：[Iperf官网](https://iperf.fr/)

\[2\]：[Iperf-Github](https://github.com/esnet/iperf)

\[3\]：[Iperf3详细介绍](https://software.es.net/iperf/)

\[4\]：[Iperf论坛](https://fasterdata.es.net/performance-testing/network-troubleshooting-tools/iperf/)

\[5\]：[更详细的参数介绍](https://baike.baidu.com/item/iperf/11067694?fr=aladdin)

\[6\]：https://blog.csdn.net/xiaodingqq/article/details/82177327

\[7\]：https://blog.csdn.net/muaxi8/article/details/115739802

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
