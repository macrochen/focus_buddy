# FocusBuddy 设计文档

## 文档信息
- 项目名称：focus_buddy_app
- 应用名称：FocusBuddy
- 开发平台：iOS
- 文档日期：2025年2月23日

## 1. 项目概述

### 1.1 目标用户
- 13岁7年级学生

### 1.2 项目目标
- 帮助学生管理时间
- 减少走神，提高专注力
- 培养良好的时间管理习惯
- 通过音乐播放提升学习体验

## 2. 系统架构

### 2.1 总体架构

#### 前端
- 使用SwiftUI实现用户界面
- 提供直观、响应式的交互体验

#### 后端逻辑
- 本地处理所有业务逻辑
  - 任务管理
  - 计时功能
  - 数据统计
  - 音乐播放

#### 数据存储
- 使用Core Data存储
  - 任务数据
  - 中断记录
  - 积分信息
  - 音乐元数据

#### 外部框架
- Speech框架/SiriKit：语音识别
- UserNotifications：任务提醒
- AVFoundation：音乐播放
- FileManager：音乐文件管理
- Vision框架（可选）：AI辅助OCR扫描

### 2.2 模块划分

1. 任务管理模块
   - 任务的创建、编辑
   - 任务分类
   - 状态管理

2. 计时与中断模块
   - 专注时间记录
   - 中断监控
   - 音乐播放控制

3. 时间预估模块
   - 预估时间输入
   - 实际时间记录
   - 对比分析

4. 奖励系统模块
   - 积分计算
   - 奖励兑换
   - 成就管理

5. 语音控制模块
   - 语音添加任务
   - 语音控制计时

6. 家长监控模块
   - 数据查看
   - 奖励设置
   - 音乐管理

7. 游戏化模块（可选）
   - 虚拟宠物
   - 主题自定义

## 3. 界面设计

### 3.1 主界面（任务列表）

#### 布局
- 顶部
  - 标题"FocusBuddy"
  - "添加任务"按钮
- 中部
  - 任务列表（按截止日期排序）
  - 展示任务标题、状态和截止时间
- 底部
  - 导航栏（任务、统计、奖励、设置）

#### 交互
- 点击任务：进入详情页面
- 长按任务：编辑或删除

### 3.2 任务详情页面

#### 布局
- 任务标题
- 描述
- 截止日期
- 预估时间输入框
- "开始计时"按钮

#### 交互
- 点击"开始计时"：进入计时页面

### 3.3 计时页面

#### 布局
- 顶部：任务标题
- 中部：专注时间进度条（实时更新）
- 下部
  - "暂停"/"继续"按钮
  - "完成"按钮
- 音乐控制区
  - 播放/暂停按钮
  - 当前曲目名称
  - 切换曲目按钮
- 中断理由选择（可选）
  - 喝水
  - 上厕所
  - 其他

#### 交互
- 暂停：记录中断时间
- 恢复：继续计时
- 音乐控制：与计时同步暂停/播放

### 3.4 统计页面

#### 布局
- 图表区域
  - 专注时间柱状图
  - 中断时长统计
  - 预估vs实际时间对比
- 数据区域
  - 中断次数
  - 音乐使用情况
  - 中断理由分析（可选）

#### 交互
- 时间范围切换（当天/当周）

### 3.5 奖励页面

#### 布局
- 积分余额显示
- 可用奖励列表
  - 奖励名称
  - 所需积分
  - 兑换按钮
- 成就展示区

#### 交互
- 兑换：扣除积分并记录

### 3.6 家长监控页面

#### 布局
- 顶部：密码输入区
- 中部
  - 任务完成情况
  - 专注时间统计
  - 中断数据
  - 音乐使用情况
- 下部
  - 奖励设置区域
  - 音乐管理区域

#### 交互
- 密码验证：解锁查看和编辑功能
- 音乐导入：调用文件选择器

### 3.7 设置页面（可选）

