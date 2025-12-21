在 Ubuntu 24.04 上安装官方 Docker-CE、启动服务并允许当前用户免 sudo 运行

```
curl -fsSL https://get.docker.com | sudo sh && sudo usermod -aG docker $USER && newgrp docker
```
