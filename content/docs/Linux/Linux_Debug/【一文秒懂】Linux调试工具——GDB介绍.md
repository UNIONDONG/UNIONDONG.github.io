---
date: '2024-01-20T10:32:28+08:00'
title:       '【一文秒懂】Linux调试工具——GDB介绍'
description: ""
author:      "Donge"
image:       ""
tags:        ["tag1", "tag2"]
categories:  ["Tech" ]
weight: 6
---

# 【一文秒懂】Linux调试工具——GDB介绍

![GDB的吉祥物：弓箭鱼](http://c.biancheng.net/uploads/allimg/200212/1-2002122135363V.gif)

## 1、GDB是什么

`GDB：GNU Project Debugger`是`GNU`工程仿真器，允许开发者能够去看程序内部发生的情况，或者发生`crash`时候， 知道程序正在做什么！它诞生于 GNU 计划（同时诞生的还有 GCC、Emacs 等），是 Linux 下常用的程序调试器。发展至今，GDB 已经迭代了诸多个版本，当下的 GDB 支持调试多种编程语言编写的程序，包括 C、C++、Go、Objective-C、OpenCL、Ada 等。实际场景中，GDB 更常用来调试 C 和 C++ 程序。

`GDB`主要功能有四个方面：

- 启动程序：指定任何可以影响其运行行为的动作
- 停止程序：使程序在指定条件下停止
- 检查错误：当程序停止时，检查发生了什么
- 纠正错误：更改程序中的内容，纠正错误

`GDB`可以在本地、远程、仿真器上执行。

![image-20221101152802333](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20221101152802333.png)

## 2、GDB如何使用

> 如何使用GDB？

要想回答这个问题，从正统角度来分析，有两种方式：

- **GDB官方手册**：https://sourceware.org/gdb/

- **GDB帮助信息**：`help all`（命令行输入）

![image-20221101153218534](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20221101153218534.png)

简单来说，`GDB`调试方法有3种：

1.  **直接调试**：`gdb [exec file]`，用于直接仿真一个执行程序
2.  **附属调试**：`gdb attach pid`，用于直接调试一个已运行的程序（`ubuntu`注意权限问题）
3.  **核心转存调试**：`gdb [exec file] [core-dump file]`，用于调试`core-dump`文件

> **Tips**：`GDB`调试的`[exec file]`，该文件最好编译的时候带上`-g`选项，生成带调试信息的可执行文件。

## 3、GDB常用指令

### 3.1 基础指令

| 指令                                  | 含义                                  |
| ------------------------------------- | ------------------------------------- |
| **file \[exec file\]**                | 选择要调试的可执行文件                |
| **run/r**                             | 重新开始运行文件                      |
| **start**                             | 暂时断点，停在第一执行语句处          |
| **list/l**                            | 查看源代码                            |
| **next/n**                            | 单步调试，逐过程，函数直接执行        |
| **step/s**                            | 单步调试，逐语句，跳入函数执行        |
| **backtrace/bt**                      | 查看函数调用的堆栈信息                |
| **finish**                            | 结束当前函数，返回函数调用点          |
| **continue**                          | 继续执行                              |
| **print/p**                           | 打印变量                              |
| **break/b \[filename:line\_number\]** | 打断点, \[文件名:行号\]，也有多种方式 |
| **quit**                              | 退出gdb调试                           |

### 3.2 进阶指令

| 指令                             | 含义                                                         |
| -------------------------------- | ------------------------------------------------------------ |
| **frame**                        | 查看当前帧信息，包括参数，文件所在位置等                     |
| **info**                         | 该指令，可以查看到更多详细信息，如下：                       |
| **info threads**                 | 查看所有线程信息                                             |
| **info sharedlibrary**           | 查看共享库信息                                               |
| **info args**                    | 查看参数信息                                                 |
| **info breakpoints**             | 查看断点信息                                                 |
| **info frame**                   | 查看当前帧信息                                               |
| **core-file \[core-dump file\]** | 选择core-dump文件                                            |
| **watch \[expr\]**               | 观察某个表达式的值是否发生变化，如果有变化，马上停住程序。   |
| **examine/x &lt;n/f/u&gt;**      | 查看内存地址的值，addr为地址信息，  <br>n表示内存长度，f表示显示格式，u表示显示字节数 |
| **set**                          | 设置变量、寄存器、内存的值                                   |
| **signal \[number\]**            | 发送一个信号给该进程                                         |
| **disassemble**                  | 反汇编，查看当前执行时的源代码的机器码                       |

### 3.3 多线程调试

| 命令                                    | 含义                                                         |
| --------------------------------------- | ------------------------------------------------------------ |
| **info threads**                        | 查看所有线程信息                                             |
| **thread id**                           | 切换到指定线程                                               |
| **thread apply all bt**                 | 查看所有线程堆栈信息                                         |
| **set scheduler-locking off\|on\|step** | off 不锁定任何线程，也就是所有线程都执行，这是默认值。  <br>on 只有当前被调试程序会执行。  <br>step 在单步的时候，除了next过一个函数的情况以外，只有当前线程会执行。 |
| **thread apply ID1 ID2 command**        | 指定某个线程执行相关命令                                     |
| **thread apply all command**            | 指定所有线程执行相关命令                                     |

> 更多命令详细使用见参考文章

## 4、参考文章

\[1\]：https://blog.csdn.net/21cnbao/article/details/7385161

\[2\]：https://blog.csdn.net/niyaozuozuihao/article/details/91802994

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
