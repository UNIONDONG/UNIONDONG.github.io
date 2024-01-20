---
date: '2024-01-20T10:39:03+08:00'
title:       '【一文秒懂】Linux内核态内存泄露检测工具'
description: ""
author:      "Donge"
image:       ""
tags:        ["tag1", "tag2"]
categories:  ["Tech" ]
weight: 11
---

# 【一文秒懂】Linux内核态内存泄露检测工具

## 1、Kmemleak介绍

在`Linux`内核开发中，`Kmemleak`是一种用于**检测内核中内存泄漏的工具**。

> **内存泄漏**指的是程序中已经不再使用的内存没有被妥善地释放，导致内存的浪费。内核中的内存泄漏同样会导致系统性能下降、系统崩溃等问题。

`Kmemleak`能够检测内核中的内存泄漏，通过检测内核中未被释放但又无法找到其使用位置的内存，进一步定位、修复内存泄漏的问题。

> 在用户空间，我们常用`Valgrind`来检测；
>
> 在内核空间，我们常用`Kmemleak`来检测。

&nbsp;

## 2、如何使用Kmemleak

### 2.1 内核配置

**内核打开相应配置**：

- `CONFIG_DEBUG_KMEMLEAK`：`Kmemleak`被加入到内核
- `CONFIG_DEBUG_KMEMLEAK_EARLY_LOG_SIZE`设置为`16000`：该参数为记录内存泄露信息的内存池，越大记录信息越多。
- `CONFIG_DEBUG_KMEMLEAK_DEFAULT_OFF` ：`Kmemleak`默认开关状态

**依赖的配置**：

- `CONFIG_DEBUG_KERNEL`：打开内核调试功能
- `CONFIG_DEBUG_FS`：需要借助到`debugfs`
- `CONFIG_STACKTRACE`：记录进程的堆栈信息

&nbsp;

### 2.2 用户空间配置

我们要想使用`Kmemleak`，需要挂在`debugfs`，来查看泄露的情况。

- **进入文件系统后，进行挂载**：

```bash
mount -t debugfs nodev /sys/kernel/debug/			#	挂在debugfs
```

- **设置扫描时间**：

```bash
echo scan=10 > /sys/kernel/debug/kmemleak			#	10S扫描一次
```

> 默认内存泄露检测时间为`10min`，上面设置为`10s`一次

- **查看泄露情况**：

```bash
cat /sys/kernel/debug/kmemleak						#	查看内存泄露情况
```

- **其他指令**：

```bash
echo scan > /sys/kernel/debug/kmemleak		#触发一次扫描
echo clear > /sys/kernel/debug/kmemleak     #清除当前 kmemleak 记录的泄露信息
echo off > /sys/kernel/debug/kmemleak       #关闭kmemleak（不可逆转的）
echo stack=off > /sys/kernel/debug/kmemleak #关闭任务栈扫描
echo stack=on > /sys/kernel/debug/kmemleak  #使能任务栈扫描
echo scan=on > /sys/kernel/debug/kmemleak   #启动自动内存扫描线程
echo scan=off > /sys/kernel/debug/kmemleak  #停止自动内存扫描线程
echo scan=<secs> > /sys/kernel/debug/kmemleak#设置自动扫描线程扫描间隔，默认是600，设置0则是停止扫描
echo dump=<addr> > /sys/kernel/debug/kmemleak #dump某个地址的内存块信息，比如上面的echo dump=0xffffffc008efd200 > /sys/kernel/debug/kmemleak即可查看详细信息
```

&nbsp;

### 2.3 通过Linux启动参数控制开关

`Kmemleak`的默认开关状态可以通过`CONFIG_DEBUG_KMEMLEAK_DEFAULT_OFF` 配置来控制，当然也可以通过向`Linux`内核启动参数中加入`kmemleak=off`来控制。

&nbsp;

## 3、Kmemleak原理

