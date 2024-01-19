---
date: '2024-01-19T21:45:04+08:00'
title:       '【一文秒懂】为什么Linux内核中不经常使用typedef'
description: ""
author:      "Donge"
image:       ""
tags:        ["typedef", "Linux驱动开发基础"]
categories:  ["Tech" ]
weight: 3
---

# 为什么 Linux 内核中不经常使用 typedef？

![为什么 Linux 内核中不经常使用 typedef_new](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/%E4%B8%BA%E4%BB%80%E4%B9%88%20Linux%20%E5%86%85%E6%A0%B8%E4%B8%AD%E4%B8%8D%E7%BB%8F%E5%B8%B8%E4%BD%BF%E7%94%A8%20typedef_new.png)

&nbsp;

我们在进行`Linux`驱动开发过程中，有没有出现过这样的报错？

```bash
WARNING: do not add new typedefs
```

不允许使用`typedef`！

虽然只是一个警告，但是如果你想往开源仓库提交代码，这就是一个必优化项。

那么，为什么`Linux`内核不建议使用`typedef`呢？

&nbsp;

## 1、Linus Torvalds 的态度

![img](https://e0.ifengimg.com/04/2019/0601/1395346C9EA500C3E71BFAE601E0940B868EF5BB_size63_w1080_h663.jpeg)

&nbsp;

> *> On Mon, 10 Jun 2002, Linus Torvalds wrote:*
> *>*
> *> --snip/snip*
> *> > But in the end, maintainership matters. I personally don't want the*
> *> > typedef culture to get the upper hand, but I don't mind a few of them, and*
> *> > people who maintain their own code usually get the last word.*
>
> *>*
> *> to sum it up:*
> *>*
> *> using the "struct mystruct" is _recommended_, but not a must.*

`Torvalds `本人不太想看到`typedef`文化占上风，但是维护自己代码的人通常有最后的发言权。

- `Torvalds `还是比较推荐使用`struct mystruct`的结构
- **不易理解**：使用`typedef`类型，不容易去理解变量的实际类型是什么样子的
- **不好维护**：由于`Linux`内核架构的庞大，不同架构之间定义的`typedef`类型可能并不具有通用性。

`Torvalds `原文详见：https://lkml.indiana.edu/hypermail/linux/kernel/0206.1/0402.html

&nbsp;

## 2、内核编码规范

![img](https://img.linux.net.cn/data/attachment/album/201403/19/233615dnal0bpykvuy0sab.jpg)

> 从内核编码规范的角度，来看`typedef`

内核编码规范给出了`typedef`使用的一些场合：

- 完全不透明的对象：隐藏内部对象
- 明确的整数类型：抽象有助于避免混淆是int型还是long型，如`u8/u16/u32`
- 在某些特殊情况下，与标准`C99`类型相同的新类型。
- 可在用户空间中使用的类型

内核编码规范详见：https://www.kernel.org/doc/html/v4.10/process/coding-style.html

&nbsp;

## 3、个人看法

个人感觉，从大型项目的开发维护上来说，`typedef`不建议使用，避免造成类型泛滥，也更加不容易理解。

对于个人开发的小项目，`typedef`可以完全看自己心情，毕竟`typedef`褒贬不一。

&nbsp;

下面分享一些社区讨论帖子：

- 为什么我们要在`C`语言中频繁使用`typedef`：https://stackoverflow.com/questions/252780/why-should-we-typedef-a-struct-so-often-in-c
- 为什么`Linux`编码锋哥不建议使用`typedef`：https://www.reddit.com/r/C_Programming/comments/dan8vr/why_does_the_linux_kernel_coding_style_guide/?rdt=36702

&nbsp;


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
