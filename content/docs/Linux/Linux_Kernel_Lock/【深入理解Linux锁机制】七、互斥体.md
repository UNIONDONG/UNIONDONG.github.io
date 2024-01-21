---
date: '2024-01-18T23:03:38+08:00'
title:       '【深入理解Linux锁机制】七、互斥体'
description: ""
author:      "Donge"
image:       ""
tags:        ["内核锁", "Linux 锁机制", "操作系统锁"," Linux 系统开发","Linux 内核"]
categories:  ["Tech" ]
bookToc: false
weight: 7
---

<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/202206141400958.jpeg" alt="0c70cff6aab3f2894c2bfd2c973e9620" alt="img"  width = 15% height =15%/></div>

<center><font color ="grey">我的圈子：<a href="https://t.zsxq.com/14hPUwE8z">
高级工程师聚集地</a></font></center>

<center><b> 创作理念：专注分享高质量嵌入式文章，让大家读有所得！</b></center>

<div align=center><img src="https://bdn.135editor.com/files/images/editor_styles/d1c723e7e296ca791c2fb3b39ebee0f3.jpg" alt="img" width = 70% height =10%/>
</div>

<br>
<br>
&nbsp;
亲爱的读者，你好：

&emsp;&emsp;感谢你对我的专栏的关注和支持，我很高兴能和你分享我的知识和经验。如果你喜欢我的内容，想要阅读更多的精彩技术文章，可以扫码加入我的社群。

&nbsp;
<center><b> <font color ="blue">欢迎关注【嵌入式艺术】，董哥原创！</font></b></center>
<div align=center><img src="https://image-1305421143.cos.ap-nanjing.myqcloud.com/image/blog.png" alt="img" width = "60%" height ="10%"/>
</div>

