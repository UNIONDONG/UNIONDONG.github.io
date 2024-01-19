---
date: '2024-01-19T21:23:10+08:00'
title:       '【一文秒懂】Linux内核调试工具——devmem'
description: ""
author:      "Donge"
image:       ""
tags:        ["Linux调试工具"]
categories:  ["Tech" ]
weight: 4
---

# 【一文秒懂】Linux内核调试工具——devmem

<img width="962" height="176" src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/93fe500adc7d40c6bf134e9d9af12b0f.gif" class="jop-noMdConv">

## 1、介绍

我们在底层开发过程中，经常需要<span style="color: blue;">**在终端查看或者修改设备寄存器的值**</span>，有这样一个工具----`devmem`，可用于读取或者修改物理寄存器的值，非常方便！

<span style="color: red;">**简而言之，`devmem`就是在`Linux`命令行模式下，直接操作我们设备寄存器的值！**</span>

## 2、如何使用

### 2.1 配置devmem

![image-20220811174204310](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20220811174204310.png)

**进入`menuconfig`选项中，按下`/`搜索关键词即可！**

### 2.2、使用devmem

> 进入`Linux`后，输入`devmem -h`查看帮助信息即可！

```bash
Usage: devmem ADDRESS [WIDTH [VALUE]]
Read/write from physical address
        ADDRESS Address to act upon
        WIDTH   Width (8/16/...)
        VALUE   Data to be written
```

`[]`内部为可选内容，比较简单，这里直接上使用代码！

- **读物理内存**

```bash
devmem 0x10000000			#读指定的物理内存值
devmem 0x10000000 16		#读16bit物理内存的值
```

- **写物理内存**

```bash
devmem 0x10000000 32 0x00000000		#以32bit写入给定的值到指定物理内存
devmem 0x10000000 8 0x010			#以8bit写入给定的值到指定物理内存
```

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
