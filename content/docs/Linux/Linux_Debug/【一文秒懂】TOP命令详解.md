---
date: '2024-01-17T21:37:13+08:00'
title:       '【一文秒懂】TOP命令详解'
description: ""
author:      "Donge"
image:       ""
tags:        ["Linux调试工具"]
categories:  ["Tech" ]
weight: 2
---
# 【一文秒懂】TOP命令详解

## 1、Top命令介绍

`Linux`系统中，`Top`命令主要用于**实时运行系统的监控**，包括`Linux`内核管理的进程或者线程的资源占用情况。

这个命令对所有正在运行的进程和系统负荷提供不断更新的概览信息，包括系统负载、CPU利用分布情况、内存使用、每个进程的内容使用情况等信息。

&nbsp;

## 2、Top命令使用

**`Top`的命令介绍如下**：

```bash
top -hv|-bcHiOSs -d secs -n max -u|U user -p pid -o fld -w [cols]
```

**常用的`Top`指令有**：

```bash
top：启动top命令
top -c：显示完整的命令行
top -b：以批处理模式显示程序信息
top -S：以累积模式显示程序信息
top -n 2：表示更新两次后终止更新显示
top -d 3：设置信息更新周期为3秒
top -p 139：显示进程号为139的进程信息，CPU、内存占用率等
top -n 10：显示更新十次后退出
```

除此之外，在`top`进程运行过程中，两个最重要的功能是查看帮助（`h` 或 `？`）和退出（`q` 或 `Ctrl+C`）。

&nbsp;

## 3、Top信息详解

`top`展示界面由从上到下3部分组成

1.  概览区域
2.  表头
3.  任务区域
4.  还有一个输入/消息行，位于概览区域和表头之间。

![image-20230811143742616](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230811143742616.png)

### 3.1 概览区详解

```bash
top - 14:46:08 up  5:46,  1 user,  load average: 0.00, 0.00, 0.00
```

- 程序或者窗口的名称：`top`
- 当前时间和系统的启动时间：`14:46:08 up 5:46`
- 总共的用户数量：`1 user`
- 过去1、5和15分钟的系统平均负载：`load average: 0.00, 0.00, 0.00`

```bash
Tasks: 290 total,   1 running, 212 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.1 sy,  0.0 ni, 99.9 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
```

这两行显示了任务数量和`CPU`状态

- 第一行该信息对`Task`进行分类，包括`running`、`sleeping`、`stopped`、`zombie`四类，显示了系统中正在运行的任务的状态统计信息。具体来说，这里有291个任务总数，其中有1个任务正在运行，212个任务正在睡眠，0个任务已停止，0个任务为僵尸进程。
- 第二行显示`CPU`的状态百分比
  - `%Cpu(s)`: CPU使用率的统计信息。
  - `us (user)`: 用户空间进程占用CPU的时间百分比。
  - `sy (system)`: 内核空间进程占用CPU的时间百分比。
  - `ni (nice)`: 用户进程以优先级调整过的占用CPU的时间百分比（通常不会有这个值）。
  - `id (idle)`: CPU空闲的时间百分比。
  - `wa (IO-wait)`: CPU等待I/O操作的时间百分比。
  - `hi (hardware interrupt)`: CPU处理硬件中断的时间百分比。
  - `si (software interrupt)`: CPU处理软件中断的时间百分比。
  - `st`: 被虚拟化环境偷取的时间百分比（通常不会有这个值）。

```bash
KiB Mem :  3994720 total,   525876 free,   595492 used,  2873352 buff/cache
KiB Swap:  2097148 total,  2096624 free,      524 used.  3114400 avail Mem
```

这两行表示内存的使用情况

- 第一行表示物理内存，分为`total`、 `free`、 `used` 、 `buff/cache`
- 第二行表示虚拟内存，分为`total`、`free`、`used`、`avail`

> 默认单位是`KiB`，使用按键`E`可以切换为`MiB`、`GiB`、`TiB`、`PiB`、`EiB`

