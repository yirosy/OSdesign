1352829	孙杨	一班    yiro
1352826	刘兆意	一班    LzyfuckSy
1352844	曹鑫博	一班    OliverJiawen
项目URL：https://gitcafe.com/yiro/OSdesign.git
项目说明：
    项目：修改或重新实现参考源码的一个或多个模块
样例BUG修复：
    ALT按键识别BUG：
	文件：kernel/keyboard.c
	函数：keyboard_read(TTY* p_tty)
	行：186
	错误：alt_r打成了alt_l
	错误：alt额外产生了一个break，原因不明，暂时使用shift来实现试图切换
