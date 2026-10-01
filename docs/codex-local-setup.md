# Codex 本地配置 / Local setup

仓库根目录就是工作区：`main.py`、`src/`、`SKILL.md`、`run.ps1` 和 `.git/` 位于同一级，不需要额外的 `repo/` 子目录。根目录的 `.venv/` 保存 Python 环境，`.env` 保存本地配置，`.local/` 保存安装清单等机器记录，`.cache/` 保存可复用缓存；这些本地目录和配置不提交到 Git。

The repository root is the workspace. Keep the source tree in its upstream layout, with the local Python environment in `.venv/`. `.env`, `.local/`, and `.cache/` are local, ignored state.

## 环境与帮助 / Environment and help

已有环境可直接运行帮助。新环境可从仓库根目录执行：

For a fresh Windows checkout, create the environment from the repository root. Skip the installation commands when the environment is already available.

```powershell
py -3.11 -m venv .venv
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\run.ps1 --help
```

`run.ps1` 自动切换到它所在的仓库根目录，使用该目录的 `.venv\Scripts\python.exe`，为子进程指定根目录 `.env`，退出后恢复调用方的工作目录和 `ENV_FILE`。不传参数也只显示帮助；它不会代替用户选择股票或启动分析。直接运行 `python main.py` 的默认行为不同，可能开始分析。

The wrapper uses this checkout's interpreter and configuration, then restores the caller's directory and `ENV_FILE`. No arguments means help. A bare `python main.py` can start analysis and is not an equivalent setup check.

## 配置与调用边界 / Configuration and execution boundaries

只在 `.env` 不存在时从 `.env.example` 创建它；保留已有配置。按 [LLM 配置指南](LLM_CONFIG_GUIDE.md) 选择模型后端和对应凭据，按需配置股票列表及数据源。首次安装只验证帮助；帮助成功不表示模型凭据、行情接口或通知服务已验证。不要打印或提交 `.env`。

Create `.env` from `.env.example` only when it does not already exist. Configure the chosen model backend before an analysis request. Help verifies the entry point, not live model, market-data, or notification access.

若使用仓库内的 tokenizer 缓存，两个变量都应相对根目录配置，因为 LiteLLM 可能用 `CUSTOM_TIKTOKEN_CACHE_DIR` 覆盖 `TIKTOKEN_CACHE_DIR`：

For a repository-local tokenizer cache, set both variables:

```dotenv
TIKTOKEN_CACHE_DIR=./.cache/tiktoken
CUSTOM_TIKTOKEN_CACHE_DIR=./.cache/tiktoken
```

缓存目录存在不代表编码文件已缓存；首次导入相关组件仍可能下载文件。`LITELLM_LOCAL_MODEL_COST_MAP=True` 只选择本地模型价目表，不阻止 tokenizer 下载。直接使用 Python 服务时，在导入前设置根目录 `ENV_FILE`，并使用仓库根目录作为工作目录。

An empty cache does not make imports offline. The local model-cost-map option controls a separate resource. Set `ENV_FILE` and the working directory before importing the Python service when bypassing the wrapper.

`--dry-run` 仍会获取行情，且启用的大盘复盘可能继续调用模型，不能当作无 API 调用的安装验证。`--no-notify` 控制通知推送，但不禁止已配置的飞书云文档创建；`perform_market_review(notifier=None)` 会回退到配置中的通知服务。用户仅请求本地分析时，检查通知和云文档配置，确保运行只执行已授权的外部动作。

`--dry-run` can fetch data and run an enabled market review. `--no-notify` does not disable configured Feishu document creation, and a `None` notifier in the market-review service can fall back to configured notifications. Check these settings against the user's requested scope before running analysis.

## 全局 Skill 注册 / Global skill registration

将全局 Skill 目录中的 `stock_analyzer` 链接到这个仓库根目录，避免另存一份源码。Windows 可从仓库根目录创建目录联接；以下命令会在注册位置已经存在时停止，先核对已有注册再处理：

Register `stock_analyzer` as a link to this checkout so the skill and source remain one copy. This Windows example stops if a registration already exists.

```powershell
$repoRoot = (Resolve-Path .).Path
$codexRoot = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path $env:USERPROFILE '.codex'
}
$skillRoot = Join-Path $codexRoot 'skills'
$skillPath = Join-Path $skillRoot 'stock_analyzer'
if (Test-Path -LiteralPath $skillPath) {
    throw 'A skill registration already exists; inspect it before replacing it.'
}
New-Item -ItemType Directory -Path $skillRoot -Force | Out-Null
New-Item -ItemType Junction -Path $skillPath -Target $repoRoot
```

注册后，Codex 下次读取 Skill 时会读取本仓库的 `SKILL.md`，源码修改也直接用于后续运行，无需再次复制安装。新注册可在下一回合发现；若当前回合已加载旧指令，下一回合重新读取。移动仓库时同步更新链接目标。Linux/macOS 可使用同等目录符号链接。

Subsequent skill reads and runs use this checkout directly. A new registration is available on the next turn; previously loaded instructions need to be read again. Update the link target if the checkout moves. Use a directory symlink on Linux/macOS.

## Fork 工作流 / Fork workflow

`origin` 指向自己的 fork，`upstream` 指向 `ZhuLinsen/daily_stock_analysis`。从 fork 克隆后，如尚无 `upstream`，可添加：

Keep `origin` as your fork and `upstream` as the source project. Add `upstream` only if it is absent:

```powershell
git remote add upstream https://github.com/ZhuLinsen/daily_stock_analysis.git
git remote -v
git fetch upstream
git status --short
git diff --stat upstream/main...HEAD
```

同步前检查本地改动与分支差异，再选择适合当前分支的更新方式。提交时只选取需要发布的源码、脚本和文档，不使用强制添加将 `.env`、`.venv/`、`.local/`、`.cache/` 或报告加入提交。将已审查的提交推送到 `origin`；是否向上游创建 PR 单独决定。协作规则以 [AGENTS.md](../AGENTS.md) 为准。

Review local changes and branch divergence before updating. Stage the intended source and documentation explicitly, keep local state ignored, and push reviewed commits to `origin`. Opening an upstream pull request is a separate action; follow the repository's `AGENTS.md`.
