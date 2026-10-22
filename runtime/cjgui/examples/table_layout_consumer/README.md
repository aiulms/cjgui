# table_layout_consumer

最小独立消费者：列定义为 `sku/stock/price/note`，与应用不同，只使用公共
`CjguiComposableUiTableColumnLayout` 和 `CjguiComposableUiTableSource`，没有复制列菜单、拖动或排序实现。

```sh
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
cd runtime/cjgui/examples/table_layout_consumer
cjpm build
./target/release/bin/main
# TABLE_LAYOUT_CONSUMER OK columns=3 order=[price, sku, stock] stock=140 revision=3
```

FFI 库复用 `../rule_set_window_app/.cjgui/native/lib`（由该应用的 `run.sh --build-only` 生成），不另存一份 native 构建。
