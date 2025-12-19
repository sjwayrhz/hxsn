文件上传到

```
https://filebin.net/
```

可以保存7天  
如果文件很多，就会产生很多条直链，用javascript语言可以复制

**第一步：切换到 Console（控制台**
在弹出的工具窗口顶部菜单栏中，找到并点击 "Console"（中文通常显示为“控制台”）。

你会看到一个闪烁的光标，这里就是输入代码的地方。

**第二步：解除粘贴限制（如果遇到）**
如果你是第一次在某个浏览器上粘贴代码，可能会看到一行警告信息，并且无法直接粘贴。这是浏览器为了防止你被诈骗脚本攻击而设定的保护。

解决方法：在光标处手动输入 allow pasting（允许粘贴），然后按下 回车键 (Enter)。

完成这一步后，你就可以像平时一样使用 Ctrl + V（Mac 为 Cmd + V）进行粘贴了。

**第三步：粘贴并运行代码**
将我之前提供的那段提取链接的脚本复制下来。

在 Console 光标处粘贴。

按下 回车键 (Enter) 运行脚本。

```
// 获取页面上所有的文件下载链接
var links = [];
document.querySelectorAll('a[href*="/' + window.location.pathname.split('/')[1] + '/"]').forEach(function(el) {
    if (el.href.includes(window.location.host) && !el.href.endsWith('/tar') && !el.href.endsWith('/zip')) {
        links.push(el.href);
    }
});

// 过滤掉重复项并打印结果
var uniqueLinks = [...new Set(links)];
console.log("共找到 " + uniqueLinks.length + " 个文件链接：");
console.log(uniqueLinks.join('\n'));

// 自动复制到剪贴板
copy(uniqueLinks.join('\n'));
alert("所有链接已成功复制到剪贴板！");
```
