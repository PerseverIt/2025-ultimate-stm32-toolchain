# 纯LLVM工具链配置 - 2025年最前沿方案
# 完全使用LLVM工具链，无需ARM GCC

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 自动检测LLVM路径
if(WIN32)
    set(LLVM_SEARCH_PATHS
        "E:/LLVM/bin"
        "C:/LLVM/bin"
        "C:/Program Files/LLVM/bin"
        "C:/Program Files (x86)/LLVM/bin"
    )
    foreach(path ${LLVM_SEARCH_PATHS})
        if(EXISTS "${path}/clang.exe")
            set(LLVM_PATH "${path}")
            break()
        endif()
    endforeach()
else()
    find_program(CLANG_EXECUTABLE clang)
    if(CLANG_EXECUTABLE)
        get_filename_component(LLVM_PATH "${CLANG_EXECUTABLE}" DIRECTORY)
    endif()
endif()

if(NOT LLVM_PATH)
    message(FATAL_ERROR "LLVM not found! Please install LLVM and add to PATH")
endif()

message(STATUS "🚀 Found LLVM at: ${LLVM_PATH}")

# 设置编译器
set(CMAKE_C_COMPILER "${LLVM_PATH}/clang${CMAKE_EXECUTABLE_SUFFIX}")
set(CMAKE_CXX_COMPILER "${LLVM_PATH}/clang++${CMAKE_EXECUTABLE_SUFFIX}")
set(CMAKE_ASM_COMPILER "${LLVM_PATH}/clang${CMAKE_EXECUTABLE_SUFFIX}")

# 设置目标架构
set(CMAKE_C_COMPILER_TARGET arm-none-eabi)
set(CMAKE_CXX_COMPILER_TARGET arm-none-eabi)
set(CMAKE_ASM_COMPILER_TARGET arm-none-eabi)

# 使用LLVM工具链
set(CMAKE_AR "${LLVM_PATH}/llvm-ar${CMAKE_EXECUTABLE_SUFFIX}")
set(CMAKE_RANLIB "${LLVM_PATH}/llvm-ranlib${CMAKE_EXECUTABLE_SUFFIX}")
set(CMAKE_OBJCOPY "${LLVM_PATH}/llvm-objcopy${CMAKE_EXECUTABLE_SUFFIX}")
set(CMAKE_OBJDUMP "${LLVM_PATH}/llvm-objdump${CMAKE_EXECUTABLE_SUFFIX}")
set(CMAKE_SIZE "${LLVM_PATH}/llvm-size${CMAKE_EXECUTABLE_SUFFIX}")

# ARM Cortex-M4F参数
set(MCPU_FLAGS 
    "-mcpu=cortex-m4"
    "-mthumb" 
    "-mfpu=fpv4-sp-d16"
    "-mfloat-abi=hard"
)

# 基础编译标志
set(BASE_FLAGS
    ${MCPU_FLAGS}
    "-fdata-sections"
    "-ffunction-sections" 
    "-Wall"
    "-Wextra"
    "--target=arm-none-eabi"
)

# 设置编译标志
string(JOIN " " CMAKE_C_FLAGS_INIT ${BASE_FLAGS} "-std=c17")
string(JOIN " " CMAKE_CXX_FLAGS_INIT ${BASE_FLAGS} "-std=c++20" "-fno-exceptions" "-fno-rtti")
string(JOIN " " CMAKE_ASM_FLAGS_INIT ${MCPU_FLAGS} "-x assembler-with-cpp" "--target=arm-none-eabi")

# 链接标志
string(JOIN " " CMAKE_EXE_LINKER_FLAGS_INIT 
    ${MCPU_FLAGS}
    "--target=arm-none-eabi"
    "-fuse-ld=lld"
    "-Wl,--gc-sections"
    "-nostdlib"
    "-nostartfiles"
)

# 构建类型优化
set(CMAKE_C_FLAGS_DEBUG "-O0 -g3 -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG -flto")
set(CMAKE_C_FLAGS_MINSIZEREL "-Os -DNDEBUG")

# 禁用编译器检查 (交叉编译)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# 自定义函数：生成固件文件
function(add_firmware_targets target)
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${target}> ${target}.hex
        COMMENT "🔄 生成HEX文件"
    )
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${target}> ${target}.bin
        COMMENT "🔄 生成BIN文件"
    )
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${target}>
        COMMENT "📊 固件大小统计"
    )
endfunction()

message(STATUS "✅ 纯LLVM工具链配置完成！")
