# 🚀 2025年最强STM32工具链使用指南

> 从零开始，手把手教你使用纯LLVM工具链开发STM32项目

## 🎯 使用前准备

### 确认工具链安装
```bash
# 检查所有工具是否正常
cmake --version    # 应显示 4.1.0-rc2
clang --version    # 应显示 19.1.6
ninja --version    # 应显示 1.12+
rustc --version    # 应显示 1.88.0
```

如果有工具显示"不是内部或外部命令"，请参考 [INSTALLATION.md](INSTALLATION.md) 重新安装。

## 📂 方式一：从现有STM32CubeMX项目开始（推荐）

### 1. 准备STM32CubeMX项目
```bash
# 假设你已经有一个STM32CubeMX生成的项目
cd your-stm32-project/
ls
# 应该看到：
# Core/          # 源码目录
# Drivers/       # HAL驱动
# *.ioc          # CubeMX项目文件
# startup_*.s    # 启动文件
# *.ld           # 链接脚本
```

### 2. 复制工具链配置文件
```bash
# 从我们的仓库复制工具链配置
mkdir cmake
cp /path/to/ultimate-stm32-toolchain/cmake/pure-llvm-toolchain.cmake cmake/
```

### 3. 创建CMakeLists.txt
在项目根目录创建 `CMakeLists.txt`：

```cmake
cmake_minimum_required(VERSION 3.20)

# 设置工具链文件
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/pure-llvm-toolchain.cmake)

# 项目定义
project(my-stm32-project C ASM)

# 设置C标准
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

# 收集所有源文件
file(GLOB_RECURSE SOURCES
    "Core/Src/*.c"
    "Drivers/STM32G4xx_HAL_Driver/Src/*.c"
    "startup_stm32g431xx.s"  # 根据你的芯片修改
)

# 头文件目录
set(INCLUDE_DIRS
    Core/Inc
    Drivers/STM32G4xx_HAL_Driver/Inc
    Drivers/STM32G4xx_HAL_Driver/Inc/Legacy
    Drivers/CMSIS/Device/ST/STM32G4xx/Include
    Drivers/CMSIS/Include
)

# 创建可执行文件
add_executable(${PROJECT_NAME} ${SOURCES})

# 设置包含目录
target_include_directories(${PROJECT_NAME} PRIVATE ${INCLUDE_DIRS})

# 链接脚本（根据你的芯片修改文件名）
set_target_properties(${PROJECT_NAME} PROPERTIES
    LINK_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/STM32G431CBTX_FLASH.ld
)

# 链接器标志
target_link_options(${PROJECT_NAME} PRIVATE
    -T${CMAKE_CURRENT_SOURCE_DIR}/STM32G431CBTX_FLASH.ld
    -Wl,-Map=${PROJECT_NAME}.map
)

# 生成固件文件 (HEX, BIN)
add_firmware_targets(${PROJECT_NAME})
```

### 4. 第一次构建
```bash
# 配置项目
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug

# 构建项目
cmake --build build

# 如果成功，你会看到：
# build/my-stm32-project.elf
# build/my-stm32-project.hex
# build/my-stm32-project.bin
```

## 📂 方式二：从零开始创建新项目

### 1. 创建项目目录结构
```bash
mkdir my-new-stm32-project
cd my-new-stm32-project

# 创建标准目录结构
mkdir -p src include cmake
```

### 2. 复制必要文件
```bash
# 复制工具链配置
cp /path/to/ultimate-stm32-toolchain/cmake/pure-llvm-toolchain.cmake cmake/

# 你需要从STM32CubeMX或其他项目获取：
# - startup_stm32g431xx.s (启动文件)
# - STM32G431CBTX_FLASH.ld (链接脚本)
# - STM32 HAL库文件
```

### 3. 创建简单的main.c
```c
// src/main.c
#include <stdint.h>

// 简单的延时函数
void delay(uint32_t count) {
    for (uint32_t i = 0; i < count; i++) {
        __asm__("nop");
    }
}

int main(void) {
    // 主循环
    while (1) {
        delay(1000000);
    }
    return 0;
}
```

### 4. 创建CMakeLists.txt
```cmake
cmake_minimum_required(VERSION 3.20)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/pure-llvm-toolchain.cmake)

project(my-new-project C ASM)

add_executable(${PROJECT_NAME}
    src/main.c
    startup_stm32g431xx.s
)

target_include_directories(${PROJECT_NAME} PRIVATE include)

set_target_properties(${PROJECT_NAME} PROPERTIES
    LINK_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/STM32G431CBTX_FLASH.ld
)

target_link_options(${PROJECT_NAME} PRIVATE
    -T${CMAKE_CURRENT_SOURCE_DIR}/STM32G431CBTX_FLASH.ld
)

add_firmware_targets(${PROJECT_NAME})
```

