# CleanMyMac（学习原型）

一个用 **Swift + SwiftUI** 编写的 macOS 系统清理工具原型，模仿 CleanMyMac 的核心思路。当前为学习/演示用途，不是完整产品。

## 功能模块

| 模块 | 说明 |
| --- | --- |
| 系统垃圾 | 扫描用户/系统缓存、日志、Xcode 派生数据、临时文件与废纸篓，按需清理 |
| 大文件与旧文件 | 递归扫描桌面、文稿、下载等目录，按大小阈值和未修改天数列出文件 |
| 卸载器 | 扫描 `/Applications`、`~/Applications` 等，展示应用体积与残留文件，一键卸载 |
| 重复文件 | 按「相同大小 + SHA-256 内容哈希」分组查找完全相同的文件 |

## 环境要求

- macOS 14.0+（Apple Silicon / Intel 均可）
- Xcode 15+（本机为 Xcode 27.2 / Swift 6.4）

## 构建与运行

```bash
# 调试构建并运行
swift run CleanMyMac

# 冒烟测试（无界面，打印扫描结果，验证核心逻辑）
swift run CleanMyMac --smoke-test

# 打包成可双击的 .app
./scripts/make-app.sh
open build/CleanMyMac.app
```

## 项目结构

```
Sources/CleanMyMac/
├── App/            # App 入口与 NSApplicationDelegate
├── Models/         # ScannedFile 等数据模型
├── Support/        # FileUtils、SmokeTest
├── Services/       # 四个扫描器（纯逻辑，无 UI）
├── ViewModels/     # @Observable 视图模型
└── Views/          # SwiftUI 界面
```

## 设计与安全说明

- 所有清理操作默认**移入废纸篓**（`FileManager.trashItem`），废纸篓内的项执行「清空」时才永久删除，最大程度避免误删。
- 扫描都在后台 `Task.detached` 中执行，不阻塞主线程。
- 删除 `~/Library`、`/Library` 下的系统缓存/日志可能需要**管理员或「完全磁盘访问」权限**，无权限时对应项会跳过或删除失败（界面会提示失败数量）。
- 重复文件扫描只对「大小相同」的文件做哈希，减少不必要的 I/O。

## 局限与后续方向

- 尚未做：内存优化、恶意软件扫描、隐私清理、空间透镜（Space Lens）、实时磁盘监控、App 图标/签名/公证。
- 大目录全量扫描可能较慢，后续可加进度、取消、增量缓存与更精细的权限处理。
- 本项目与 MacPaw 的 CleanMyMac 无关，仅用于学习。

## 免责声明

请勿在生产/重要数据环境直接使用删除功能。清理前请核对勾选项；本原型不对误删数据负责。
