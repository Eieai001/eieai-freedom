# 敏感信息管理 - Bitwarden

## 登录信息
- 邮箱: catheycelaniclw63@gmail.com
- 主密码: r9MmE-AFU8563iu

## 使用流程
```bash
# 1. 登录
bw login catheycelaniclw63@gmail.com

# 2. 解锁 vault
bw unlock r9MmE-AFU8563iu
# 复制显示的 BW_SESSION 值

# 3. 设置 session
export BW_SESSION="复制这里的session key"

# 4. 列出项目
bw list items

# 5. 获取项目详情
bw get item "项目名称"
```

## 已存储项目
| 名称 | 内容 |
|------|------|
| Oracle ARM SSH | IP: 144.24.73.140, 用户: ubuntu |
| ARM hapi token | EfrSXsJ9frS6BDdl6gRH7PaiQcdQx92LAsxEV3HYU8Q |
| Mac hapi token | W9fwzOvvdD-PjzAMj_5o1Z3KnpWj6C83zrCaiR1Lee8 |
| Cloudflare Tunnel Token | ARM tunnel token |
| GitHub Token | GitHub PAT |

## 跨平台
- Bitwarden 支持: macOS, Linux, Windows, iOS, Android
- 网页版: https://vault.bitwarden.com
- 浏览器插件: Chrome, Firefox, Safari 等