## 🔧 日常开发工作流

### 1. 修改代码
使用VS Code或任何编辑器修改源码

### 2. 快速编译
```bash
# 增量编译（只编译修改的文件）
cmake --build build

# 清理重新编译
cmake --build build --clean-first
```

### 3. 不同构建类型
```bash
# 调试版本（编译快，便于调试）
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug

# 发布版本（最高性能，启用LTO）
cmake -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release

# 体积优化版本（最小固件大小）
cmake -B build-size -DCMAKE_BUILD_TYPE=MinSizeRel
cmake --build build-size
```

### 4. 查看编译结果
```bash
# 查看固件大小
llvm-size build/my-project.elf

# 查看内存映射
cat build/my-project.map

# 反汇编查看生成的代码
llvm-objdump -d build/my-project.elf > disasm.txt
```

## 🔍 烧录和调试

### 方法1：使用probe-rs（推荐）
```bash
# 烧录固件
probe-rs run --chip STM32G431CBTx build/my-project.elf

# 启动调试会话
probe-rs attach --chip STM32G431CBTx

# 实时日志输出（需要在代码中配置RTT）
probe-rs rtt --chip STM32G431CBTx
```

### 方法2：使用OpenOCD（传统方式）
```bash
# 烧录HEX文件
openocd -f interface/stlink.cfg -f target/stm32g4x.cfg \
        -c "program build/my-project.hex verify reset exit"

# 启动调试服务器
openocd -f interface/stlink.cfg -f target/stm32g4x.cfg
```

### 方法3：使用STM32CubeProgrammer
```bash
# 烧录HEX文件
STM32_Programmer_CLI -c port=SWD -w build/my-project.hex -v -rst
```

## ⚡ 性能优化技巧

### 1. 编译器优化选项
```cmake
# 在CMakeLists.txt中添加
target_compile_options(${PROJECT_NAME} PRIVATE
    -O3                    # 最高优化
    -flto                  # 链接时优化
    -ffast-math           # 快速数学运算
    -funroll-loops        # 循环展开
)
```

### 2. 链接器优化
```cmake
target_link_options(${PROJECT_NAME} PRIVATE
    -flto                 # 链接时优化
    -Wl,--gc-sections     # 移除未使用代码
    -Wl,--lto-O3         # LTO优化级别
)
```

### 3. 代码大小优化
```cmake
# 体积优化构建
set(CMAKE_C_FLAGS_MINSIZEREL "-Os -DNDEBUG -flto")
```

## 🐛 常见问题解决

### 问题1：找不到头文件
```bash
# 错误：fatal error: 'stm32g4xx_hal.h' file not found
# 解决：检查include路径
target_include_directories(${PROJECT_NAME} PRIVATE
    Drivers/STM32G4xx_HAL_Driver/Inc
    # 添加缺失的路径
)
```

### 问题2：链接错误
```bash
# 错误：undefined reference to `_start`
# 解决：检查启动文件和链接脚本
add_executable(${PROJECT_NAME}
    src/main.c
    startup_stm32g431xx.s  # 确保包含启动文件
)
```

### 问题3：编译速度慢
```bash
# 使用并行编译
cmake --build build --parallel

# 或指定线程数
cmake --build build --parallel 8
```

### 问题4：调试信息缺失
```bash
# Debug构建包含调试信息
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug
```

## 📊 性能监控

### 编译时间测试
```bash
# 测试编译速度
time cmake --build build --clean-first

# 我的实测结果：
# 简单项目：2-3秒
# 复杂HAL项目：5-8秒
# 比传统ARM GCC快10-15倍！
```

### 代码大小分析
```bash
# 详细大小分析
llvm-size -A build/my-project.elf

# 符号大小排序
llvm-nm --size-sort build/my-project.elf
```

## 🎯 下一步学习

1. **学习CMake高级用法** - 模块化构建
2. **掌握probe-rs调试** - 现代化调试体验
3. **尝试Rust嵌入式开发** - 更安全的系统编程
4. **集成CI/CD** - 自动化构建和测试

## 💡 最佳实践

1. **项目结构标准化** - 使用统一的目录结构
2. **版本控制** - 用Git管理代码和配置
3. **文档化** - 记录项目配置和依赖
4. **测试驱动** - 编写单元测试验证功能
5. **性能监控** - 定期检查编译时间和代码大小

**享受极速的STM32开发体验！** ⚡
