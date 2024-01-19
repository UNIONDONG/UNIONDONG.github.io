---
date: '2024-01-19T20:29:33+08:00'
title:       '【LED子系统深度剖析】五、核心层详解（二）'
description: ""
author:      "Donge"
image:       ""
tags:        ["LED子系统", "LED子系统深度剖析", "Linux驱动开发", "LED驱动开发"]
categories:  ["Tech" ]
weight: 5
---
# 【LED子系统深度剖析】五、核心层详解（二）

## 1、前言

> 上篇文章我们了解了子系统的核心层`led-class.c`，下面我们来分析驱动框架中核心层的`led-core.c`实现以及作用。

![image-20230417084033734](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230417084033734.png)

<span style="color: red;">**我们接着从`led-core.c`文件开始分析**</span>

## 2、led\_init\_core分析

> 上一篇文章，我们知道在将`leds_classdev`注册进入子系统后，会调用`led_init_core`函数，初始化核心层，下面我们以`led_init_core`该函数为突破口分析。

### 2.1 相关数据结构

#### 2.1.1 work_struct

```C
struct work_struct {
    atomic_long_t data;
    struct list_head entry;
    work_func_t func;
#ifdef CONFIG_LOCKDEP
    struct lockdep_map lockdep_map;
#endif
};
```

**结构体名称**：`work_struct`

**文件位置**：`include/linux/workqueue.h.h`

**主要作用**：定义一个工作队列，包括了工作项的状态和数据，以及处理工作项的函数指针，用于实现**异步执行任务的功能**。在工作队列中，每个工作项都是一个`work_struct`结构体的实例，通过将工作项添加到工作队列中，可以实现后台执行任务的功能。

#### 2.1.2 timer_list

```C
struct timer_list {
    /*
     * All fields that change during normal runtime grouped to the
     * same cacheline
     */
    struct hlist_node	entry;
    unsigned long		expires;
    void			(*function)(struct timer_list *);
    u32			flags;

#ifdef CONFIG_LOCKDEP
    struct lockdep_map	lockdep_map;
#endif
};
```

**结构体名称**：`work_struct`

**文件位置**：`include/linux/timer.h`

**主要作用**：表示一个定时器，其中包括定时器到期时间，处理函数，以及一些标志位信息。

- `entry`：一个`hlist_node`结构体，用于将定时器添加到哈希表中。
- `expires`：一个`unsigned long`类型的值，表示定时器何时到期。
- `function`：表示定时器的处理函数
- `flags`：一个`u32`类型的值，表示定时器的标志位
- `lockdep_map`：如果定义了`CONFIG_LOCKDEP`，则包含一个`lockdep_map`结构体，用于跟踪定时器的锁定情况。

### 2.2 相关实现

```c
void led_init_core(struct led_classdev *led_cdev)
{
    INIT_WORK(&led_cdev->set_brightness_work, set_brightness_delayed);

    timer_setup(&led_cdev->blink_timer, led_timer_function, 0);
}
```

**函数介绍**：这部分代码，用于初始化核心层，此函数通过设置延迟工作队列来设置 `LED` 亮度，并通过计时器来进行软件闪烁。

#### 2.2.1 INIT_WORK

```c
INIT_WORK(&led_cdev->set_brightness_work, set_brightness_delayed);

#define INIT_WORK(_work, _func)						\
    __INIT_WORK((_work), (_func), 0)

// #define __INIT_WORK(&led_cdev->set_brightness_work, set_brightness_delayed, 0)

#define __INIT_WORK(_work, _func, _onstack)				\
    do {								\
        __init_work((_work), _onstack);				\
        (_work)->data = (atomic_long_t) WORK_DATA_INIT();	\
        INIT_LIST_HEAD(&(_work)->entry);			\
        (_work)->func = (_func);				\
    } while (0)

/*
do {
    __init_work(&led_cdev->set_brightness_work, 0);
    (&led_cdev->set_brightness_work)->data = (atomic_long_t) WORK_DATA_INIT();
    INIT_LIST_HEAD(&(&led_cdev->set_brightness_work)->entry);
    (&led_cdev->set_brightness_work)->func = set_brightness_delayed;
} while (0)
*/
```

**函数介绍**：`INIT_WORK`该宏定义，两个参数，一个是表示工作队列的指针`&led_cdev->set_brightness_work`，一个是工作队列的处理函数`set_brightness_delayed`

**实现思路**：

1.  调用`INIT_WORK`宏定义，将工作队列指针和处理函数作为参数传递
2.  最终通过`do while`将工作队列初始化函数包括在内，实现工作队列的初始化

#### 2.2.2 timer_setup

```c
    timer_setup(&led_cdev->blink_timer, led_timer_function, 0);
```

**函数介绍**：这里不展开介绍，同上，将定时器指针和处理函数作为参数，直接初始化。定时器的超时时间通过`mod_timer`来设置。

> 由上文可知，我们`led-core.c`的核心是初始化了一个工作队列和一个定时器函数，<span style="color: red;">**通过延迟工作队列来设置 `LED` 亮度，并通过计时器来进行软件闪烁。**</span>
> 
> 我们先来分析`led_timer_function`函数

