#!/usr/bin/env python3
"""Make a model prompt only from this HAP's saved public discovery and owner read."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

import verify_normal_generated_consumption as normal


GOAL = {
    "settings": ("settings-beacon", ("name", "enabled"), "INCREMENT",
                 "展示当前设置标志图，编辑名称，切换启用计数，点击增加计数，并加中文标题"),
    "thermo": ("thermo-heat-map", ("note", "eco"), "TEMP_UP",
               "展示当前恒温热图，编辑备注，切换节能模式，点击升高温度，并加中文标题"),
}
IMAGE_PROPERTIES = {"resource", "resourceVersion", "contentMode", "fixedWidth", "fixedHeight"}


def prepare_prompt(app: str, discovery_dir: Path) -> tuple[str, int]:
    if app not in GOAL:
        raise ValueError("unknown application")
    discovery = json.loads((discovery_dir / "model_discovery.json").read_text(encoding="utf-8"))
    capabilities = discovery.get("capabilities", {})
    if not isinstance(capabilities, dict):
        raise ValueError("public capabilities are absent")
    key, fields, action, goal = GOAL[app]
    components = capabilities.get("components", [])
    image_components = [item for item in components if item.get("kind") == "image"]
    if len(image_components) != 1 or not IMAGE_PROPERTIES.issubset(
            {item.get("name") for item in image_components[0].get("properties", [])}):
        raise ValueError("public image component lacks required properties")
    public_fields = {item.get("field_id") for item in capabilities.get("fields", [])}
    public_actions = {item.get("name") for item in capabilities.get("actions", [])}
    if not set(fields).issubset(public_fields) or action not in public_actions:
        raise ValueError("business goal is absent from public capabilities")

    context: str | None = None
    for line in (discovery_dir / "exchanges.jsonl").read_text(encoding="utf-8").splitlines():
        row = json.loads(line)
        if row.get("command") == "GET_CONTEXT 0" and row.get("response_kind") == "SNAPSHOT":
            context = row.get("raw_response")
    if not isinstance(context, str):
        raise ValueError("same-run public owner context is absent")
    resource_id = normal.APP_CONTRACT[app][2]
    matches = re.findall(rf"^FIELD {resource_id} imageVersion INTEGER ([1-9]\d*)$",
                         context, flags=re.M)
    if len(matches) != 1:
        raise ValueError("owner imageVersion is absent or ambiguous")
    version = int(matches[0])
    registered = [item for item in capabilities.get("image_resources", [])
                  if item.get("key") == key and item.get("version") == version and
                  item.get("content_type") == "PNG"]
    if len(registered) != 1:
        raise ValueError("current owner image version is not in public resource catalog")

    message = (
        "你是通过 CJGUI 公开 generated UI 协议操作当前鸿蒙应用的外部模型。"
        "下面只有这个正在运行的应用实际公开的能力、已接受结构和 owner 上下文。"
        f"请从零生成一个紧凑、屏幕可见的面板：{goal}。"
        f"图片只能引用公开资源 key={key}、当前 resourceVersion {version}；"
        "图片节点须用 contentMode fill、fixedWidth 160、fixedHeight 72。"
        "保留真实字段和动作绑定，其他属性只选公开组件允许的项，遵守预算。"
        "只输出完整协议文本：首行 GENERATED_UI_STRUCTURE 1，末行 END；"
        "不要解释、代码块、JSON、文件路径或未公开规则。\n\n"
        "本轮公开发现：\n" + json.dumps(discovery, ensure_ascii=False, indent=2, sort_keys=True) +
        "\n\n本轮公开 owner 上下文原文：\n" + context + "\n")
    return message, version


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", choices=sorted(GOAL), required=True)
    parser.add_argument("--discovery-dir", type=Path, required=True)
    parser.add_argument("--prompt-file", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        message, version = prepare_prompt(args.app, args.discovery_dir)
        args.prompt_file.parent.mkdir(parents=True, exist_ok=True)
        with args.prompt_file.open("x", encoding="utf-8") as output:
            output.write(message)
        digest = hashlib.sha256(message.encode("utf-8")).hexdigest()
        print(json.dumps({"app": args.app, "image_version": version,
                          "prompt_file": str(args.prompt_file), "prompt_sha256": digest},
                         ensure_ascii=False))
        return 0
    except Exception as exc:
        print(f"model image prompt preparation failed: {type(exc).__name__}: {exc}",
              file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
