# ⚡ 快速参考卡片

> 常用命令和配置的速查表

## 🚀 基本命令

### 项目配置
```bash
# Debug版本（快速编译，便于调试）
cmake -B build-debug -G Ninja -DCMAKE_BUILD_TYPE=Debug

# Release版本（最高性能，启用LTO）
cmake -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release

# MinSizeRel版本（最小体积）
cmake -B build-size -G Ninja -DCMAKE_BUILD_TYPE=MinSizeRel
```

### 编译构建
```bash
# 增量编译
cmake --build build-debug

# 清理重编译
cmake --build build-debug --clean-first

# 并行编译（使用所有CPU核心）
cmake --build build-debug --parallel

# 详细输出
cmake --build build-debug --verbose
```

### 固件分析
```bash
# 查看固件大小
llvm-size build/firmware.elf

# 查看段信息
llvm-size -A build/firmware.elf

# 符号表（按大小排序）
llvm-nm --size-sort build/firmware.elf

# 反汇编
llvm-objdump -d build/firmware.elf > disasm.txt
```

## 🔥 烧录调试

### probe-rs（推荐）
```bash
# 烧录并运行
probe-rs run --chip STM32G431CBTx build/firmware.elf

# 仅烧录
probe-rs download --chip STM32G431CBTx build/firmware.elf

# 启动调试会话
probe-rs attach --chip STM32G431CBTx

# 实时日志（RTT）
probe-rs rtt --chip STM32G431CBTx
```

### OpenOCD（传统）
```bash
# 烧录HEX
openocd -f interface/stlink.cfg -f target/stm32g4x.cfg \
        -c "program build/firmware.hex verify reset exit"

# 启动调试服务器
openocd -f interface/stlink.cfg -f target/stm32g4x.cfg
```

### STM32CubeProgrammer
```bash
# 烧录HEX
STM32_Programmer_CLI -c port=SWD -w build/firmware.hex -v -rst

# 烧录BIN（指定地址）
STM32_Programmer_CLI -c port=SWD -w build/firmware.bin 0x08000000 -v -rst
```

## 📝 CMakeLists.txt模板

### 基础模板
```cmake
cmake_minimum_required(VERSION 3.20)
set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/cmake/pure-llvm-toolchain.cmake)

project(my-project C ASM)
set(CMAKE_C_STANDARD 17)

# 芯片定义
add_definitions(-DSTM32G431xx)

# 源文件
set(SOURCES
    Core/Src/main.c
    Core/Src/stm32g4xx_it.c
    # ... 其他源文件
    startup_stm32g431xx.s
)

# 头文件目录
target_include_directories(${PROJECT_NAME} PRIVATE
    Core/Inc
    Drivers/STM32G4xx_HAL_Driver/Inc
    Drivers/CMSIS/Device/ST/STM32G4xx/Include
    Drivers/CMSIS/Include
)

# 链接脚本
target_link_options(${PROJECT_NAME} PRIVATE
    -T${CMAKE_CURRENT_SOURCE_DIR}/STM32G431CBTX_FLASH.ld
    -Wl,-Map=${PROJECT_NAME}.map
)

# 生成固件文件
add_firmware_targets(${PROJECT_NAME})
```

### 高级优化
```cmake
# 编译器优化
target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<CONFIG:Release>:-O3 -flto>
    $<$<CONFIG:Debug>:-O0 -g3>
    $<$<CONFIG:MinSizeRel>:-Os>
)

# 链接器优化
target_link_options(${PROJECT_NAME} PRIVATE
    $<$<CONFIG:Release>:-flto -Wl,--lto-O3>
    -Wl,--gc-sections
    -Wl,--print-memory-usage
)
```

## 🎯 常用芯片配置

### STM32G4系列
```cmake
# STM32G431CBTx
add_definitions(-DSTM32G431xx)
# 启动文件: startup_stm32g431xx.s
# 链接脚本: STM32G431CBTX_FLASH.ld

# STM32G474RETx  
add_definitions(-DSTM32G474xx)
# 启动文件: startup_stm32g474xx.s
# 链接脚本: STM32G474RETX_FLASH.ld
```

### STM32F4系列
```cmake
# STM32F407VGTx
add_definitions(-DSTM32F407xx)
# 启动文件: startup_stm32f407xx.s
# 链接脚本: STM32F407VGTX_FLASH.ld

# STM32F411CEUx
add_definitions(-DSTM32F411xE)
# 启动文件: startup_stm32f411xe.s
# 链接脚本: STM32F411CEUX_FLASH.ld
```

## 🐛 故障排除

### 编译错误
```bash
# 找不到头文件
fatal error: 'xxx.h' file not found
→ 检查 target_include_directories()

# 未定义的引用
undefined reference to `xxx`
→ 检查源文件列表，添加缺失的.c文件

# 链接脚本错误
cannot open linker script file
→ 检查.ld文件路径和名称
```

### 运行时错误
```bash
# 程序不启动
→ 检查启动文件 startup_xxx.s
→ 检查芯片型号定义 -DSTM32xxx
→ 检查时钟配置

# HardFault异常
→ 启用调试信息：-DCMAKE_BUILD_TYPE=Debug
→ 使用probe-rs或GDB调试
```

### 性能问题
```bash
# 编译慢
→ 使用并行编译：--parallel
→ 使用Ninja生成器：-G Ninja
→ 检查防病毒软件排除

# 固件太大
→ 使用MinSizeRel构建类型
→ 启用链接器垃圾回收：-Wl,--gc-sections
→ 移除未使用的HAL模块
```

## 📊 性能基准

### 编译速度（我的实测）
```
项目类型          传统工具    LLVM工具链    提升倍数
简单LED闪烁       8秒        0.5秒        16x
HAL GPIO项目      15秒       2秒          7.5x
复杂多模块项目    45秒       5秒          9x
```

### 代码大小对比
```
优化级别    Flash使用    RAM使用     编译时间
Debug      12KB        2KB         最快
Release    8KB         1.5KB       中等  
MinSizeRel 6KB         1.2KB       较慢
```

## 🔧 环境变量

### 临时设置（当前会话）
```bash
# Windows
set PATH=E:\cmake\bin;E:\LLVM\bin;E:\ninja;%PATH%

# Linux/macOS
export PATH="/usr/local/llvm/bin:/usr/local/cmake/bin:$PATH"
```

### 永久设置
```bash
# Windows: 系统设置 → 环境变量 → PATH
# Linux: ~/.bashrc 或 ~/.zshrc
# macOS: ~/.bash_profile 或 ~/.zshrc
```

## 🎯 最佳实践

1. **项目结构标准化** - 使用统一目录布局
2. **版本控制** - Git管理代码和配置
3. **构建类型分离** - Debug/Release分别构建
4. **并行编译** - 充分利用多核CPU
5. **定期清理** - 避免构建缓存问题

**保存这个参考卡片，随时查阅！** 📋