## 3、led\_timer\_function分析

> 由上文可知，`led_timer_function`主要负责`LED`的闪烁功能

```c
static void led_timer_function(struct timer_list *t)
{
    struct led_classdev *led_cdev = from_timer(led_cdev, t, blink_timer);	//	获取结构体指针
    unsigned long brightness;
    unsigned long delay;

    if (!led_cdev->blink_delay_on || !led_cdev->blink_delay_off) {			//	闪烁延时判断
        led_set_brightness_nosleep(led_cdev, LED_OFF);
        clear_bit(LED_BLINK_SW, &led_cdev->work_flags);
        return;
    }

    if (test_and_clear_bit(LED_BLINK_ONESHOT_STOP,							//	测试是否为闪烁一次
                   &led_cdev->work_flags)) {
        clear_bit(LED_BLINK_SW, &led_cdev->work_flags);
        return;
    }

    brightness = led_get_brightness(led_cdev);								//	获取当前亮度值
    if (!brightness) {
        /* Time to switch the LED on. */
        if (test_and_clear_bit(LED_BLINK_BRIGHTNESS_CHANGE,
                    &led_cdev->work_flags))
            brightness = led_cdev->new_blink_brightness;					//	设置新的亮度值
        else
            brightness = led_cdev->blink_brightness;						//	设置默认亮度值
        delay = led_cdev->blink_delay_on;
    } else {
        /* Store the current brightness value to be able
         * to restore it when the delay_off period is over.
         */
        led_cdev->blink_brightness = brightness;							//	存储当前亮度值
        brightness = LED_OFF;												//	更新亮度值为0
        delay = led_cdev->blink_delay_off;
    }

    led_set_brightness_nosleep(led_cdev, brightness);						//	设置亮度

    /* Return in next iteration if led is in one-shot mode and we are in
     * the final blink state so that the led is toggled each delay_on +
     * delay_off milliseconds in worst case.
     */
    if (test_bit(LED_BLINK_ONESHOT, &led_cdev->work_flags)) {				//	一次闪烁判断
        if (test_bit(LED_BLINK_INVERT, &led_cdev->work_flags)) {
            if (brightness)
                set_bit(LED_BLINK_ONESHOT_STOP,
                    &led_cdev->work_flags);
        } else {
            if (!brightness)
                set_bit(LED_BLINK_ONESHOT_STOP,
                    &led_cdev->work_flags);
        }
    }

    mod_timer(&led_cdev->blink_timer, jiffies + msecs_to_jiffies(delay));	//	更新定时器时间
}
```

**函数介绍**：该函数实现了定时触发，每次触发控制`LED`的亮度情况，实现亮灭的效果。

**实现思路**：

1.  首先通过`from_timer`接口，底层还是通过`container_of`函数，获取`led_classdev`结构体指针
2.  判断`blink_delay_on`和`blink_delay_off`延时是否为`0`，如果为`0`，默认为关闭`LED`
3.  通过`led_get_brightness`获取亮度值，闪烁逻辑如下：
    1.  如果亮度为`0`，则设置亮度值，更新延时为亮延时：`delay = led_cdev->blink_delay_on`
    2.  如果亮度不为0，则设置亮度为0，`brightness = LED_OFF;`然后设置延时为灭延时：`delay = led_cdev->blink_delay_off`
4.  调用`led_set_brightness_nosleep`设置`LED`亮度
5.  调用`mod_timer`更新定时器时间

#### 3.1.1 led\_get\_brightness

```C
static inline int led_get_brightness(struct led_classdev *led_cdev)
{
    return led_cdev->brightness;
}
```

**函数介绍**：该函数比较简单，直接获取`led_classdev`结构体的亮度值即可！

#### 3.1.2 led\_set\_brightness_nosleep

```c
void led_set_brightness_nosleep(struct led_classdev *led_cdev,
                enum led_brightness value)
{
    led_cdev->brightness = min(value, led_cdev->max_brightness);

    if (led_cdev->flags & LED_SUSPENDED)
        return;

    led_set_brightness_nopm(led_cdev, led_cdev->brightness);
}
EXPORT_SYMBOL_GPL(led_set_brightness_nosleep);
```

**函数介绍**：与最大亮度值进行比较，并设置`LED`亮度，如果`LED`被挂起（进入休眠），则直接返回。所以，正如其名，`nosleep`即不休眠时的函数生效。。

#### 3.1.3 led\_set\_brightness_nopm

```C
void led_set_brightness_nopm(struct led_classdev *led_cdev,
                  enum led_brightness value)
{
    /* Use brightness_set op if available, it is guaranteed not to sleep */
    if (!__led_set_brightness(led_cdev, value))
        return;

    /* If brightness setting can sleep, delegate it to a work queue task */
    led_cdev->delayed_set_value = value;
    schedule_work(&led_cdev->set_brightness_work);
}

static int __led_set_brightness(struct led_classdev *led_cdev,
                enum led_brightness value)
{
    if (!led_cdev->brightness_set)
        return -ENOTSUPP;

    led_cdev->brightness_set(led_cdev, value);

    return 0;
}
```

