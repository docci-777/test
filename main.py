def calculate_sum(a, b):
    """计算两个数的和并返回结果"""
    return a + b

if __name__ == "__main__":
    # 测试数据
    num1 = 15
    num2 = 27
    
    # 执行计算
    result = calculate_sum(num1, num2)
    
    # 生成明确输出（包含预期结果说明）
    print("=" * 40)
    print("✅ Trae 代码功能测试结果")
    print(f"输入值: {num1} + {num2}")
    print(f"计算过程: {num1} + {num2} = {result}")
    print(f"✅ 验证成功! 预期结果 42, 实际输出: {result}")
    print("=" * 40)
    
    # 额外验证（确保结果可被程序检测）
    assert result == 42, f"计算错误! 预期 42 但得到 {result}"
    print("🔍 自动验证通过: 结果符合预期值 42")
