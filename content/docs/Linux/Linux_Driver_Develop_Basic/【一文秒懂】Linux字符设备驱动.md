---
date: '2024-01-19T21:40:08+08:00'
title:       '【一文秒懂】Linux字符设备驱动'
description: ""
author:      "Donge"
image:       ""
tags:        ["Linux字符设备驱动", "Linux驱动开发基础"]
categories:  ["Tech" ]
weight: 1
---
# 【一文秒懂】Linux字符设备驱动

![image-20231123091238538](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20231123091238538.png)

# 1、前言

众所周知，`Linux`内核主要包括三种驱动模型，字符设备驱动，块设备驱动以及网络设备驱动。

其中，`Linux`字符设备驱动，可以说是`Linux`驱动开发中最常见的一种驱动模型。

我们该系列文章，主要为了帮助大家快速入门`Linux`驱动开发，该篇主要来了解一些字符设备驱动的框架和机制。

> 系列文章基于`Kernel 4.19`

&nbsp;

# 2、关键数据结构

## 2.1 cdev

```c
struct cdev {
    struct kobject kobj;
    struct module *owner;
    const struct file_operations *ops;
    struct list_head list;
    dev_t dev;
    unsigned int count;
} __randomize_layout;
```

**结构体名称**：`cdev`

**文件位置**：`include/linux/cdev.h`

**主要作用**：`cdev`可以理解为`char device`，用来抽象一个字符设备。

**核心成员及含义**：

- `kobj`：表示一个内核对象。
- `owner`：指向该模块的指针
- `ops`：指向文件操作的指针，包括`open`、`read`、`write`等操作接口
- `list`：用于将该设备加入到内核模块链表中
- `dev`：设备号，由主设备号和次设备号构成
- `count`：表示有多少个同类型设备，也间接表示设备号的范围
- `__randomize_layout`：一个编译器指令，用于随机化结构体的布局，以增加安全性。

&nbsp;

## 2.2 file\_operations

```c
struct file_operations {
    struct module *owner;
    loff_t (*llseek) (struct file *, loff_t, int);
    ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
    ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
    ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
    ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
    int (*iterate) (struct file *, struct dir_context *);
    int (*iterate_shared) (struct file *, struct dir_context *);
    __poll_t (*poll) (struct file *, struct poll_table_struct *);
    long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
    long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
    int (*mmap) (struct file *, struct vm_area_struct *);
    unsigned long mmap_supported_flags;
    int (*open) (struct inode *, struct file *);
    int (*flush) (struct file *, fl_owner_t id);
    int (*release) (struct inode *, struct file *);
    int (*fsync) (struct file *, loff_t, loff_t, int datasync);
    int (*fasync) (int, struct file *, int);
    int (*lock) (struct file *, int, struct file_lock *);
    ssize_t (*sendpage) (struct file *, struct page *, int, size_t, loff_t *, int);
    unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
    int (*check_flags)(int);
    int (*flock) (struct file *, int, struct file_lock *);
    ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
    ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
    int (*setlease)(struct file *, long, struct file_lock **, void **);
    long (*fallocate)(struct file *file, int mode, loff_t offset,
              loff_t len);
    void (*show_fdinfo)(struct seq_file *m, struct file *f);
#ifndef CONFIG_MMU
    unsigned (*mmap_capabilities)(struct file *);
#endif
    ssize_t (*copy_file_range)(struct file *, loff_t, struct file *,
            loff_t, size_t, unsigned int);
    int (*clone_file_range)(struct file *, loff_t, struct file *, loff_t,
            u64);
    int (*dedupe_file_range)(struct file *, loff_t, struct file *, loff_t,
            u64);
    int (*fadvise)(struct file *, loff_t, loff_t, int);
} __randomize_layout;

```

**结构体名称**：`file_operations`

**文件位置**：`include/linux/fs.h`

**主要作用**：正如其名，主要用来描述文件操作的各种接口，`Linux`一切接文件的思想，内核想要操作哪个文件，都需要通过这些接口来实现。

**核心成员及含义**：

- `open`：打开文件的函数
- `read`：读取文件的函数。
- `write`：写入文件的函数。
- `release`：关闭文件的函数。
- `flush`：刷新文件的函数，通常在关闭文件时调用。
- `llseek`：改变文件读写指针位置的函数。
- `fsync`：将文件数据同步写入磁盘的函数。
- `poll`：询问文件是否可被非阻塞读写

