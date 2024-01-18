---
date: '2024-01-18T23:02:13+08:00'
title:       '【深入理解Linux锁机制】三、原子操作'
description: ""
author:      "Donge"
image:       ""
tags:        ["内核锁", "Linux 锁机制", "操作系统锁"," Linux 系统开发","Linux 内核"]
categories:  ["Tech" ]
weight: 3
---

# 【深入理解Linux内核锁】三、原子操作

![img](https://pics6.baidu.com/feed/a044ad345982b2b73288e884305a63e977099b5d.jpeg?token=534118da5c3201a68dadb33ea815373b)

## 1、原子操作思想

原子操作`（atomic operation）`，不可分割的操作。其通过原子变量来实现，以保证单个`CPU`周期内，读写该变量不能被打断，进而判断该变量的值，来解决并发引起的互斥。

**`Atomic`类型的变量可以在执行期间禁止中断，并保证在访问变量时的原子性。**

> 简单来说，我们可以把原子变量看作为一个标志位，然后再来检测该标志位的值。
> 
> 其原子性表现在：操作该标志位的值，不可被打断。

在`Linux`内核中，提供了两类原子操作的接口，分别是针对**位**和**整型变量**的原子操作。

![image-20230730171728090](https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/image-20230730171728090.png)

## 2、整型变量原子操作

### 2.1 API接口

> 对于整形变量的原子操作，内核提供了一系列的 `API`接口

```c
/*设置原子变量的值*/
atomic_t v = ATOMIC_INIT(0);            /* 定义原子变量v并初始化为0 */
void atomic_set(atomic_t *v, int i);    /* 设置原子变量的值为i */

/*获取原子变量的值*/
atomic_read(atomic_t *v);        		/* 返回原子变量的值*/

/*原子变量的加减*/
void atomic_add(int i, atomic_t *v);      /* 原子变量增加i */
void atomic_sub(int i, atomic_t *v);      /* 原子变量减少i */

/*原子变量的自增，自减*/
void atomic_inc(atomic_t *v);				/* 原子变量增加1 */
void atomic_dec(atomic_t *v);     			/* 原子变量减少1 */

/*原子变量的操作并测试*/
int atomic_inc_and_test(atomic_t *v);		/*进行对应操作后，测试原子变量值是否为0*/
int atomic_dec_and_test(atomic_t *v);
int atomic_sub_and_test(int i, atomic_t *v);

/*原子变量的操作并返回*/
int atomic_add_return(int i, atomic_t *v);	/*进行对应操作后，返回新的值*/
int atomic_sub_return(int i, atomic_t *v);
int atomic_inc_return(atomic_t *v);
int atomic_dec_return(atomic_t *v);
```

### 2.2 API实现

> 我们下面就介绍几个稍微有代表性的接口实现
> 
> 以下基于`Linux`内核源码`4.19`，刚看是看的时候，有点摸不着头脑，因为定义的地方和引用的地方较多，不太容易找到，后来才慢慢得窥门径。

#### 2.2.1 原子变量结构体

```C
typedef struct {
    int counter;
} atomic_t;
```

**结构体名称**：`atomic_t`

**文件位置**：`include/linux/types.h`

**主要作用**：原子变量结构体，该结构体只包含一个整型成员变量`counter`，用于存储原子变量的值。

#### 2.2.2 设置原子变量操作

> 设置原子变量的值的方式有两种：
> 
> 1.  通过`ATOMIC_INIT`宏定义来设置
> 2.  通过`atomic_set`函数来定义

##### 2.2.2.1 ATOMIC_INIT

```
#define ATOMIC_INIT(i)	{ (i) }
```

**函数介绍**：定义了一个ATOMIC类型的变量，并初始化为给定的值。

**文件位置**：`arch/arm/include/asm/atomic.h`

**实现方法**：这个宏定义比较简单，通过大括号将值包裹起来作为一个结构体，结构体的第一个成员就是给定的该值。

##### 2.2.2.2 atomic_set

```C
// arch/arm/include/asm/atomic.h
#define atomic_set(v,i)	WRITE_ONCE(((v)->counter), (i))

// include/linux/compiler.h
#define WRITE_ONCE(x, val) \
({							\
    union { typeof(x) __val; char __c[1]; } __u =	\
        { .__val = (__force typeof(x)) (val) }; \
    __write_once_size(&(x), __u.__c, sizeof(x));	\
    __u.__val;					\
})

static __always_inline void __write_once_size(volatile void *p, void *res, int size)
{
    switch (size) {
    case 1: *(volatile __u8 *)p = *(__u8 *)res; break;
    case 2: *(volatile __u16 *)p = *(__u16 *)res; break;
    case 4: *(volatile __u32 *)p = *(__u32 *)res; break;
    case 8: *(volatile __u64 *)p = *(__u64 *)res; break;
    default:
        barrier();
        __builtin_memcpy((void *)p, (const void *)res, size);
        barrier();
    }
}
```

**函数介绍**：该函数也用作初始化原子变量

**文件位置**：`arch/arm/include/asm/atomic.h`

**实现方式**：通过调用`WRITE_ONCE`来实现，其中`WRITE_ONCE`宏实现了一些屏蔽编译器优化的技巧，确保写入操作是原子的。

1.  `atomic_set`调用`WRITE_ONCE`将`i`的值写入原子变量`(v)->counter`中，`WRITE_ONCE`以保证操作的原子性
2.  `WRITE_ONCE`用来保证操作的原子性，它是怎么实现的呢？
    1.  创建`union`联合体，包括`__val`和`__C`成员变量
    2.  定义一个`__U`变量，使用强制转换将参数`__val`转换为`typeof(x)`类型，传递给联合体变量`__u.__val`
    3.  调用`__write_once_size`函数，将`__u.__c`指向的内存块的内容写入到变量`x`的内存空间中，大小为`sizeof(x)`。
    4.  函数返回`__u.__val`，也就是写入的值
3.  `union`联合体
    1.  它的特点是存储多种数据类型的值，但是所有成员共享同一个内存空间，这样可以节省内存空间。
    2.  主要作用是将一个非字符类型的数据`x`强制转换为一个字符类型的数据，以字符类型数据来访问该区块的内存单元。
4.  `__write_once_size`函数实现了操作的原子性，核心有以下几点：
    1.  该函数在向内存写入数据时使用了`volatile`关键字，告诉编译器不要进行优化，每次操作都从内存中读取最新的值。
    2.  函数中的`switch`语句保证了对不同大小的数据类型使用不同的存储方式，可以保证内存访问的原子性。
    3.  对于默认情况，则使用了`__builtin_memcpy`函数进行复制，而这个函数具有原子性。
    4.  `barrier()`函数指示`CPU`要完成所有之前的内存操作，以及确保执行顺序与其他指令不发生重排。

#### 2.2.3 原子变量的加减

##### 2.2.3.1 ATOMIC_OPS

```C
/*
 * ARMv6 UP and SMP safe atomic ops.  We use load exclusive and
 * store exclusive to ensure that these are atomic.  We may loop
 * to ensure that the update happens.
 */

#define ATOMIC_OP(op, c_op, asm_op)					\
static inline void atomic_##op(int i, atomic_t *v)			\
{									\
    unsigned long tmp;						\
    int result;							\
                                    \
    prefetchw(&v->counter);						\
    __asm__ __volatile__("@ atomic_" #op "\n"			\
"1:	ldrex	%0, [%3]\n"						\
"	" #asm_op "	%0, %0, %4\n"					\
"	strex	%1, %0, [%3]\n"						\
"	teq	%1, #0\n"						\
"	bne	1b"							\
    : "=&r" (result), "=&r" (tmp), "+Qo" (v->counter)		\
    : "r" (&v->counter), "Ir" (i)					\
    : "cc");							\
}									\

#define ATOMIC_OP_RETURN(op, c_op, asm_op)				\
static inline int atomic_##op##_return_relaxed(int i, atomic_t *v)	\
{									\
    unsigned long tmp;						\
    int result;							\
                                    \
    prefetchw(&v->counter);						\
                                    \
    __asm__ __volatile__("@ atomic_" #op "_return\n"		\
"1:	ldrex	%0, [%3]\n"						\
"	" #asm_op "	%0, %0, %4\n"					\
"	strex	%1, %0, [%3]\n"						\
"	teq	%1, #0\n"						\
"	bne	1b"							\
    : "=&r" (result), "=&r" (tmp), "+Qo" (v->counter)		\
    : "r" (&v->counter), "Ir" (i)					\
    : "cc");							\
                                    \
    return result;							\
}

#define ATOMIC_FETCH_OP(op, c_op, asm_op)				\
static inline int atomic_fetch_##op##_relaxed(int i, atomic_t *v)	\
{									\
    unsigned long tmp;						\
    int result, val;						\
                                    \
    prefetchw(&v->counter);						\
                                    \
    __asm__ __volatile__("@ atomic_fetch_" #op "\n"			\
"1:	ldrex	%0, [%4]\n"						\
"	" #asm_op "	%1, %0, %5\n"					\
"	strex	%2, %1, [%4]\n"						\
"	teq	%2, #0\n"						\
"	bne	1b"							\
    : "=&r" (result), "=&r" (val), "=&r" (tmp), "+Qo" (v->counter)	\
    : "r" (&v->counter), "Ir" (i)					\
    : "cc");							\
                                    \
    return result;							\
}

#define ATOMIC_OPS(op, c_op, asm_op)					\
    ATOMIC_OP(op, c_op, asm_op)					\
    ATOMIC_OP_RETURN(op, c_op, asm_op)				\
    ATOMIC_FETCH_OP(op, c_op, asm_op)
    
ATOMIC_OPS(add, +=, add)
ATOMIC_OPS(sub, -=, sub)
```

> 找`atomic_add`找半天，还找到了不同的架构下面。:(
> 
> 原来内核通过各种宏定义将其操作全部管理起来，宏定义在内核中的使用也是非常广泛了。

**函数作用**：通过一些列宏定义，来实现原子变量的`add`、`sub`、`and`、`or`等原子变量操作

**文件位置**：`arch/arm/include/asm/atomic.h`

**实现方式**：

> 我们以`atomic_##op`为例来介绍，其他大同小异！

```C
#define ATOMIC_OP(op, c_op, asm_op)					\
static inline void atomic_##op(int i, atomic_t *v)			\
{									\
    unsigned long tmp;						\
    int result;							\
                                    \
    prefetchw(&v->counter);						\
    __asm__ __volatile__("@ atomic_" #op "\n"			\
"1:	ldrex	%0, [%3]\n"						\
"	" #asm_op "	%0, %0, %4\n"					\
"	strex	%1, %0, [%3]\n"						\
"	teq	%1, #0\n"						\
"	bne	1b"							\
    : "=&r" (result), "=&r" (tmp), "+Qo" (v->counter)		\
    : "r" (&v->counter), "Ir" (i)					\
    : "cc");							\
}		
```

1.  首先是函数名称`atomic_##op`，通过`##`来实现字符串的拼接，使函数名称可变，如`atomic_add`、`atomic_sub`等
2.  调用`prefetchw`函数，预取数据到`L1`缓存，方便操作，提高程序性能，但是不要滥用。
3.  `__asm__ __volatile__`：表示汇编指令
4.  `"@ atomic_" #op "\n"`：添加汇编注释，也就是我们的函数名字，如：`atomic_add`、`atomic_sub`
5.  `"1: ldrex %0, [%3]\n"`：将`%3`存储地址的数据，读入到`%0`地址中，`ldrex`为独占式的读取操作。
6.  `" " #asm_op " %0, %0, %4\n"`：`" #asm_op "`表示作为宏定义传进来的参数，表示不同的操作码`add`、`sub`等，操作`%0`和`%4`对应的地址的值，并将结果返回到`%0`地址处
7.  `" strex %1, %0, [%3]\n"` ：表示将`%0`地址处的值写入`%3`地址处，`strex`为独占式的写操作，写入的结果会返回到`%1`地址中
8.  `" teq %1, #0\n"`：测试`%1`寄存器的值是否为0，如果不等于0，则执行下面的`" bne 1b"` 操作，跳转到`1`代码标签的位置，也就是`ldrex`前面的`1`的位置
9.  `: "=&r" (result), "=&r" (tmp), "+Qo" (v->counter)`：根据汇编语法，前两个为输出操作数，第三个为输入输出操作数
10. `: "r" (&v->counter), "Ir" (i)`：根据汇编语法，这两个为输入操作数
11. `: "cc"`：表示可能会修改条件码寄存器，编译期间需要优化。

<span style="color: red;">**总结：上述原子操作，通过`ldrex`和`strex`也就是我们说的`load`和`store`指令，来完成数据的读写，同时也保证了其原子性！**</span>

> 这一部分，牵涉到汇编的语法，需要提前了解下基础的汇编指令。

##### 2.2.3.2 atomic\_add和atomic\_sub定义

```c
ATOMIC_OPS(add, +=, add)
ATOMIC_OPS(sub, -=, sub)
```

> 通过宏定义来实现`atomic_add`和`atomic_sub`的定义，下面我们就不一一分析了，原理都是通过`ARM`提供的`ldrex` `strex`也就是我们常说的`Load`和`Store`指令实现读取操作，确保操作的原子性。

## 3、位原子操作

> 对于位原子操作，内核也提供了一系列的 `API`接口

### 3.1 API接口

```c
void set_bit(nr, void *addr);		//	设置位：设置addr地址的第nr位，所谓设置位即是将位写为1
void clear_bit(nr, void *addr);		//	清除位：清除addr地址的第nr位，所谓清除位即是将位写为0
void change_bit(nr, void *addr);	//	改变位：对addr地址的第nr位进行反置。
int test_bit(nr, void *addr);		//	测试位：返回addr地址的第nr位。
int test_and_set_bit(nr, void *addr);//	测试并设置位
int test_and_clear_bit(nr, void *addr);	//	测试并清除位
int test_and_change_bit(nr, void *addr);//	测试并改变位
```

### 3.2 API实现

> 同样，我们还是简单介绍几个接口，其他核心实现原理相同

#### 3.2.1 set_bit

```C
#define set_bit(nr,p)			ATOMIC_BITOP(set_bit,nr,p)

#define ATOMIC_BITOP(name,nr,p)			\
    (__builtin_constant_p(nr) ? ____atomic_##name(nr, p) : _##name(nr,p))

extern void _set_bit(int nr, volatile unsigned long * p);

/*
 * These functions are the basis of our bit ops.
 *
 * First, the atomic bitops. These use native endian.
 */
static inline void ____atomic_set_bit(unsigned int bit, volatile unsigned long *p)
{
    unsigned long flags;
    unsigned long mask = BIT_MASK(bit);

    p += BIT_WORD(bit);

    raw_local_irq_save(flags);
    *p |= mask;
    raw_local_irq_restore(flags);
}

#define BIT_MASK(nr)		(1UL << ((nr) % BITS_PER_LONG))
#define BIT_WORD(nr)		((nr) / BITS_PER_LONG)

#ifdef CONFIG_64BIT
#define BITS_PER_LONG 64
#else
#define BITS_PER_LONG 32
#endif /* CONFIG_64BIT */
```

**函数介绍**：该函数用于原子操作某个地址的某一位。

**文件位置**：`/arch/arm/include/asm/bitops.h`

**实现方式**：

1.  `__builtin_constant_p`：`GCC`的一个内置函数，用来判断表达式是否为常量，如果为常量，则返回值为1
2.  `____atomic_set_bit`函数中`BIT_MASK`，用于获取操作位的掩码，将要设置的位设置为1，其他为0
3.  `BIT_WORD`：确定要操作位的偏移，要偏移多少个字
4.  最后通过`raw_local_irq_save`和`raw_local_irq_restore`中断屏蔽来保证位操作`*p |= mask;`的原子性

## 4、总结

该文章主要详细了解了`Linux`内核锁的原子操作，原子操作分为两种：整型变量的原子操作和位原子操作。

- 整型变量的原子操作：**通过`ldrex`和`strex`来实现**
- 位原子操作：**通过中断屏蔽来实现。**




<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>
