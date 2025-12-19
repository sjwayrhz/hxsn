在serverless平台可以启动ubuntu-xfce桌面系统

## 举例Zeabur

核心部署参数 (Zeabur 面板)
在 Zeabur 部署时选择 "Deploy Container"，填写以下信息：

### Docker Image

- accetto/ubuntu-vnc-xfce-g3
- Port (端口):
- 添加一个端口：6901
- 类型：HTTP

### Environment Variables

- VNC_PW: password
- VNC_RESOLUTION: 1280x720
- START_XFCE4: yes

然后设置一个Domain，再打开的时候输入密码是password就可以了
