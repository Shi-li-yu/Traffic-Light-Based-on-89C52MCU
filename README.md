# Traffic-Light-Based-on-89C52MCU

### Proteus Simulation Video:
[http://https://www.bilibili.com/video/av39625094](http://https://www.bilibili.com/video/av39625094)
### Achievement Demonstration:
[http://https://www.bilibili.com/video/av39772128](http://https://www.bilibili.com/video/av39772128)
### Proteus:
![](https://i.imgur.com/APCsanW.png)

### Mode Interpretation


- 启动之后工作在红绿灯倒计时的循环模式，绿灯倒计时3s时会进行闪烁，提醒过往车辆,黄灯恒为5s。
（In the beginning,the controller is in the working mode.The Green Light will flicker when its time is less then 3s.The duration for yellow light is constant 5 seconds. ）

-  按下按键Stop 进入设置模式，up键按一次红灯绿灯时长各增加5s,down键按一次，各减5s（红绿灯的时长会显示在数码管上）
（Press key 'Stop' for set mode,and press 'UP' and 'DOWN'key to adjust the duration of red and green light.UP: +5s,down:-5s. The actual duration while be displayed on nixie tube.）

- 完成设置之后，再次按下stop键，则以设置的时长为基础进行倒计时工作
(Press key 'STOP'again for work mode.The following working will be based on the setting result.)

### Main Flow Chart
![](https://i.imgur.com/RMt6lo1.png)

### Flow Chart for  the Flashing of the  Green Light
![](https://i.imgur.com/YPITWR1.png)