#### 布局
- 主题选择
  - 颜色设置
  - 背景选择
- 虚拟宠物设置

#### 交互
- 主题切换：实时预览
- 宠物样式：即时更新

## 4. 技术要求

### 4.1 开发环境
- 语言：Swift
- UI框架：SwiftUI
- 数据存储：Core Data

### 4.2 外部框架
- Speech：语音识别实现
- UserNotifications：任务提醒功能
- AVFoundation：音乐播放控制
- FileManager：音乐文件管理
- Vision（可选）：AI预估时间OCR

## 5. 功能实现细节

### 5.1 任务管理模块

#### 数据结构
```swift
@objc(Task)
class Task: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var description: String
    @NSManaged var category: String
    @NSManaged var deadline: Date
    @NSManaged var estimatedTime: Int // 分钟
    @NSManaged var actualTime: Int // 分钟
    @NSManaged var status: String // 未开始、进行中、已完成
}
```

#### 实现方式
- 使用SwiftUI的List展示任务列表
- Form视图实现任务创建和编辑

### 5.2 计时与中断模块

#### 数据结构
```swift
@objc(FocusSession)
class FocusSession: NSManagedObject {
    @NSManaged var taskId: UUID
    @NSManaged var startTime: Date
    @NSManaged var endTime: Date?
    @NSManaged var interruptions: NSSet? // 一对多关系
    @NSManaged var usedMusic: Bool
    @NSManaged var musicTrack: String?
}

@objc(Interruption)
class Interruption: NSManagedObject {
    @NSManaged var startTime: Date
    @NSManaged var duration: Int // 秒
    @NSManaged var reason: String? // 可选理由
    @NSManaged var session: FocusSession? // 反向关系
}
```

#### 实现方式
- Timer类实现计时功能
- AVAudioPlayer实现音乐播放
- 计时暂停时同步暂停音乐
- Core Data存储中断记录

### 5.3 时间预估与对比

#### 实现方式
- Task实体存储预估和实际时间
- Charts框架绘制对比图表
- AI预估（可选）
  - Vision框架识别作业内容
  - 基于历史数据计算预估

### 5.4 奖励与激励系统

#### 数据结构
```swift
@objc(Reward)
class Reward: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var pointsRequired: Int
}

@objc(User)
class User: NSManagedObject {
    @NSManaged var points: Int
    @NSManaged var rewardsClaimed: NSSet?
    @NSManaged var achievements: [String]
}
```

#### 实现方式
- 任务完成后积分累加
- List展示可用奖励
- Button触发兑换操作

### 5.5 语音识别

#### 实现方式
- SFSpeechRecognizer监听语音输入
- 转换为任务标题或计时命令

### 5.6 家长监控

#### 数据结构
```swift
@objc(MusicTrack)
class MusicTrack: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var filePath: String
}
```

#### 实现方式
- SecureField实现密码输入
- UIDocumentPickerViewController导入音乐
- FileManager管理音乐文件

### 5.7 游戏化元素（可选）

#### 实现方式
- SwiftUI动画实现虚拟宠物
- EnvironmentObject管理主题

## 6. 开发计划

### 6.1 第一阶段：核心功能
1. 任务管理模块
2. 计时功能
3. 基础音乐播放

### 6.2 第二阶段：功能扩展
1. 中断管理
2. 统计分析
3. 语音控制

### 6.3 第三阶段：完善系统
1. 奖励系统
2. 家长监控
3. 音乐管理

### 6.4 最终阶段：优化改进
1. UI/UX优化
2. 性能优化
3. 游戏化元素（可选）

## 7. 总结

FocusBuddy应用通过结合任务管理、专注计时、音乐播放和家长监控等功能，为目标用户提供了一个完整的学习辅助解决方案。使用Core Data确保了数据管理的灵活性，新增的音乐功能满足了用户习惯，同时通过家长监控确保了内容的适当性。建议从核心的任务管理和计时功能开始开发，逐步实现其他功能模块。