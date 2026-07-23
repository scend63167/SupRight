# 贡献指南

感谢你愿意改进 SupRight。

## 提交问题

请说明：

- macOS 版本与 SupRight 版本
- 复现步骤、预期结果和实际结果
- Finder 右键菜单是否出现
- 是否已授予完全磁盘访问
- 相关截图或错误信息（请先移除隐私信息）

## 提交代码

1. 从 `main` 创建分支。
2. 保持改动聚焦，并更新相关文档。
3. 运行一次构建检查：

   ```zsh
   xcodebuild -project SupRight.xcodeproj -scheme SupRight -configuration Debug CODE_SIGNING_ALLOWED=NO build
   ```

4. 在 Finder 中手动验证受影响的右键菜单操作。
5. 提交 Pull Request，说明改动、动机与验证方式。

请勿提交证书、私钥、个人路径、授权数据、构建产物或未脱敏的截图。