```bash
KiB = kibibyte = 1024 bytes
MiB = mebibyte = 1024 KiB = 1,048,576 bytes
GiB = gibibyte = 1024 MiB = 1,073,741,824 bytes
TiB = tebibyte = 1024 GiB = 1,099,511,627,776 bytes
PiB = pebibyte = 1024 TiB = 1,125,899,906,842,624 bytes
EiB = exbibyte = 1024 PiB = 1,152,921,504,606,846,976 bytes
```

&nbsp;

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp;

### 3.2 任务区

任务区是按照列的形式来显示的，并且有多个字段可以用来查看进程的状态信息。

#### 3.2.1 任务字段介绍

- `%CPU`： `CPU Usage`，自上次屏幕更新以来任务占用的CPU时间份额，表示为总CPU时间的百分比。

- `%MEM`： `Memory Usage`，进程使用的物理内存百分比

- `CODE`：`Code Size`，可执行代码占用的物理内存量

- `COMMAND`：`Command Name or Command Line`，用于显示输入的命令行或者程序名称

- `PID`：`Process Id`，任务独立的`ID`，即进程`ID`

- `PPID`：`Parent Process Id`，父进程`ID`

- `UID`：`User Id`，任务所有者的用户`ID`

- `USER`：`User Name`，用户名

- `RUSER`：`Real User Name`，实际的用户名

- `TTY`：`Controlling Tty`，控制终端名称

- `TIME`：`CPU TIME`，该任务`CPU`总共运行的时间

- `TIME+`：同`TIME`，其粒度更细

- `OOMa`：`Out of Memory Adjustment Factor`，内存溢出调整机制，这个字段会被增加到当前内存溢出分数中，来决定什么任务会被杀掉，范围是-1000到+1000。

- `OOMs`：`Out of Memory Score`，内存溢出分数，这个字段是用来选择当内存耗尽时杀掉的任务，范围是0到+1000。0的意思是绝不杀掉，1000的意思是总是杀掉。

- `S`：`Process Status`，表示进程状态信息

  - `D`： 不可中断休眠
  - `I`：空闲
  - `R`：运行中
  - `S`：休眠
  - `T`：被任务控制信号停止
  - `t`：在跟踪期间被调试器停止
  - `Z`：僵尸

> 相关属性有很多，可以使用`man top`查看，这里先列举这些。

&nbsp;

#### 3.2.2 字段管理

我们输入`top`后，默认只显示一部分属性信息，我们可以自行管理想要的属性信息。

我们输入`F`或者`f`，进入字段管理功能，用于选择想要的字段信息

| 按键         | 功能                                            |
| ------------ | ----------------------------------------------- |
| `↑`、`↓`     | 光标上下移动选择                                |
| `空格`、`d`  | 切换                                            |
| `s`          | 设置为排序依据字段                              |
| `a`、`w`     | 在4种窗口中切换：1.默认，2.任务，3.内存，4.用户 |
| `Esc键`、`q` | 退出当前窗口                                    |

&nbsp;

## 4、交互命令详解

`top`的功能很多，基本能够查看进程的各种状态信息，其中还有一些交互式的命令，方便我们更好的查看系统状态。

> 在`top`主界面中，我们输入下面的命令

| 命令           | 功能                                                         |
| -------------- | ------------------------------------------------------------ |
| `h`、`?`       | 帮助信息查看，涵盖所有的快捷键                               |
| 空格、回车按键 | 手动刷新界面信息                                             |
| `q`、`ESC`按键 | 退出                                                         |
| `B`            | 粗体显示功能                                                 |
| `d`、`s`       | 改变间隔时间                                                 |
| `E`、`e`       | 切换内存显示的单位，从`KiB`到`EiB`                           |
| `g`            | 然后输入`1-4`其中一个数字，选择哪种窗口（1.默认，2.任务，3.内存，4.用户） |
| `H`            | 进程、线程显示切换                                           |
| `k`            | 输入`PID`信息，杀掉一个任务                                  |
| `Z`            | 改变配色                                                     |

> 上面介绍了一些比较常见的交互式命令，还有更多需要你去探索哦！


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/Embeded_Art.gif" alt="img" width = "60%" height ="10%"/>
</div>
