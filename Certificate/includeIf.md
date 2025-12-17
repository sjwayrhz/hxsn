# includeIf 使用方法介绍

功能描述：允许 Git 根据当前仓库所在的文件夹路径，自动决定是否加载某一份特定的配置文件。

假设我有两个github账号，一个是sjwayrhz，另外一个是hsitj，现在希望设置两个目录供给他们使用，其中：

```
D:\Projects-hsitj 属于hsitj使用
D:\Projects-sjwayrhz 属于sjwayrhz使用
```

两个 SSH key 路径分别是：

```
~/.ssh/id_rsa_sjwayrhz
~/.ssh/id_rsa_hsitj
```

以windows的administrator为例，配置文件的存放位置位于`C:\Users\Administrator`，也就是需要将当前目录文件拷贝到

```
C:\Users\Administrator\.gitconfig
C:\Users\Administrator\.gitconfig-hsitj
C:\Users\Administrator\.gitconfig-sjwayrhz
C:\Users\Administrator\.ssh\id_rsa_hsitj
C:\Users\Administrator\.ssh\id_rsa_sjwayrhz
```

然后进入目录`D:\Projects-hsitj`下创建的项目使用的就是hsitj的配置信息

进入目录`D:\Projects-sjwayrhz`下创建的项目使用的就是sjwayrhz的配置信息

# 文件举例

第一类文件

## .gitconfig

```
[core]
    autocrlf = true
[includeIf "gitdir/i:D:/Projects-sjwayrhz/"]
    path = ~/.gitconfig-sjwayrhz
[includeIf "gitdir/i:D:/Projects-hsitj/"]
    path = ~/.gitconfig-hsitj
```

第二类文件

## .gitconfig-hsitj

```
[user]
    name = hsitj
    email = sjwayrhz@hotmail.com
[core]
    sshCommand = "ssh -i ~/.ssh/id_rsa_hsitj"
```

第二类文件

## .gitconfig-sjwayrhz

```
[user]
    name = sjwayrhz
    email = sjwayrhz@gmail.com
[core]
    sshCommand = "ssh -i ~/.ssh/id_rsa_sjwayrhz"
```

第三类文件

## .ssh/id_rsa_hsitj

```
key of hsitj
```

第三类文件

## .ssh/id_rsa_sjwayrhz

```
key of hsitj
```