**函数介绍**：设置`LED`亮度，该函数首先尝试使用`__led_set_brightness`函数来设置亮度，该函数保证不会使系统进入睡眠状态。如果不成功，则将亮度设置委托给工作队列任务。

**相关实现**：

1.  尝试调用`__led_set_brightness`接口，该函数用于未打开休眠功能。
  
2.  如果该`__led_set_brightness`函数返回错误码，则代表了打开了休眠功能
  
3.  休眠状态下，想要设置`LED`亮度值，需要将`delayed_set_value`变量设置为所需的亮度值，然后调度`set_brightness_work`任务。
  

## 4、set\_brightness\_delayed分析

> 由上面可知，如果子系统打开了休眠功能，设置`LED`亮度时，需要加入工作队列，而工作队列的处理函数即： `set_brightness_delayed`

```C
static void set_brightness_delayed(struct work_struct *ws)
{
    struct led_classdev *led_cdev =
        container_of(ws, struct led_classdev, set_brightness_work);
    int ret = 0;

    if (test_and_clear_bit(LED_BLINK_DISABLE, &led_cdev->work_flags)) {
        led_cdev->delayed_set_value = LED_OFF;
        led_stop_software_blink(led_cdev);
    }

    ret = __led_set_brightness(led_cdev, led_cdev->delayed_set_value);
    if (ret == -ENOTSUPP)
        ret = __led_set_brightness_blocking(led_cdev,
                    led_cdev->delayed_set_value);
    if (ret < 0 &&
        /* LED HW might have been unplugged, therefore don't warn */
        !(ret == -ENODEV && (led_cdev->flags & LED_UNREGISTERING) &&
        (led_cdev->flags & LED_HW_PLUGGABLE)))
        dev_err(led_cdev->dev,
            "Setting an LED's brightness failed (%d)\n", ret);
}
```

**函数介绍**：`set_brightness_delayed`正如其名，延时设置`LED`灯的亮度。

**实现思路**：

1.  首先通过`container_of`来获取`led_classdev`结构体指针
2.  `test_and_clear_bit`对闪烁标志位进行判断，如果不支持，则关闭
3.  调用`__led_set_brightness`和`__led_set_brightness_blocking`来设置`LED`的亮度

#### 4.1.1 \_\_led\_set_brightness

```c
static int __led_set_brightness(struct led_classdev *led_cdev,
                enum led_brightness value)
{
    if (!led_cdev->brightness_set)
        return -ENOTSUPP;

    led_cdev->brightness_set(led_cdev, value);

    return 0;
}
```

**函数介绍**：**非阻塞**设置`LED`亮度，该函数调用`led-gpio.c`硬件驱动层分配的函数来操作硬件实现，**用于不支持休眠时，不用考虑休眠是否打断该函数执行**

#### 4.1.2 \_\_led\_set\_brightness\_blocking

```C
static int __led_set_brightness_blocking(struct led_classdev *led_cdev,
                     enum led_brightness value)
{
    if (!led_cdev->brightness_set_blocking)
        return -ENOTSUPP;

    return led_cdev->brightness_set_blocking(led_cdev, value);
}
```

**函数介绍**：**阻塞**设置`LED`亮度，该函数调用`led-gpio.c`硬件驱动层分配的函数来操作硬件实现，**用于在支持休眠时，避免休眠打断该函数执行**。

> 这两个函数，如果看源码的话，还是有点绕的，因为`__led_set_brightness_blocking`内部竟然也直接调用了`__led_set_brightness`，所以这里也尽量还原代码原本的意思。

这篇就先讲到这里，当然该文件中还有一些`xxx_blink`相关的函数，主要用于管理闪烁，我们放到后面再了解。

## 5、总结

上面我们了解到核心层的主要作用：<span style="color: red;">**通过延迟工作队列来设置 `LED` 亮度，并通过计时器来进行软件闪烁。**</span>

### 5.1 代码实现流程

```C
led_timer_function(drivers/leds/led-core.c)
    |--> led_get_brightness                 //  获取亮度值
    |--> led_set_brightness_nosleep         //  设置LED亮度
        |--> led_set_brightness_nopm        //  在非休眠状态下设置
            |--> __led_set_brightness       // 
                |--> led_cdev->brightness_set// 硬件驱动层实现 



set_brightness_delayed(drivers/leds/led-core.c)
    |--> __led_set_brightness               //  非阻塞函数，调用该接口设置LED亮度后立即返回
        |--> led_cdev->brightness_set
            |--> gpio_led_set(drivers/leds/leds-gpio.c) //  最终调用的函数
    |--> __led_set_brightness_blocking      //  阻塞函数，调用该接口设置LED亮度后必须等待设置完成，才返回
        |--> led_cdev->brightness_set_blocking
            |--> gpio_led_set_blocking

```

核心层的接口，大都是提供给外部使用的，这些函数也都通过`EXPORT_SYMBOL_GPL`宏定义来导出的，即：向上提供了操作的接口。——**乘上**

并且这些函数底层实现，都关联到了`led-gpio.c`硬件驱动层，即：调用底层的相关接口——**启下**




<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