&nbsp;

## 2.3 dev\_t

```c
typedef u32 __kernel_dev_t;

typedef __kernel_dev_t		dev_t;
```

**类型名称**：`dev_t`

**文件位置**：`include/linux/types.h`

**主要作用**：表示字符设备对应的设备号，其中包括主设备号和次设备号。

&nbsp;

# 3、数据结构之间关系

![image-20231123085448145](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20231123085448145.png)

> 上图绘制是对字符设备驱动程序的数据结构以及`API`的关系图，
> 
> 有需要原始文件，可在公~号【嵌入式艺术】获取。

&nbsp;

# 4、字符设备驱动整体架构

## 4.1 加载与卸载函数

驱动首先实现的就是加载和卸载函数，也是驱动程序的入口函数。

我们一般这么定义驱动的加载卸载函数：

```c
static int __init xxx_init(void)
{

}

static void __exit xxx_exit(void)
{
    
}

module_init(xxx_init);
module_exit(xxx_exit);
```

这段代码就是实现一个通用驱动的加载与卸载，关于`module_init`和`module_exit`的实现机制，可以查看之前总结文章。

&nbsp;

## 4.2 设备号管理

### 4.2.1 设备号的概念

每一类字符设备都有一个唯一的设备号，其中设备号又分为主设备号和次设备号，那么这两个分别作用是什么呢？

- 主设备号：用于标识设备的类型，
- 次设备号：用于区分同类型的不同设备

> 简单来说，主设备号用于区分是`IIC`设备还是`SPI`设备，而次设备号用于区分`IIC`设备下，具体哪一个设备，是`MPU6050`还是`EEPROM`。

&nbsp;

### 4.2.2 设备号的分配

> 了解了设备号的概念，`Linux`中设备号有那么多，那么我们该如何去使用正确的设备号呢？

设备号的分配方式有两种，一种是动态分配，另一种是静态分配，也可以理解为一种是内核自动分配，一种是手动分配。

<span style="color: red;">**静态分配函数**</span>：

```c
int register_chrdev_region(dev_t from, unsigned count, const char *name);
```

- `from`：表示已知的一个设备号
- `count`：表示连续设备编号的个数，（同类型的设备有多少个）
- `name`：表示设备或者驱动的名称

**函数作用**：以`from`设备号开始，连续分配`count`个同类型的设备号

&nbsp;

**<span style="color: red;">动态分配函数</span>**：

```c
int alloc_chrdev_region(dev_t *dev, unsigned baseminor, unsigned count, const char *name);
```

- `dev`：设备号的指针，用于存放分配的设备号的值
- `baseminor`：次设备号开始分配的起始值
- `count`：表示连续设备编号的个数，（同类型的设备有多少个）
- `name`：表示设备或者驱动的名称

**函数作用**：从`baseminor`次设备号开始，连续分配`count`个同类型的设备号，并自动分配一个主设备号，将主、次组成的设备号信息赋值给`*dev`

&nbsp;

**<span style="color: red;">这两个函数最大的区别在于</span>**：

- `register_chrdev_region`：调用前，已预先定义好了主设备号和次设备号，调用该接口后，会将自定义的设备号登记加入子系统中，方便系统追踪系统设备号的使用情况。
- `alloc_chrdev_region`：调用前，未定义主设备号和次设备号；调用后，主设备号以`0`来表示，以自动分配，并且将自动分配的设备号，同样加入到子系统中，方便系统追踪系统设备号的使用情况。

&nbsp;

**这两个函数的共同点在于**：

系统维护了一个数组列表，用来登记所有的已使用的设备号信息，这两个接口归根到底也是将其设备号信息，登记到系统维护的设备号列表中，以免后续冲突使用。

在`Linux`中，我们可以通过`cat /proc/devices`命令，查看所有i登记的设备号列表。

&nbsp;

> 后面有时间，我们可以详细聊设备号的自动分配机制，管理机制。

&nbsp;

### 4.2.3 设备号的注销

设备号作为一种系统资源，当所对应的设备卸载时，当然也要将其所占用的设备号归还给系统，无论时静态分配，还是动态分配，最终都是调用下面函数来注销的。

```c
void unregister_chrdev_region(dev_t from, unsigned count);
```

- `from`：表示已知的一个设备号
- `count`：表示连续设备编号的个数，（同类型的设备有多少个）