`Kmemleak`提供了一种跟踪垃圾回收器[tracing garbage collector](https://en.wikipedia.org/wiki/Tracing_garbage_collection)的原理，来检测内核中存在的内存泄露，其不同之处在于：孤立的对象并没有被释放掉，而是通过`/sys/kernel/debug/kmemleak`仅仅被报告。

> 这种方法同样应用于`Valgrind`中，不过该工具主要用于检测用户空间不同应用的内存泄露情况。
>
> 在用户空间，我们常用`Valgrind`来检测应用进程；
>
> 在内核空间，我们常用`Kmemleak`来检测内核代码。

通过`kmalloc()`、`vmalloc（）`、`kmem_cache_alloc()`等函数分配内存时，会跟踪指针，堆栈等信息，将其存储在一个红黑树中。

同时跟踪相应的释放函数调用，并从`kmemleak`数据结构中删除指针。

> **简单理解**：相当于追踪内存分配相关接口，记录分配内存的首地址，堆栈大小等信息，在内存释放阶段将其删除。

我们通过查看相关内核文档可知，内存泄露检测的扫描算法步骤如下：

- 将所有对象标记为白色（最后剩余的白色对象将被视为孤立对象）
- 从数据段和堆栈开始扫描内存，根据红黑树中存储的地址信息来检查值，如果找到指向白色对象的指针，则添加到灰色列表
- 扫描灰色列表以查找地址匹配的对象，直到灰色列表完成
- 剩下的白色对象被视为孤立对象，并通过/sys/kernel/debug/kmemleak进行报告

&nbsp;

## 4、Kmemleak API接口

```c
kmemleak_init - 初始化 kmemleak
kmemleak_alloc - 内存块分配通知
kmemleak_alloc_percpu - 通知 percpu 内存块分配
kmemleak_vmalloc - 通知 vmalloc() 内存分配
kmemleak_free - 通知内存块释放
kmemleak_free_part - 通知释放部分内存块
kmemleak_free_percpu - 通知 percpu 内存块释放
kmemleak_update_trace - 更新对象分配堆栈跟踪
kmemleak_not_leak - 将对象标记为非泄漏
kmemleak_ignore - 不扫描或报告对象泄漏
kmemleak_scan_area - 在内存块内添加扫描区域
kmemleak_no_scan - 不扫描内存块
kmemleak_erase - 擦除指针变量中的旧值
kmemleak_alloc_recursive - 作为kmemleak_alloc，但检查递归性
kmemleak_free_recursive - 作为kmemleak_free，但检查递归性
```

&nbsp;

## 5、Kmemleak特殊情况

- **漏报**：真正内存泄露了，但是未报告，因为在内存扫描期间找到的值指向此类对象。为了减少误报的数量，`kmemleak`提供了`kmemleak_ignore`，`kmemleak_scan_area`，`kmemleak_no_scan`和`kmemleak_erase`功能

- **误报**：实际没有泄露，但是却错误的报告了内存泄露。`kmemleak`提供了`kmemleak_not_leak`功能。

&nbsp;

## 6、Kmemleak验证

内核也提供了一个示例：`kmemleak-test`模块，该模块用以判断是否打开了`Kmemleak`功能。通过配置`CONFIG_DEBUG_KMEMLEAK_TEST`选项可以选择。

```bash
# modprobe kmemleak-test
# echo scan > /sys/kernel/debug/kmemleak
```

```bash
# cat /sys/kernel/debug/kmemleak
unreferenced object 0xffff89862ca702e8 (size 32):
  comm "modprobe", pid 2088, jiffies 4294680594 (age 375.486s)
  hex dump (first 32 bytes):
    6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b  kkkkkkkkkkkkkkkk
    6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b 6b a5  kkkkkkkkkkkkkkk.
  backtrace:
    [<00000000e0a73ec7>] 0xffffffffc01d2036
    [<000000000c5d2a46>] do_one_initcall+0x41/0x1df
    [<0000000046db7e0a>] do_init_module+0x55/0x200
    [<00000000542b9814>] load_module+0x203c/0x2480
    [<00000000c2850256>] __do_sys_finit_module+0xba/0xe0
    [<000000006564e7ef>] do_syscall_64+0x43/0x110
    [<000000007c873fa6>] entry_SYSCALL_64_after_hwframe+0x44/0xa9
...
```

&nbsp;

## 7、参考文章

- **内核官方文档**：https://www.kernel.org/doc/html/latest/dev-tools/kmemleak.html
- **其他文章推荐**：https://blog.csdn.net/weixin_41944449/article/details/123441820

&nbsp;



<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
