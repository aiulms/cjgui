# CJGUI framework source preview

Experimental macOS source preview, not a released SDK, stable ABI or notarized installer.
Start with [the quick start](README.md). The exact payload is recorded by the exporter
in `source-manifest.json`; it contains export-relative names, source/content SHA-256,
origin (`identical` or `rewritten`) and file sizes. It contains no author checkout path
or endpoint capability. The manifest itself is excluded from its own content digest.

The author-side command remains valid from the original framework repository
(the exporter itself is not part of this source SDK; package users start with
the included create/run entry points in README.md):

```sh
zsh scripts/export_framework_preview.sh DESTINATION
# Default: --profile full, retaining the existing optional consumers.
zsh scripts/export_framework_preview.sh DESTINATION --profile macos-dev
```

Both profiles contain:

- `framework/cjgui/src/` and `shared_operation_core/src/`: every production source in
  the current packages' `src` directories, excluding `*_test.cj`. This is derived by
  `cjgui_package_source_paths`, rather than a list of public module names. New form,
  collection or other production modules therefore accompany their callers.
- Both `cjpm.toml` manifests, top-level macOS native `.m`/`.h` inputs, resources,
  normal `run_macos_application.sh`, `create_macos_application.sh`, and all four
  source templates (`ui-only`, `collaboration`, `mixed-form`, `command-surface`). Template domain/window
  test sources remain available to application developers; no test binary ships.
- The generic `client.py`, typed `cjgui_generated_client.py` and existing public
  Python consumption examples, all over the same application-issued descriptor.
- This explanation, a quick start, MACOS-CANDIDATE.md, the accessibility, layout and command guides,
  the host guide, and repository `LICENSE`/`NOTICE`
  beside the preview and each common package. Source terms remain Apache-2.0.

`macos-dev` is the bounded developer handoff: it includes the existing generated collection and rule-set window consumers, their rule-set domain dependency, and current layout/field/card usage. It excludes framework-history documents.
The optional `mixed-form --commands` entry composes the existing print-preset owner,
toolbar/palette/native menu, field feedback, slider, boolean and registered image.
Its context menu retains the clicked command button's live target; it does not
retarget a field request to another control. Default `mixed-form` and `ui-only`
remain offline. `command-surface` remains an independent small entry.
Its framework/client README pointers are local to the package. The default `full`
profile additionally retains the tree, generated-panel and adaptive-layout consumers. Their relative dependencies and
launchers are rewritten for the export tree; their whole source trees, including
consumer tests, remain included. They are not newly runtime-accepted by a source export.

Excluded in both profiles: target, `.cjgui`, native/lib, CJO/BC/object/archive caches,
framework `*_test.cj`, probes, native verification programs, artifacts, evidence,
fixtures, user data and the compiler/system SDK. Copies filter producer directories
before traversal. Existing selective standalone-cjc source profiles remain unchanged;
they are specialized probe/Linux inputs, not the cjpm export's source manifest.

The exporter hashes original inputs before copying, checks their bytes and production
membership again before publication, and removes its own staging directory on failure.
Changed sources make the export fail without publishing a mixed snapshot. This is not
a repository lock or a release signature. The normal runner materializes native caches
from these sources and records actual `source_origin` / `resource_origin`; successful
independent compilation and normal consumption are separate evidence.
Two source-lock formats drive the same exit. **Closure lock (format 2)** covers the
whole delivery closure — common sources, top-level native `.m/.h` ABI inputs,
`build.cj`, runner/build scripts, `cjpm.toml` configuration, templates and assets —
by raw source SHA-256, and requires the lock set to equal the export set exactly:
an added or dropped input is refused by name, and a moved native or script digest
is refused with its category (`native`, `script`, `template`, `asset`, `source`,
`build`, `config`). Write one with `--write-source-lock PATH` during a successful
export, then drive later exports with `--source-lock PATH`; two lock-driven exports
of the same inputs produce the identical `exported_content_sha256`. The older
**flat `.cj` map** remains supported unchanged: omitting a required non-test
template source is an error there, and optional `*_test.cj` files may sit outside
it. In both modes the manifest covers the actual exported native headers and
public Python clients as well as Cangjie sources, and each entry records its
delivery `category`, its raw `source_sha256` and its exported `sha256`
(`origin` distinguishes byte-identical copies from export-time rewrites).

**First-version support subset.** Supported: macOS Apple Silicon (arm64), Cangjie
1.1.3 cjnative, the generated/composite interface protocol 2 surface the catalog
publishes (`SURFACE`/`COMPONENT`/`COMPOSITE`/`ELEMENT`/`FIELD`/`ACTION`/`SUPPORT`/
`EVIDENCE` lines), the four source templates and the included consumers. This is an
experimental source handoff, not a stable ABI: interfaces are `additive_only` and
may change; the internal native archive (`libcjgui_internal_renderer.a`) and the
application launcher archive are private build products with no ABI promise, and a
prebuilt App must be rebuilt from the same source package rather than relinked
against another version. The composite element role `projection` and its `source`
token (`field_error`, `field_reason`, `action_reason`, `owner_status`) are part of
that experimental surface: a projection is read-only owner text, is resolved from
the instance's one frozen snapshot on every build, and may be omitted by a factory
when it has nothing to show; a mounted projection must carry the owner's exact
text. Unverified boundaries remain the ones published by the application's own
`EVIDENCE`/`SUPPORT` lines: VoiceOver navigation, the full IME matrix, GiB loads,
other platforms and strict performance/GPU-presentation limits are not claimed by
this package.

The completed App embeds Cangjie runtime libraries plus its declared resources, while
the source preview requires the developer's Cangjie 1.1.3 and macOS SDK to rebuild.
UI-only starts without an endpoint; optional collaboration uses the existing permission
and descriptor contract. Neither the package nor a scripted client is a model runtime.


Source-document links are relocated to shipped files. Historical evidence and unshipped
source references remain labelled text rather than links to the author's checkout.
The source manifest records these documentation rewrites; it is not runtime acceptance.

DS52 新增 `framework/cjgui/src/composable_ui_collection_workspace.cj`（生产源，随 source set 自动入包）。holder 视图状态事务、集合挂载的发布/回滚/释放责任、公共集合工作区的最小用法与视图偏好范围见 README.md 的 DS52 段；它只描述当前包能力，不是运行时验收。

公共字体资源文档 `framework/cjgui/FONT_RESOURCES.md`、Lilex Regular / OFL.txt 和 mixed-form 的可选 `--fonts` 随同一 macos-dev 出口交付；生成方只引用公开 key/version，不包含作者字体路径或预注册系统字体依赖。
