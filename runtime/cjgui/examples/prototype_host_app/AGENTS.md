<!-- cjgui-app-dev:begin -->
<!-- cjgui-app-dev:generated content-sha256=92fc1d30993ce465676663618b960130f73b7ba974f1236e17fc600df52b1210 template-sha256=6b2fc7c3ac6b2aeee8faf23120897685f3e3879b504e45a5d26c563e5c6c2051 -->
## CJGUI 应用开发入口

任务涉及创建、修改、构建或诊断 CJGUI 消费方应用，或查询应用所用版本的公开 API 时，先加载
`cjgui-app-dev` 技能；现有项目的 `cjpm.toml` 直接/间接依赖 CJGUI、workspace 成员使用 CJGUI，
或应用源码 `import cjgui.*` 都可作为识别线索，新建应用不要求先已有这些文件。
宿主没有按名调用能力时，直接读取 [CJGUI 应用开发技能](<../../skills/cjgui-app-dev/SKILL.md>) 并按需加载指南。
若此链接因迁移失效，沿当前应用依赖定位所用 SDK 的 `skills/cjgui-app-dev/SKILL.md`，
或读取宿主已安装的同名技能；不自行改用最新 SDK。

已有应用先识别实际依赖，workspace 的成员发现不等于默认构建选择；新应用先选定 SDK 建项再识别。
先查同版用法，再开发与验证；有价值的阻碍保留事实、身份和复现，待筛选为框架缺陷、易用性改进或无需框架处理。
纯框架内核、native 后端或治理修改按框架项目规则执行，不因出现 CJGUI 名称就加载应用技能；
混合任务只在应用消费部分使用。按任务对象判断，不把应用的 `src/*.cj` 排除在外。
<!-- cjgui-app-dev:end -->
