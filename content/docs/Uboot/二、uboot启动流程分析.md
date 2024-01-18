---
date: '2023-11-17T22:11:57+08:00'
title:       '二、uboot启动流程分析'
description: "同大多数的Bootloader一样，uboot的启动过程也分为BL1、BL2两个阶段，分别对应着SPL和Uboot。SPL（BL1阶段）：负责开发板的基础配置和设备初始化，并且搬运Uboot到内存中，由汇编代码和少量的C语言实现.Uboot（BL2阶段）：主要负责初始化外部设备，引导Kernel启动，由纯C语言实现。"
author:      "Donge"
image:       "img/post-bg-ios9-web.jpg"
tags:
    - Uboot开发详解
categories:  ["Tech"]
weight: 2
---

# 二、uboot启动流程分析

![Uboot启动流程](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202203071811279.png)

> 上一篇文章：[（一）uboot基础了解](https://blog.csdn.net/dong__ge/article/details/122199992) 下一篇文章：[（三）Uboot驱动模型](https://blog.csdn.net/dong__ge/article/details/122637220)

同大多数的Bootloader一样，uboot的启动过程也分为BL1、BL2两个阶段，分别对应着`SPL`和`Uboot`。

**SPL（BL1阶段）**：负责开发板的基础配置和设备初始化，并且搬运Uboot到内存中，由汇编代码和少量的C语言实现

**Uboot（BL2阶段）**：主要负责初始化外部设备，引导Kernel启动，由纯C语言实现。

> 我们这篇文章，主要介绍Uboot（BL2阶段）的启动流程，BL1阶段启动流程的详细分析，可以见我的后续文章。想要深入了解的，可以好好研究下！

![img](https://i.loli.net/2021/12/02/dXOn3fe91FZQWzq.jpg)

## 2.1、程序执行流程图

我们先总体来看一下Uboot的执行步骤，这里以EMMC作为启动介质，进行分析！

无论是哪种启动介质，基本流程都相似，我们这就往下看！

![image-20220210191302537](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202202101913627.png)

**==打开图片，结合文档、图片、代码进行理解！==**

* * *

## 2.2、u-boot.lds——Uboot的入口函数

`u-boot.lds`：是uboot工程的链接脚本文件，对于工程的编译和链接有非常重要的作用，决定了uboot的组装，并且`u-boot.lds`链接文件中的`ENTRY(_start)`指定了uboot程序的入口地址。

> 如果不知道`u-boot.lds`放到在哪里，可以通过`find -name u-boot.lds`查找，根目录要进入到uboot的源码的位置哦！
>
> 如果查找结果有很多，结合自己的板子信息，确定自己使用的`u-boot.lds`。
>
> 当然，准确的方法是查看Makefile文件，分析出来`u-boot.lds`所生成的位置。

在`u-boot.lds`的文件中，可以看到`.text`段，存放的就是执行的文本段。截取部分代码段如下：

```asm
OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)
SECTIONS
{
 . = 0x00000000;				@起始地址
 . = ALIGN(4);					@四字节对齐
 .text :			
 {	
  *(.__image_copy_start)		@映像文件复制起始地址
  *(.vectors)					@异常向量表
  arch/arm/cpu/armv7/start.o (.text*)	@启动函数
 }
 ......
}
```

- `ENTRY(_start)`：程序的入口函数，`_start`在`arch/arm/lib/vectors.S`中定义`.globl _start`

- `SECTIONS`定义了段，包括`text`文本段、`data`数据段、`bss`段等。

- `__image_copy_start`在System.map和u-boot.map中均有定义

- `arch/arm/cpu/armv7/start.o`对应文件`arch/arm/cpu/armv7/start.S`，该文件中定义了`main`函数的入口。

> **Tip**：上面只进行大概分析，有汇编经验的朋友，可以详细进行分析！

![img](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202202271147055.png)

## 2.3、board\_init\_f——板级前置初始化

跟随上文的程序执行流程图，我们看`board_init_f`这个函数。其位于`common/board_f.c`。

```c
void board_init_f(ulong boot_flags)
{
    gd->flags = boot_flags;
    gd->have_console = 0;

    if (initcall_run_list(init_sequence_f))
        hang();
}

static const init_fnc_t init_sequence_f[] = {
    setup_mon_len,
    ...
    log_init,
    arch_cpu_init,		/* basic arch cpu dependent setup */
    env_init,		/* initialize environment */
    ...       
    reloc_fdt,
    reloc_bootstage,
    reloc_bloblist,
    setup_reloc,
    ...
}
```

`board_init_f()`，其最核心的内容就是调用了`init_sequence_f`初始化序列，进行了一系列初始化的工作。

主要包括：串口、定时器、设备树、DM驱动模型等，另外还包括`global_data`结构体相关对象的变量。

> 详细分析，可以看文末的参考文章\[1\]

我们需要注意的一点就是，在初始化队列末尾，执行了几个`reloc_xxx`的函数，这几个函数实现了Uboot的重定向功能。

## 2.4、relocate_code重定向

> 重定向技术，可以说也算是`Uboot`的一个重点了，也就是将`uboot`自身镜像拷贝到`ddr`上的另外一个位置的动作。

### 2.4.1 为什么需要重定向呢？

> 一般需要重定向的条件如下：

- `uboot`存储在只读存储器上，比如`ROM`、`Nor flash`，需要将代码拷贝到`DDR`上，才能完整运行`Uboot`。
- 为`Kernel`腾空间，`Kernel`一般会放在`DDR`的地段地址上，所以要把`Uboot`重定向到顶端地址，避免冲突。

### 2.4.2 Uboot是如何重定向的？

Uboot的重定向有如下几个步骤：

- 对`relocate`进行空间划分
- 计算uboot代码空间到`relocate`的位置的偏移
- `relocate`旧的`global_data`到新的`global_data`空间上
- `relocate` Uboot
- 修改`relocate`后的全局变量的`label`
- `relocate`中断向量表

**运行大致流程：**

`arch/arm/lib/crt0.S`文件内，主要实现了：

```asm
ENTRY(_main)
    bl  board_init_f
@@ 在board_init_f里面实现了
@@                             （1）对relocate进行空间规划
@@                             （2）计算uboot代码空间到relocation的位置的偏移
@@                             （3）relocate旧的global_data到新的global_data的空间上

    ldr sp, [r9, #GD_START_ADDR_SP] /* sp = gd->start_addr_sp */
    bic sp, sp, #7  /* 8-byte alignment for ABI compliance */
    ldr r9, [r9, #GD_BD]        /* r9 = gd->bd */
    sub r9, r9, #GD_SIZE        /* new GD is below bd */
@@ 把新的global_data地址放在r9寄存器中

    adr lr, here
    ldr r0, [r9, #GD_RELOC_OFF]     /* r0 = gd->reloc_off */
    add lr, lr, r0
@@ 计算返回地址在新的uboot空间中的地址。b调用函数返回之后，就跳到了新的uboot代码空间中。

    ldr r0, [r9, #GD_RELOCADDR]     /* r0 = gd->relocaddr */
@@ 把uboot的新的地址空间放到r0寄存器中，作为relocate_code的参数
    b   relocate_code
@@ 跳转到relocate_code中，在这里面实现了
@@                                       （1）relocate旧的uboot代码空间到新的空间上去
@@                                       （2）修改relocate之后全局变量的label
@@ 注意，由于上述已经把lr寄存器重定义到uboot新的代码空间中了，所以返回之后，就已经跳到了新的代码空间了！！！！！！

    bl  relocate_vectors
@@ relocate中断向量表
```

- **setup_reloc——重定向地址查看（仿真有关）**

在这里我们说明一下`board_init_f`里面的`setup_reloc`初始化函数

```c
static int setup_reloc(void)
{
    if (gd->flags & GD_FLG_SKIP_RELOC) {
        debug("Skipping relocation due to flag\n");
        return 0;
    }

#ifdef CONFIG_SYS_TEXT_BASE
#ifdef ARM
    gd->reloc_off = gd->relocaddr - (unsigned long)__image_copy_start;
#elif defined(CONFIG_M68K)
    /*
     * On all ColdFire arch cpu, monitor code starts always
     * just after the default vector table location, so at 0x400
     */
    gd->reloc_off = gd->relocaddr - (CONFIG_SYS_TEXT_BASE + 0x400);
#elif !defined(CONFIG_SANDBOX)
    gd->reloc_off = gd->relocaddr - CONFIG_SYS_TEXT_BASE;
#endif
#endif
    memcpy(gd->new_gd, (char *)gd, sizeof(gd_t));

    debug("Relocation Offset is: %08lx\n", gd->reloc_off);
    if (is_debug_open()) {
        printf("Relocating to %08lx, new gd at %08lx, sp at %08lx\n",
              gd->relocaddr, (ulong)map_to_sysmem(gd->new_gd),
              gd->start_addr_sp);
    }

    return 0;
}
```

由于，`Uboot`进行了重定向，所以按照常规的地址仿真的话，我们可能访问到错误的内存空间，通过`setup_reloc`的`Relocating to %08lx`打印，我们可以得到重定向后的地址，方便我们仿真。

`Uboot`的重定向也有相当大的一部分知识点，上面也仅仅是简单介绍了`relocate`的基本步骤和流程，后续看大家需要，如果大家想了解，我再补上这一部分。

### 2.4.3 Uboot重定向作用

**总之**，`Uboot`重定向之后，把`Uboot`整体搬运到了高端内存区，为`Kernel`的加载提供空间，避免内存践踏。

![img](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202202271147055.png)

## 2.5、board\_init\_r——板级后置初始化

> 我们接着跟着流程图往下看，重定向之后，Uboot运行于新的地址空间，接着我们执行`board_init_r`，主要作为`Uboot`运行的最后初始化步骤。

`board_init_r`这个函数，同样位于`common/board_f.c`，主要用于初始化各类外设信息

```c
void board_init_r(gd_t *new_gd, ulong dest_addr)
{	
    if (initcall_run_list(init_sequence_r))
        hang();

    /* NOTREACHED - run_main_loop() does not return */
    hang();
}
static init_fnc_t init_sequence_r[] = {
    initr_reloc,
    initr_reloc_global_data,
    board_init,	/* Setup chipselects */
    initr_dm,
    initr_mmc,
    ...
    run_main_loop
}
```

与`board_init_f`相同，同样有一个`init_sequence_r`初始化列表，包括：`initr_dm`DM模型初始化，`initr_mmc`MMC驱动初始化，等等。

最终，uboot就运行到了`run_main_loop`，进而执行`main_loop`这个函数。

## 2.6、main_loop——Uboot主循环

> 该函数为Uboot的最终执行函数，无论是加载kernel还是uboot的命令行体系，均由此实现。

```c
void main_loop(void)
{
    const char *s;

    bootstage_mark_name(BOOTSTAGE_ID_MAIN_LOOP, "main_loop");

    if (IS_ENABLED(CONFIG_VERSION_VARIABLE))
        env_set("ver", version_string);  /* set version variable */

    cli_init();

    if (IS_ENABLED(CONFIG_USE_PREBOOT))
        run_preboot_environment_command();

    if (IS_ENABLED(CONFIG_UPDATE_TFTP))
        update_tftp(0UL, NULL, NULL);

    s = bootdelay_process();
    if (cli_process_fdt(&s))
        cli_secure_boot_cmd(s);

    autoboot_command(s);

    cli_loop();
    panic("No CLI available");
}

```

`env_set`：设置环境变量，两个参数分别为`name`和`value`

`cli_init`：用于初始化hash shell的一些变量

`run_preboot_environment_command`：执行预定义的环境变量的命令

`bootdelay_process`：加载延时处理，一般用于`Uboot`启动后，有几秒的倒计时，用于进入命令行模式。

`cli_loop`：命令行模式，主要作用于`Uboot`的命令行交互。

### 2.6.1 bootdelay_process

> **记得对照文章开始的执行流程图哦！**

详细解释标注于代码中......

```c
const char *bootdelay_process(void)
{
    char *s;
    int bootdelay;

    bootcount_inc();

    s = env_get("bootdelay");								//先判断是否有bootdelay环境变量，如果没有，就使用menuconfig中配置的CONFIG_BOOTDELAY时间
    bootdelay = s ? (int)simple_strtol(s, NULL, 10) : CONFIG_BOOTDELAY;

    if (IS_ENABLED(CONFIG_OF_CONTROL))						//是否使用设备树进行配置
        bootdelay = fdtdec_get_config_int(gd->fdt_blob, "bootdelay",
                          bootdelay);

    debug("### main_loop entered: bootdelay=%d\n\n", bootdelay);

    if (IS_ENABLED(CONFIG_AUTOBOOT_MENU_SHOW))
        bootdelay = menu_show(bootdelay);
    bootretry_init_cmd_timeout();

#ifdef CONFIG_POST
    if (gd->flags & GD_FLG_POSTFAIL) {
        s = env_get("failbootcmd");
    } else
#endif /* CONFIG_POST */
    if (bootcount_error())
        s = env_get("altbootcmd");
    else
        s = env_get("bootcmd");								//获取bootcmd环境变量，用于后续的命令执行

    if (IS_ENABLED(CONFIG_OF_CONTROL))
        process_fdt_options(gd->fdt_blob);
    stored_bootdelay = bootdelay;

    return s;
}
```

### 2.6.2 autoboot_command

详细解释标注于代码中......

```c
void autoboot_command(const char *s)
{
    debug("### main_loop: bootcmd=\"%s\"\n", s ? s : "<UNDEFINED>");

    if (stored_bootdelay != -1 && s && !abortboot(stored_bootdelay)) {
        bool lock;
        int prev;

        lock = IS_ENABLED(CONFIG_AUTOBOOT_KEYED) &&
            !IS_ENABLED(CONFIG_AUTOBOOT_KEYED_CTRLC);
        if (lock)
            prev = disable_ctrlc(1); /* disable Ctrl-C checking */

        run_command_list(s, -1, 0);

        if (lock)
            disable_ctrlc(prev);	/* restore Ctrl-C checking */
    }

    if (IS_ENABLED(CONFIG_USE_AUTOBOOT_MENUKEY) &&
        menukey == AUTOBOOT_MENUKEY) {
        s = env_get("menucmd");
        if (s)
            run_command_list(s, -1, 0);
    }
}

```

我们看一下判断条件`stored_bootdelay != -1 && s && !abortboot(stored_bootdelay`

- `stored_bootdelay`：为环境变量的值，或者`menuconfig`设置的值
- `s`：为环境变量`bootcmd`的值，为后续运行的指令
- `abortboot(stored_bootdelay)`：主要用于判断是否有按键按下。如果按下，则不执行`bootcmd`命令，进入`cli_loop` 命令行模式；如果不按下，则执行`bootcmd`命令，跳转到加载Linux启动。

### 2.6.3 cli_loop

```c
void cli_loop(void)
{
    bootstage_mark(BOOTSTAGE_ID_ENTER_CLI_LOOP);
#ifdef CONFIG_HUSH_PARSER
    parse_file_outer();
    /* This point is never reached */
    for (;;);					//死循环
#elif defined(CONFIG_CMDLINE)
    cli_simple_loop();
#else
    printf("## U-Boot command line is disabled. Please enable CONFIG_CMDLINE\n");
#endif /*CONFIG_HUSH_PARSER*/
}
```

如上代码，程序只执行`parse_file_outer`来处理用户的输入、输出信息。

> 好啦，基本到这里，我们已经对Uboot的启动流程了然于胸了吧！
>
> 当然，更深层次的不建议去深入了解，有时间可以慢慢去研究。

大家有疑问，可以评论区交流......

![img](https://cdn.jsdelivr.net/gh/UNIONDONG/Get_Pic_Url/Media202202271147055.png)

**参考文章**：

\[1\]：[boadr\_init\_f介绍](https://blog.csdn.net/qq_34591581/article/details/104101598)

\[2\]：[启动流程参考](https://blog.csdn.net/ooonebook/article/details/53070065)

\[3\]：[main_loop相关](https://blog.csdn.net/monkea123/article/details/103148946)



<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
