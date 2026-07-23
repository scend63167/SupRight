# v0.1.0 测试版发布流程

## 目标

发布一个未签名、未公证的 GitHub 测试包，供愿意手动绕过 Gatekeeper 的 macOS 用户试用。

## 构建

```zsh
./Scripts/package-beta.sh
```

脚本输出：

- `dist/SupRight-v0.1.0-macos-unsigned.zip`
- `dist/SupRight-v0.1.0-macos-unsigned.zip.sha256`

## 发布前检查

1. 解压 ZIP，确认内部仅包含 `SupRight.app`。
2. 在干净 macOS 用户账户或另一台 Mac 上测试安装。
3. 完成首次“仍要打开”和完全磁盘访问授权。
4. 验证 Finder 右键、所有预设文件、自定义文件、复制、Terminal、语言和功能开关。
5. 在 GitHub Release 中明确标记为“未签名、未公证测试版”。

发布说明可直接参考根目录的 [CHANGELOG.md](../CHANGELOG.md)。

## 正式发布的后续步骤

当项目进入正式 `v1.0.0` 时，加入 Apple Developer Program，使用 Developer ID 签名、启用 Hardened Runtime、提交 Apple 公证，然后发布公证后的 ZIP 或 DMG。
