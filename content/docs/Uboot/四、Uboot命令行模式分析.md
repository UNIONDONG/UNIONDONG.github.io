---
date: '2024-01-17T21:31:50+08:00'
title:       '四、Uboot命令行模式分析'
description: ""
author:      "Donge"
image:       ""
tags:        ["Uboot开发详解"]
categories:  ["Tech" ]
weight: 4
---

# 四、Uboot命令行模式分析

![四、Uboot命令行模式分析](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205312213482.png)


> 前几篇文章，我们也了解了`Uboot`的启动流程，那么这节就主要讲讲`Uboot`的命令行模式。
>
> **另外，文章末尾还提供`eMMC5.1官方标准协议.pdf`和`eMMC4.51官方标准协议-中文.pdf`下载渠道，方便深入了解底层协议。**
>
> **正文如下**：

&nbsp;

## 4.1 如何进入命令行模式

我们正常启动流程，默认是直接跳过`Uboot`命令行模式的，因为`Uboot`主要的作用是引导`Kernel`，一般我们不进行`uboot`开发时，都默认跳过进入命令行模式。

&nbsp;

<font color = "red">**那么，我们要想进入Uboot命令行模式，需要进行哪些配置呢？**</font>

> 打开我们准备好一份Uboot源码，进入menuconfig配置菜单，主要设置下列几个配置信息！

- `CONFIG_CMDLINE`：命令行模式开关
- `CONFIG_SYS_PROMPT`：命令行模式提示符
- `CONFIG_HUSH_PARSER`：使用hush shell 来对命令进行解析
- `BOOTDELAY`：设置启动延时

> **Tip**：`meneconfig`中查找苦难？实时`/`符号，输入`1或2或3`，直接查找指定标识。

&nbsp;

![image-20220531165504571](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311655629.png)

&nbsp;

打开之后，重新编译，并将`Uboot`镜像烧录到开发板中，再次启动，我们就能够看到倒计时。

```bash
[2022-03-02:13:33:47]U-Boot 2020.10-rc1-00043-ge62a6d17c6-dirty (Feb 08 2022 - 10:14:14 +0800)
[2022-03-02:13:33:47]
[2022-03-02:13:33:47]Model: xxxxxx
[2022-03-02:13:33:47]MMC:   mmc1@xxxxxx: 1
[2022-03-02:13:33:47]In:    serial
[2022-03-02:13:33:47]Out:   serial
[2022-03-02:13:33:47]Err:   serial
[2022-03-02:13:33:47]Model: xxxxxx
[2022-03-02:13:33:49]Hit any key to stop autoboot:  2 
```

`Hit any key to stop autoboot`：我们在倒计时结束前，任意键入一个按键，即可进入！

&nbsp;

## 4.2 `Uboot`基本命令解析

进入`Uboot`命令行模式后，键入`help`或者`?`，可以查看所有支持的`Uboot`命令。

![image-20220531170218298](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311702352.png)

**注意**：`Uboot`支持的命令大都远远超过显示的，还有好多没有打开，可以在`menuconfig`中，打开相应的功能，如`mmc`相关的，`md`内存相关的。

&nbsp;

<font color = "red">**常用命令如下**</font>：

```bash
version				#查看uboot版本
reset 				#重启Uboot

printenv			#打印uboot环境变量
setenv name value	#设置环境变量


md addr				#查看内存指令
nm addr				#修改内存值
mm addr				#自增修改内存值

mmc dev id			#选择mmc卡
mmc rescan			#扫描卡

echo $name			#打印环境变量
```

> 更多指令使用，可以见文末整理的文档

&nbsp;

## 4.3 命令行模式代码执行流程分析

> 结合下面的程序执行流程图，代码，一起分析。

![image-20220531170831165](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311708227.png)

