<p align="center">
<img src="https://raw.githubusercontent.com/felangel/mason/master/assets/mason_full.png" height="125" alt="mason logo" />
</p>

<p align="center">
<a href="https://pub.dev/packages/mason_cli"><img src="https://img.shields.io/pub/v/mason_cli.svg" alt="Pub"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://github.com/felangel/mason/workflows/mason_cli/badge.svg" alt="mason"></a>
<a href="https://github.com/felangel/mason/actions"><img src="https://raw.githubusercontent.com/felangel/mason/master/packages/mason_cli/coverage_badge.svg" alt="coverage"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/felangel/mason"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge" alt="Powered by Mason"></a>
</p>

---

[![en](https://img.shields.io/badge/language-english-cyan.svg)](https://github.com/felangel/mason/blob/master/packages/mason_cli/README.md)

Mason CLI 允许开发人员创建和使用称为 bricks 的复用模板，这些模板由 [mason](https://pub.dev/packages/mason) 生成器支援。

![Mason Demo][mason_demo]

## 快速開始

```sh
# 🎯 Activate from https://pub.dev
dart pub global activate mason_cli

# 🚀 Initialize mason
mason init

# 📦 Install your first brick
mason add hello

# 🧱 Use your first brick
mason make hello
```

---

## 目录

- [快速開始](#快速開始)
- [目录](#目录)
- [概述](#概述)
  - [安裝](#安裝)
  - [初始化](#初始化)
  - [命令变量](#命令变量)
  - [变量提示](#变量提示)
  - [输入变量的配置文件](#输入变量的配置文件)
  - [自定义输出目录](#自定义输出目录)
  - [解决文件冲突](#解决文件冲突)
- [创建新的 Bricks](#创建新的-bricks)
- [磚塊 YAML](#磚塊-yaml)
  - [磚塊模板](#磚塊模板)
    - [嵌套模板（部分）](#嵌套模板部分)
    - [内置 Lambda](#内置-lambda)
    - [在生成后检测变化](#在生成后检测变化)
    - [自定義腳本執行（Hooks）](#自定義腳本執行hooks)
      - [Hooks 使用](#hooks-使用)
- [寻找砖块](#寻找砖块)
  - [搜索用法](#搜索用法)
- [添加砖块](#添加砖块)
  - [添加用法](#添加用法)
- [移除砖块](#移除砖块)
  - [删除用法](#删除用法)
- [列出已安装的砖块](#列出已安装的砖块)
  - [列表用法](#列表用法)
- [升级砖块](#升级砖块)
  - [升级使用](#升级使用)
- [捆绑](#捆绑)
  - [捆绑使用](#捆绑使用)
- [解绑](#解绑)
  - [解绑使用](#解绑使用)
- [登录](#登录)
  - [登录使用](#登录使用)
- [登出](#登出)
  - [注销使用](#注销使用)
- [发布砖块](#发布砖块)
  - [发布用法](#发布用法)
- [完整用法](#完整用法)
- [视频教程](#视频教程)

## 概述

### 安裝

```sh
# 🎯 从 https://pub.dev 激活
dart pub global activate mason_cli

# 🍺 或者从 https://brew.sh 安装
brew tap felangel/mason
brew install mason
```

### 初始化

```sh
mason init
```

`mason init` 在当前目录中初始化 Mason CLI。

运行 `mason init` 会生成一个 `mason.yaml`，以便您可以立即开始。

```yaml
# Register bricks which can be consumed via the Mason CLI.
# Run "mason get" to install all registered bricks.
# To learn more, visit https://docs.brickhub.dev.
bricks:
  # Bricks can be imported via version constraint from a registry.
  # Uncomment the following line to import the "hello" brick from BrickHub.
  # hello: 0.1.0+1
  # Bricks can also be imported via remote git url.
  # Uncomment the following lines to import the "widget" brick from git.
  # widget:
  #   git:
  #     url: https://github.com/felangel/mason.git
  #     path: bricks/widget
```

例如，我们可以取消注释“hello”砖 (`hello: 0.1.0+1`):

```yaml
bricks:
  hello: 0.1.0+1
```

要在 `mason.yaml` 中載入所有积木，请运行：

```sh
mason get
```

然后你可以使用 `mason make` 来生成你的第一个檔案：

```sh
mason make hello
```

❗ 注意：**不要**提交 .mason 目录。使用版本化的砖块时(git/hosted)，**请**提交 mason-lock.json 檔案。

### 命令变量

任何变量都可以作为命令参数传递。

```sh
mason make hello --name Felix
```

### 变量提示

任何未指定为命令参数的变量都会提示用户要输入。

```sh
mason make hello
name: Felix
```

### 输入变量的配置文件

可以通过配置文件传递任何指定变量：

```dart
mason make hello -c config.json
```

其中的 `config.json` 內容：

```json
{
  "name": "Felix"
}
```

上述命令将在当前目录中生成 `HELLO.md` 檔案，其内容如下：

```md
Hello Felix!
```

### 自定义输出目录

默认情况下，`mason make` 将在当前工作目录中生成模板代碼，但也可以通过 `-o` 选项指定输出目录：

```sh
mason make hello --name Felix -o ./path/to/directory
```

### 解决文件冲突

默认情况下，`mason make` 将在每个檔案冲突时提示用户，并允许用户通过 `Yyna` 指定如何解决冲突：

```txt
y - 是的，覆盖（默认）
Y - 是的，覆盖这个和其他
n - 不要，不覆盖
a - 新增到现有檔案
```

可以通过 `--on-conflict` 选项指定檔案冲突的解决策略：

```sh
# 在冲突时提示（默认）
mason make hello --name Felix --on-conflict prompt

# 在冲突时覆盖
mason make hello --name Felix --on-conflict overwrite

# 在冲突时跳过
mason make hello --name Felix --on-conflict skip

# 在冲突时新增
mason make hello --name Felix --on-conflict append
```

## 创建新的 Bricks

使用 `mason new` 命令创建一个新的 Brick。

```sh
# 在当前目录中生成新的 Brick。
mason new <BRICK_NAME>

# 生成一个带有自定义描述的 Brick。
mason new <BRICK_NAME> --desc "我的超棒新 Brick！"

# 生成一个带有 hooks 的 Brick。
mason new <BRICK_NAME> --hooks

# 在自定义路径中生成新的 Brick。
mason new <BRICK_NAME> --output-dir ./path/to/brick

# 在自定义路径的缩写语法中生成新的 Brick。
mason new <BRICK_NAME> -o ./path/to/brick
```

## 磚塊 YAML

`brick.yaml` 包含了 brick 模板的配置資料。

```yaml
name: example
description: An example brick

# 以下定义了 brick 的版本和构建编号。
# 版本号是由三个用点分隔的数字组成的，例如 1.2.34
# 随后是可选的构建编号（由 + 分隔）。
version: 0.1.0+1

# 以下定义了当前 brick 的环境。
# 它包括 brick 所需的 mason 版本。
environment:
  mason: ">=0.1.0-dev <0.1.0"

# 变量指定了 Brick 依赖的动态值。
# 对于给定的 Brick，可以指定零个或多个变量。
# 每个变量有：
#  * 一个类型（字符串、数字、布尔、枚举或数组）
#  * 一个可选的简短描述
#  * 一个可选的默认值
#  * 一个可选的默认值列表（仅适用于数组）
#  * 在询问变量时使用的可选提示文字
#  * 一组值（仅适用于枚举）
vars:
  name:
    type: string
    description: Your name.
    default: Dash
    prompt: What is your name?
```

### 磚塊模板

使用 [mustache 模板](https://mustache.github.io/) 在 **brick** 目录中编写您的磚塊模板。 有关详细的使用信息，请参阅 [mustache 手册](https://mustache.github.io/mustache.5.html)。

`__brick__/example.md`

```md
# Hello {{name}}!
```

❗ **注意：`__brick__` 可以包含多个文件和子目录**

❗ **注意：当您希望 `variable` 的值不被转义时，请使用 `{{{variable}}}` 代替 `{{variable}}`**

#### 嵌套模板（部分）

可以将模板嵌套在其他模板中。 例如，以下结构：

```
├── HELLO.md
├── {{~ footer.md }}
└── {{~ header.md }}
```

`{{~ header.md }}` 和 `{{~ footer.md }}` 是局部的（局部模板）。 不会生成，但可以作为现有模板的一部分。

舉例分别設置`{{~ header.md }}`和`{{~ footer.md }}`的内容

```md
# 🧱 {{name}}
```

```md
_made with 💖 by mason_
```

我们可以通过 `{{> header.md }}` 和 `{{> footer.md }}` 将部分内容嵌入为模板的一部分。

像此例子中的 “HELLO.md”：

```md
{{> header.md }}

Hello {{name}}!

{{> footer.md }}
```

我们可以使用 `mason make hello --name Felix` 来生成 `HELLO.md`：

```md
# 🧱 Felix

Hello Felix!

_made with 💖 by mason_
```

❗ **注意：嵌套部分可以像常规模板一样包含变量**

####档案解析

可以使用 `{{% %}}` 标签根据路径输入变量解析档案。

例如，设置以下“brick.yaml”：

```yaml
name: app_icon
description: Create an app icon file from a URL
version: 0.1.0+1
vars:
  url:
    type: string
    description: The app icon URL.
    prompt: Enter your app icon URL.
```

以下积木模板：

`__brick__/{{% url %}}`

运行 `mason make app_icon --url path/to/icon.png` 将生成包含 `path/to/icon.png` 内容的 `icon.png`，其中 `path/to/icon.png` 可以是本地或远程路径。 查看 [app icon example brick](https://github.com/felangel/mason/tree/master/bricks/app_icon) 示例。

#### 内置 Lambda

Mason 支持一些内置的 lambda，可以帮助自定义生成的代码：

| Name           | Example             | Shorthand Syntax              | Full Syntax                                      |
| -------------- | ------------------- | ----------------------------- | ------------------------------------------------ |
| `camelCase`    | `helloWorld`        | `{{variable.camelCase()}}`    | `{{#camelCase}}{{variable}}{{/camelCase}}`       |
| `constantCase` | `HELLO_WORLD`       | `{{variable.constantCase()}}` | `{{#constantCase}}{{variable}}{{/constantCase}}` |
| `dotCase`      | `hello.world`       | `{{variable.dotCase()}}`      | `{{#dotCase}}{{variable}}{{/dotCase}}`           |
| `headerCase`   | `Hello-World`       | `{{variable.headerCase()}}`   | `{{#headerCase}}{{variable}}{{/headerCase}}`     |
| `lowerCase`    | `hello world`       | `{{variable.lowerCase()}}`    | `{{#lowerCase}}{{variable}}{{/lowerCase}}`       |
| `mustacheCase` | `{{ Hello World }}` | `{{variable.mustacheCase()}}` | `{{#mustacheCase}}{{variable}}{{/mustacheCase}}` |
| `pascalCase`   | `HelloWorld`        | `{{variable.pascalCase()}}`   | `{{#pascalCase}}{{variable}}{{/pascalCase}}`     |
| `paramCase`    | `hello-world`       | `{{variable.paramCase()}}`    | `{{#paramCase}}{{variable}}{{/paramCase}}`       |
| `pathCase`     | `hello/world`       | `{{variable.pathCase()}}`     | `{{#pathCase}}{{variable}}{{/pathCase}}`         |
| `sentenceCase` | `Hello world`       | `{{variable.sentenceCase()}}` | `{{#sentenceCase}}{{variable}}{{/sentenceCase}}` |
| `snakeCase`    | `hello_world`       | `{{variable.snakeCase()}}`    | `{{#snakeCase}}{{variable}}{{/snakeCase}}`       |
| `titleCase`    | `Hello World`       | `{{variable.titleCase()}}`    | `{{#titleCase}}{{variable}}{{/titleCase}}`       |
| `upperCase`    | `HELLO WORLD`       | `{{variable.upperCase()}}`    | `{{#upperCase}}{{variable}}{{/upperCase}}`       |

_示例用法_

以下示例：

```
__brick__
  ├── {{name.snakeCase()}}.md
  └── {{name.pascalCase()}}.java
```

`brick.yaml`:

```yaml
name: example
description: An example brick.
version: 0.1.0+1
vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
```

我们可以通过以下方式生成代码：

```sh
mason make example --name my-name
```

输出将是：

```
├── my_name.md
└── MyName.java
```

#### 在生成后检测变化

Mason 支持通过 `--set-exit-if-changed` 验证 `mason make` 没有更改任何档案。 这在持续集成 (CI) 环境中通常很有用，可确保所有生成的代码都是最新的。

```sh
# fail with exit code 70 if any files were changed
mason make example --name Dash --set-exit-if-changed
```

#### 自定義腳本執行（Hooks）

Mason 支持通過 `hooks` 執行自定義腳本。 支持的 Hooks 是：

- `pre_gen` - 在生成步驟之前立即執行
- `post_gen` - 在生成步驟後立即執行

必須在 brick 根目錄的 hooks 目錄中定義：

```
├── __brick__
├── brick.yaml
└── hooks
    ├── post_gen.dart
    ├── pre_gen.dart
    └── pubspec.yaml
```

❗ 目前 mason 只支持用 [Dart](https://dart.dev) 写的 hooks。

##### Hooks 使用

每个钩子都必须包含一个 run 方法，该方法接受来自 `package:mason/mason.dart` 的 `HookContext`。

例如，以下`示例`：

```sh
.
├── __brick__
│   └── example.md
├── brick.yaml
└── hooks
    ├── post_gen.dart
    └── pubspec.yaml
```

`brick.yaml` 看起来像：

```yaml
name: example
description: An example brick.
version: 0.1.0+1
vars:
  name:
    type: string
    description: Your name
    default: Dash
    prompt: What is your name?
```

`pubspec.yaml` 看起来像：

```yaml
name: example_hooks

environment:
  sdk: ">=2.12.0 <3.0.0"

dependencies:
  mason: any
```

`post_gen.dart` 包含：

```dart
import 'package:mason/mason.dart';

void run(HookContext context) {
  context.logger.info('hello {{name}}!');
}
```

运行 `mason make example --name Dash` 的结果：

```sh
mason make example --name Dash
✓ Made brick example (0.0s)
✓ Generated 1 file:
  /Users/dash/mason/example/example.md (new)
hello Dash!
```

💡 **注意**：脚本可以包含模板变量。 另外，脚本的工作目录就是生成代码的目录。

`HookContext` 可用于访问/修改 brick `vars` 或与 logger 交互。

```dart
import 'package:mason/mason.dart';

void run(HookContext context) {
  // Read/Write vars
  context.vars = {...context.vars, 'custom_var': 'foo'};

  // Use the logger
  context.logger.info('hook says hi!');
}
```

可以使用 --no-hooks 标志禁用钩子执行：

```sh
# Disable hook script execution
mason make example --name Dash --no-hooks
```

## 寻找砖块

`search` 命令允许开发人员在 https://brickhub.dev 上搜索已发布的砖块。

### 搜索用法

```sh
# 搜索与“bloc”相关的砖块
mason search bloc
```

## 添加砖块

`add` 命令允许开发人员从本地路径或 git url 在本地或全局添加 brick 模板。 默认情况下，`mason add` 将在本地添加模板，但可以通过提供 `--global` (`-g`) 标志在全局添加砖块。

### 添加用法

```sh
# add latest version from registry
mason add my_brick

# add latest version from registry (global)
mason add --global my_brick

# add version 0.1.0 from registry
mason add my_brick 0.1.0

# add version 0.1.0 from registry (global)
mason add --global my_brick 0.1.0

# add from registry shorthand syntax (global)
mason add -g my_brick

# add from path
mason add my_brick --path ./path/to/my_brick

# add from path (global)
mason add --global my_brick --path ./path/to/my_brick

# add from path shorthand syntax (global)
mason add -g my_brick --path ./path/to/my_brick

# add from git url
mason add my_brick --git-url https://github.com/org/repo

# add from git url (global)
mason add -g my_brick --git-url https://github.com/org/repo

# add from git url with path
mason add my_brick --git-url https://github.com/org/repo --git-path path/to/my_brick

# add from git url with path and ref
mason add my_brick --git-url https://github.com/org/repo --git-path path/to/my_brick --git-ref tag-name
```

添加砖块后，可以通过 `mason make` 命令使用它：

```sh
mason make <BRICK_NAME>
```

## 移除砖块

可以使用 `remove` 命令移除。 使用 `--global` (`-g`) 标志移除全局砖块。

### 删除用法

```sh
# 移除砖块
mason remove <BRICK_NAME>

# 移除砖块（全局）
mason remove -g <BRICK_NAME>
```

## 列出已安装的砖块

所有安装的砖块都可以通过 `list`（简称 `ls`）命令查看。

### 列表用法

```sh
# 列出所有本地安装的砖块
mason list

# 列出所有全局安装的砖块
mason list --global

# 使用别名 “ls” 而不是 “list” 作为速记语法
mason ls

# 列出所有全局安装的速记语法
mason ls -g
```

## 升级砖块

已安装的 bricks 可以通过 upgrade 命令升级到最新版本。

### 升级使用

```sh
# 升级所有本地砖块并生成新的 mason-lock.json
mason upgrade

# 升级所有全局砖块
mason upgrade --global

# 升级所有全局砖速记语法
mason upgrade -g
```

## 捆绑

您可以使用 mason 为现有模板生成一个包。 对于您希望将模板作为独立 CLI 的一部分，捆绑包很方便。 [非常好的 CLI](https://github.com/VeryGoodOpenSource/very_good_cli) 是一个很好的例子。

目前有两种类型的捆绑包：

1. Universal - 一个与平台无关的包
2. Dart - 一个特定于 Dart 的包

### 捆绑使用

要生成一个包：

```sh
# 从本地块创建一个通用包。
mason bundle ./path/to/brick -o ./path/to/destination

# 从本地 brick 创建一个 dart bundle。
mason bundle ./path/to/brick -t dart -o ./path/to/destination

# 从 git brick 创建一个通用包。
mason bundle --source git https://github.com/:org/:repo -o ./path/to/destination

# 从 git brick 创建一个 dart 包。
mason bundle --source git https://github.com/:org/:repo -t dart -o ./path/to/destination

# 从托管的 brick 创建一个通用包。
mason bundle --source hosted <BRICK_NAME> -o ./path/to/destination

# 从托管的 brick 创建一个 dart 包。
mason bundle --source hosted <BRICK_NAME> -t dart -o ./path/to/destination
```

然后可以使用 bundle 以编程方式从 brick 生成代码：

```dart
// 从现有的 bundle 创建一个 MasonGenerator。
final generator = MasonGenerator.fromBundle(...);

// 根据捆绑的 brick 生成代码。
await generator.generate(...);
```

## 解绑

您可以使用 mason 从现有包中生成砖块。 在您想要更改现有捆绑包的情况下，取消捆绑很有用，因为您可以先取消捆绑，对模板进行更改，然后生成新的捆绑包。

### 解绑使用

要从现有包生成块模板：

```sh
# 通用包
mason unbundle ./path/to/bundle -o ./path/to/destination/

# Dart包
mason unbundle ./path/to/bundle -t dart -o ./path/to/destination/
```

## 登录

您可以通过 `登录` 命令使用注册帐户登录。

### 登录使用

```sh
# 使用邮箱和密码登录
mason login
```

## 登出

您可以通过 `logout` 命令注销帐户。

### 注销使用

```sh
# 注销当前账号
mason logout
```

## 发布砖块

您可以通过 `publish` 命令发布砖块。 您必须使用经过验证的电子邮件地址登录帐户才能发布。

❗ **注意：砖块一旦发布，将永远无法取消发布。**

### 发布用法

```sh
# 在当前目录下发布砖块
mason publish

# 从自定义路径发布砖块
mason publish --directory ./path/to/brick

# 使用速记语法从自定义路径发布砖块
mason publish -C ./path/to/brick
```

## 完整用法

```sh
mason
🧱  mason • lay the foundation!

Usage: mason <command> [arguments]

Global options:
-h, --help       Print this usage information.
    --version    Print the current version.

Available commands:
  add        Adds a brick from a local or remote source.
  bundle     Generates a bundle from a brick template.
  cache      Interact with mason cache.
  get        Gets all bricks in the nearest mason.yaml.
  init       Initialize mason in the current directory.
  list       Lists installed bricks.
  login      Log into brickhub.dev.
  logout     Log out of brickhub.dev.
  make       Generate code using an existing brick template.
  new        Creates a new brick template.
  publish    Publish the current brick to brickhub.dev.
  remove     Removes a brick.
  search     Search published bricks on brickhub.dev.
  unbundle   Generates a brick template from a bundle.
  update     Update mason.
  upgrade    Upgrade bricks to their latest versions.

Run "mason help <command>" for more information about a command.
```

## 视频教程

[![Mason Video Tutorial](https://img.youtube.com/vi/SnrHoN632NU/0.jpg)](https://www.youtube.com/watch?v=SnrHoN632NU)

**Say HI to Mason Package! - The Top Tier Code Generation Tool | Complete Tutorial** by [_Flutterly_](https://www.youtube.com/channel/UC5PYcSe3to4mtm3SPCUmjvw)

[mason_demo]: https://raw.githubusercontent.com/felangel/mason/master/assets/mason_demo.gif
