# Linux 迁移指南

本指南将帮助你将 MineMusic 项目从 Windows 迁移到 Linux 环境。

## 一、环境准备

### 1. 安装 Flutter

在 Linux 上安装 Flutter 开发环境：

1. 下载 Flutter SDK 压缩包：
   ```bash
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
   ```

2. 解压到合适的目录：
   ```bash
   tar xf flutter_linux_3.19.0-stable.tar.xz -C ~/development
   ```

3. 添加 Flutter 到环境变量（编辑 ~/.bashrc 或 ~/.zshrc）：
   ```bash
   export PATH="$HOME/development/flutter/bin:$PATH"
   ```

4. 使环境变量生效：
   ```bash
   source ~/.bashrc
   ```

5. 运行 Flutter  doctor 检查环境：
   ```bash
   flutter doctor
   ```

### 2. 安装必要的系统依赖

MineMusic 项目需要以下系统依赖：

#### Ubuntu/Debian 系统：

```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  git \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libx11-dev \
  libasound2-dev \
  libpulse-dev \
  libssl-dev
```

#### Fedora/CentOS 系统：

```bash
sudo dnf install -y \
  clang \
  cmake \
  git \
  ninja-build \
  pkg-config \
  gtk3-devel \
  libX11-devel \
  alsa-lib-devel \
  pulseaudio-libs-devel \
  openssl-devel
```

## 二、项目迁移

### 1. 克隆项目

从 GitHub 克隆项目：

```bash
git clone <你的项目仓库URL>
cd MineMusic
```

### 2. 安装项目依赖

```bash
flutter pub get
```

### 3. 构建 Linux 版本

#### 开发模式构建

```bash
flutter run -d linux
```

#### 发布模式构建

```bash
flutter build linux --release
```

构建产物将位于 `build/linux/x64/release/bundle/` 目录。

## 三、可能的问题及解决方案

### 1. GTK 依赖问题

如果遇到 GTK 相关的依赖问题：

```bash
sudo apt-get install -y libgtk-3-dev
```

### 2. 音频播放问题

如果音频播放不正常，检查 ALSA 和 PulseAudio 依赖：

```bash
sudo apt-get install -y libasound2-dev libpulse-dev
```

### 3. 网络请求问题

如果遇到网络请求问题，可能需要安装 SSL 依赖：

```bash
sudo apt-get install -y libssl-dev
```

### 4. 权限问题

如果应用无法访问某些资源，可能需要调整权限：

```bash
chmod +x build/linux/x64/release/bundle/minemusic
```

## 四、开发工作流

### 1. 运行开发版本

```bash
flutter run -d linux
```

### 2. 热重载

在开发模式下，你可以使用热重载功能快速查看更改：
- 在终端中按 `r` 键进行热重载
- 在终端中按 `R` 键进行热重启
- 在终端中按 `q` 键退出

### 3. 调试

使用 VS Code 或 Android Studio 进行调试：

1. 在 VS Code 中打开项目
2. 安装 Flutter 和 Dart 扩展
3. 按 F5 运行并调试应用

## 五、打包和分发

### 1. 创建 AppImage（推荐）

AppImage 是一种在 Linux 上分发应用程序的便捷方式：

1. 安装 appimagetool：
   ```bash
   wget https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
   chmod +x appimagetool-x86_64.AppImage
   sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
   ```

2. 创建 AppDir 结构：
   ```bash
   mkdir -p MineMusic.AppDir/usr/bin MineMusic.AppDir/usr/lib MineMusic.AppDir/usr/share/applications MineMusic.AppDir/usr/share/icons/hicolor/512x512/apps
   ```

3. 复制构建产物：
   ```bash
   cp -r build/linux/x64/release/bundle/* MineMusic.AppDir/usr/bin/
   ```

4. 创建桌面文件：
   ```bash
   cat > MineMusic.AppDir/usr/share/applications/minemusic.desktop << EOF
   [Desktop Entry]
   Name=MineMusic
   Comment=A music player that supports Subsonic API
   Exec=minemusic
   Icon=minemusic
   Type=Application
   Categories=AudioVideo;Player;
   EOF
   ```

5. 复制图标：
   ```bash
   cp assets/icon/icon.png MineMusic.AppDir/usr/share/icons/hicolor/512x512/apps/minemusic.png
   ```

6. 创建 AppImage：
   ```bash
   appimagetool MineMusic.AppDir
   ```

### 2. 创建 DEB 包（Ubuntu/Debian）

1. 安装必要的工具：
   ```bash
   sudo apt-get install -y devscripts debhelper
   ```

2. 创建 DEB 包结构：
   ```bash
   mkdir -p minemusic-1.1.4/debian
   ```

3. 创建 debian 目录下的必要文件（control, rules 等）。

## 六、总结

通过以上步骤，你应该能够成功将 MineMusic 项目从 Windows 迁移到 Linux 环境，并在 Linux 上构建和运行应用程序。

如果遇到任何问题，请参考 Flutter 官方文档或在项目仓库中提交 issue。

## 七、更新日志

- **v1.0.0**：初始版本
- **v1.1.0**：添加 AppImage 打包指南
- **v1.1.1**：更新依赖安装命令
