// 中文维护注释：这是 CJGUI minimal UI framework demo 复用用的 experimental domain evidence value model。
// Scope: 用 typed value 承载 layout / controls / served / reuse 语义事实，减少 demo-local 裸字符串模板。
// Stop-line: 只保存 demo process-local 脱水字符串，不写 runtime_state / renderer_state，不调用 native bridge，不扩 public C ABI。
package cjgui.demo_support

/// Experimental demo support API：布局语义 evidence value。
public class CjguiExperimentalDemoLayoutEvidence {
    /// 布局事实值保持脱水字符串，供现有 stdout evidence 兼容消费。
    public let layoutValue: String

    public init(layoutValue: String) {
        this.layoutValue = layoutValue
    }

    /// 转换为现有 `layout` fact value。
    public func factValue(): String {
        return layoutValue
    }
}

/// Experimental demo support API：控件语义 evidence value。
public class CjguiExperimentalDemoControlsEvidence {
    /// 控件事实值保持脱水字符串，供现有 stdout evidence 兼容消费。
    public let controlsValue: String

    public init(controlsValue: String) {
        this.controlsValue = controlsValue
    }

    /// 转换为现有 `controls` fact value。
    public func factValue(): String {
        return controlsValue
    }
}

/// Experimental demo support API：单 demo harness 服务语义 evidence value。
public class CjguiExperimentalDemoServedDemoEvidence {
    /// 被服务 demo 名称保持脱水字符串。
    public let servedDemo: String

    public init(servedDemo: String) {
        this.servedDemo = servedDemo
    }

    /// 转换为现有 `served_demo` fact value。
    public func servedDemoValue(): String {
        return servedDemo
    }
}

/// Experimental demo support API：多 demo harness 服务语义 evidence value。
public class CjguiExperimentalDemoServedDemosEvidence {
    /// 被服务 demo 列表保持脱水字符串。
    public let servedDemos: String
    /// 被服务 demo 数量保持字符串，避免在 evidence path 引入额外格式化差异。
    public let servedDemoCount: String

    public init(servedDemos: String, servedDemoCount: String) {
        this.servedDemos = servedDemos
        this.servedDemoCount = servedDemoCount
    }

    /// 转换为现有 `served_demos` fact value。
    public func servedDemosValue(): String {
        return servedDemos
    }

    /// 转换为现有 `served_demo_count` fact value。
    public func servedDemoCountValue(): String {
        return servedDemoCount
    }
}

/// Experimental demo support API：可复用组件合同语义 evidence value。
public class CjguiExperimentalDemoReusableComponentEvidence {
    /// 复用 demo 列表保持脱水字符串。
    public let reusedDemos: String
    /// 组件类型列表保持脱水字符串。
    public let componentKinds: String

    public init(reusedDemos: String, componentKinds: String) {
        this.reusedDemos = reusedDemos
        this.componentKinds = componentKinds
    }

    /// 转换为现有 `reused_demos` fact value。
    public func reusedDemosValue(): String {
        return reusedDemos
    }

    /// 转换为现有 `component_kinds` fact value。
    public func componentKindsValue(): String {
        return componentKinds
    }
}
