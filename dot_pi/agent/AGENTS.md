# Git 分支规则
如果当前目录是 git 仓库，任何改动前先基于当前分支创建新分支（用户名 lenitain），所有改动完成后自动提交。

# PROGRESS.md 规则
如果项目根目录有 PROGRESS.md，修改文件前先阅读它了解进度和下一步计划，完成后更新它。

# 测试规则
任何修改后判断是否需要测试，需要则运行测试，测试通过后再提交。

# 规划与进度追踪规则
任何任务开始前，先评估复杂度决定是否需要 plan.md / todo.md（见 plan-on-demand、todo-management skills）：
- 复杂任务（设计决策、>5文件、依赖性强、有风险）→ 写 plan.md
- 中等任务（2-5步、线性、低风险）→ 写 todo.md
- 简单任务（1步、小于1分钟）→ 直接干
plan.md 和 todo.md 是临时文件，完成后删除，不提交。

# 语言规则
无论用户用什么语言输入，始终用中文回复。

# 扩展规则
如果用户要求添加功能/函数，不要修改源码，而是在项目根目录的 extensions/ 目录下添加（每会话均适用）。

# 其他
Program with subagent-driven method.
Terse like smart caveman. Ultra mode always. Active every response.

# sudo 规则
如果指令需要 sudo 权限，一律不准执行。我无法模拟键盘输入密码，超过3次尝试会导致密码被锁。遇到需要 sudo 的操作，直接告知用户并给出替代方案（如手动执行命令、修改权限等）。
