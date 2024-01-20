---
date: '2024-01-20T10:34:18+08:00'
title:       '【一文秒懂】Linux远程调试工具——gdbserver'
description: ""
author:      "Donge"
image:       ""
tags:        ["tag1", "tag2"]
categories:  ["Tech" ]
weight: 7
---

# 【一文秒懂】Linux远程调试工具——gdbserver

<img width="712" height="193" src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/7d4df75ef808461785ff957c8a8da235.gif" class="jop-noMdConv">

## 1、介绍

> 对于开发者来说，调试必不可少。
>
> 对于开发PC软件，通常系统已经继承了调试工具（比如Linux系统的GDB），或者IDE直接支持对程序的调试。
>
> 而对于开发嵌入式软件来说调试的手段比较有限，很多开发者仅有的调试手段依然是最原始的打印（我也是其中之一）。
>
> 当然除了打印调试之外还有通过`gdb+gdbserver`来调试，`gdbserver`在目标系统中运行，`gdb`则在宿主机上运行。

<span style="color: red;">**简而言之，`gdbserver` 是一个程序，它允许宿主机可以通过网络，远程调试目标板。**</span>

## 2、如何使用

### 2.1 编译器准备

> **这里就不再详细讲解编译器的安装什么的了，网上一大把！**

```bash
#直接安装
sudo apt-get install gcc-arm-linux-gnueabihf			

#源码安装
$ tar zxvf gdb-7.12.tar.gz 
$ cd gdb-7.12/
$ ./configure --target=arm-linux --prefix=$PWD/__install
$ make
$ make install
```

> 编译完成后，最终会生成`gdbserver` 的可执行程序，这个就是我们要使用的工具。

### 2.2 目标机准备

1.  我们将`gdb_server`可执行程序放置目标板上。
2.  再将我们要调试的程序放置目标板上，如`helloworld`
3.  使用`gdb_server`进行调试，使用方法如下：

![img](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/1498371-deedb3829b54d646.png)

```bash
gdbserver 192.168.xx.xx:1234 ./helloworld
```

`192.168.xx.xx`：IP地址信息

`1234`：自定义端口号

`./helloworld`：运行要仿真的程序

<span style="color: red;">**此时gdbserver监听端口号1234，并等待客户端连接。**</span>

### 2.3 宿主机准备

1.  在宿主机(Ubuntu)上，使用`gdb`调试
2.  远程连接目标机
3.  运行程序

```bash
 $ gdb
 (gdb) target remote 192.168.xx.xx:1234
 Remote debugging using :1234
 c		#运行
```

`target remote`：远程连接到指定IP的端口

`c`：全速运行

## 3、gdb_server详解

```c
gdbserver <comm> <program> [<args> ...]
```

`comm`：通信方式选择，可以是`USB`、`TCP`等多种方式

`program`：要调试的程序

```bash
gdbserver --attach <comm> <pid>
```

`pid`：是当前正在运行的进程的进程 ID。

&nbsp;

## 4、其他

**网上较为详细总结**：https://blog.csdn.net/m0_43406494/article/details/124815879

**宿主机`Ubuntu`上有时会使用到如下指令**：

`set solib-search-path external-toolchain/arm-linux-gnueabihf/libc/lib/`：设置动态库查找路径

`generate-core-file`：生成`core-dump`文件



<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