上图为`Uboot`命令行模式的代码具体执行流程，结合  **[专栏系列（二）uboot启动流程分析](https://blog.csdn.net/dong__ge/article/details/123336063?spm=1001.2014.3001.5502#t9)**，文章内已经详细分析函数内部实现。

&nbsp;

```c
static int abortboot(int bootdelay)
{
	int abort = 0;

	if (bootdelay >= 0) {
		if (IS_ENABLED(CONFIG_AUTOBOOT_KEYED))
			abort = abortboot_key_sequence(bootdelay);
		else
			abort = abortboot_single_key(bootdelay);				//按键检测
	}

	if (IS_ENABLED(CONFIG_SILENT_CONSOLE) && abort)
		gd->flags &= ~GD_FLG_SILENT;

	return abort;
}


static int abortboot_single_key(int bootdelay)
{
	int abort = 0;
	unsigned long ts;

	printf("Hit any key to stop autoboot: %2d ", bootdelay);			//打印倒计时

	/*
	 * Check if key already pressed
	 */
	if (tstc()) {	/* we got a key press	*/							//获取按键
		(void) getc();  /* consume input	*/
		puts("\b\b\b 0");
		abort = 1;	/* don't auto boot	*/
	}

	while ((bootdelay > 0) && (!abort)) {
		--bootdelay;
		/* delay 1000 ms */
		ts = get_timer(0);
		do {
			if (tstc()) {	/* we got a key press	*/					//获取按键
				int key;

				abort  = 1;	/* don't auto boot	*/
				bootdelay = 0;	/* no more delay	*/
				key = getc(); /* consume input	*/
				if (IS_ENABLED(CONFIG_USE_AUTOBOOT_MENUKEY))
					menukey = key;
				break;
			}
			udelay(10000);
		} while (!abort && get_timer(ts) < 1000);						//延时1S

		printf("\b\b\b%2d ", bootdelay);
	}

	putc('\n');

	return abort;
}

```

`abortboot_single_key`：该函数主要用于`while`循环检测按键，如果有按键按下，将`abort`标志位置1，最后运行`cli_loop`命令行模式的函数。

如果按键不按下，标志位`abort`不起作用，直接运行`run_command_list(s, -1, 0);`，`s = env_get("bootcmd");`，直接跳转到我们设置的环境变量`bootcmd`所设定的指令，而不执行`cli_loop`函数。

> 对照运行流程图看代码，容易理解！！！

&nbsp;

## 4.4 如何添加Uboot命令

<font color = "red">**如何自定义一个`Uboot`命令呢？**</font>

我们暂且先不考虑实现的原理，就仅仅照葫芦画瓢来实现一个简单的`Uboot`命令！

&nbsp;

### 第一步：照葫芦

我们打开`Uboot`的源码文件，进入`cmd`目录，没错，所有的命令实现都存放在该目录下。

![image-20220531171054987](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311710040.png)

有没有看到`help.C`这个文件呢，我们就拿`help`这个文件来类比。

![image-20220531171133262](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311711319.png)

`U_BOOT_CMD`：用来定义一个命令

`help`：用于命令行键入的指令

`do_help`：键入指令后，执行的函数

**要想进一步使用该命令，我们不得不去了解每个参数的含义。**

```c
struct cmd_tbl_s {
	char		*name;		/* Command Name			*/
	int		maxargs;	/* maximum number of arguments	*/
	int		repeatable;	/* autorepeat allowed?		*/
					/* Implementation function	*/
	int		(*cmd)(struct cmd_tbl_s *, int, int, char *[]);
	char		*usage;		/* Usage message	(short)	*/
	char		*help;		/* Help  message	(long)	*/
	/* do auto completion on the arguments */
	int		(*complete)(int argc, char *argv[], char last_char, int maxv, char *cmdv[]);
};

typedef struct cmd_tbl_s	cmd_tbl_t;
```

每个参数分别对应了：命令名、可接收的最大参数、命令可重复、响应函数、使用示例、帮助信息。

&nbsp;

### 第二步：画瓢

弄明白这个道理，假如我们想加入一个`helpme`的指令，该怎么做？

- <font color = "red">**定义一个指令**</font>

```c
U_BOOT_CMD(
	helpme,	CONFIG_SYS_MAXARGS,	1,	do_helpme,
	"helpme dong",
	"\n"
	"	- print brief description of all commands\n"
	"helpme command ...\n"
	"	- print detailed usage of 'command'"
);
```

- <font color = "red">**定义一个执行函数**</font>

```c
static int do_helpme(struct cmd_tbl *cmdtp, int flag, int argc,
		   char *const argv[])
{
	printf("Cmd test ok!\r\n");
	printf("argc = %d\r\n", argc);
	printf("argv = ");
	for(int i = 0; i < argc; ++i) {
		printf("%s\t", argv[i]);
	}
	printf("\r\n");
}
```

这样，就可以编译->烧录->运行了。

进入`Uboot`命令行，键入`help`查看添加的命令`helpme`。

- <font color = "red">**键入命令测试**</font>

```bash
=> helpme 123456 123
Cmd test ok!
argc = 3
argv = helpme   123456  123
```

&nbsp;

### 第三步：优雅

如果我们只是暂时测试，这样添加无伤大雅；如果我们需要投入正规项目使用，这么做有点激进了。

更加合理的做法是：

- 在`uboot/cmd`目录下，建立一个文件`XXX.c`
- 将要添加的命令写入`XXX.c`该文件中
- 修改`Makefile`文件，编译该文件：`obj-y += XXX.o`
- 重新编译，烧录

> 说白了，就是创建一个文件，将自定义指令添加进去，尽量不修改源码！

&nbsp;

## 4.5 Uboot命令底层实现分析

上面写了傻瓜式添加命令的方法，对于进行`Uboot`开发，当然我们需要去了解一下内部的实现原理。

### 4.5.1 U_BOOT_CMD

查看`U_BOOT_CMD`宏定义

```c
#define U_BOOT_CMD(_name, _maxargs, _rep, _cmd, _usage, _help)		\
	U_BOOT_CMD_COMPLETE(_name, _maxargs, _rep, _cmd, _usage, _help, NULL)
```

```c
#define U_BOOT_CMD_COMPLETE(_name, _maxargs, _rep, _cmd, _usage, _help, _comp) \
	ll_entry_declare(struct cmd_tbl, _name, cmd) =			\
		U_BOOT_CMD_MKENT_COMPLETE(_name, _maxargs, _rep, _cmd,	\
						_usage, _help, _comp);
```

```c
#define U_BOOT_CMD_MKENT_COMPLETE(_name, _maxargs, _rep, _cmd,		\
				_usage, _help, _comp)			\
		{ #_name, _maxargs,					\
		 _rep ? cmd_always_repeatable : cmd_never_repeatable,	\
		 _cmd, _usage, _CMD_HELP(_help) _CMD_COMPLETE(_comp) }
```

```c
#define ll_entry_declare(_type, _name, _list)				\
	_type _u_boot_list_2_##_list##_2_##_name __aligned(4)		\
			__attribute__((unused,				\
			section(".u_boot_list_2_"#_list"_2_"#_name)))
```

&nbsp;

> **乍一看，都是宏定义，为什么看起来这么吃力？**

#### 在这里，不得不提到`#`和`##`的区别

- `#`：转换为字符串

```c
...
#define TO_STR(x) #x
int main()
{
    int value = 123;
    printf("TO_STR(value) = %s\n", TO_STR(value));
    printf("TO_STR(123) = %s\n", TO_STR(123));
}

//打印
TO_STR(value) = value;
TO_STR(123) = 123;
```

- `##`：两个字符拼接

```c
#define CONNECT(x,y) x##y
#define VAR(y) data##y
int main()
{
    int xy = 123;
    printf("xy = %d\n", CONNECT(x, y));

    CONNECT(x, y) = 123456;
    printf("xy = %d\n", CONNECT(x, y));

    int VAR(1) = 100;
    printf("VAR(1) = data1 = %d\n", data1);
}

//打印
xy = 123
xy = 123456
VAR(1) = data1 = 100
```



> <font color = "red">**回到正文**</font>

**上面的宏定义，简单来看，转换流程就是**：

`U_BOOT_CMD` -> `U_BOOT_CMD_COMPLETE` -> `ll_entry_declare = U_BOOT_CMD_MKENT_COMPLETE` -> `_type xxx = {aaa, bbb, ccc , ...}`

<font color='red'> **其本质就是：** `struct my_struct test = {1, 2, 3};`**结构体赋值语句**。</font>

&nbsp;

**以`help`命令为例**：

```c
U_BOOT_CMD(
	help,	CONFIG_SYS_MAXARGS,	1,	do_help,
	"print command description/usage",
	"\n"
	"	- print brief description of all commands\n"
	"help command ...\n"
	"	- print detailed usage of 'command'"
);
```

**直接展开来看**：

```c
struct cmd_tbl _u_boot_list_2_cmd_2_help __aligned(4) __attribute__((unused, section(".u_boot_list_2_cmd_2_help"))) = 
{"help", CONFIG_SYS_MAXARGS, cmd_always_repeatable, do_help, "xxx", "xxx"};
```

也就相当于，我们定义一个命令，给其赋值。



#### 定义的命令存放在哪里呢？

根据上面展开来看，`section(".u_boot_list_2_cmd_2_help")`，存放在段`.u_boot_list_2_cmd_2_help`中，打开`u-boot.map`文件，我们可以查找得到。

![image-20220531171337636](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311713707.png)

有没有觉得很熟悉，没错，跟前面讲过的驱动模型很像。

我们定义的命令，被`u_boot_list_2_cmd_1`和`u_boot_list_2_cmd_3`两个段所包括，用于遍历，最终查找得到我们想要的命令。



## 4.6 Uboot命令响应流程

**命令响应流程见图**：

![image-20220531194613304](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202205311946369.png)

&nbsp;

根据`4.3 命令行模式代码执行流程分析`，我们可以知道，命令行模式最终执行`cli_loop`函数，实现与用户的交互。

```c
void cli_loop(void)
{
	bootstage_mark(BOOTSTAGE_ID_ENTER_CLI_LOOP);
#ifdef CONFIG_HUSH_PARSER
	parse_file_outer();
	/* This point is never reached */
	for (;;);
#elif defined(CONFIG_CMDLINE)
	cli_simple_loop();
#else
	printf("## U-Boot command line is disabled. Please enable CONFIG_CMDLINE\n");
#endif /*CONFIG_HUSH_PARSER*/
}
```

通过分析代码，`Uboot`的命令行有两种模式：一种是`HUSH解析`，另一种是`通用解析`。

- **HUSH解析**：调用`parse_file_outer`并不断循环
- **通用解析**：调用`cli_simple_loop`并不断循环。

&nbsp;

<font color="red">**无论哪种命令行解析，说白了就是输入输出的处理，必定会读取数据，执行相应命令，打印出对应数据**</font>

&nbsp;

**HUSH模式**

- **输入数据处理**：`parse_stream`
- **输出数据处理**：`run_list`

**通用模式**：

- **输入数据处理**：`cli_readline`
- **输出数据处理**：`run_command_repeatable`



> **具体实现流程，参照上面的流程图！**
>
> **命令行模式的深入解析，准备在下节详细介绍！**

目前，我们已经对命令行的整体运行流程进行梳理，熟悉整体的运行逻辑，并且能够添加自定义命令喽。

&nbsp;

## 4.6 推荐文档

[1]：https://www.pianshen.com/article/21471247431/

[2]：https://blog.csdn.net/weixin_44895651/article/details/108211268

[3]：https://blog.51cto.com/u_2847568/4917530?b=totalstatistic

[4]：https://blog.csdn.net/SilverFOX111/article/details/86892231

[5]：https://blog.csdn.net/andy_wsj/article/details/8614905

&nbsp;
另外，如果有同学想了解`Emmc`协议的，可以【[戳这里](https://t.zsxq.com/0eUcTOhdO)】下载`eMMC5.1官方标准协议.pdf`和`eMMC4.51官方标准协议-中文.pdf`

<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/Embeded_Art.gif" alt="img" width = "60%" height ="10%"/>
</div>