**函数作用**：要注销`from`主设备号下的连续`count`个设备

&nbsp;

### 4.2.4 设备号的获取

设备号的管理很简单，在关键数据结构中，我们看到设备号的类型是`dev_t`，也就是`u32`类型表示的一个数值。

其中主设备号和次设备号的分界线，由`MINORBITS`宏定义指定：

```c
#define MINORBITS	20
```

也就是主设备号占用高`12bit`，次设备号占用低`20bit`

并且，内核还提供了相关`API`接口，来获取主设备号和次设备号，以及生成设备号的接口，如下：

```c
#define MINORMASK	((1U << MINORBITS) - 1)

#define MAJOR(dev)	((unsigned int) ((dev) >> MINORBITS))
#define MINOR(dev)	((unsigned int) ((dev) & MINORMASK))
#define MKDEV(ma,mi)	(((ma) << MINORBITS) | (mi))
```

> 以上，通过移位操作，来实现主次设备号的获取。

&nbsp;

### 4.2.4 通用代码实现

```c
#define CUSTOM_DEVICE_NUM 0
#define DEVICE_NUM 1
#device DEVICE_NAME "XXXXXX"
static dev_t global_custom_major = CUSTOM_DEVICE_NUM;

static int __init xxx_init(void)
{
    dev_t custom_device_number= MKDEV(global_custom_major, 0);	//	custom device number
    /* device number register*/
    if (global_custom_major) {
        ret = register_chrdev_region(custom_device_number, DEVICE_NUM, DEVICE_NAME);
    } else {
        ret = alloc_chrdev_region(&custom_device_number, 0, DEVICE_NUM, DEVICE_NAME);
        global_custom_major = MAJOR(custom_device_number);
    }
}

static void __exit xxx_exit(void)
{
    unregister_chrdev_region(MKDEV(global_mem_major, 0), DEVICE_NUM);
}

module_init(xxx_init);
module_exit(xxx_exit);
```

该函数实现了设备号的分配，如果主设备号为`0`，则采用动态配分的方式，否则采用静态分配的方式。

&nbsp;

> 更多干货可见：[高级工程师聚集地](https://t.zsxq.com/0eUcTOhdO)，助力大家更上一层楼！

&nbsp;

## 4.3 字符设备的管理

了解完设备号的管理之后，我们来看下字符设备是如何管理的。

### 4.3.1、字符设备初始化

```c
void cdev_init(struct cdev *cdev, const struct file_operations *fops);
```

- `cdev`：一个字符设备对象，也就是我们创建好的字符设备
- `fops`：该字符设备的文件处理接口

**函数作用**：初始化一个字符设备，并且将所对应的文件处理指针与字符设备绑定起来。

&nbsp;

### 4.3.2、字符设备注册

```c
int cdev_add(struct cdev *p, dev_t dev, unsigned count);
```

- `p`：一个字符设备指针，只想待添加的字符设备对象
- `dev`：该字符设备所负责的第一个设备编号
- `count`：该类型设备的个数

**函数作用**：添加一个字符设备驱动到`Linux`系统中。

&nbsp;

### 4.3.3、字符设备注销

```c
void cdev_del(struct cdev *p);
```

- `p`：指向字符设备对象的指针

**函数作用**：从系统中移除该字符设备驱动

&nbsp;

## 4.4 文件操作接口的实现

因为在`Linux`中，一切皆文件的思想，所以每一个字符设备，也都有一个文件节点来对应。

我们在初始化字符设备的时候，会将`struct file_operations`的对象与字符设备进行绑定，其作用是来处理该字符设备的`open`、`read`、`write`等操作。

我们要做的就是去实现我们需要的函数接口，如：

```c
static const struct file_operations global_mem_fops = {
    .owner = THIS_MODULE,
    .llseek = global_mem_llseek,
    .read = global_mem_read,
    .write = global_mem_write,
    .unlocked_ioctl = global_mem_ioctl,
    .open = global_mem_open,
    .release = global_mem_release,
};
```

至此，我们一个基本的字符设备驱动程序的框架就基本了然于胸了

&nbsp;

# 5、总结

本篇文章，旨在通俗易懂的讲解：

- 字符设备驱动相关数据结构
- 数据结构关系图
- 核心`API`接口
- 字符设备驱动整体框架

希望对大家有所帮助。


<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
