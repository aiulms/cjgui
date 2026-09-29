// Experimental runtime-generated UI: a typed capability catalog, a validated
// structure value model, a single structure holder and an expansion path that
// reuses the ordinary component/layout/scene acceptance chain.
//
// Ownership: the application owns business fields, drafts and actions and
// exposes them through CjguiGeneratedUiBindingProvider; this module owns only
// the accepted structure description, its version and the node identity
// allocation for accepted keys. Generated descriptions never carry writable
// business data, source code, native handles or new permissions.
package cjgui

import std.env.*
import std.random.*
import std.collection.*
import cjgui_shared_operation_core.*

/// One application field as seen by generated UI. It is *derived* from the
/// application's existing shared form binding, so the handwritten form, the
/// public description and the generated editor all read one definition
/// instead of three hand-maintained lists. `writeActionName` is the framework
/// operation a generated editor must use for this field; it is derived here,
/// in one place, from the form editor kind - consumers never switch on field
/// names or hardcode `EDIT_DRAFT_TEXT`/`EDIT_DRAFT_BOOLEAN`.
public class CjguiGeneratedUiFieldSpec {
    public let fieldId: String
    public let label: String
    public let editorKind: String // "TEXT" | "INTEGER" | "BOOLEAN"
    public let resourceId: Int64
    public let writeActionName: String // "" when the framework has no writer
    public let minimum: Int64
    public let maximum: Int64
    public let required: Bool // declared by the application's binding

    // Declared TEXT length limit in Unicode scalar values (Rune); 0 = none.
    public let maximumLength: Int64
    /// The writer operation's own ARGUMENT name, from the application's single
    /// field definition. It travels with the field so a consumer (or an external
    /// reader) never has to guess which argument the owner operation takes.
    public let argumentName: String

    /// `writeActionName` may be given explicitly by an application whose owner
    /// writes immediately (for example SET_TITLE) instead of through the
    /// shared draft operations. It is still a single declared value, so no
    /// consumer re-derives the writer from a field name.
    public init(fieldId: String, label: String, editorKind: String, resourceId: Int64, minimum!: Int64 = 0,
        maximum!: Int64 = 0, writeActionName!: String = "", required!: Bool = false, maximumLength!: Int64 = 0,
        argumentName!: String = "") {
        this.fieldId = fieldId
        this.label = label
        this.editorKind = editorKind
        this.resourceId = resourceId
        this.writeActionName = if (writeActionName.size > 0) {
            writeActionName
        } else {
            CjguiGeneratedUiFieldSpec.writeActionForEditorKind(editorKind)
        }
        this.minimum = minimum
        this.maximum = maximum
        this.required = required
        this.maximumLength = maximumLength
        this.argumentName = argumentName
    }

    /// The single place that maps a shared-form editor kind to the framework
    /// draft write operation. An unknown kind has no writer, and an editor
    /// bound to it is rejected instead of silently writing the wrong field.
    public static func writeActionForEditorKind(editorKind: String): String {
        if (editorKind == "BOOLEAN") {
            return "EDIT_DRAFT_BOOLEAN"
        }
        if (editorKind == "TEXT" || editorKind == "INTEGER") {
            return "EDIT_DRAFT_TEXT"
        }
        return ""
    }

    /// The generated input kind that presents this editor kind.
    public func inputKind(): String {
        if (editorKind == "BOOLEAN") {
            return "booleanInput"
        }
        if (editorKind == "INTEGER") {
            return "integerInput"
        }
        if (editorKind == "TEXT") {
            return "textInput"
        }
        return ""
    }

    public func isWritable(): Bool {
        return writeActionName.size > 0
    }

    /// The human event kind that carries a change for this editor kind. The
    /// native bridge reports a toggled boolean as a *boolean change* (kind 29,
    /// with the projected next value in `text`) and an edited text/integer
    /// projection as a text change (kind 28) - never as a bare activation.
    /// Publishing this beside `writeActionForEditorKind` keeps the contract in
    /// one definition: a consumer asks its field what a change looks like
    /// instead of hardcoding kinds and silently dropping real input when the
    /// framework reports a different one.
    public func changeEventKind(): Int64 {
        if (editorKind == "BOOLEAN") {
            return CJGUI_COMPOSABLE_UI_EVENT_BOOLEAN_CHANGED
        }
        return CJGUI_COMPOSABLE_UI_EVENT_TEXT_CHANGED
    }

    /// Whether `eventKind` is a change for this editor kind. Anything else
    /// (focus, scroll, activation) must not be turned into a field write.
    public func acceptsChangeEventKind(eventKind: Int64): Bool {
        return eventKind == changeEventKind()
    }

    /// Derives the generation-side field definition from the application's
    /// shared form binding. The binding stays the only authored definition.
    ///
    /// `textArgument`/`booleanArgument` are the writer operation's own ARGUMENT
    /// names from the SAME application definition that publishes the write
    /// operations. When the application declares them, the capability description
    /// carries them with the field, so an external caller (or a composite element)
    /// never guesses which argument `EDIT_DRAFT_TEXT`/`EDIT_DRAFT_BOOLEAN` takes.
    public static func fromFormBinding(binding: CjguiSharedFormBinding, textArgument!: String = "",
        booleanArgument!: String = ""): ArrayList<CjguiGeneratedUiFieldSpec> {
        let result = ArrayList<CjguiGeneratedUiFieldSpec>()
        for (descriptor in binding.allFields()) {
            // The declared business constraints travel with the field: the
            // generated spec (and therefore the validator and the external
            // capability description) enforces and publishes exactly what the
            // application declared in its one binding.
            let declaredArgument = if (descriptor.editorKind == "BOOLEAN") {
                booleanArgument
            } else {
                textArgument
            }
            result.add(
                CjguiGeneratedUiFieldSpec(descriptor.fieldId, descriptor.label, descriptor.editorKind,
                    descriptor.resourceId, minimum: descriptor.minimum, maximum: descriptor.maximum,
                    required: descriptor.required, maximumLength: descriptor.maximumLength,
                    argumentName: declaredArgument))
        }
        return result
    }
}

/// Hard upper bound on the number of component instances one generated
/// structure may mount. It is a real framework limit (the per-controller
/// component registry), so the validator enforces it as an explicit rejection
/// instead of letting the render fail later with an internal capacity issue.
public let CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY: Int64 = 64

/// One property an application-registered component accepts.
public class CjguiGeneratedUiPropertySpec {
    public let name: String
    public let valueType: String // "STRING" | "INTEGER" | "BOOLEAN"
    public let required: Bool
    public let minimum: Int64
    public let maximum: Int64
    public let maxLength: Int64
    /// Allowed values for an enumerated STRING property (empty = free text).
    /// Publishing them is how a generated description states the accepted
    /// vocabulary without the reader guessing.
    public let values: ArrayList<String>
    /// The effective default the framework applies when the description omits
    /// the property ("" = no framework default / the property is optional and
    /// simply not set). It is published so a reader never has to guess what an
    /// omitted property means.
    public let defaultValue: String
    /// Wire grammar of a structured STRING value ("" = a plain scalar token).
    /// Published from the SAME constant the parser/encoder obey, so discovery
    /// and acceptance cannot drift apart.
    public let encoding: String
    /// Unit of a structured/numeric value ("" = unitless).
    public let unit: String
    /// Accepted value domain for a structured value ("" = described by the
    /// numeric minimum/maximum or the enumerated `values`).
    public let valueRange: String
    /// Meaning of the explicit empty/`none` form and of an omitted property
    /// ("" = the property has no such dual meaning).
    public let semantics: String
    /// Stability marker of the property's contract ("" = stable).
    public let stability: String
    /// Backend support surface of the property ("" = all publishing backends).
    public let backendSupport: String

    public init(name: String, valueType: String, required!: Bool = false, minimum!: Int64 = 0, maximum!: Int64 = 0,
        maxLength!: Int64 = 0, values!: ArrayList<String> = ArrayList<String>(), defaultValue!: String = "",
        encoding!: String = "", unit!: String = "", valueRange!: String = "", semantics!: String = "",
        stability!: String = "", backendSupport!: String = "") {
        this.name = name
        this.valueType = valueType
        this.required = required
        this.minimum = minimum
        this.maximum = maximum
        this.maxLength = maxLength
        this.values = values
        this.defaultValue = defaultValue
        this.encoding = encoding
        this.unit = unit
        this.valueRange = valueRange
        this.semantics = semantics
        this.stability = stability
        this.backendSupport = backendSupport
    }
}

/// Typed presentation an application-registered component kind maps onto. The
/// framework implements exactly these presentations with existing components
/// and layout; a kind that declares anything else is rejected when it is
/// registered, so a registered-but-unimplemented component can never silently
/// degrade into a label.
public let CJGUI_GENERATED_PRESENTATION_VERTICAL: String = "CONTAINER_VERTICAL"
public let CJGUI_GENERATED_PRESENTATION_HORIZONTAL: String = "CONTAINER_HORIZONTAL"
public let CJGUI_GENERATED_PRESENTATION_LABEL: String = "LABEL"
public let CJGUI_GENERATED_PRESENTATION_ACTION: String = "ACTION_BUTTON"
public let CJGUI_GENERATED_PRESENTATION_IMAGE: String = "IMAGE"
/// A scroll container published by the generated catalog. It is a REAL viewport
/// on the same public `CjguiComposableUiScrollViewport` the handwritten tree
/// uses, not a description of some container the application wrapped around it.
public let CJGUI_GENERATED_PRESENTATION_SCROLL: String = "CONTAINER_SCROLL"
/// A two-pane split published by the generated catalog. It reuses the scoped
/// split view (and therefore the framework-allocated divider identity and the
/// existing pointer-capture/keyboard size rule); the declaration supplies only
/// the INITIAL first size and both minimums.
public let CJGUI_GENERATED_PRESENTATION_SPLIT: String = "CONTAINER_SPLIT"
/// A bounded page container published by the generated catalog. It reuses the
/// SAME public component, page identity and tab view state the handwritten tree
/// uses: the declaration supplies the initial page, the page titles and which
/// page each child presents, and the framework owns the active page afterwards.
public let CJGUI_GENERATED_PRESENTATION_TABS: String = "CONTAINER_TABS"
/// ONE page of a generated tab container. The wrapper carries the page's stable
/// key and title; its single child is the page's content. Keeping the page
/// metadata on a DEDICATED kind is what lets the validator bind a key to a page
/// without inventing properties on every possible content kind.
public let CJGUI_GENERATED_PRESENTATION_TAB_PAGE: String = "CONTAINER_TAB_PAGE"

/// ONE application image resource, declared once and shared by handwritten
/// code, the generated side and the public capability discovery.
///
/// `key` is the stable logical identity an external caller references; `rasterPath`
/// is the application's own resolution of that key inside its bundle or
/// distribution. An external caller can never inject a path or a native handle:
/// only the registered key plus a matching version resolves, and everything else
/// is rejected as a whole candidate.
public class CjguiGeneratedUiImageResourceSpec {
    public let key: String
    /// Only decoded raster types the existing native path supports; PNG is the
    /// supported set in this package.
    public let contentType: String
    public let version: Int64
    /// Human name/purpose published for discovery.
    public let name: String
    /// Application-resolved raster path (bundle-relative or absolute as the
    /// application decides). It is never accepted from an external caller.
    public let rasterPath: String

    public init(key: String, contentType: String, version: Int64, name: String, rasterPath: String) {
        this.key = key
        this.contentType = contentType
        this.version = version
        this.name = name
        this.rasterPath = rasterPath
    }

    public func isValid(): Bool {
        return key.size > 0 && contentType == "PNG" && version >= 1 && name.size > 0 && rasterPath.size > 0
    }
}

public class CjguiGeneratedUiPresentation {
    public static func isImplemented(presentation: String): Bool {
        return presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL || presentation ==
            CJGUI_GENERATED_PRESENTATION_HORIZONTAL || presentation == CJGUI_GENERATED_PRESENTATION_LABEL ||
            presentation == CJGUI_GENERATED_PRESENTATION_ACTION || presentation == CJGUI_GENERATED_PRESENTATION_IMAGE ||
            presentation == CJGUI_GENERATED_PRESENTATION_SCROLL || presentation == CJGUI_GENERATED_PRESENTATION_SPLIT ||
            presentation == CJGUI_GENERATED_PRESENTATION_TABS || presentation == CJGUI_GENERATED_PRESENTATION_TAB_PAGE ||
            // An application composite is presented by its own registered
            // factory; the catalog only stores this presentation together with
            // that factory, so accepting it here cannot degrade an unregistered
            // kind into a label.
            presentation == CJGUI_GENERATED_PRESENTATION_COMPOSITE || presentation == "FIELD_TEXT" || presentation ==
            "FIELD_INTEGER" || presentation == "FIELD_BOOLEAN"
    }

    /// Presentation inferred from a built-in kind. An application kind must
    /// declare its presentation explicitly.
    public static func forBuiltInKind(kind: String): String {
        if (kind == "vertical") {
            return CJGUI_GENERATED_PRESENTATION_VERTICAL
        }
        if (kind == "horizontal") {
            return CJGUI_GENERATED_PRESENTATION_HORIZONTAL
        }
        if (kind == "label") {
            return CJGUI_GENERATED_PRESENTATION_LABEL
        }
        if (kind == "action") {
            return CJGUI_GENERATED_PRESENTATION_ACTION
        }
        if (kind == "image") {
            return CJGUI_GENERATED_PRESENTATION_IMAGE
        }
        if (kind == "scrollArea") {
            return CJGUI_GENERATED_PRESENTATION_SCROLL
        }
        if (kind == "split") {
            return CJGUI_GENERATED_PRESENTATION_SPLIT
        }
        if (kind == "tabs") {
            return CJGUI_GENERATED_PRESENTATION_TABS
        }
        if (kind == "tabPage") {
            return CJGUI_GENERATED_PRESENTATION_TAB_PAGE
        }
        if (kind == "textInput") {
            return "FIELD_TEXT"
        }
        if (kind == "integerInput") {
            return "FIELD_INTEGER"
        }
        if (kind == "booleanInput") {
            return "FIELD_BOOLEAN"
        }
        return ""
    }

    /// Content properties of the built-in `tabs` kind: the page a NEW instance
    /// starts on (never a business value, and never a way to move an existing
    /// instance) plus the title row height.
    public static func tabsContentProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("initialPage", "STRING", maxLength: 64))
        properties.add(CjguiGeneratedUiPropertySpec("titleHeight", "INTEGER", minimum: 0, maximum: 200,
            defaultValue: "28"))
        // The title row consumes ONE registered named style: the reference
        // carries the title's base paint AND its interaction states together,
        // exactly like the handwritten `titleStyle`/`titleInteraction` pair.
        // Validation refuses an unregistered reference as a whole candidate.
        properties.add(CjguiGeneratedUiPropertySpec("titleStyle", "STRING", maxLength: 64))
        return properties
    }

    /// Content properties of one generated tab PAGE: its stable key plus the
    /// title a person reads. The key is what a restored active page refers to.
    public static func tabPageContentProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("pageKey", "STRING", required: true, maxLength: 64))
        properties.add(CjguiGeneratedUiPropertySpec("pageTitle", "STRING", required: true, maxLength: 64))
        return properties
    }

    /// Content properties of the built-in `split` kind. The declared `firstSize`
    /// is the INITIAL pixel size of the first pane (the same unit the scoped
    /// split already uses); both minimums bound the divider so a narrow window
    /// can never produce a negative or overlapping pane.
    public static func splitContentProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("firstSize", "INTEGER", minimum: 0, maximum: 10000,
            defaultValue: "0"))
        properties.add(
            CjguiGeneratedUiPropertySpec("firstMinimum", "INTEGER", minimum: 0, maximum: 10000, defaultValue: "120"))
        properties.add(
            CjguiGeneratedUiPropertySpec("secondMinimum", "INTEGER", minimum: 0, maximum: 10000, defaultValue: "120"))
        return properties
    }

    /// Content properties of the built-in `scrollArea` kind: the declaration's
    /// INITIAL offset (a request the first accepted solve clamps) and the inner
    /// padding. After the first solve the view state belongs to the instance, so
    /// re-submitting the same structure never resets a human's scroll position.
    public static func scrollContentProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("offset", "INTEGER", minimum: 0, maximum: 1000000, defaultValue: "0"))
        return properties
    }

    /// Content properties of the built-in `image` kind: the logical resource
    /// key, the exact version and the fit/fill mode the existing native image
    /// path implements. ONE definition, so both applications publish the same
    /// vocabulary instead of hand-copying it.
    public static func imageContentProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("resource", "STRING", required: true, maxLength: 64))
        properties.add(
            CjguiGeneratedUiPropertySpec("resourceVersion", "INTEGER", required: true, minimum: 1, maximum: 1000000))
        properties.add(
            CjguiGeneratedUiPropertySpec("contentMode", "STRING", maxLength: 8,
                values: ArrayList<String>(["fit", "fill"]), defaultValue: "fit"))
        return properties
    }

    /// The style property names the generated side really consumes: size
    /// constraints, growth, alignment and font. They map onto the SAME
    /// `CjguiComposableUiStyle` the handwritten tree uses.
    /// The paint vocabulary every presentation carries: strict color tokens plus a
    /// named-style reference, plus the two encoded effects (`shadow` and
    /// `gradient`) whose tokens carry their own color stops. `borderWidth` is a
    /// numeric style name because it is a real layout/paint field on the shared
    /// Style.
    public static func isPaintPropertyName(name: String): Bool {
        return name == "background" || name == "border" || name == "textColor" || name == "shadow" ||
            name == "gradient" || name == "effectGroup"
    }

    public static func isStylePropertyName(name: String): Bool {
        return name == "fixedWidth" || name == "fixedHeight" || name == "minWidth" || name == "maxWidth" || name ==
            "minHeight" || name == "maxHeight" || name == "growX" || name == "growY" || name == "alignX" || name ==
            "alignY" || name == "fontSize" || name == "fontWeight" || name == "borderWidth" ||
            name == "translateX" || name == "translateY"
    }

    /// Whether one presentation consumes one style property. A container also
    /// consumes its own gap/padding; a leaf does not (a leaf's padding would be
    /// declared but the same leaf the handwritten builder writes carries none).
    public static func consumesStyleProperty(presentation: String, name: String): Bool {
        if (presentation != CJGUI_GENERATED_PRESENTATION_VERTICAL && presentation !=
            CJGUI_GENERATED_PRESENTATION_HORIZONTAL && presentation != CJGUI_GENERATED_PRESENTATION_SCROLL &&
            presentation != CJGUI_GENERATED_PRESENTATION_SPLIT && presentation != CJGUI_GENERATED_PRESENTATION_TABS &&
            presentation != CJGUI_GENERATED_PRESENTATION_TAB_PAGE && presentation != CJGUI_GENERATED_PRESENTATION_LABEL &&
            presentation != CJGUI_GENERATED_PRESENTATION_ACTION && presentation != CJGUI_GENERATED_PRESENTATION_IMAGE &&
            presentation != "FIELD_TEXT" && presentation != "FIELD_INTEGER" && presentation != "FIELD_BOOLEAN") {
            return false
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL || presentation ==
            CJGUI_GENERATED_PRESENTATION_HORIZONTAL || presentation == CJGUI_GENERATED_PRESENTATION_TABS) {
            // A tab container stacks its title row above the active page, so it
            // consumes the same gap/padding vocabulary as any other container.
            if (name == "gap" || name == "padding") {
                return true
            }
        }
        if (CjguiGeneratedUiPresentation.isPaintPropertyName(name) || name == "style") {
            return true
        }
        return isStylePropertyName(name)
    }

    /// The properties each presentation actually reads. A registered property
    /// that no presentation consumes is rejected, so a declared attribute
    /// cannot pass validation and then be ignored by the renderer.
    public static func isPropertyImplemented(presentation: String, name: String, valueType: String): Bool {
        if (presentation == CJGUI_GENERATED_PRESENTATION_COMPOSITE) {
            // A composite's declared properties are consumed by the
            // application's own factory, which the framework cannot inspect
            // statically. The declaration itself is the contract: a property
            // only exists here because registerComposite accepted it with a real
            // value type, and a description carrying anything else is still
            // rejected as unknown_property against the SAME declaration.
            return valueType == "STRING" || valueType == "INTEGER" || valueType == "BOOLEAN"
        }
        if (name == "alignX" || name == "alignY") {
            return consumesStyleProperty(presentation, name) && valueType == "STRING"
        }
        if (name == "translateX" || name == "translateY") {
            return consumesStyleProperty(presentation, name) && valueType == "STRING"
        }
        if (CjguiGeneratedUiPresentation.isPaintPropertyName(name) || name == "style") {
            return consumesStyleProperty(presentation, name) && valueType == "STRING"
        }
        // A motion reference is consumed by the holder's accepted key→rule
        // binding. It is valid on an implemented node because the public window
        // animation entry addresses every accepted node identity.
        if (name == "motion") {
            return isImplemented(presentation) && valueType == "STRING"
        }
        if (isStylePropertyName(name)) {
            return consumesStyleProperty(presentation, name) && valueType == "INTEGER"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_SCROLL) {
            return name == "offset" && valueType == "INTEGER"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_TABS) {
            // The declaration supplies the page a NEW instance starts on plus the
            // title row height; the ACTIVE page afterwards is window view state.
            // A tab container also stacks its title row above the page body, so it
            // consumes the container gap/padding vocabulary. `titleStyle` is a
            // registered named-style reference feeding the title row's base
            // paint AND interaction states through the same resolution as `style`.
            return (name == "initialPage" && valueType == "STRING") || (name == "titleHeight" && valueType == "INTEGER") ||
                (name == "titleStyle" && valueType == "STRING") || ((name == "gap" || name == "padding") && valueType ==
                "INTEGER")
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_TAB_PAGE) {
            return (name == "pageKey" && valueType == "STRING") || (name == "pageTitle" && valueType == "STRING")
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_SPLIT) {
            return (name == "firstSize" || name == "firstMinimum" || name == "secondMinimum") && valueType == "INTEGER"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL || presentation ==
            CJGUI_GENERATED_PRESENTATION_HORIZONTAL) {
            return (name == "gap" || name == "padding") && valueType == "INTEGER"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_LABEL) {
            return name == "text" && valueType == "STRING"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_ACTION) {
            // `label` is the button caption; `action` is the declared action
            // name the validator checks against the node's own binding. A
            // generated action may also declare a transfer endpoint; the
            // application validates its role/format and stages a real window
            // provider binding with the scene before it becomes accepted.
            return (name == "label" || name == "action" || name == "transferRole" ||
                name == "transferFormat" || name == "transferFileSource") && valueType == "STRING"
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_IMAGE) {
            // The logical resource key and its version are resolved against the
            // application's OWN resource table; the external caller never ships a
            // local path. `contentMode` is the fit/fill mode the existing native
            // image path already implements.
            if (name == "resource" || name == "contentMode") {
                return valueType == "STRING"
            }
            if (name == "resourceVersion") {
                return valueType == "INTEGER"
            }
            return false
        }
        if (presentation == "FIELD_TEXT" || presentation == "FIELD_INTEGER" || presentation == "FIELD_BOOLEAN") {
            return name == "label" && valueType == "STRING"
        }
        return false
    }

    /// The ONE shared declaration of the style properties a generated kind
    /// accepts, so both applications register the same vocabulary instead of
    /// hand-maintaining their own subset. The values are the ones the mapping in
    /// `styleFor` really applies; a property listed here is never ignored.
    public static func boxProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = ArrayList<CjguiGeneratedUiPropertySpec>()
        properties.add(CjguiGeneratedUiPropertySpec("fixedWidth", "INTEGER", minimum: 0, maximum: 4096,
            defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("fixedHeight", "INTEGER", minimum: 0, maximum: 4096,
            defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("minWidth", "INTEGER", minimum: 0, maximum: 4096, defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("maxWidth", "INTEGER", minimum: 0, maximum: 4096, defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("minHeight", "INTEGER", minimum: 0, maximum: 4096, defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("maxHeight", "INTEGER", minimum: 0, maximum: 4096, defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("growX", "INTEGER", minimum: 0, maximum: 8, defaultValue: "0"))
        properties.add(CjguiGeneratedUiPropertySpec("growY", "INTEGER", minimum: 0, maximum: 8, defaultValue: "0"))
        properties.add(
            CjguiGeneratedUiPropertySpec("alignX", "STRING", maxLength: 8,
                values: ArrayList<String>(["start", "center", "end", "stretch"]), defaultValue: "stretch"))
        properties.add(
            CjguiGeneratedUiPropertySpec("alignY", "STRING", maxLength: 8,
                values: ArrayList<String>(["start", "center", "end", "stretch"]), defaultValue: "start"))
        // Shared paint vocabulary: a strict color token or a named-style
        // reference. `borderWidth` joins the numeric style names so its range is
        // validated by the same INTEGER path.
        properties.add(CjguiGeneratedUiPropertySpec("style", "STRING", maxLength: 64, defaultValue: ""))
        properties.add(CjguiGeneratedUiPropertySpec("background", "STRING", maxLength: 9, defaultValue: ""))
        properties.add(CjguiGeneratedUiPropertySpec("border", "STRING", maxLength: 9, defaultValue: ""))
        properties.add(CjguiGeneratedUiPropertySpec("textColor", "STRING", maxLength: 9, defaultValue: ""))
        // Encoded effects: an outer shadow / linear gradient carried on one
        // string token. The grammar, unit, domain, `none` semantics, stability
        // and backend support are all published from the ONE shared effect
        // contract, so a client can assemble a legal effect from discovery
        // alone. `none` and the empty string CLEAR the effect; an absent
        // property INHERITS the named base; malformed text is refused as a
        // whole candidate with a stable reason, never ignored.
        properties.add(
            CjguiGeneratedUiPropertySpec("shadow", "STRING", maxLength: 64, values: ArrayList<String>(["none"]),
                defaultValue: "", encoding: CjguiComposableUiEffectValidation.SHADOW_ENCODING,
                unit: CjguiComposableUiEffectValidation.SHADOW_UNIT,
                valueRange: CjguiComposableUiEffectValidation.SHADOW_RANGE,
                semantics: CjguiComposableUiEffectValidation.EFFECT_NONE_SEMANTICS,
                stability: CjguiComposableUiEffectValidation.EFFECT_STABILITY,
                backendSupport: CjguiComposableUiEffectValidation.EFFECT_BACKEND_SUPPORT))
        properties.add(
            CjguiGeneratedUiPropertySpec("gradient", "STRING", maxLength: 256, values: ArrayList<String>(["none"]),
                defaultValue: "", encoding: CjguiComposableUiEffectValidation.GRADIENT_ENCODING,
                unit: CjguiComposableUiEffectValidation.GRADIENT_UNIT,
                valueRange: CjguiComposableUiEffectValidation.GRADIENT_RANGE,
                semantics: CjguiComposableUiEffectValidation.EFFECT_NONE_SEMANTICS,
                stability: CjguiComposableUiEffectValidation.EFFECT_STABILITY,
                backendSupport: CjguiComposableUiEffectValidation.EFFECT_BACKEND_SUPPORT))
        properties.add(
            CjguiGeneratedUiPropertySpec("effectGroup", "STRING", maxLength: 256, defaultValue: "",
                encoding: CjguiComposableUiEffectValidation.EFFECT_GROUP_ENCODING,
                unit: CjguiComposableUiEffectValidation.EFFECT_GROUP_UNIT,
                valueRange: CjguiComposableUiEffectValidation.EFFECT_GROUP_RANGE,
                semantics: "none_or_empty=clear,absent=inherit,mask=sx,sy,ex,ey,pos:alpha|...,stops=2..4,blur=radiusPoints,unblurred",
                stability: CjguiComposableUiEffectValidation.EFFECT_STABILITY,
                backendSupport: CjguiComposableUiEffectValidation.EFFECT_GROUP_BACKEND_SUPPORT))
        properties.add(CjguiGeneratedUiPropertySpec("borderWidth", "INTEGER", minimum: 0, maximum: 64, defaultValue: "1"))
        properties.add(CjguiGeneratedUiPropertySpec("translateX", "STRING", maxLength: 12,
            defaultValue: "", encoding: "signed decimal, at most 3 fractional digits",
            unit: "logical points", valueRange: "[-1024,1024]; cumulative [-4096,4096]",
            semantics: "absent=inherit named style; empty=clear to 0",
            stability: "experimental", backendSupport: "macOS; other backends unsupported"))
        properties.add(CjguiGeneratedUiPropertySpec("translateY", "STRING", maxLength: 12,
            defaultValue: "", encoding: "signed decimal, at most 3 fractional digits",
            unit: "logical points", valueRange: "[-1024,1024]; cumulative [-4096,4096]",
            semantics: "absent=inherit named style; empty=clear to 0",
            stability: "experimental", backendSupport: "macOS; other backends unsupported"))
        // A registered app rule may be referenced by any accepted generated
        // instance. The holder publishes the resolved rule only with that
        // instance's accepted structure transaction.
        properties.add(CjguiGeneratedUiPropertySpec("motion", "STRING", maxLength: 64,
            stability: "experimental", backendSupport: "accepted generated node animation"))
        return properties
    }

    /// The container style vocabulary: the box properties plus its own gap and
    /// padding. A leaf gets `fontProperties()` instead: a container's padding is
    /// consumed by its own layout, a leaf's is not.
    public static func containerStyleProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = boxProperties()
        properties.add(CjguiGeneratedUiPropertySpec("gap", "INTEGER", minimum: 0, maximum: 32, defaultValue: "4"))
        properties.add(CjguiGeneratedUiPropertySpec("padding", "INTEGER", minimum: 0, maximum: 32, defaultValue: "0"))
        return properties
    }

    /// The leaf style vocabulary: box properties plus font size/weight. Font
    /// size is published in whole points (the generated value model has no
    /// fractional type); the mapping passes it to the same Float64 Style field.
    public static func leafStyleProperties(): ArrayList<CjguiGeneratedUiPropertySpec> {
        let properties = boxProperties()
        properties.add(CjguiGeneratedUiPropertySpec("fontSize", "INTEGER", minimum: 1, maximum: 128, defaultValue: "13"))
        properties.add(CjguiGeneratedUiPropertySpec("fontWeight", "INTEGER", minimum: 0, maximum: 1, defaultValue: "0"))
        return properties
    }

    /// The field editor kind a field presentation requires ("TEXT", "INTEGER",
    /// "BOOLEAN"), or "" when the presentation is not a field presentation.
    public static func requiredEditorKind(presentation: String): String {
        if (presentation == "FIELD_TEXT") {
            return "TEXT"
        }
        if (presentation == "FIELD_INTEGER") {
            return "INTEGER"
        }
        if (presentation == "FIELD_BOOLEAN") {
            return "BOOLEAN"
        }
        return ""
    }
}

/// One component kind the current application registers as generatable.
public class CjguiGeneratedUiComponentSpec {
    public let kind: String
    public let properties: ArrayList<CjguiGeneratedUiPropertySpec>
    public let allowsChildren: Bool
    public let childLimit: Int64
    /// Typed presentation this kind is drawn with. Empty for an unknown custom
    /// kind (which registration rejects).
    public let presentation: String

    public init(kind: String, properties: ArrayList<CjguiGeneratedUiPropertySpec>, allowsChildren: Bool,
        childLimit!: Int64 = 0, presentation!: String = "") {
        this.kind = kind
        this.properties = properties
        this.allowsChildren = allowsChildren
        this.childLimit = childLimit
        let declared = if (presentation.size > 0) {
            presentation
        } else {
            CjguiGeneratedUiPresentation.forBuiltInKind(kind)
        }
        this.presentation = declared
    }

    public func isImplemented(): Bool {
        return CjguiGeneratedUiPresentation.isImplemented(presentation)
    }
}

/// One business action the application exposes to generated buttons.
public class CjguiGeneratedUiActionSpec {
    public let name: String
    public let label: String
    public let parameterNames: ArrayList<String>

    public init(name: String, label: String, parameterNames!: ArrayList<String> = ArrayList<String>()) {
        this.name = name
        this.label = label
        this.parameterNames = parameterNames
    }
}

/// Typed capability catalog. The application registers what generated
/// structures may use; the query result is what an external client reads
/// before submitting a candidate.
public class CjguiGeneratedUiCapabilityCatalog {
    private let components: ArrayList<CjguiGeneratedUiComponentSpec>
    private let actions: ArrayList<CjguiGeneratedUiActionSpec>
    private let fields: ArrayList<CjguiGeneratedUiFieldSpec>
    // Application composites: the declared kind/elements and the compiled
    // factory. Both are registered together, so a kind that claims the COMPOSITE
    // presentation can never exist without a real implementation.
    private let composites: ArrayList<CjguiCompositeComponentSpec>
    private let compositeFactories: ArrayList<CjguiCompositeComponentFactory>
    // Application image resources: ONE declaration per logical key, published
    // through the same capability text the external caller already reads.
    private let imageResources: ArrayList<CjguiGeneratedUiImageResourceSpec>
    // Raster each published `(key, version)` identity has already denoted. ONE
    // published identity must keep denoting ONE resolved resource: replacing the
    // actual description behind it would let an accepted instance (still holding
    // the old path) and a freshly resolved candidate share a public identity
    // while resolving to different files. A content change therefore requires a
    // NEW version, while a metadata-only change is legal on the same version.
    // This is an identity guard, not a history ledger: it is bounded, the oldest
    // entries are dropped past the cap, and the current declaration stays the
    // authoritative check.
    private let imageContentIdentities: HashMap<String, String>
    private let imageContentIdentityOrder: ArrayList<String>
    // App-owned motion declarations accepted by this catalog. The window's
    // built-in interaction rule is separate; generated candidates may only name
    // rules this application registered here.
    private let motionRuleRegistryValue: CjguiGeneratedMotionRegistry
    // Application-visible named styles. ONE definition feeds handwritten helpers,
    // generated nodes and registered composites through the same resolution, and
    // the capability text publishes it beside the kinds/properties.
    private let namedStyleCatalog: CjguiComposableUiNamedStyleCatalog
    // Window appearance changes affect the host window rather than a generated
    // node. Each application must explicitly opt its generated directory in
    // before the root-only declaration is discoverable or accepted.
    private var windowBackgroundEnabledValue: Bool = false
    public let maxDepth: Int64
    public let maxNodes: Int64
    public let maxPropertiesPerNode: Int64
    public let maxStringLength: Int64

    public init(maxDepth!: Int64 = 12, maxNodes!: Int64 = 512, maxPropertiesPerNode!: Int64 = 8,
        maxStringLength!: Int64 = 256) {
        this.components = ArrayList<CjguiGeneratedUiComponentSpec>()
        this.actions = ArrayList<CjguiGeneratedUiActionSpec>()
        this.fields = ArrayList<CjguiGeneratedUiFieldSpec>()
        this.composites = ArrayList<CjguiCompositeComponentSpec>()
        this.compositeFactories = ArrayList<CjguiCompositeComponentFactory>()
        this.imageResources = ArrayList<CjguiGeneratedUiImageResourceSpec>()
        this.imageContentIdentities = HashMap<String, String>()
        this.liveImageIdentities = HashMap<String, Int64>()
        this.imageContentIdentityOrder = ArrayList<String>()
        this.motionRuleRegistryValue = CjguiGeneratedMotionRegistry()
        this.namedStyleCatalog = CjguiComposableUiNamedStyleCatalog()
        this.lastRegistrationIssue = ""
        this.maxDepth = maxDepth
        // The declared node bound can never exceed what the framework can
        // actually mount: one component instance per node, capped by the
        // per-controller registry. Reporting a larger bound would advertise a
        // structure size that can only fail later.
        this.maxNodes = if (maxNodes > CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY) {
            CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY
        } else {
            maxNodes
        }
        this.maxPropertiesPerNode = maxPropertiesPerNode
        this.maxStringLength = maxStringLength
    }

    /// Registers one component kind. A kind whose presentation is not
    /// implemented, or whose declared layout properties do not map onto a real
    /// layout attribute, is rejected here - registration itself is the
    /// guarantee that a generated node can actually be presented.
    public func registerComponent(spec: CjguiGeneratedUiComponentSpec): Bool {
        if (spec.kind.size == 0 || !spec.isImplemented()) {
            lastRegistrationIssue = "component_presentation_not_implemented:${spec.kind}"
            return false
        }
        if (let Some(_) <- componentFor(spec.kind)) {
            lastRegistrationIssue = "duplicate_component_kind:${spec.kind}"
            return false
        }
        if (!spec.allowsChildren && spec.childLimit > 0) {
            lastRegistrationIssue = "child_limit_without_children:${spec.kind}"
            return false
        }
        for (property in spec.properties) {
            if (property.valueType != "STRING" && property.valueType != "INTEGER" && property.valueType != "BOOLEAN") {
                lastRegistrationIssue = "unknown_property_type:${spec.kind}:${property.name}"
                return false
            }
            if (!CjguiGeneratedUiPresentation.isPropertyImplemented(spec.presentation, property.name, property.valueType)) {
                lastRegistrationIssue = "property_not_implemented:${spec.kind}:${property.name}"
                return false
            }
        }
        components.add(spec)
        lastRegistrationIssue = ""
        return true
    }

    /// Registers one rule the application's generated descriptions may use.
    /// It shares the framework tween value contract with handwritten motion but
    /// remains scoped to this catalog/application.
    public func registerMotionRule(rule: CjguiGeneratedMotionRule): Bool {
        let accepted = motionRuleRegistryValue.registerRule(rule)
        lastRegistrationIssue = if (accepted) { "" } else { motionRuleRegistryValue.lastIssue() }
        return accepted
    }

    /// Explicitly publishes and enables the generated root `windowBackground`
    /// declaration for this application. The default remains disabled.
    public func enableWindowBackground(): Unit {
        windowBackgroundEnabledValue = true
    }

    public func windowBackgroundEnabled(): Bool {
        return windowBackgroundEnabledValue
    }

    public func motionRuleRegistry(): CjguiGeneratedMotionRegistry {
        return motionRuleRegistryValue
    }

    public func registerAction(spec: CjguiGeneratedUiActionSpec): Bool {
        if (spec.name.size == 0) {
            lastRegistrationIssue = "empty_action_name"
            return false
        }
        if (let Some(_) <- actionFor(spec.name)) {
            lastRegistrationIssue = "duplicate_action:${spec.name}"
            return false
        }
        actions.add(spec)
        lastRegistrationIssue = ""
        return true
    }

    /// Registers one application field from its derived definition. Callers
    /// build these from their existing form binding
    /// (CjguiGeneratedUiFieldSpec.fromFormBinding), so there is exactly one
    /// authored field list.
    public func registerField(spec: CjguiGeneratedUiFieldSpec): Bool {
        let existing = fieldFor(spec.fieldId)
        if (let Some(_) <- existing) {
            lastRegistrationIssue = "duplicate_field:${spec.fieldId}"
            return false
        }
        if (spec.resourceId <= 0) {
            lastRegistrationIssue = "field_without_resource:${spec.fieldId}"
            return false
        }
        fields.add(spec)
        lastRegistrationIssue = ""
        return true
    }

    private static let imageContentIdentityLimit: Int64 = 256

    private static func imageContentIdentityKey(key: String, version: Int64): String {
        return "${key}\u{1f}${version}"
    }

    /// How many live ACCEPTED/candidate bindings still reference one identity.
    /// The recorded raster may only be forgotten when this reaches zero.
    private var liveImageIdentities: HashMap<String, Int64>

    /// Declares that one accepted/candidate binding holds this published identity.
    /// A live identity occupies its slot, so eviction can only drop records no
    /// holder references any more.
    public func retainImageIdentity(key: String, version: Int64): Unit {
        let identity = CjguiGeneratedUiCapabilityCatalog.imageContentIdentityKey(key, version)
        let current = match (liveImageIdentities.get(identity)) {
            case Some(value) => value
            case None => 0
        }
        liveImageIdentities.add(identity, current + 1)
        if (!imageContentIdentities.contains(identity)) {
            // Occupies a slot even before the raster is known, so the bounded
            // table reflects real references.
            imageContentIdentities.add(identity, "")
            imageContentIdentityOrder.add(identity)
        }
    }

    public func releaseImageIdentity(key: String, version: Int64): Unit {
        let identity = CjguiGeneratedUiCapabilityCatalog.imageContentIdentityKey(key, version)
        let current = match (liveImageIdentities.get(identity)) {
            case Some(value) => value
            case None => 0
        }
        if (current <= 1) {
            let _ = liveImageIdentities.remove(identity)
        } else {
            liveImageIdentities.add(identity, current - 1)
        }
    }

    private func imageIdentityIsLive(identity: String): Bool {
        return match (liveImageIdentities.get(identity)) {
            case Some(value) => value > 0
            case None => false
        }
    }

    /// How many published identities the accepted/candidate bindings still hold.
    /// Observation only: no raster path or native handle is exposed.
    public func liveImageIdentityCount(): Int64 {
        var count: Int64 = 0
        for ((_, held) in liveImageIdentities) {
            if (held > 0) {
                count += 1
            }
        }
        return count
    }

    /// The total number of holds. One accepted binding owns exactly one hold, so
    /// repeated successful commits of the same identity must not grow this.
    public func liveImageIdentityHoldCount(): Int64 {
        var total: Int64 = 0
        for ((_, held) in liveImageIdentities) {
            if (held > 0) {
                total += held
            }
        }
        return total
    }

    /// Admits the raster a published identity denotes, or reports the conflict.
    /// A recorded identity may only be reused with the SAME raster: a removal
    /// does not lift this, because an accepted instance can still hold the
    /// retired identity, so re-registering the same version under another file
    /// would make the public identity mean two different things.
    /// Reasons this admission can refuse: "" (accepted),
    /// `image_resource_content_identity_conflict` (the same published identity
    /// already means another raster) or `image_resource_identity_capacity` (every
    /// slot is held by a live reference and nothing may be forgotten).
    private func admitImageContentIdentityReason(key: String, version: Int64, rasterPath: String): String {
        // The current directory is authoritative and does not depend on the
        // bounded history table: a declared key/version already means the raster
        // it was declared with, so reclaiming its history slot can never let the
        // same published identity be re-pointed at another file.
        for (declared in imageResources) {
            if (declared.key == key && declared.version == version) {
                return if (declared.rasterPath == rasterPath) {
                    ""
                } else {
                    "image_resource_content_identity_conflict"
                }
            }
        }
        let identity = CjguiGeneratedUiCapabilityCatalog.imageContentIdentityKey(key, version)
        if (let Some(existing) <- imageContentIdentities.get(identity)) {
            if (existing.size == 0) {
                // A live reference occupies the slot before a raster is known.
                imageContentIdentities.add(identity, rasterPath)
                return ""
            }
            return if (existing == rasterPath) {
                ""
            } else {
                "image_resource_content_identity_conflict"
            }
        }
        if (imageContentIdentityOrder.size >= CjguiGeneratedUiCapabilityCatalog.imageContentIdentityLimit) {
            // Drop the oldest record that NO accepted/candidate binding holds.
            var index = 0
            var evicted: Option<String> = None
            while (index < imageContentIdentityOrder.size) {
                let candidate = imageContentIdentityOrder[index]
                if (!imageIdentityIsLive(candidate)) {
                    evicted = Some(candidate)
                    let _ = imageContentIdentityOrder.remove(at: index)
                    break
                }
                index += 1
            }
            if (let Some(evictedIdentity) <- evicted) {
                let _ = imageContentIdentities.remove(evictedIdentity)
            } else {
                return "image_resource_identity_capacity"
            }
        }
        imageContentIdentities.add(identity, rasterPath)
        imageContentIdentityOrder.add(identity)
        return ""
    }

    /// The recorded raster of one published identity, or "" when it is unknown
    /// (never admitted / already reclaimed).
    public func imageContentIdentityRasterFor(key: String, version: Int64): String {
        // The current directory answers first: its declaration is authoritative
        // even when the bounded history slot was reclaimed.
        for (declared in imageResources) {
            if (declared.key == key && declared.version == version) {
                return declared.rasterPath
            }
        }
        let identity = CjguiGeneratedUiCapabilityCatalog.imageContentIdentityKey(key, version)
        return match (imageContentIdentities.get(identity)) {
            case Some(value) => value
            case None => ""
        }
    }

    /// Registers ONE application image resource. The declaration is the only
    /// place a raster path exists: an external candidate names the logical key
    /// and version, never a file. A duplicate key, an unsupported type, a
    /// non-positive version or an empty name/path is rejected at registration.
    public func registerImageResource(spec: CjguiGeneratedUiImageResourceSpec): Bool {
        lastRegistrationIssue = ""
        if (!spec.isValid()) {
            lastRegistrationIssue = "image_resource_declaration_invalid:${spec.key}"
            return false
        }
        for (existing in imageResources) {
            if (existing.key == spec.key) {
                lastRegistrationIssue = "duplicate_image_resource_key:${spec.key}"
                return false
            }
        }
        let identityReason = admitImageContentIdentityReason(spec.key, spec.version, spec.rasterPath)
        if (identityReason.size > 0) {
            lastRegistrationIssue = identityReason
            return false
        }
        imageResources.add(spec)
        return true
    }

    /// Replaces the declaration of an ALREADY registered key (for example a new
    /// version hosting a different raster). The identity stays the same logical
    /// resource; the version is part of the declaration, so a caller that still
    /// references the old version stops resolving. Declaring a version the key
    /// never had is an error, not an implicit registration. The SAME version may
    /// not be re-pointed at another raster: that would change what an accepted
    /// instance's published identity means. A metadata (name) change is legal on
    /// the same version.
    public func updateImageResource(spec: CjguiGeneratedUiImageResourceSpec): Bool {
        lastRegistrationIssue = ""
        if (!spec.isValid()) {
            lastRegistrationIssue = "image_resource_declaration_invalid:${spec.key}"
            return false
        }
        var index: Int64 = 0
        while (index < imageResources.size) {
            if (imageResources[index].key == spec.key) {
                let identityReason = admitImageContentIdentityReason(spec.key, spec.version, spec.rasterPath)
                if (identityReason.size > 0) {
                    lastRegistrationIssue = identityReason
                    return false
                }
                imageResources[index] = spec
                return true
            }
            index += 1
        }
        lastRegistrationIssue = "image_resource_not_registered:${spec.key}"
        return false
    }

    /// Removes a declaration. Any accepted reference to it stops resolving; the
    /// resource revision moves so observers are told the reference set changed.
    public func removeImageResource(key: String): Bool {
        lastRegistrationIssue = ""
        var index: Int64 = 0
        while (index < imageResources.size) {
            if (imageResources[index].key == key) {
                let _ = imageResources.remove(at: index)
                return true
            }
            index += 1
        }
        lastRegistrationIssue = "image_resource_not_registered:${key}"
        return false
    }

    /// Strict resolution: the key must be registered AND the declared version
    /// must equal the registered one. A newer/older version is not silently
    /// served by the closest resource.
    public func imageResourceFor(key: String, version: Int64): ?CjguiGeneratedUiImageResourceSpec {
        for (spec in imageResources) {
            if (spec.key == key && spec.version == version) {
                return Some(spec)
            }
        }
        return None
    }

    public func imageResourceSpecs(): ArrayList<CjguiGeneratedUiImageResourceSpec> {
        let specs = ArrayList<CjguiGeneratedUiImageResourceSpec>()
        for (spec in imageResources) {
            specs.add(spec)
        }
        return specs
    }

    /// Whether ANY version of the key is registered (used only to distinguish
    /// "unknown resource" from "wrong version" in the public rejection).
    public func imageResourceKeyRegistered(key: String): Bool {
        for (spec in imageResources) {
            if (spec.key == key) {
                return true
            }
        }
        return false
    }

    public func imageResourceNames(): ArrayList<String> {
        let names = ArrayList<String>()
        for (spec in imageResources) {
            names.add(spec.key)
        }
        return names
    }

    /// The application's named-style registry. The same object is consumed by the
    /// application's handwritten helpers and by the generated resolution below.
    public func namedStyles(): CjguiComposableUiNamedStyleCatalog {
        return namedStyleCatalog
    }

    /// Fingerprint of the registered resource declarations (key, type, version,
    /// NAME and path). A declaration change moves it, so public discovery and
    /// observation can report that references may have been withdrawn - including
    /// a metadata-only name change, which does not need a new image version but
    /// must still invalidate what was published. Register, update and remove all
    /// feed this one source.
    public func imageResourceRevision(): Int64 {
        var hash: Int64 = 17
        for (spec in imageResources) {
            hash = (hash * 131 + spec.version) % 2147483647
            for (byte in spec.key.toArray()) {
                hash = (hash * 131 + Int64(byte)) % 2147483647
            }
            for (byte in spec.contentType.toArray()) {
                hash = (hash * 131 + Int64(byte)) % 2147483647
            }
            for (byte in spec.name.toArray()) {
                hash = (hash * 131 + Int64(byte)) % 2147483647
            }
            for (byte in spec.rasterPath.toArray()) {
                hash = (hash * 131 + Int64(byte)) % 2147483647
            }
        }
        return hash
    }

    /// Registers several derived field definitions at once (one definition per
    /// application form binding).
    public func registerFields(specs: ArrayList<CjguiGeneratedUiFieldSpec>): Bool {
        for (spec in specs) {
            if (!registerField(spec)) {
                return false
            }
        }
        return true
    }

    private var lastRegistrationIssue: String = ""

    /// Registers an application composite kind together with its compiled
    /// implementation. The kind is validated against the SAME rules a built-in
    /// kind obeys (no override of a built-in kind, no duplicate, known property
    /// value types, real field/action references, budgets within the catalog's),
    /// and the derived component spec uses the COMPOSITE presentation. Because
    /// spec and factory are stored atomically, a kind can never be registered
    /// with the composite presentation but no real implementation.
    public func registerComposite(spec: CjguiCompositeComponentSpec, factory: CjguiCompositeComponentFactory): Bool {
        lastRegistrationIssue = ""
        if (spec.kind.size == 0) {
            lastRegistrationIssue = "empty_component_kind"
            return false
        }
        if (CjguiGeneratedUiPresentation.forBuiltInKind(spec.kind).size > 0) {
            lastRegistrationIssue = "built_in_kind_not_overridable:${spec.kind}"
            return false
        }
        if (let Some(_) <- componentFor(spec.kind)) {
            lastRegistrationIssue = "duplicate_component_kind:${spec.kind}"
            return false
        }
        if (spec.elements.size == 0) {
            lastRegistrationIssue = "composite_has_no_elements:${spec.kind}"
            return false
        }
        if (spec.expandedNodeLimit <= 0 || spec.expandedNodeLimit > maxNodes) {
            lastRegistrationIssue = "composite_expanded_node_limit:${spec.kind}"
            return false
        }
        if (spec.expandedDepthLimit <= 0 || spec.expandedDepthLimit > maxDepth) {
            lastRegistrationIssue = "composite_expanded_depth_limit:${spec.kind}"
            return false
        }
        // Element keys are the scoped identities: unique within the kind, and
        // every declared parent must itself be an element.
        let elementKeys = HashSet<String>()
        for (element in spec.elements) {
            if (element.elementKey.size == 0 || elementKeys.contains(element.elementKey)) {
                lastRegistrationIssue = "composite_duplicate_element_key:${spec.kind}:${element.elementKey}"
                return false
            }
            elementKeys.add(element.elementKey)
        }
        for (element in spec.elements) {
            if (!element.parentKey.isEmpty() && !elementKeys.contains(element.parentKey)) {
                lastRegistrationIssue = "composite_unknown_parent:${spec.kind}:${element.elementKey}"
                return false
            }
            validateCompositeElement(spec, element)
            if (!lastRegistrationIssue.isEmpty()) {
                return false
            }
        }
        // Property value types must be real, and a declared property nothing can
        // consume is rejected exactly like a built-in property that no
        // presentation reads.
        for (property in spec.properties) {
            if (property.valueType != "STRING" && property.valueType != "INTEGER" && property.valueType != "BOOLEAN") {
                lastRegistrationIssue = "unknown_property_type:${spec.kind}:${property.name}"
                return false
            }
        }
        let derived = CjguiGeneratedUiComponentSpec(spec.kind, spec.properties, spec.allowsChildren,
            childLimit: spec.childLimit, presentation: CJGUI_GENERATED_PRESENTATION_COMPOSITE)
        if (!registerComponent(derived)) {
            return false
        }
        composites.add(spec)
        compositeFactories.add(factory)
        return true
    }

    private func validateCompositeElement(spec: CjguiCompositeComponentSpec, element: CjguiCompositeElementSpec): Unit {
        let role = element.role
        if (role == CJGUI_COMPOSITE_ELEMENT_CONTAINER) {
            if (!element.fieldId.isEmpty() || !element.actionName.isEmpty()) {
                lastRegistrationIssue = "composite_container_binding:${spec.kind}:${element.elementKey}"
                return
            }
            if (!element.argumentName.isEmpty()) {
                lastRegistrationIssue = "composite_container_argument:${spec.kind}:${element.elementKey}"
            }
            return
        }
        if (role == CJGUI_COMPOSITE_ELEMENT_FIELD || role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
            if (element.fieldId.isEmpty()) {
                lastRegistrationIssue = "composite_field_required:${spec.kind}:${element.elementKey}"
                return
            }
            if (let None <- fieldFor(element.fieldId)) {
                lastRegistrationIssue = "unknown_field:${spec.kind}:${element.fieldId}"
                return
            }
            let field = match (fieldFor(element.fieldId)) {
                case Some(value) => value
                case None => CjguiGeneratedUiFieldSpec("", "", "", -1)
            }
            if (!field.isWritable()) {
                lastRegistrationIssue = "composite_field_has_no_writer:${spec.kind}:${element.fieldId}"
                return
            }
            if (role == CJGUI_COMPOSITE_ELEMENT_PRESET && element.presetValue.size == 0) {
                lastRegistrationIssue = "composite_preset_value_required:${spec.kind}:${element.elementKey}"
                return
            }
            if (element.argumentName.isEmpty()) {
                // Without the writer's argument the framework could only hand the
                // consumer a writer name, and every consumer would guess the
                // argument again. The application declares it once, here.
                lastRegistrationIssue = "composite_field_argument_required:${spec.kind}:${element.elementKey}"
                return
            }
            // When the FIELD itself declares the argument its writer takes, the
            // element must use that same argument: otherwise the framework would
            // hand the consumer an argument the owner's operation does not accept,
            // which is exactly the drift the single definition exists to prevent.
            if (field.argumentName.size > 0 && element.argumentName != field.argumentName) {
                lastRegistrationIssue = "composite_element_argument_mismatch:${spec.kind}:${element.elementKey}"
                return
            }
            if (!element.actionName.isEmpty()) {
                lastRegistrationIssue = "composite_field_element_action:${spec.kind}:${element.elementKey}"
            }
            return
        }
        if (role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
            if (element.actionName.isEmpty()) {
                lastRegistrationIssue = "composite_action_required:${spec.kind}:${element.elementKey}"
                return
            }
            if (let None <- actionFor(element.actionName)) {
                lastRegistrationIssue = "unknown_action:${spec.kind}:${element.actionName}"
                return
            }
            if (!element.fieldId.isEmpty()) {
                lastRegistrationIssue = "composite_action_element_field:${spec.kind}:${element.elementKey}"
                return
            }
            if (!element.argumentName.isEmpty()) {
                // An action owns its declared parameters; a composite action
                // element does not bind a field argument.
                lastRegistrationIssue = "composite_action_argument:${spec.kind}:${element.elementKey}"
            }
            return
        }
        lastRegistrationIssue = "composite_unknown_role:${spec.kind}:${element.elementKey}"
    }

    public func compositeFor(kind: String): ?CjguiCompositeComponentSpec {
        for (spec in composites) {
            if (spec.kind == kind) {
                return Some(spec)
            }
        }
        return None
    }

    public func compositeFactoryFor(kind: String): ?CjguiCompositeComponentFactory {
        var index: Int64 = 0
        while (index < composites.size) {
            if (composites[index].kind == kind) {
                return Some(compositeFactories[index])
            }
            index += 1
        }
        return None
    }

    /// Declared composite kinds, so an external reader can discover them beside
    /// the built-in component kinds.
    public func compositeKinds(): ArrayList<String> {
        let result = ArrayList<String>()
        for (spec in composites) {
            result.add(spec.kind)
        }
        return result
    }

    /// Reason text of the most recent rejected registration ("" when the last
    /// registration succeeded).
    public func lastRegistrationRejection(): String {
        return lastRegistrationIssue
    }

    public func componentFor(kind: String): ?CjguiGeneratedUiComponentSpec {
        for (spec in components) {
            if (spec.kind == kind) {
                return Some(spec)
            }
        }
        return None
    }

    public func actionFor(name: String): ?CjguiGeneratedUiActionSpec {
        for (spec in actions) {
            if (spec.name == name) {
                return Some(spec)
            }
        }
        return None
    }

    public func fieldFor(fieldId: String): ?CjguiGeneratedUiFieldSpec {
        for (field in fields) {
            if (field.fieldId == fieldId) {
                return Some(field)
            }
        }
        return None
    }

    public func hasField(fieldId: String): Bool {
        return fieldFor(fieldId).isSome()
    }

    public func componentKinds(): ArrayList<String> {
        let result = ArrayList<String>()
        for (spec in components) {
            result.add(spec.kind)
        }
        return result
    }

    public func actionNames(): ArrayList<String> {
        let result = ArrayList<String>()
        for (spec in actions) {
            result.add(spec.name)
        }
        return result
    }

    public func fieldIds(): ArrayList<String> {
        let result = ArrayList<String>()
        for (field in fields) {
            result.add(field.fieldId)
        }
        return result
    }

    public func fieldSpecs(): ArrayList<CjguiGeneratedUiFieldSpec> {
        return ArrayList<CjguiGeneratedUiFieldSpec>(fields)
    }
}

/// Structure value model: one node of a candidate description.
public class CjguiGeneratedUiNodeSpec {
    public let key: String
    public let kind: String
    public let properties: HashMap<String, String>
    public let fieldId: String
    public let actionName: String
    public let children: ArrayList<CjguiGeneratedUiNodeSpec>

    public init(key: String, kind: String, properties!: HashMap<String, String> = HashMap<String, String>(),
        fieldId!: String = "", actionName!: String = "",
        children!: ArrayList<CjguiGeneratedUiNodeSpec> = ArrayList<CjguiGeneratedUiNodeSpec>()) {
        this.key = key
        this.kind = kind
        this.properties = properties
        this.fieldId = fieldId
        this.actionName = actionName
        this.children = children
    }

    public func property(name: String): String {
        if (let Some(value) <- properties.get(name)) {
            return value
        }
        return ""
    }
}

/// Validation outcome with the specific position and reason.
public class CjguiGeneratedUiValidation {
    public let accepted: Bool
    public let reason: String
    public let path: String

    public init(accepted: Bool, reason: String, path: String) {
        this.accepted = accepted
        this.reason = reason
        this.path = path
    }

    public static func ok(): CjguiGeneratedUiValidation {
        return CjguiGeneratedUiValidation(true, "", "")
    }

    public static func reject(reason: String, path: String): CjguiGeneratedUiValidation {
        return CjguiGeneratedUiValidation(false, reason, path)
    }
}

/// Validates a candidate description against the catalog and the size bounds.
public class CjguiGeneratedUiValidator {
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    // Nodes visited in the current validation walk. The counter lives on the
    // validator (reset per validate call) because the tree walk must count
    // every node once, not only the current path.
    private var nodesSeen: Int64
    // Reserved for future NON-FATAL declaration advisories. The encoded-effect
    // path no longer uses it: a malformed `shadow`/`gradient` now refuses the
    // whole candidate through the ordinary rejection path with a stable reason.
    private var lastAdvisory: String

    public init(catalog: CjguiGeneratedUiCapabilityCatalog) {
        this.catalog = catalog
        this.nodesSeen = 0
        this.lastAdvisory = ""
    }

    public func validate(root: CjguiGeneratedUiNodeSpec): CjguiGeneratedUiValidation {
        let seen = HashSet<String>()
        nodesSeen = 0
        lastAdvisory = ""
        return validateNode(root, "root", 0, seen)
    }

    /// Readable note of the last non-fatal declaration problem seen by this
    /// validator ("" when none). It is reserved for future advisories; a
    /// malformed `shadow`/`gradient` is no longer advisory and instead rejects
    /// the candidate with a stable reason.
    public func lastAdvisoryNote(): String {
        return lastAdvisory
    }

    private func validateNode(node: CjguiGeneratedUiNodeSpec, path: String, depth: Int64, seen: HashSet<String>): CjguiGeneratedUiValidation {
        if (depth > catalog.maxDepth) {
            return CjguiGeneratedUiValidation.reject("max_depth_exceeded", path)
        }
        nodesSeen += 1
        if (nodesSeen > catalog.maxNodes) {
            return CjguiGeneratedUiValidation.reject("max_nodes_exceeded", path)
        }
        if (nodesSeen > CJGUI_GENERATED_UI_COMPONENT_INSTANCE_CAPACITY) {
            // The framework's component registry caps one generated structure
            // at this many live instances; declaring it here keeps the failure
            // at validation time with a specific reason.
            return CjguiGeneratedUiValidation.reject("component_instance_capacity", path)
        }
        if (node.key.size == 0) {
            return CjguiGeneratedUiValidation.reject("empty_key", path)
        }
        if (seen.contains(node.key)) {
            return CjguiGeneratedUiValidation.reject("duplicate_key", "${path}/${node.key}")
        }
        seen.add(node.key)
        if (let Some(spec) <- catalog.componentFor(node.kind)) {
            if (!spec.isImplemented()) {
                return CjguiGeneratedUiValidation.reject("component_not_implemented", "${path}/${node.key}")
            }
            if (node.properties.size > catalog.maxPropertiesPerNode) {
                return CjguiGeneratedUiValidation.reject("too_many_properties", "${path}/${node.key}")
            }
            for ((name, value) in node.properties) {
                if (name == "windowBackground") {
                    if (!catalog.windowBackgroundEnabled()) {
                        return CjguiGeneratedUiValidation.reject("window_background_not_enabled",
                            "${path}/${node.key}/${name}")
                    }
                    if (depth != 0) {
                        return CjguiGeneratedUiValidation.reject("window_background_root_only",
                            "${path}/${node.key}/${name}")
                    }
                    if (!CjguiWindowBackgroundPolicy.isValidToken(value)) {
                        return CjguiGeneratedUiValidation.reject("window_background_value_invalid",
                            "${path}/${node.key}/${name}")
                    }
                    continue
                }
                // A small common semantic vocabulary is available to every
                // registered author without copying role properties into each
                // application component catalog. Kind/role admission remains
                // strict so a label cannot claim to be an actionable tree row.
                if (name == "semanticRole") {
                    if (!((value == "outline" && spec.presentation == CJGUI_GENERATED_PRESENTATION_SCROLL) ||
                        (value == "row" && spec.presentation == CJGUI_GENERATED_PRESENTATION_ACTION))) {
                        return CjguiGeneratedUiValidation.reject("semantic_role_kind_invalid", "${path}/${node.key}/${name}")
                    }
                    continue
                }
                if (name == "semanticSelected" || name == "semanticExpandable" || name == "semanticExpanded" ||
                    name == "disabled") {
                    if ((value != "true" && value != "false") ||
                        (name != "disabled" && node.property("semanticRole") != "row") ||
                        (name == "disabled" && spec.presentation != CJGUI_GENERATED_PRESENTATION_ACTION)) {
                        return CjguiGeneratedUiValidation.reject("semantic_boolean_invalid", "${path}/${node.key}/${name}")
                    }
                    continue
                }
                if (name == "semanticLevel") {
                    let level = match (parseGeneratedInteger(value)) {
                        case Some(number) => number
                        case None => -1
                    }
                    if (node.property("semanticRole") != "row" || level < 0 || level > 32) {
                        return CjguiGeneratedUiValidation.reject("semantic_level_invalid", "${path}/${node.key}/${name}")
                    }
                    continue
                }
                if (name == "semanticRowKey" || name == "semanticParentKey") {
                    if (node.property("semanticRole") != "row" || value.size == 0 || value.size > 64 ||
                        !CjguiComposableUiNamedStyleCatalog.isValidName(value)) {
                        return CjguiGeneratedUiValidation.reject("semantic_key_invalid", "${path}/${node.key}/${name}")
                    }
                    continue
                }
                if (name == "semanticLabel") {
                    if (value.size == 0 || value.size > 256) {
                        return CjguiGeneratedUiValidation.reject("semantic_label_invalid", "${path}/${node.key}/${name}")
                    }
                    continue
                }
                if (let Some(property) <- propertySpec(spec, name)) {
                    let rejected = validatePropertyValue(property, value, "${path}/${node.key}/${name}")
                    if (let Some(reason) <- rejected) {
                        return CjguiGeneratedUiValidation.reject(reason, "${path}/${node.key}/${name}")
                    }
                } else {
                    return CjguiGeneratedUiValidation.reject("unknown_property", "${path}/${node.key}/${name}")
                }
            }
            if (node.property("semanticRole") == "row") {
                if (node.property("semanticExpanded") == "true" &&
                    node.property("semanticExpandable") != "true") {
                    return CjguiGeneratedUiValidation.reject("semantic_expanded_without_group", "${path}/${node.key}")
                }
                if (node.property("semanticParentKey").size > 0 &&
                    node.property("semanticParentKey") == node.property("semanticRowKey")) {
                    return CjguiGeneratedUiValidation.reject("semantic_parent_cycle", "${path}/${node.key}")
                }
            }
            // Required properties must actually be present; an omitted required
            // attribute is not the same as an empty value.
            for (property in spec.properties) {
                if (property.required && !node.properties.contains(property.name)) {
                    return CjguiGeneratedUiValidation.reject("missing_required_property",
                        "${path}/${node.key}/${property.name}")
                }
            }
            if (spec.presentation == CJGUI_GENERATED_PRESENTATION_IMAGE) {
                let imageIssue = validateImageResource(node, path)
                if (let Some(reason) <- imageIssue) {
                    return CjguiGeneratedUiValidation.reject(reason, "${path}/${node.key}")
                }
            }
            let bindingIssue = validateBinding(node, spec, path)
            if (let Some(reason) <- bindingIssue) {
                return CjguiGeneratedUiValidation.reject(reason, "${path}/${node.key}")
            }
            if (spec.presentation == CJGUI_GENERATED_PRESENTATION_SPLIT && node.children.size != 2) {
                return CjguiGeneratedUiValidation.reject("split_requires_two_children", "${path}/${node.key}")
            }
            if (spec.presentation == CJGUI_GENERATED_PRESENTATION_TABS) {
                // A bounded working set of pages, each with a STABLE page key: the
                // key is what a restored active page refers to, so a duplicate or
                // a missing key is refused as a whole candidate.
                if (node.children.size < 2 || node.children.size > 3) {
                    return CjguiGeneratedUiValidation.reject("tabs_require_two_or_three_pages", "${path}/${node.key}")
                }
                let seenKeys = ArrayList<String>()
                for (child in node.children) {
                    // A page is its own kind, so the key/title binding is explicit
                    // and an arbitrary content node cannot smuggle a page identity.
                    let childPresentation = match (catalog.componentFor(child.kind)) {
                        case Some(childSpec) => childSpec.presentation
                        case None => ""
                    }
                    if (childPresentation != CJGUI_GENERATED_PRESENTATION_TAB_PAGE) {
                        return CjguiGeneratedUiValidation.reject("tabs_child_must_be_page",
                            "${path}/${node.key}/${child.key}")
                    }
                    if (child.children.size != 1) {
                        return CjguiGeneratedUiValidation.reject("tabs_page_requires_one_content",
                            "${path}/${node.key}/${child.key}")
                    }
                    let pageKey = child.property("pageKey")
                    if (pageKey.size == 0) {
                        return CjguiGeneratedUiValidation.reject("tabs_page_key_required",
                            "${path}/${node.key}/${child.key}")
                    }
                    if (child.property("pageTitle").size == 0) {
                        return CjguiGeneratedUiValidation.reject("tabs_page_title_required",
                            "${path}/${node.key}/${child.key}")
                    }
                    for (existing in seenKeys) {
                        if (existing == pageKey) {
                            return CjguiGeneratedUiValidation.reject("tabs_duplicate_page_key",
                                "${path}/${node.key}/${child.key}")
                        }
                    }
                    seenKeys.add(pageKey)
                }
                let declaredPage = node.property("initialPage")
                if (declaredPage.size > 0) {
                    var declaredFound = false
                    for (key in seenKeys) {
                        if (key == declaredPage) {
                            declaredFound = true
                        }
                    }
                    if (!declaredFound) {
                        return CjguiGeneratedUiValidation.reject("tabs_initial_page_unknown", "${path}/${node.key}")
                    }
                }
            }
            if (spec.presentation == CJGUI_GENERATED_PRESENTATION_SCROLL) {
                // Nested GENERATED scroll is not supported: with two nested
                // viewports the wheel route would have to guess which one owns a
                // gesture. The check walks the WHOLE descendant subtree, because a
                // `scroll -> vertical -> scroll` shape would otherwise slip past a
                // direct-children test and be accepted with two viewports.
                let nested = nestedScrollDescendant(node)
                if (nested.size > 0) {
                    // `path` names this node's PARENT, so the offending path is the
                    // parent chain plus this node's key plus the descendant chain.
                    return CjguiGeneratedUiValidation.reject("nested_scroll_not_supported",
                        "${path}/${node.key}/${nested}")
                }
            }
            if (!spec.allowsChildren && node.children.size > 0) {
                return CjguiGeneratedUiValidation.reject("children_not_allowed", "${path}/${node.key}")
            }
            if (spec.childLimit > 0 && node.children.size > spec.childLimit) {
                return CjguiGeneratedUiValidation.reject("child_limit_exceeded", "${path}/${node.key}")
            }
        } else {
            return CjguiGeneratedUiValidation.reject("unknown_component", "${path}/${node.key}")
        }
        var index: Int64 = 0
        while (index < node.children.size) {
            let result = validateNode(node.children[index], "${path}/${node.key}", depth + 1, seen)
            if (!result.accepted) {
                return result
            }
            index += 1
        }
        return CjguiGeneratedUiValidation.ok()
    }

    /// An image node must name a resource this application registered AND the
    /// exact version. The public reason distinguishes an unknown key from a
    /// version mismatch; a candidate that would silently drop the image is
    /// rejected as a whole, leaving the accepted interface untouched.
    private func validateImageResource(node: CjguiGeneratedUiNodeSpec, path: String): ?String {
        let key = node.property("resource")
        if (key.size == 0) {
            return Some("image_resource_missing")
        }
        let version = match (parseGeneratedInteger(node.property("resourceVersion"))) {
            case Some(value) => value
            case None => return Some("image_resource_version_invalid")
        }
        if (let Some(_) <- catalog.imageResourceFor(key, version)) {
            let mode = node.property("contentMode")
            if (mode.size > 0 && mode != "fit" && mode != "fill") {
                return Some("image_content_mode_unsupported")
            }
            return None
        }
        if (catalog.imageResourceKeyRegistered(key)) {
            return Some("image_resource_version_mismatch")
        }
        return Some("image_resource_not_registered")
    }

    private func propertySpec(spec: CjguiGeneratedUiComponentSpec, name: String): ?CjguiGeneratedUiPropertySpec {
        for (property in spec.properties) {
            if (property.name == name) {
                return Some(property)
            }
        }
        return None
    }

    /// Enforces the declared property value type and numeric range. A declared
    /// type is a contract: a non-numeric value for an INTEGER property or an
    /// out-of-range number is rejected with its own reason instead of being
    /// forwarded to the renderer as text.
    private func validatePropertyValue(property: CjguiGeneratedUiPropertySpec, value: String, path: String): ?String {
        if (property.valueType == "STRING") {
            if (property.maxLength > 0 && value.size > property.maxLength) {
                return "property_too_long"
            }
            if (property.name == "style" || property.name == "titleStyle") {
                if (catalog.namedStyles().forName(value).isNone()) {
                    return "style_reference_not_registered"
                }
            } else if (property.name == "translateX" || property.name == "translateY") {
                if (value.size > 0 && cjguiComposableUiParseTranslationScalar(value).isNone()) {
                    return "translation_value_invalid"
                }
            } else if (property.name == "shadow" || property.name == "gradient" || property.name == "effectGroup") {
                // An encoded effect is a real contract, not an advisory: `none`
                // and the empty value explicitly CLEAR the effect, a legal token
                // REPLACES it, and malformed text refuses the WHOLE candidate
                // with a stable reason (the caller adds the property path). A
                // bad effect never half-applies while the previous accepted
                // structure is silently kept.
                if (!cjguiComposableUiEffectTokenIsNone(value)) {
                    if (property.name == "shadow") {
                        if (cjguiComposableUiParseShadowToken(value).isNone()) {
                            return "shadow_value_invalid"
                        }
                    } else if (property.name == "gradient") {
                        if (cjguiComposableUiParseGradientToken(value).isNone()) {
                            return "gradient_value_invalid"
                        }
                    } else {
                        if (cjguiComposableUiParseEffectGroupToken(value).isNone()) {
                            return "effect_group_value_invalid"
                        }
                    }
                }
            } else if (property.name == "motion") {
                let reason = catalog.motionRuleRegistry().rejectionReasonForName(value)
                if (reason.size > 0) {
                    return reason
                }
            } else if (CjguiGeneratedUiPresentation.isPaintPropertyName(property.name)) {
                if (cjguiComposableUiParseColorToken(value).isNone()) {
                    return "color_value_invalid"
                }
            }
            return None
        }
        if (property.valueType == "BOOLEAN") {
            if (value != "true" && value != "false") {
                return "property_not_boolean"
            }
            return None
        }
        if (property.valueType == "INTEGER") {
            let parsed = parseGeneratedInteger(value)
            if (let None <- parsed) {
                return "property_not_integer"
            }
            let number = match (parsed) {
                case Some(number) => number
                case None => 0
            }
            if (property.maximum > property.minimum) {
                if (number < property.minimum || number > property.maximum) {
                    return "property_out_of_range"
                }
            }
            return None
        }
        return "unknown_property_type"
    }

    /// Field/control compatibility: a field presentation is only valid with a
    /// registered field of the matching editor kind, an action node must
    /// reference a registered action, and a structural node must not carry a
    /// field or action binding at all.
    /// Path of the first DESCENDANT of `node` (at any depth) whose kind presents
    /// a scroll area, or "" when the subtree nests none. The whole subtree is
    /// walked, so an intermediate container cannot hide a second viewport from
    /// the nesting refusal.
    private func nestedScrollDescendant(node: CjguiGeneratedUiNodeSpec): String {
        for (child in node.children) {
            if (let Some(childSpec) <- catalog.componentFor(child.kind)) {
                if (childSpec.presentation == CJGUI_GENERATED_PRESENTATION_SCROLL) {
                    return child.key
                }
            }
            let deeper = nestedScrollDescendant(child)
            if (deeper.size > 0) {
                return "${child.key}/${deeper}"
            }
        }
        return ""
    }

    private func validateBinding(node: CjguiGeneratedUiNodeSpec, spec: CjguiGeneratedUiComponentSpec, path: String): ?String {
        let requiredEditor = CjguiGeneratedUiPresentation.requiredEditorKind(spec.presentation)
        if (requiredEditor.size > 0) {
            if (node.fieldId.isEmpty()) {
                return "field_binding_required"
            }
            let field = match (catalog.fieldFor(node.fieldId)) {
                case Some(value) => value
                case None => return "unknown_field"
            }
            if (field.editorKind != requiredEditor) {
                return "field_editor_kind_mismatch"
            }
            return None
        }
        if (spec.presentation == CJGUI_GENERATED_PRESENTATION_ACTION) {
            if (node.actionName.isEmpty()) {
                return "action_binding_required"
            }
            if (let None <- catalog.actionFor(node.actionName)) {
                return "unknown_action"
            }
            let declared = node.property("action")
            if (declared.size > 0 && declared != node.actionName) {
                return "action_property_mismatch"
            }
            return None
        }
        if (!node.fieldId.isEmpty()) {
            return "field_not_allowed"
        }
        if (!node.actionName.isEmpty()) {
            return "action_not_allowed"
        }
        return None
    }
}

/// Parses one generation-side integer property value. Returns None for
/// anything that is not a plain optionally-signed decimal integer, so a
/// declared INTEGER contract is enforced instead of silently becoming text.
/// Every stable key in one accepted generated structure, root included. The
/// holder uses it to release the per-instance view state of elements that are no
/// longer present, instead of keeping a removed instance's size or offset alive.
private func cjguiCollectGeneratedSpecKeys(spec: CjguiGeneratedUiNodeSpec, keys: ArrayList<String>): Unit {
    keys.add(spec.key)
    for (child in spec.children) {
        cjguiCollectGeneratedSpecKeys(child, keys)
    }
}

/// Resolves every declared motion reference to its app-registered rule value.
/// The validator has already proved each reference exists, so a missing value
/// here is treated defensively by omitting it; such a candidate cannot reach
/// this helper through the public submit path.
private func cjguiCollectGeneratedMotionRules(spec: CjguiGeneratedUiNodeSpec,
    registry: CjguiGeneratedMotionRegistry, bindings: HashMap<String, CjguiGeneratedMotionRule>): Unit {
    let motionName = spec.property("motion")
    if (motionName.size > 0) {
        if (let Some(rule) <- registry.ruleFor(motionName)) {
            bindings.add(spec.key, rule)
        }
    }
    for (child in spec.children) {
        cjguiCollectGeneratedMotionRules(child, registry, bindings)
    }
}

func parseGeneratedInteger(value: String): ?Int64 {
    if (value.size == 0) {
        return None
    }
    var result: Int64 = 0
    var negative = false
    var index = 0
    for (byte in value.toArray()) {
        if (index == 0 && byte == 45) {
            negative = true
            index += 1
            continue
        }
        if (byte < 48 || byte > 57) {
            return None
        }
        result = result * 10 + Int64(byte - 48)
        index += 1
    }
    return Some(if (negative) {
        -result
    } else {
        result
    })
}

// Stable, bounded binding generation for generated action rows. Reordering
// keeps the same AX wrapper; changing the public action target under the same
// key retires it even though its numeric layout id stays stable.
private func generatedSemanticActionIncarnation(actionName: String): Int64 {
    var result: Int64 = 7
    for (byte in actionName.toArray()) {
        result = (result * 31 + Int64(byte)) % 2147483647
    }
    return result
}

/// Application-owned bindings for generated fields and actions. Implementors
/// read live business state; the generated description never stores values.
public interface CjguiGeneratedUiBindingProvider {
    /// The shared field resource id for a field id, so a generated input
    /// references exactly the same field the handwritten form binds. Returns
    /// a negative value when the field is unknown.
    func fieldResourceId(fieldId: String): Int64
    /// The business owner target the field currently edits (for example the
    /// selected record id). A negative value means the field is not editable
    /// right now, and the generated input must not accept text.
    func fieldOperationResourceId(fieldId: String): Int64
    /// Draft text for a field ("", when the field has no text value).
    func draftText(fieldId: String): String
    /// Applied text for a field.
    func appliedText(fieldId: String): String
    /// Draft boolean value and whether the field is a boolean field.
    func draftBoolean(fieldId: String): ?Bool
    /// Executes an application action; returns the human-readable outcome and
    /// whether the domain applied it.
    func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult
    /// Whether the action is currently executable.
    func actionAvailable(actionName: String): Bool
    /// CURRENT, dynamic availability of one field's write: may it be edited
    /// right now, and if not, why. It must come from the SAME owner condition the
    /// write path enforces, so an editor's enabled state never promises a write
    /// the owner will refuse (the owner still re-checks inside its transaction).
    /// The default answers "unknown": a provider that has no evaluable condition
    /// does not claim either verdict.
    func fieldAvailability(fieldId: String): CjguiSharedAvailability {
        return CjguiSharedAvailability.unknown()
    }
    /// CURRENT, dynamic availability of one action, from the same owner
    /// condition. The default answers "unknown".
    func actionAvailability(actionName: String): CjguiSharedAvailability {
        return CjguiSharedAvailability.unknown()
    }
}

public class CjguiGeneratedUiActionResult {
    public let applied: Bool
    public let reason: String

    public init(applied: Bool, reason: String) {
        this.applied = applied
        this.reason = reason
    }
}

/// Public submission outcome. Candidate acceptance is deliberately separate
/// from scene acceptance: a candidate may be validated, rendered and prepared
/// while the window has not yet accepted the scene that contains it. The
/// accepted structure version only advances when the scene is accepted, and
/// the caller can distinguish the two states.
public class CjguiGeneratedUiSubmitResult {
    public let candidateAccepted: Bool
    public let sceneAccepted: Bool
    public let reason: String
    public let path: String
    public let structureVersionBefore: Int64
    public let structureVersionAfter: Int64
    public let candidateVersion: Int64
    /// Token of THIS submission attempt (0 only for a caller that did not go
    /// through the holder). The token, not the version, is what an external
    /// caller uses to ask about its own submission afterwards.
    public let candidateToken: Int64
    /// Stable receipt string of this attempt.
    public let receipt: String

    public init(candidateAccepted: Bool, sceneAccepted: Bool, reason: String, path: String,
        structureVersionBefore: Int64, structureVersionAfter: Int64, candidateVersion!: Int64 = 0,
        candidateToken!: Int64 = 0, receipt!: String = "") {
        this.candidateAccepted = candidateAccepted
        this.sceneAccepted = sceneAccepted
        this.reason = reason
        this.path = path
        this.structureVersionBefore = structureVersionBefore
        this.structureVersionAfter = structureVersionAfter
        this.candidateVersion = candidateVersion
        this.candidateToken = candidateToken
        this.receipt = receipt
    }
}

/// Render outcome for one candidate expansion.
class CjguiGeneratedUiRendered {
    let ok: Bool
    let reason: String
    let path: String
    let node: CjguiComposableUiNode

    init(ok: Bool, reason: String, path: String, node: CjguiComposableUiNode) {
        this.ok = ok
        this.reason = reason
        this.path = path
        this.node = node
    }
}

/// Terminal state of ONE candidate submission attempt.
///
/// A token is allocated for every attempt, including one that fails before any
/// structure exists (a malformed candidate or a structure-version conflict), so
/// an external submitter can always ask what happened to its OWN submission.
/// A version number cannot serve that purpose: two submitters can share a base
/// version, and a receipt string alone cannot cover the asynchronous scene
/// commit that happens after the submit reply.
public class CjguiGeneratedUiCandidateRecord {
    public let token: Int64
    /// Stable per-attempt receipt. Two submits of the SAME payload still get
    /// different receipts, so a reader can tell them apart.
    public let receipt: String
    /// Accepted structure version at the moment of this attempt.
    public let baseVersion: Int64
    /// Version this attempt would install (accepted version + 1).
    public let candidateVersion: Int64
    private var terminalStateValue: String
    private var sceneStateValue: String
    private var reasonValue: String
    private var pathValue: String
    private var acceptedVersionValue: Int64

    init(token: Int64, receipt: String, baseVersion: Int64, candidateVersion: Int64) {
        this.token = token
        this.receipt = receipt
        this.baseVersion = baseVersion
        this.candidateVersion = candidateVersion
        this.terminalStateValue = "PENDING"
        this.sceneStateValue = ""
        this.reasonValue = ""
        this.pathValue = ""
        this.acceptedVersionValue = 0
    }

    /// "PENDING" | "ACCEPTED" | "SUPERSEDED" | "REJECTED".
    public func terminalState(): String {
        return terminalStateValue
    }

    /// Scene-side state of this attempt: "scene_pending", "scene_accepted",
    /// "scene_rejected:<reason>", or a candidate-level rejection note. It is
    /// deliberately separate from `terminalState`: "the window has not shown it
    /// yet" is not "the candidate was rejected".
    public func sceneState(): String {
        return sceneStateValue
    }

    public func reason(): String {
        return reasonValue
    }

    public func path(): String {
        return pathValue
    }

    /// Structure version this attempt produced when it was accepted (0 while it
    /// was never accepted).
    public func acceptedVersion(): Int64 {
        return acceptedVersionValue
    }

    func markRejected(sceneState: String, reason: String, path: String): Unit {
        terminalStateValue = "REJECTED"
        sceneStateValue = sceneState
        reasonValue = reason
        pathValue = path
    }

    /// Records that the candidate was received and is waiting for the window's
    /// scene transaction. It does not settle the attempt.
    func markReceived(): Unit {
        if (terminalStateValue == "PENDING") {
            sceneStateValue = "candidate_received"
        }
    }

    func markSuperseded(): Unit {
        // Never overwrite a terminal state: an ACCEPTED attempt stays accepted.
        if (terminalStateValue != "PENDING") {
            return
        }
        terminalStateValue = "SUPERSEDED"
        // "candidate_received" only means the holder accepted the payload; the
        // attempt then never reached the scene, so the scene state must say so.
        if (sceneStateValue.isEmpty() || sceneStateValue == "candidate_received") {
            sceneStateValue = "superseded_by_newer_candidate"
        }
    }

    func markAccepted(version: Int64): Unit {
        terminalStateValue = "ACCEPTED"
        sceneStateValue = "scene_accepted"
        acceptedVersionValue = version
    }
}

/// The single structure holder:/// owns the accepted description and its
/// version, allocates stable node identities per accepted key, and renders the
/// accepted structure through ordinary component builders. Business fields and
/// drafts remain with the application provider.
/// Identity emitted by this holder's current render attempt. It is only a
/// staging value; accepted instance reads continue to use the committed map.
public class CjguiGeneratedUiRefreshIdentity {
    public let nodeId: Int64
    public let semanticId: String

    public init(nodeId: Int64, semanticId: String) {
        this.nodeId = nodeId
        this.semanticId = semanticId
    }
}

public class CjguiGeneratedUiStructureHolder {
    private let catalog: CjguiGeneratedUiCapabilityCatalog
    private let validator: CjguiGeneratedUiValidator
    private let registry: CjguiComposableUiComponentRegistry
    private let rootScope: CjguiComposableUiIdentityScope
    // Accepted (scene-committed) structure and identity table. Only the
    // commit hook below advances these.
    private var accepted: ?CjguiGeneratedUiNodeSpec
    private var acceptedVersion: Int64
    // Candidate received from an external submission, prepared but not yet
    // scene-accepted. It never becomes visible through the accepted reads.
    private var candidate: ?CjguiGeneratedUiNodeSpec
    private var candidateVersion: Int64
    private var candidatePrepared: Bool
    /// Whether the OPEN identity composition of the pending candidate was already
    /// consumed by a build. A candidate may legitimately be built more than once
    /// (a retried or rebuilt refresh); the second build starts a FRESH
    /// composition instead of re-claiming keys the first pass already claimed.
    private var candidateCompositionUsed: Bool = false
    private var lastReason: String
    private var lastSceneOutcomeValue: String
    private var renderFailureReason: String
    private var renderFailurePath: String
    // Node identity -> accepted stable key, rebuilt on every expansion so an
    // event can only resolve to the currently accepted object.
    private var nodeIdToKey: HashMap<Int64, String>
    // Candidate identity table, published only by the commit hook.
    private var candidateNodeIdToKey: HashMap<Int64, String>
    // Current build's exact key -> semantic identity. Candidate declarations
    // need this before acceptance to stage native bindings with that scene.
    // Rebuilt attempts replace the map; commit/rollback remove it.
    private var refreshIdentities: HashMap<String, CjguiGeneratedUiRefreshIdentity>
    // Resource binding each image reference was resolved with. The ACCEPTED map
    // is part of the accepted scene: an application that redeclares the same key
    // at a new version must not make the accepted interface unresolvable, so an
    // ordinary refresh rebuilds from what was accepted and never re-queries the
    // replaced catalog. New candidates are still validated against the CURRENT
    // catalog and stage their own bindings until the scene accepts them.
    private var acceptedImageBindings: HashMap<String, CjguiGeneratedUiImageResourceSpec>
    private var candidateImageBindings: HashMap<String, CjguiGeneratedUiImageResourceSpec>
    // ONE public viewport per stable generated instance key. It is view state,
    // not a business value: a legal reorder or an ordinary field refresh keeps
    // the human's scroll position, and two windows never share it.
    private var instanceScrollViewports: HashMap<String, CjguiComposableUiScrollViewport>
    // ONE first-pane size per stable generated split instance. The declaration's
    // `firstSize` is only the INITIAL value: once a human drags the divider the
    // view state belongs to this instance, so re-submitting the same structure
    // (or an ordinary field refresh, a theme change or a resize) cannot silently
    // overwrite the layout the person just chose.
    private var instanceSplitStates: HashMap<String, CjguiComposableUiSplitState>
    /// Per-instance ACTIVE page of every generated tab container. Like the other
    /// view states it belongs to the window instance, never to the declaration.
    private var instanceTabsStates: HashMap<String, CjguiComposableUiTabsState>
    /// Snapshot of the instance view-state tables taken when a candidate refresh
    /// begins. A candidate build CREATES view state for new keys; if that attempt
    /// is rejected the tables are restored to this snapshot, so an abandoned
    /// attempt can never leave state a later legal structure would inherit.
    private var stagedInstanceScrollViewports: ?HashMap<String, CjguiComposableUiScrollViewport> = None
    private var stagedInstanceSplitStates: ?HashMap<String, CjguiComposableUiSplitState> = None
    private var stagedInstanceTabsStates: ?HashMap<String, CjguiComposableUiTabsState> = None
    // True while a candidate refresh transaction is open. A candidate build must
    // not publish a re-declaration into an object the ACCEPTED scene is still
    // using: it stages it (see CjguiComposableUiSplitState.stageBoundsDeclaration
    // and CjguiComposableUiTabsState.stageReconcile) and only the accepted scene
    // promotes it. The staged objects are remembered so commit/rollback can settle
    // exactly the instances this attempt touched.
    private var candidateViewStateStagingActive: Bool = false
    // True while the tree being rendered is the ACCEPTED one (an immediate build
    // outside a candidate transaction), false for a candidate build.
    private var buildIntoAcceptedTable: Bool = true
    private var candidateTouchedSplitStates: ArrayList<CjguiComposableUiSplitState> = ArrayList<CjguiComposableUiSplitState>()
    private var candidateTouchedTabsStates: ArrayList<CjguiComposableUiTabsState> = ArrayList<CjguiComposableUiTabsState>()
    // Definition each named style LAST resolved to. A named style may carry
    // geometry and typography, not only paint, so removing its declaration must
    // not silently turn an accepted instance back into the framework default:
    // the accepted scene would change shape without any accepted change. An
    // accepted build therefore keeps the last committed resolution, while a
    // still-registered name stays authoritative so a legal update reaches the
    // next successful refresh instead of freezing the snapshot forever.
    private var resolvedNamedStyles: HashMap<String, CjguiComposableUiNamedStyle>
    // Resolutions made by the refresh currently in flight. They are promoted into
    // the committed map only when the scene that used them is accepted; a
    // rejected build discards them, so "most recently resolved" can never
    // disagree with "most recently accepted".
    private var stagedNamedStyles: HashMap<String, CjguiComposableUiNamedStyle>
    // Last state SAMPLED for each accepted image binding, on the window's own
    // thread. It is a plain value: the public read never calls native itself.
    private var imageResourceStates: HashMap<String, String>
    // Accepted composite element bindings by node identity. A composite element
    // (field / preset / action) resolves its owner binding from here, so no
    // consumer re-derives it from a control type or a field name.
    private var acceptedCompositeElements: HashMap<Int64, CjguiCompositeElementBinding>
    private var candidateCompositeElements: HashMap<Int64, CjguiCompositeElementBinding>
    // Motion references are staged with the generated candidate and promoted
    // only when the corresponding scene transaction commits.
    private var acceptedMotionRules: HashMap<String, CjguiGeneratedMotionRule>
    private var candidateMotionRules: HashMap<String, CjguiGeneratedMotionRule>
    // Counters proving the expanded-subtree budget is really checked.
    private var lastExpandedNodeCount: Int64
    private var lastExpandedDepth: Int64
    // Candidate ownership. Every submit attempt gets a monotonic, non-reused
    // token and a bounded terminal record; the records are what make "did MY
    // submission arrive, was it replaced, did the scene accept it" answerable.
    private var nextCandidateToken: Int64
    private var pendingCandidateTokenValue: Int64
    private var acceptedCandidateTokenValue: Int64
    private var candidateRecords: ArrayList<CjguiGeneratedUiCandidateRecord>

    private static let candidateRecordLimit: Int64 = 64

    public init(catalog: CjguiGeneratedUiCapabilityCatalog,
        rootScope!: CjguiComposableUiIdentityScope = CjguiComposableUiIdentityScope("generated-root")) {
        this.catalog = catalog
        this.validator = CjguiGeneratedUiValidator(catalog)
        this.registry = CjguiComposableUiComponentRegistry()
        this.rootScope = rootScope
        this.accepted = None
        this.acceptedVersion = 0
        this.candidate = None
        this.candidateVersion = 0
        this.candidatePrepared = false
        this.candidateCompositionUsed = false
        this.lastReason = ""
        this.lastSceneOutcomeValue = ""
        this.renderFailureReason = ""
        this.renderFailurePath = ""
        this.nodeIdToKey = HashMap<Int64, String>()
        this.candidateNodeIdToKey = HashMap<Int64, String>()
        this.refreshIdentities = HashMap<String, CjguiGeneratedUiRefreshIdentity>()
        this.acceptedImageBindings = HashMap<String, CjguiGeneratedUiImageResourceSpec>()
        this.candidateImageBindings = HashMap<String, CjguiGeneratedUiImageResourceSpec>()
        this.instanceScrollViewports = HashMap<String, CjguiComposableUiScrollViewport>()
        this.instanceSplitStates = HashMap<String, CjguiComposableUiSplitState>()
        this.instanceTabsStates = HashMap<String, CjguiComposableUiTabsState>()
        this.resolvedNamedStyles = HashMap<String, CjguiComposableUiNamedStyle>()
        this.stagedNamedStyles = HashMap<String, CjguiComposableUiNamedStyle>()
        this.imageResourceStates = HashMap<String, String>()
        this.acceptedCompositeElements = HashMap<Int64, CjguiCompositeElementBinding>()
        this.candidateCompositeElements = HashMap<Int64, CjguiCompositeElementBinding>()
        this.acceptedMotionRules = HashMap<String, CjguiGeneratedMotionRule>()
        this.candidateMotionRules = HashMap<String, CjguiGeneratedMotionRule>()
        this.lastExpandedNodeCount = 0
        this.lastExpandedDepth = 0
        this.nextCandidateToken = 0
        this.pendingCandidateTokenValue = 0
        this.acceptedCandidateTokenValue = 0
        this.candidateRecords = ArrayList<CjguiGeneratedUiCandidateRecord>()
    }

    /// Allocates a submission token before the candidate is even decoded, so a
    /// decode or structure-version failure is still attributable to one attempt.
    /// The holder is the only owner of the token: the transport and the external
    /// client cannot see the asynchronous scene commit that settles it.
    public func allocateCandidateAttempt(): Int64 {
        nextCandidateToken += 1
        let token = nextCandidateToken
        recordCandidate(
            CjguiGeneratedUiCandidateRecord(token, CjguiGeneratedUiStructureHolder.receiptForToken(token),
                acceptedVersion, acceptedVersion + 1))
        return token
    }

    /// Receipt of one attempt. Stable and unique per attempt, so two submits of
    /// the same payload are still distinguishable.
    public static func receiptForToken(token: Int64): String {
        return "generated-ui-candidate-${token}"
    }

    /// Identity of ONE resolved image binding: the logical key plus the exact
    /// version. Two declarations of the same key at different versions are two
    /// different bindings, which is what makes the accepted scene independent of
    /// a later catalog replacement.
    public static func imageBindingKey(key: String, version: Int64): String {
        return "${key}#${version}"
    }

    /// Samples the native preparation state of every ACCEPTED image binding ON
    /// THE WINDOW'S OWN THREAD. The application calls this from the scene build
    /// it already runs; the public read path only consumes the plain values
    /// below, so nothing calls native from the protocol thread.
    public func sampleImageResourceStates(window: CjguiComposableUiWindow): Unit {
        let sampled = HashMap<String, String>()
        for ((bindingKey, spec) in acceptedImageBindings) {
            let status = window.imageResourceStatus(spec.rasterPath, spec.key, spec.version)
            sampled.add(bindingKey, status.state)
        }
        imageResourceStates = sampled
    }

    /// Last sampled preparation state of one image binding ("unrequested" when
    /// the binding was never sampled). It reports loading/ready/failed, never a
    /// path or native handle.
    public func imageResourceState(key: String, version: Int64): String {
        if (let Some(state) <- imageResourceStates.get(CjguiGeneratedUiStructureHolder.imageBindingKey(key, version))) {
            return state
        }
        return "unrequested"
    }

    /// Order-independent fingerprint of the sampled resource states, so a
    /// completion or a failure is observable without an external structure
    /// resubmission.
    public func imageResourceStateRevision(): Int64 {
        var accumulator: Int64 = 0
        var count: Int64 = 0
        for ((bindingKey, state) in imageResourceStates) {
            var entry: Int64 = 7
            for (byte in bindingKey.toArray()) {
                entry = (entry * 131 + Int64(byte)) % 2147483647
            }
            for (byte in state.toArray()) {
                entry = (entry * 131 + Int64(byte)) % 2147483647
            }
            accumulator = (accumulator + entry) % 2147483647
            count += 1
        }
        return (accumulator * 1000003 + count) % 2147483647
    }

    /// Marks an attempt that never reached `submit` (malformed payload,
    /// structure-version conflict) as rejected, keeping its exact reason.
    public func rejectCandidateAttempt(token: Int64, reason: String, path: String): Unit {
        if (let Some(record) <- candidateRecord(token)) {
            record.markRejected("candidate_rejected", reason, path)
        }
    }

    /// Terminal record for one token, or None when the token is older than the
    /// bounded table (an evicted token is NOT reported as some other state).
    public func candidateRecord(token: Int64): ?CjguiGeneratedUiCandidateRecord {
        for (record in candidateRecords) {
            if (record.token == token) {
                return Some(record)
            }
        }
        return None
    }

    /// Token of the candidate waiting for scene acceptance (0 when none).
    public func pendingCandidateToken(): Int64 {
        return pendingCandidateTokenValue
    }

    /// Token whose candidate the scene accepted most recently (0 when none yet).
    public func currentAcceptedCandidateToken(): Int64 {
        return acceptedCandidateTokenValue
    }

    /// Token of the most recent submission ATTEMPT, settled or not (0 before any
    /// attempt). It is the observation source's candidate identity: a rejected
    /// decode or a scene-rejected candidate still moved it, so a change reader
    /// must not miss an attempt just because no candidate is pending.
    public func latestCandidateToken(): Int64 {
        return nextCandidateToken
    }

    /// Compact ticket read for ONE attempt, encoded as the line payload of the
    /// `GET_GENERATED_UI_CANDIDATE` command. An evicted token reports
    /// `TERMINAL_STATE UNKNOWN` instead of borrowing another attempt's state.
    public func candidateTicketPayload(token: Int64): String {
        let builder = StringBuilder()
        builder.append("CANDIDATE_TOKEN ${token}\n")
        if (let Some(record) <- candidateRecord(token)) {
            builder.append("RECEIPT ${record.receipt}\n")
            builder.append("BASE_VERSION ${record.baseVersion}\n")
            builder.append("CANDIDATE_VERSION ${record.candidateVersion}\n")
            builder.append("TERMINAL_STATE ${record.terminalState()}\n")
            builder.append("SCENE_STATE ${if (record.sceneState().size > 0) { record.sceneState() } else { "none" }}\n")
            builder.append("REASON ${if (record.reason().size > 0) { record.reason() } else { "none" }}\n")
            builder.append("PATH ${if (record.path().size > 0) { record.path() } else { "none" }}\n")
            builder.append("ACCEPTED_VERSION ${record.acceptedVersion()}\n")
        } else {
            builder.append("RECEIPT none\nBASE_VERSION 0\nCANDIDATE_VERSION 0\nTERMINAL_STATE UNKNOWN\n")
            builder.append("SCENE_STATE none\nREASON none\nPATH none\nACCEPTED_VERSION 0\n")
        }
        builder.append("CURRENT_ACCEPTED_TOKEN ${acceptedCandidateTokenValue}\n")
        builder.append("PENDING_TOKEN ${pendingCandidateTokenValue}")
        return builder.toString()
    }

    private func recordCandidate(record: CjguiGeneratedUiCandidateRecord): Unit {
        candidateRecords.add(record)
        pruneCandidateRecords()
    }

    /// Bounded table: the oldest settled record is dropped first. A pending or
    /// currently accepted record is never dropped, so the answer to "what is my
    /// submission doing" cannot disappear while it is still meaningful.
    private func pruneCandidateRecords(): Unit {
        while (candidateRecords.size > candidateRecordLimit) {
            var index = 0
            var removed = false
            while (index < candidateRecords.size) {
                let candidateRecordValue = candidateRecords[index]
                let settled = candidateRecordValue.terminalState() != "PENDING"
                let stillRelevant = candidateRecordValue.token == acceptedCandidateTokenValue ||
                    candidateRecordValue.token == pendingCandidateTokenValue
                if (settled && !stillRelevant) {
                    let _ = candidateRecords.remove(at: index)
                    removed = true
                    break
                }
                index += 1
            }
            if (!removed) {
                return
            }
        }
    }

    /// Nodes the last composite expansion really produced, and its real depth.
    /// Evidence for the budget check, not a declared value.
    public func lastCompositeExpansionNodes(): Int64 {
        return lastExpandedNodeCount
    }

    public func lastCompositeExpansionDepth(): Int64 {
        return lastExpandedDepth
    }

    /// Scene-accepted structure version. It advances only when the window
    /// committed the candidate, so an external reader can never observe a
    /// structure that the scene has not accepted.
    public func structureVersion(): Int64 {
        return acceptedVersion
    }

    public func acceptedStructure(): ?CjguiGeneratedUiNodeSpec {
        return accepted
    }

    /// Host window policy read for a scene being prepared. While a generated
    /// candidate is pending its root declaration is staged; otherwise the
    /// accepted declaration is the source. Omission always resolves to opaque.
    public func candidateWindowBackground(): String {
        if (let Some(root) <- candidate) {
            return windowBackgroundToken(root)
        }
        return windowBackgroundToken(accepted)
    }

    /// Host window policy published only from the scene accepted transaction.
    public func acceptedWindowBackground(): String {
        return windowBackgroundToken(accepted)
    }

    private func windowBackgroundToken(root: ?CjguiGeneratedUiNodeSpec): String {
        if (let Some(spec) <- root) {
            let declared = spec.property("windowBackground")
            if (CjguiWindowBackgroundPolicy.isValidToken(declared)) {
                return declared
            }
        }
        return CjguiWindowBackgroundPolicy.OPAQUE
    }

    /// The rule referenced by one scene-accepted generated key. Candidate
    /// declarations remain invisible until `commitCandidateRefresh` accepts the
    /// matching rendered scene; an absent key/reference returns None.
    public func acceptedMotionRuleForKey(key: String): ?CjguiGeneratedMotionRule {
        return acceptedMotionRules.get(key)
    }

    /// Version the pending candidate would install (0 when none is pending).
    public func candidateStructureVersion(): Int64 {
        return candidateVersion
    }

    /// True while a validated candidate is prepared and waiting for the
    /// window's scene acceptance.
    public func hasPendingCandidate(): Bool {
        return !candidate.isNone()
    }

    /// "scene_accepted", "scene_rejected:<reason>", or "" before any commit.
    public func lastSceneOutcome(): String {
        return lastSceneOutcomeValue
    }

    public func lastRejection(): String {
        return lastReason
    }

    /// Reason text of the most recent rejected candidate ("" when the last
    /// submission was accepted).
    public func rejectedReason(): String {
        return lastReason
    }

    /// Registry issue text from the last expansion (test/diagnostic surface).
    public func lastIssue(): String {
        return registry.lastIssue()
    }

    /// Readable note of the last NON-FATAL declaration problem ("" when none):
    /// an encoded `shadow`/`gradient` whose text was malformed was ignored
    /// instead of rejecting the candidate. The scene is still accepted.
    public func lastDeclarationAdvisory(): String {
        return validator.lastAdvisoryNote()
    }

    /// Validates the candidate and records it as pending, but does NOT publish
    /// it: the accepted structure, its version and the event identity table
    /// stay exactly as they were until the window commits the candidate in the
    /// same transaction that accepts the scene. Rendering happens inside that
    /// transaction, so a candidate that cannot be built is rejected at scene
    /// time without ever destroying an accepted instance.
    public func submit(candidate: CjguiGeneratedUiNodeSpec, provider: CjguiGeneratedUiBindingProvider,
        attemptToken!: Int64 = 0): CjguiGeneratedUiSubmitResult {
        let before = acceptedVersion
        // An application that decoded CAS before this call owns the token it
        // allocated; otherwise the attempt gets its own token here.
        let token = if (attemptToken > 0) {
            attemptToken
        } else {
            allocateCandidateAttempt()
        }
        let validation = validator.validate(candidate)
        if (!validation.accepted) {
            lastReason = validation.reason
            if (let Some(record) <- candidateRecord(token)) {
                record.markRejected("candidate_rejected", validation.reason, validation.path)
            }
            return CjguiGeneratedUiSubmitResult(false, false, validation.reason, validation.path, before, before,
                candidateVersion: candidateVersion, candidateToken: token,
                receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
        }
        // Superseding an uncommitted candidate is legal: the previous one was
        // never published, so only its (unaccepted) identities are dropped. Its
        // ticket must record that it never reached the scene, not that it failed.
        if (!this.candidate.isNone()) {
            if (let Some(previous) <- candidateRecord(pendingCandidateTokenValue)) {
                previous.markSuperseded()
            }
            registry.rollbackTransaction()
            // Superseding an uncommitted candidate drops ITS holds; the accepted
            // scene's own holds are untouched.
            releaseCandidateImageHolds()
            // Its staged instance view state goes back too, for the same reason a
            // rejected candidate's does.
            restoreStagedInstanceViewStates()
        }
        let motionBindings = HashMap<String, CjguiGeneratedMotionRule>()
        cjguiCollectGeneratedMotionRules(candidate, catalog.motionRuleRegistry(), motionBindings)
        candidateMotionRules = motionBindings
        this.candidate = Some(candidate)
        this.candidateVersion = before + 1
        this.candidatePrepared = false
        this.candidateCompositionUsed = false
        this.pendingCandidateTokenValue = token
        this.lastReason = ""
        if (let Some(record) <- candidateRecord(token)) {
            record.markReceived()
        }
        return CjguiGeneratedUiSubmitResult(true, false, "", "", before, before, candidateVersion: candidateVersion,
            candidateToken: token, receipt: CjguiGeneratedUiStructureHolder.receiptForToken(token))
    }

    /// Opens the component-identity transaction for the pending candidate.
    /// Called from the window's begin-scene-refresh hook, before the scene is
    /// built; it publishes nothing.
    public func beginCandidateRefresh(): Bool {
        refreshIdentities.clear()
        if (candidate.isNone()) {
            return true
        }
        if (!registry.beginTransaction()) {
            lastSceneOutcomeValue = "scene_rejected:${registry.lastIssue()}"
            rejectPendingWith(lastSceneOutcomeValue, registry.lastIssue())
            return false
        }
        candidatePrepared = false
        candidateCompositionUsed = false
        // The instance view-state tables are candidate STAGING too: a build may
        // create state for new keys, and a rejected attempt must give it back.
        stagedInstanceScrollViewports = Some(HashMap<String, CjguiComposableUiScrollViewport>(instanceScrollViewports))
        stagedInstanceSplitStates = Some(HashMap<String, CjguiComposableUiSplitState>(instanceSplitStates))
        stagedInstanceTabsStates = Some(HashMap<String, CjguiComposableUiTabsState>(instanceTabsStates))
        // The instance OBJECTS are shared with the accepted scene, so restoring
        // the tables alone is not enough: a re-declaration is staged on the object
        // and only the accepted scene publishes it.
        candidateViewStateStagingActive = true
        candidateTouchedSplitStates = ArrayList<CjguiComposableUiSplitState>()
        candidateTouchedTabsStates = ArrayList<CjguiComposableUiTabsState>()
        lastSceneOutcomeValue = "scene_pending"
        return true
    }

    /// Builds the tree for the refresh currently in flight: the pending
    /// candidate while its identity transaction is open, otherwise the accepted
    /// structure. The candidate's identities are used for the scene, but the
    /// accepted identity table is only replaced by `commitCandidateRefresh`.
    public func buildRefreshNode(provider: CjguiGeneratedUiBindingProvider): CjguiComposableUiNode {
        if (let Some(structure) <- candidate) {
            // A SECOND build of the SAME pending candidate must start a fresh
            // identity composition: the first pass already claimed these keys and
            // re-using the open composition is rejected as
            // duplicate_component_key. Exactly one composition stays live for the
            // candidate, and the instances created by the previous pass are reused.
            if (candidateCompositionUsed) {
                registry.rollbackTransaction()
                if (!registry.beginTransaction()) {
                    lastSceneOutcomeValue = "scene_rejected:${registry.lastIssue()}"
                    rejectPendingWith(lastSceneOutcomeValue, registry.lastIssue())
                    candidatePrepared = false
                    candidateCompositionUsed = false
                    return buildAccepted(provider)
                }
            }
            candidateCompositionUsed = true
            let rendered = renderIntoCandidate(structure, provider)
            if (!rendered.ok) {
                // A candidate that cannot be built must not take the scene down
                // with it: roll its identity transaction back and keep the
                // accepted interface operable.
                registry.rollbackTransaction()
                candidatePrepared = false
                candidateCompositionUsed = false
                lastSceneOutcomeValue = "scene_rejected:${rendered.reason}"
                rejectPendingWith(lastSceneOutcomeValue, rendered.reason)
                return buildAccepted(provider)
            }
            candidatePrepared = true
            return rendered.node
        }
        return buildAccepted(provider)
    }

    /// Completes the candidate declaration before layout/native submission, so
    /// a duplicate/capacity fault fails while the old interface is untouched.
    public func prepareCandidateRefresh(): Bool {
        if (candidate.isNone()) {
            return true
        }
        if (!candidatePrepared) {
            // Keep the SPECIFIC rejection recorded by the failed candidate build
            // (for example composite_expansion_node_limit). Replacing it with the
            // generic "candidate_not_prepared" would hide the real cause from the
            // evidence and from a caller deciding how to recover.
            if (!lastSceneOutcomeValue.startsWith("scene_rejected:")) {
                lastSceneOutcomeValue = "scene_rejected:candidate_not_prepared"
            }
            rejectPendingWith(lastSceneOutcomeValue, lastSceneOutcomeValue.replace("scene_rejected:", ""))
            return false
        }
        if (!registry.prepareTransaction()) {
            lastSceneOutcomeValue = "scene_rejected:${registry.lastIssue()}"
            rejectPendingWith(lastSceneOutcomeValue, registry.lastIssue())
            return false
        }
        return true
    }

    /// Publishes the prepared candidate as the accepted structure. Called only
    /// after the window accepted the scene that contains it; the candidate's
    /// component identities are promoted in the same step, and only then are
    /// the instances it dropped destroyed.
    public func commitCandidateRefresh(): Bool {
        refreshIdentities.clear()
        let pending = candidate
        if (let Some(structure) <- pending) {
            if (!candidatePrepared) {
                lastSceneOutcomeValue = "scene_rejected:candidate_not_prepared"
                rejectPendingWith(lastSceneOutcomeValue, "candidate_not_prepared")
                return false
            }
            registry.commitTransaction()
            accepted = Some(structure)
            acceptedVersion = candidateVersion
            acceptedMotionRules = candidateMotionRules
            candidateMotionRules = HashMap<String, CjguiGeneratedMotionRule>()
            // Ownership transfer, once: the PREVIOUS accepted scene's holds are
            // released and the candidate's own holds become the accepted ones.
            // Each accepted binding therefore owns exactly one hold no matter how
            // many times the same identity is committed successfully. The new
            // accepted map is a fresh copy, so a later candidate can never alias
            // it and release an accepted reference through its own rollback.
            releaseAcceptedImageHolds()
            acceptedImageBindings = HashMap<String, CjguiGeneratedUiImageResourceSpec>(candidateImageBindings)
            candidateImageBindings = HashMap<String, CjguiGeneratedUiImageResourceSpec>()
            nodeIdToKey = candidateNodeIdToKey
            // Removing or re-identifying an element releases its per-instance
            // view state in the SAME transaction that accepts the new structure:
            // the accepted spec tree is the only authority for which instances
            // still exist.
            let acceptedInstanceKeys = ArrayList<String>()
            cjguiCollectGeneratedSpecKeys(structure, acceptedInstanceKeys)
            // The candidate's re-declarations of SURVIVING instances become the
            // published constraints in the same transaction as the structure. This
            // happens before the removal sweep so an instance that is dropped in
            // the same commit is released with its staging already settled.
            commitStagedInstanceViewStates()
            retainInstanceViewStatesFor(acceptedInstanceKeys)
            stagedInstanceScrollViewports = None
            stagedInstanceSplitStates = None
            stagedInstanceTabsStates = None
            candidateViewStateStagingActive = false
            // The composite element bindings are part of the same accepted
            // transaction: an event on a composite element resolves its owner
            // binding only from the accepted table.
            acceptedCompositeElements = candidateCompositeElements
            // The attempt that produced this scene becomes the accepted one, and
            // only now does its ticket settle as ACCEPTED.
            if (let Some(record) <- candidateRecord(pendingCandidateTokenValue)) {
                record.markAccepted(acceptedVersion)
            }
            acceptedCandidateTokenValue = pendingCandidateTokenValue
            pendingCandidateTokenValue = 0
            candidate = None
            candidateMotionRules = HashMap<String, CjguiGeneratedMotionRule>()
            candidatePrepared = false
            candidateCompositionUsed = false
            // No candidate is pending any more: the public candidate read must
            // not keep reporting the version that is now the accepted one.
            candidateVersion = 0
            lastSceneOutcomeValue = "scene_accepted"
            // The accepted scene's style resolutions become the committed ones in
            // the SAME transaction as the accepted structure.
            commitStyleRefresh()
            return true
        }
        lastSceneOutcomeValue = "scene_accepted"
        candidateViewStateStagingActive = false
        discardStagedInstanceViewStates()
        commitStyleRefresh()
        return true
    }

    /// Discards a candidate whose scene was rejected. The previous accepted
    /// structure, version, identity table and component instances are
    /// untouched, so the old interface stays addressable and editable.
    public func rollbackCandidateRefresh(): Unit {
        refreshIdentities.clear()
        rollbackStyleRefresh()
        releaseCandidateImageHolds()
        // Give back every instance view state this CANDIDATE build created or
        // changed: the accepted structure is the only authority for which
        // instances exist, and an abandoned attempt must not seed the next one.
        restoreStagedInstanceViewStates()
        if (!candidate.isNone()) {
            if (lastSceneOutcomeValue.isEmpty() || lastSceneOutcomeValue == "scene_pending") {
                lastSceneOutcomeValue = "scene_rejected:layout_or_native"
            }
            registry.rollbackTransaction()
            // Keep the SPECIFIC reason a failed build or prepare already
            // recorded; only fill in the generic layout/native reason when the
            // attempt has no reason of its own.
            rejectPendingWith(lastSceneOutcomeValue, lastSceneOutcomeValue.replace("scene_rejected:", ""))
            pendingCandidateTokenValue = 0
            candidate = None
            candidatePrepared = false
            candidateCompositionUsed = false
            candidateVersion = 0
        }
    }

    /// Settles the pending attempt as REJECTED once, preserving a more specific
    /// reason a previous hook already recorded for the same attempt.
    private func rejectPendingWith(sceneState: String, reason: String): Unit {
        if (let Some(record) <- candidateRecord(pendingCandidateTokenValue)) {
            if (record.terminalState() == "PENDING" && record.reason().isEmpty()) {
                record.markRejected(sceneState, reason, "")
            }
        }
    }

    /// Renders the currently accepted structure (empty group when none was
    /// accepted yet).
    public func buildAccepted(provider: CjguiGeneratedUiBindingProvider): CjguiComposableUiNode {
        if (let Some(structure) <- accepted) {
            let rendered = renderInto(structure, provider, true)
            if (rendered.ok) {
                return rendered.node
            }
            // The accepted structure was built successfully when it was
            // committed; a later provider-driven build failure keeps the
            // placeholder so the rest of the window scene still commits.
            return cjguiComposableVertical(900001, "generated-empty", CjguiComposableUiStyle(gap: 4))
        }
        refreshIdentities.clear()
        // A dedicated placeholder id: node id 1 belongs to the window's own
        // layer host, and a duplicate id rejects the whole scene commit.
        return cjguiComposableVertical(900001, "generated-empty", CjguiComposableUiStyle(gap: 4))
    }

    /// Renders the accepted structure through the immediate composition path
    /// (begin/finish). Used outside a refresh transaction only.
    private func renderInto(structure: CjguiGeneratedUiNodeSpec, provider: CjguiGeneratedUiBindingProvider,
        intoAcceptedTable: Bool): CjguiGeneratedUiRendered {
        buildIntoAcceptedTable = true
        refreshIdentities.clear()
        nodeIdToKey = HashMap<Int64, String>()
        acceptedCompositeElements = HashMap<Int64, CjguiCompositeElementBinding>()
        lastExpandedNodeCount = 0
        lastExpandedDepth = 0
        renderFailureReason = ""
        renderFailurePath = ""
        if (!registry.begin()) {
            return CjguiGeneratedUiRendered(false, "component_composition_failed", "",
                cjguiComposableVertical(900001, "generated-empty", CjguiComposableUiStyle(gap: 4)))
        }
        let node = nodeFor(structure, provider, intoAcceptedTable)
        if (!registry.finish()) {
            return CjguiGeneratedUiRendered(false, "component_composition_commit_failed", "", node)
        }
        if (!renderFailureReason.isEmpty()) {
            return CjguiGeneratedUiRendered(false, renderFailureReason, renderFailurePath, node)
        }
        return CjguiGeneratedUiRendered(true, "", "", node)
    }

    /// Renders the pending candidate inside the identity transaction already
    /// opened by `beginCandidateRefresh`. It never commits and never destroys
    /// an accepted instance.
    private func renderIntoCandidate(structure: CjguiGeneratedUiNodeSpec, provider: CjguiGeneratedUiBindingProvider): CjguiGeneratedUiRendered {
        buildIntoAcceptedTable = false
        refreshIdentities.clear()
        candidateNodeIdToKey = HashMap<Int64, String>()
        candidateCompositeElements = HashMap<Int64, CjguiCompositeElementBinding>()
        // A pending candidate may be built more than once (a retried or rebuilt
        // refresh). Each build retains the published identities it resolves, so
        // the rebuild must first RETURN the holds the previous build of this same
        // candidate recorded; otherwise one candidate would own two references
        // and commit/rollback/supersede could only ever return one of them.
        releaseCandidateImageHolds()
        renderFailureReason = ""
        renderFailurePath = ""
        let node = nodeFor(structure, provider, false)
        if (!renderFailureReason.isEmpty()) {
            return CjguiGeneratedUiRendered(false, renderFailureReason, renderFailurePath, node)
        }
        if (!registry.lastIssue().isEmpty()) {
            return CjguiGeneratedUiRendered(false, registry.lastIssue(), "", node)
        }
        return CjguiGeneratedUiRendered(true, "", "", node)
    }

    /// Node identity currently bound to an accepted stable key (negative when
    /// the key is not part of the accepted expansion). Consumers use it to
    /// prove that a structure update kept the same identity for a surviving
    /// key, which is what lets focus/selection/drafts continue.
    public func nodeIdForKey(key: String): Int64 {
        for ((nodeId, mappedKey) in nodeIdToKey) {
            if (mappedKey == key) {
                return nodeId
            }
        }
        return -1
    }

    /// The exact identity created by the latest build, valid only until that
    /// build commits or rolls back. A candidate transfer provider uses this
    /// narrow lookup to stage its declaration with the candidate scene.
    public func refreshIdentityForKey(key: String): ?CjguiGeneratedUiRefreshIdentity {
        return refreshIdentities.get(key)
    }

    /// Accepted stable key for a generated node identity. Events resolve their
    /// target through this mapping, never by re-deriving a key from text.
    public func keyForNodeId(nodeId: Int64): String {
        if (let Some(key) <- nodeIdToKey.get(nodeId)) {
            return key
        }
        return ""
    }

    /// Accepted composite element binding for a node identity, or None when the
    /// node is an ordinary generated node.
    public func compositeElementForNodeId(nodeId: Int64): ?CjguiCompositeElementBinding {
        return acceptedCompositeElements.get(nodeId)
    }

    /// Accepted composite element bindings belonging to one instance key, so a
    /// consumer (or a test) can address an element without knowing its node id.
    public func compositeElementNodeIdsForKey(key: String): ArrayList<CjguiCompositeElementBinding> {
        let result = ArrayList<CjguiCompositeElementBinding>()
        for ((_, binding) in acceptedCompositeElements) {
            if (keyForNodeId(binding.nodeId) == key) {
                result.add(binding)
            }
        }
        return result
    }

    /// PUBLIC BINDING ADAPTER: resolves a raw control event into a typed intent,
    /// so every consumer dispatches through one contract instead of guessing from
    /// the control type.
    ///
    /// Two behaviours this fixes:
    ///   * a composite PRESET button activates (it is not a text change), yet it
    ///     must reach the field's owner writer with its declared constant - the
    ///     adapter resolves it from the element's role, never from the field's
    ///     editor kind;
    ///   * a control whose event is not a change for its field must not be
    ///     swallowed: if the accepted node declares an action, the adapter
    ///     resolves the ACTION intent instead of silently returning nothing.
    /// Whether one incoming layout node still matches the accepted binding the
    /// framework resolved for its identity. This is the composite counterpart of
    /// the ordinary generated node's `node_binding_mismatch` check: an object
    /// that was replaced while keeping the same node id must not be able to route
    /// its late event through the new object's owner binding.
    private func compositeElementNodeMatches(element: CjguiCompositeElementBinding, node: CjguiComposableUiLayoutNode): Bool {
        if (element.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
            return node.fieldId == element.fieldId && node.operationActionName == element.writerOperation &&
                node.operationResourceId == element.ownerTargetResourceId && (element.bindingResourceId <= 0 ||
                node.resourceId == element.bindingResourceId)
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
            return node.nodeKind == CJGUI_COMPOSABLE_UI_BUTTON && (element.bindingResourceId <= 0 || node.resourceId == element
                .bindingResourceId) && node.operationActionName == element.writerOperation &&
                node.operationResourceId == element.ownerTargetResourceId
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
            // The declared action reaches the owner through the adapter, so the
            // control itself must be the framework's generic action button.
            return node.nodeKind == CJGUI_COMPOSABLE_UI_BUTTON && node.actionName == "GENERATED_ACTION"
        }
        // A container element carries no owner binding; its identity is the check.
        return true
    }

    public func resolveIntent(node: CjguiComposableUiLayoutNode, eventKind: Int64, text: String): CjguiGeneratedUiIntent {
        let key = keyForNodeId(node.nodeId)
        if (key.isEmpty()) {
            return CjguiGeneratedUiIntent.none("unknown_node")
        }
        // Composite element: the role and the resolved owner binding are the
        // framework's, not the consumer's.
        if (let Some(element) <- acceptedCompositeElements.get(node.nodeId)) {
            // The event's layout node must still match the CURRENT accepted
            // binding for this identity. A same-key rebind keeps the node id but
            // can change the owner target/resource; without this pre-check an
            // event produced by the OLD object would resolve through the new
            // binding and write the new owner. Only the fields the role really
            // carries are compared, so a container is never rejected for a field
            // it never had.
            if (!compositeElementNodeMatches(element, node)) {
                return CjguiGeneratedUiIntent.none("element_binding_mismatch")
            }
            if (element.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
                let field = match (catalog.fieldFor(element.fieldId)) {
                    case Some(value) => value
                    case None => return CjguiGeneratedUiIntent.none("unknown_field")
                }
                if (!field.acceptsChangeEventKind(eventKind)) {
                    return CjguiGeneratedUiIntent.none("event_not_a_field_change")
                }
                let value = if (field.editorKind == "BOOLEAN") {
                    CjguiSharedOperationValue.boolean(if (text == "true" || text == "false") {
                        text == "true"
                    } else {
                        !element.draftBoolean
                    })
                } else {
                    CjguiSharedOperationValue.string(text)
                }
                return CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, key, "", fieldId: element.fieldId,
                    writerOperation: element.writerOperation, ownerTargetResourceId: element.ownerTargetResourceId,
                    argumentName: element.argumentName, value: value)
            }
            if (element.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
                if (eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
                    return CjguiGeneratedUiIntent.none("event_not_an_activation")
                }
                // The declared constant goes to the owner unchanged: an
                // out-of-range preset must be refused by the owner's rule, never
                // clamped here.
                return CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, key, "", fieldId: element.fieldId,
                    writerOperation: element.writerOperation, ownerTargetResourceId: element.ownerTargetResourceId,
                    argumentName: element.argumentName, value: CjguiSharedOperationValue.string(element.presetValue))
            }
            if (element.role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
                if (eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
                    return CjguiGeneratedUiIntent.none("event_not_an_activation")
                }
                return CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_ACTION, key, "", actionName: element.actionName)
            }
            return CjguiGeneratedUiIntent.none("composite_container_event")
        }
        // Ordinary generated node: keep the same verification the consumers
        // performed themselves (declared writer, field id, binding resource), so
        // a stale or rebound node never writes another field.
        let spec = match (acceptedNodeForKey(key)) {
            case Some(value) => value
            case None => return CjguiGeneratedUiIntent.none("unknown_node_key")
        }
        if (!spec.fieldId.isEmpty()) {
            let field = match (catalog.fieldFor(spec.fieldId)) {
                case Some(value) => value
                case None => return CjguiGeneratedUiIntent.none("unknown_field")
            }
            if (field.acceptsChangeEventKind(eventKind)) {
                if (node.operationActionName.size == 0 || node.operationActionName != field.writeActionName ||
                    node.fieldId != spec.fieldId || node.resourceId != field.resourceId) {
                    return CjguiGeneratedUiIntent.none("node_binding_mismatch")
                }
                if (node.operationResourceId < 0) {
                    return CjguiGeneratedUiIntent.none("owner_target_missing")
                }
                let value = if (field.editorKind == "BOOLEAN") {
                    CjguiSharedOperationValue.boolean(if (text == "true" || text == "false") {
                        text == "true"
                    } else {
                        true
                    })
                } else {
                    CjguiSharedOperationValue.string(text)
                }
                return CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, key, "", fieldId: spec.fieldId,
                    writerOperation: field.writeActionName, ownerTargetResourceId: node.operationResourceId,
                    argumentName: field.argumentName, value: value)
            }
            // Not a change for that field: fall through to the action intent so an
            // activation is never swallowed by the field branch.
        }
        if (node.actionName == "GENERATED_ACTION") {
            let actionName = actionNameForKey(key)
            if (actionName.isEmpty()) {
                return CjguiGeneratedUiIntent.none("unknown_action_key")
            }
            // A stable key keeps its node id across a candidate rebind. The
            // event still carries the old accepted node object, so its declared
            // owner action must match the CURRENT accepted binding before a
            // late activation can reach the new action.
            if (node.operationActionName != actionName) {
                return CjguiGeneratedUiIntent.none("node_binding_mismatch")
            }
            if (eventKind != CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) {
                return CjguiGeneratedUiIntent.none("event_not_an_activation")
            }
            return CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_ACTION, key, "", actionName: actionName)
        }
        return CjguiGeneratedUiIntent.none("unrouted_event")
    }

    /// Expands one node into ordinary components through the presentation its
    /// registered kind declares. An unregistered or unimplemented kind is an
    /// explicit render failure - it never degrades into a label. `nodeIdToKey`
    /// is updated for whichever table this render targets (accepted or
    /// candidate), so a candidate never mutates the accepted identity table.
    private func nodeFor(spec: CjguiGeneratedUiNodeSpec, provider: CjguiGeneratedUiBindingProvider,
        intoAcceptedTable: Bool): CjguiComposableUiNode {
        let declared = match (catalog.componentFor(spec.kind)) {
            case Some(value) => value
            case None => CjguiGeneratedUiComponentSpec("__unregistered__", ArrayList<CjguiGeneratedUiPropertySpec>(),
                false)
        }
        if (!declared.isImplemented()) {
            noteRenderFailure("component_not_implemented", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        // Identity: the stable key maps to a deterministic identity slot in the
        // accepted expansion. Slots are allocated once per accepted key and
        // reused across re-orders, so an event still resolves to the same
        // object while the node id never overlaps the window's manual ids.
        let instance = registry.use("generated-${spec.key}")
        let registryNodeId = instance.nodeId("node")
        let nodeId = if (registryNodeId > 0) {
            800000 + registryNodeId
        } else {
            -1
        }
        let semanticId = instance.semanticId("node")
        refreshIdentities.add(spec.key, CjguiGeneratedUiRefreshIdentity(nodeId, semanticId))
        if (intoAcceptedTable) {
            nodeIdToKey.add(nodeId, spec.key)
        } else {
            candidateNodeIdToKey.add(nodeId, spec.key)
        }
        let style = styleFor(spec, intoAcceptedTable)
        let presentation = declared.presentation
        if (presentation == CJGUI_GENERATED_PRESENTATION_COMPOSITE) {
            return compositeFor(spec, provider, instance, intoAcceptedTable)
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL || presentation ==
            CJGUI_GENERATED_PRESENTATION_HORIZONTAL) {
            let group = if (presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL) {
                cjguiComposableVertical(nodeId, semanticId, style)
            } else {
                cjguiComposableHorizontal(nodeId, semanticId, style)
            }
            for (child in spec.children) {
                group.add(nodeFor(child, provider, intoAcceptedTable))
            }
            return group
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_TAB_PAGE) {
            // A page wrapper contributes ONLY its page metadata: its single child
            // is the content the container presents.
            if (spec.children.size != 1) {
                noteRenderFailure("tabs_page_requires_one_content", spec.key)
                return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
            }
            return nodeFor(spec.children[0], provider, intoAcceptedTable)
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_TABS) {
            if (spec.children.size < 2 || spec.children.size > 3) {
                noteRenderFailure("tabs_require_two_or_three_pages", spec.key)
                return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
            }
            let declaredPage = spec.property("initialPage")
            let titleHeight = match (parseGeneratedInteger(spec.property("titleHeight"))) {
                case Some(value) => value
                case None => 28
            }
            // The instance's OWN active page wins over the declaration, so an
            // ordinary refresh or a reorder never moves a person back to the
            // declared page; a removed page falls back through reconcile().
            let state = tabsStateForInstance(spec.key, declaredPage)
            let keys = ArrayList<String>()
            let pages = ArrayList<CjguiComposableUiTabPage>()
            for (pageSpec in spec.children) {
                let pageKey = pageSpec.property("pageKey")
                let pageTitle = pageSpec.property("pageTitle")
                let enabled = !(pageSpec.property("disabled") == "true")
                keys.add(pageKey)
                pages.add(
                    CjguiComposableUiTabPage(pageKey, pageTitle, nodeFor(pageSpec, provider, intoAcceptedTable),
                        enabled: enabled))
            }
            if (candidateViewStateStagingActive && !intoAcceptedTable) {
                // A candidate build must not publish a page reconcile into the
                // object the ACCEPTED scene is still showing: the candidate scene
                // reads the staged page, and only acceptance publishes it.
                let _ = state.stageReconcile(keys, declaredPage)
                candidateTouchedTabsStates.add(state)
            } else {
                let _ = state.reconcile(keys, declaredPage)
            }
            let scope = CjguiComposableUiIdentityScope("generated-${spec.key}")
            // ONE registered named style feeds BOTH the title's base paint and
            // its interaction states - the same pair the handwritten tabs entry
            // accepts, resolved through the same staged/accepted named-style
            // transaction as every other node. No title paint is invented here.
            // ONE resolution of the role packages base + interaction together
            // (the same whole-group binding the handwritten entry accepts).
            let titleBound = match (namedStyleDefinition(spec.property("titleStyle"), intoAcceptedTable)) {
                case Some(definition) => CjguiComposableUiBoundStyle(definition.base, definition.interaction)
                case None => CjguiComposableUiBoundStyle(CjguiComposableUiStyle(), CjguiComposableUiInteractionStyle())
            }
            return cjguiComposableTabs(scope, semanticId, pages, state, style, titleHeight: titleHeight,
                titleStyle: titleBound.style, titleInteraction: titleBound.interaction, containerNodeId: nodeId)
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_SPLIT) {
            if (spec.children.size != 2) {
                noteRenderFailure("split_requires_two_children", spec.key)
                return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
            }
            let first = nodeFor(spec.children[0], provider, intoAcceptedTable)
            let second = nodeFor(spec.children[1], provider, intoAcceptedTable)
            let firstSize = match (parseGeneratedInteger(spec.property("firstSize"))) {
                case Some(value) => value
                case None => 0
            }
            let firstMinimum = match (parseGeneratedInteger(spec.property("firstMinimum"))) {
                case Some(value) => value
                case None => 120
            }
            let secondMinimum = match (parseGeneratedInteger(spec.property("secondMinimum"))) {
                case Some(value) => value
                case None => 120
            }
            // The scoped split owns the divider identity and the one size rule
            // shared by drag and keyboard; the declaration only seeds the initial
            // size and the bounds.
            let scope = CjguiComposableUiIdentityScope("generated-${spec.key}")
            // The instance's OWN view state wins over the declaration, so a human
            // drag is never reset by re-submitting the same structure; the state
            // object is attached to BOTH panes' container and divider so the
            // framework can apply its ONE size rule to the accepted track.
            let splitState = splitStateForInstance(spec.key, firstSize, firstMinimum: firstMinimum,
                secondMinimum: secondMinimum)
            let effectiveFirstSize = splitState.firstSize()
            return cjguiComposableScopedSplitView(scope, semanticId, first, second,
                CjguiComposableUiSplitAxis.HORIZONTAL, effectiveFirstSize, firstMinimum, secondMinimum, style,
                splitState: splitState, containerNodeId: nodeId)
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_SCROLL) {
            // Exactly one content child (validation enforces the declared
            // childLimit). The viewport is per stable instance key, and the
            // framework's own wheel/焦点 path applies to it like any other.
            let initialOffset = match (parseGeneratedInteger(spec.property("offset"))) {
                case Some(value) => value
                case None => 0
            }
            let viewport = scrollViewportForInstance(spec.key, initialOffset)
            let scroll = cjguiComposableScrollArea(nodeId, semanticId, viewport, style)
            if (spec.property("semanticRole") == "outline") {
                scroll.semanticRole = CJGUI_COMPOSABLE_UI_SEMANTIC_TREE
                scroll.semanticLabel = spec.property("semanticLabel")
            }
            for (child in spec.children) {
                scroll.add(nodeFor(child, provider, intoAcceptedTable))
            }
            return scroll
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_IMAGE) {
            let key = spec.property("resource")
            let version = match (parseGeneratedInteger(spec.property("resourceVersion"))) {
                case Some(value) => value
                case None => 0
            }
            let bindingKey = CjguiGeneratedUiStructureHolder.imageBindingKey(key, version)
            let resolved = match (if (intoAcceptedTable) {
                acceptedImageBindings.get(bindingKey)
            } else {
                candidateImageBindings.get(bindingKey)
            }) {
                case Some(value) => value
                case None => match (catalog.imageResourceFor(key, version)) {
                    case Some(value) =>
                        if (intoAcceptedTable) {
                            // An accepted structure should always carry its own
                            // binding; resolving from the live catalog here only
                            // serves a build outside the commit path and is
                            // cached so the next refresh cannot lose it.
                            acceptedImageBindings.add(bindingKey, value)
                        } else {
                            candidateImageBindings.add(bindingKey, value)
                            // The candidate now HOLDS this published identity, so
                            // the bounded identity table may not forget it even if
                            // the candidate is later rejected within this round.
                            catalog.retainImageIdentity(value.key, value.version)
                        }
                        value
                    case None =>
                        // Validation already refused an unresolvable reference; this
                        // path only exists for a build performed outside a validated
                        // candidate and must not fabricate a path.
                        noteRenderFailure("image_resource_not_registered", spec.key)
                        return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
                }
            }
            // The SAME native image node the handwritten tree builds: the
            // application-resolved raster path plus the logical identity and
            // version, with the shared Style driving its size/layout.
            let mode = if (spec.property("contentMode") == "fill") {
                2
            } else {
                1
            }
            return cjguiComposableImage(nodeId, semanticId, resolved.rasterPath, style, contentMode: mode,
                imageResourceId: resolved.key, imageResourceVersion: resolved.version,
                interactionStyle: interactionStyleFor(spec, intoAcceptedTable))
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_LABEL) {
            return cjguiComposableText(nodeId, semanticId, spec.property("text"), style,
                interactionStyle: interactionStyleFor(spec, intoAcceptedTable))
        }
        if (presentation == CJGUI_GENERATED_PRESENTATION_ACTION) {
            let label = if (spec.property("label").size > 0) {
                spec.property("label")
            } else if (let Some(action) <- catalog.actionFor(spec.actionName)) {
                action.label
            } else {
                spec.actionName
            }
            let action = cjguiComposableButton(nodeId, semanticId, label, "GENERATED_ACTION", nodeId, style,
                enabled: actionEnabledFor(provider, spec.actionName) && spec.property("disabled") != "true",
                operationActionName: spec.actionName,
                interactionStyle: interactionStyleFor(spec, intoAcceptedTable))
            action.semanticIncarnation = generatedSemanticActionIncarnation(spec.actionName)
            if (spec.property("semanticRole") == "row") {
                action.semanticRole = CJGUI_COMPOSABLE_UI_SEMANTIC_TREE_ROW
                action.semanticLabel = if (spec.property("semanticLabel").size > 0) {
                    spec.property("semanticLabel")
                } else {
                    label
                }
                action.semanticSelected = spec.property("semanticSelected") == "true"
                action.semanticExpandable = spec.property("semanticExpandable") == "true"
                action.semanticExpanded = spec.property("semanticExpanded") == "true"
                action.semanticLevel = match (parseGeneratedInteger(spec.property("semanticLevel"))) {
                    case Some(value) => value
                    case None => 0
                }
                action.semanticKey = if (spec.property("semanticRowKey").size > 0) {
                    spec.property("semanticRowKey")
                } else {
                    spec.key
                }
                action.semanticParentKey = spec.property("semanticParentKey")
            }
            return action
        }
        let fieldOption = catalog.fieldFor(spec.fieldId)
        if (let None <- fieldOption) {
            noteRenderFailure("field_not_registered", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        let field = match (fieldOption) {
            case Some(value) => value
            case None => CjguiGeneratedUiFieldSpec("", "", "", -1)
        }
        if (field.writeActionName.isEmpty()) {
            noteRenderFailure("field_has_no_write_operation", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        // The shared field resource and the owner target come from the field
        // definition plus the live provider, never from a kind-name switch.
        let bindingResourceId = if (field.resourceId > 0) {
            field.resourceId
        } else {
            nodeId
        }
        let ownerTarget = provider.fieldOperationResourceId(spec.fieldId)
        // The declared field value comes from the application's live draft,
        // exactly like the handwritten form: a legally empty draft is a draft
        // and must not be replaced by the applied value.
        if (presentation == "FIELD_BOOLEAN") {
            let draft = provider.draftBoolean(spec.fieldId) ?? false
            return cjguiComposableBooleanInput(nodeId, semanticId, spec.property("label"), draft, bindingResourceId,
                style, enabled: fieldEnabledFor(provider, spec.fieldId, ownerTarget), fieldId: spec.fieldId,
                operationActionName: field.writeActionName, operationResourceId: ownerTarget, displayValueRole: "draft",
                interactionStyle: interactionStyleFor(spec, intoAcceptedTable))
        }
        let value = provider.draftText(spec.fieldId)
        if (presentation == "FIELD_INTEGER") {
            return cjguiComposableIntegerInput(nodeId, semanticId, spec.property("label"), value, bindingResourceId,
                style, enabled: fieldEnabledFor(provider, spec.fieldId, ownerTarget), fieldId: spec.fieldId,
                operationActionName: field.writeActionName, operationResourceId: ownerTarget, displayValueRole: "draft",
                interactionStyle: interactionStyleFor(spec, intoAcceptedTable))
        }
        return cjguiComposableTextInput(nodeId, semanticId, spec.property("label"), value, bindingResourceId, style,
            enabled: fieldEnabledFor(provider, spec.fieldId, ownerTarget), fieldId: spec.fieldId,
            operationActionName: field.writeActionName, operationResourceId: ownerTarget, displayValueRole: "draft",
            interactionStyle: interactionStyleFor(spec, intoAcceptedTable))
    }

    private func noteRenderFailure(reason: String, key: String): Unit {
        if (renderFailureReason.isEmpty()) {
            renderFailureReason = reason
            renderFailurePath = key
        }
    }

    /// The enabled projection of one field: the owner's CURRENT availability when
    /// it can be evaluated, and only the legacy "a target exists" test when the
    /// provider reports it cannot evaluate a condition. The control keeps its
    /// target and its draft either way: becoming unavailable must not silently
    /// move the edit to another object or discard what was typed.
    private func fieldEnabledFor(provider: CjguiGeneratedUiBindingProvider, fieldId: String, ownerTarget: Int64): Bool {
        let availability = provider.fieldAvailability(fieldId)
        if (availability.known) {
            // The enabled state is the projection of the owner's answer AND the
            // visible-control constraint (with no owner target there is nothing
            // to edit), never a permission of its own.
            return availability.isAvailable && ownerTarget >= 0
        }
        return ownerTarget >= 0
    }

    /// The enabled projection of one action, on the same terms.
    private func actionEnabledFor(provider: CjguiGeneratedUiBindingProvider, actionName: String): Bool {
        let availability = provider.actionAvailability(actionName)
        if (availability.known) {
            return availability.isAvailable
        }
        return provider.actionAvailable(actionName)
    }

    /// The owner's reason when a field is currently blocked ("" otherwise), so a
    /// frozen control can explain itself while staying readable.
    private func fieldBlockedReasonFor(provider: CjguiGeneratedUiBindingProvider, fieldId: String): String {
        let availability = provider.fieldAvailability(fieldId)
        if (availability.known && !availability.isAvailable) {
            return availability.reason
        }
        return ""
    }

    private func actionBlockedReasonFor(provider: CjguiGeneratedUiBindingProvider, actionName: String): String {
        let availability = provider.actionAvailability(actionName)
        if (availability.known && !availability.isAvailable) {
            return availability.reason
        }
        return ""
    }

    /// Framework-allocated node identity for one composite element. The formula
    /// matches the ordinary generated identity allocation, so a composite element
    /// can never collide with a window's own manual node ids.
    private func allocatedElementNodeId(instance: CjguiComposableUiComponentInstance, elementKey: String): Int64 {
        let registryNodeId = instance.nodeId(elementKey)
        if (registryNodeId > 0) {
            return 800000 + registryNodeId
        }
        return -1
    }

    /// Resolves one composite element from the registered field/action
    /// definitions and the live provider. The factory never sees the catalog, so
    /// it cannot substitute a different owner or writer.
    private func resolveCompositeElement(element: CjguiCompositeElementSpec, instanceKey: String, nodeId: Int64,
        semanticId: String, provider: CjguiGeneratedUiBindingProvider): CjguiCompositeElementBinding {
        if (element.role == CJGUI_COMPOSITE_ELEMENT_CONTAINER) {
            return CjguiCompositeElementBinding(element.elementKey, element.role, nodeId, semanticId, element.label,
                instanceKey: instanceKey)
        }
        if (element.role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
            let label = if (element.label.size > 0) {
                element.label
            } else if (let Some(action) <- catalog.actionFor(element.actionName)) {
                action.label
            } else {
                element.actionName
            }
            return CjguiCompositeElementBinding(element.elementKey, element.role, nodeId, semanticId, label,
                instanceKey: instanceKey, actionName: element.actionName,
                actionEnabled: actionEnabledFor(provider, element.actionName),
                blockedReason: actionBlockedReasonFor(provider, element.actionName))
        }
        let field = match (catalog.fieldFor(element.fieldId)) {
            case Some(value) => value
            case None => CjguiGeneratedUiFieldSpec("", "", "", -1)
        }
        let resourceId = if (field.resourceId > 0) {
            field.resourceId
        } else {
            nodeId
        }
        let ownerTarget = provider.fieldOperationResourceId(element.fieldId)
        let label = if (element.label.size > 0) {
            element.label
        } else {
            field.label
        }
        if (field.editorKind == "BOOLEAN") {
            return CjguiCompositeElementBinding(element.elementKey, element.role, nodeId, semanticId, label,
                instanceKey: instanceKey, fieldId: element.fieldId, argumentName: element.argumentName,
                writerOperation: field.writeActionName, ownerTargetResourceId: ownerTarget,
                bindingResourceId: resourceId, editorKind: field.editorKind, presetValue: element.presetValue,
                draftBoolean: provider.draftBoolean(element.fieldId) ?? false,
                ownerAvailable: fieldEnabledFor(provider, element.fieldId, ownerTarget),
                blockedReason: fieldBlockedReasonFor(provider, element.fieldId))
        }
        return CjguiCompositeElementBinding(element.elementKey, element.role, nodeId, semanticId, label,
            instanceKey: instanceKey, fieldId: element.fieldId, argumentName: element.argumentName,
            writerOperation: field.writeActionName, ownerTargetResourceId: ownerTarget, bindingResourceId: resourceId,
            editorKind: field.editorKind, presetValue: element.presetValue,
            draftText: provider.draftText(element.fieldId),
            ownerAvailable: fieldEnabledFor(provider, element.fieldId, ownerTarget),
            blockedReason: fieldBlockedReasonFor(provider, element.fieldId))
    }

    /// Renders one application composite. The framework allocates every
    /// element's identity, resolves its owner binding and validates the REAL
    /// subtree the factory returns against the declared budget before any
    /// identity table is published. A failure keeps the previously accepted
    /// scene and its routes.
    private func compositeFor(spec: CjguiGeneratedUiNodeSpec, provider: CjguiGeneratedUiBindingProvider,
        instance: CjguiComposableUiComponentInstance, intoAcceptedTable: Bool): CjguiComposableUiNode {
        if (let None <- catalog.compositeFor(spec.kind)) {
            noteRenderFailure("composite_not_registered", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        if (let None <- catalog.compositeFactoryFor(spec.kind)) {
            noteRenderFailure("composite_factory_missing", spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        let composite = match (catalog.compositeFor(spec.kind)) {
            case Some(value) => value
            case None => CjguiCompositeComponentSpec("", ArrayList<CjguiGeneratedUiPropertySpec>(),
                ArrayList<CjguiCompositeElementSpec>())
        }
        let factory = match (catalog.compositeFactoryFor(spec.kind)) {
            case Some(value) => value
            case None => CjguiCompositeMissingFactory()
        }
        let properties = HashMap<String, String>()
        for ((name, value) in spec.properties) {
            properties.add(name, value)
        }
        let bindings = ArrayList<CjguiCompositeElementBinding>()
        let allocated = HashSet<Int64>()
        for (element in composite.elements) {
            let elementNodeId = allocatedElementNodeId(instance, element.elementKey)
            if (elementNodeId <= 0) {
                noteRenderFailure("composite_element_identity_missing", spec.key)
                return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
            }
            allocated.add(elementNodeId)
            bindings.add(
                resolveCompositeElement(element, spec.key, elementNodeId, instance.semanticId(element.elementKey),
                    provider))
        }
        let children = ArrayList<CjguiComposableUiNode>()
        for (child in spec.children) {
            children.add(nodeFor(child, provider, intoAcceptedTable))
        }
        if (!renderFailureReason.isEmpty()) {
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        // The SAME resolved-style mapping the built-in nodes use, so an
        // application composite consumes the declared style properties through
        // the one shared conversion instead of re-parsing them.
        let context = CjguiCompositeBuildContext(spec.key, properties, bindings, children: children,
            resolvedStyle: styleFromDeclaredProperties(properties, false, intoAcceptedTable),
            resolvedInteraction: interactionStyleFor(spec, intoAcceptedTable))
        let built = factory.buildComposite(context)
        let audit = CjguiCompositeExpansionAudit()
        // Caller-provided children carry identities another instance allocated:
        // they are legitimate here, but they are still counted against the budget
        // and must really appear in the returned subtree.
        for (child in children) {
            audit.placedChildren.add(child.nodeId)
        }
        auditExpanded(built, 1, composite, allocated, audit)
        if (audit.issue.isEmpty()) {
            for (allocatedId in allocated) {
                if (!audit.seen.contains(allocatedId)) {
                    audit.issue = "composite_element_missing"
                    break
                }
            }
        }
        if (audit.issue.isEmpty()) {
            for (child in children) {
                if (!audit.seen.contains(child.nodeId)) {
                    audit.issue = "composite_children_missing"
                    break
                }
            }
        }
        if (audit.issue.isEmpty()) {
            audit.issue = auditElementBindings(bindings, audit)
        }
        if (!audit.issue.isEmpty()) {
            noteRenderFailure(audit.issue, spec.key)
            return cjguiComposableText(-1, "generated-rejected", "", CjguiComposableUiStyle())
        }
        lastExpandedNodeCount = audit.count
        lastExpandedDepth = audit.maxDepth
        // Only a validated expansion publishes identities and bindings.
        for (binding in bindings) {
            if (intoAcceptedTable) {
                nodeIdToKey.add(binding.nodeId, spec.key)
                acceptedCompositeElements.add(binding.nodeId, binding)
            } else {
                candidateNodeIdToKey.add(binding.nodeId, spec.key)
                candidateCompositeElements.add(binding.nodeId, binding)
            }
        }
        return built
    }

    /// Audits the REAL expanded subtree: node count against the declared limit
    /// and the catalog bound, depth against the declared limit, and every node
    /// identity must be one the framework allocated for this instance exactly
    /// once. A custom declaration therefore cannot expand past capacity, invent
    /// an id, drop a declared element or reuse an identity.
    private func auditExpanded(node: CjguiComposableUiNode, depth: Int64, composite: CjguiCompositeComponentSpec,
        allocated: HashSet<Int64>, audit: CjguiCompositeExpansionAudit): Unit {
        if (!audit.issue.isEmpty()) {
            return
        }
        audit.count += 1
        if (audit.count > composite.expandedNodeLimit) {
            audit.issue = "composite_expansion_node_limit"
            return
        }
        if (audit.count > catalog.maxNodes) {
            audit.issue = "composite_expansion_catalog_limit"
            return
        }
        if (depth > composite.expandedDepthLimit) {
            audit.issue = "composite_expansion_depth_limit"
            return
        }
        if (depth > audit.maxDepth) {
            audit.maxDepth = depth
        }
        if (node.nodeId <= 0) {
            audit.issue = "composite_unidentified_node"
            return
        }
        let isPlacedChild = audit.placedChildren.contains(node.nodeId)
        if (!isPlacedChild && !allocated.contains(node.nodeId)) {
            audit.issue = "composite_foreign_node_id"
            return
        }
        if (audit.seen.contains(node.nodeId)) {
            // A caller-provided child can appear only once too: duplicating it
            // would mount the same identity twice.
            audit.issue = "composite_duplicate_node_id"
            return
        }
        audit.seen.add(node.nodeId)
        audit.nodesById.add(node.nodeId, node)
        for (child in node.children()) {
            auditExpanded(child, depth + 1, composite, allocated, audit)
        }
    }

    /// Checks that every framework-allocated element node really carries the
    /// binding the framework resolved for that element: a factory may not mount
    /// an element with another field, writer, owner target or action. The
    /// expansion audit alone (identity/count/depth) could not prove this.
    private func auditElementBindings(bindings: ArrayList<CjguiCompositeElementBinding>,
        audit: CjguiCompositeExpansionAudit): String {
        for (binding in bindings) {
            let node = match (audit.nodesById.get(binding.nodeId)) {
                case Some(value) => value
                case None => return "composite_element_missing"
            }
            if (binding.role == CJGUI_COMPOSITE_ELEMENT_FIELD) {
                // A field element must really carry the resolved field binding,
                // including the editor's own binding resource: comparing only the
                // id/writer/target would accept a control bound to another
                // resource and then route the owner write from the declaration.
                if (node.fieldId != binding.fieldId || node.operationActionName != binding.writerOperation ||
                    node.operationResourceId != binding.ownerTargetResourceId || node.resourceId != binding
                    .bindingResourceId) {
                    return "composite_element_binding_mismatch"
                }
            } else if (binding.role == CJGUI_COMPOSITE_ELEMENT_PRESET) {
                // A preset is a BUTTON: the adapter resolves its press from the
                // element's declared role and constant, so its node carries no
                // field binding. It must still carry the RESOLVED owner writer and
                // target (plus its own binding resource), otherwise a same-key
                // rebind to another target would be indistinguishable from the old
                // object and a late press would write the new owner.
                if (node.nodeKind != CJGUI_COMPOSABLE_UI_BUTTON || node.resourceId != binding.bindingResourceId ||
                    node.operationActionName != binding.writerOperation || node.operationResourceId != binding
                    .ownerTargetResourceId) {
                    return "composite_element_binding_mismatch"
                }
            } else if (binding.role == CJGUI_COMPOSITE_ELEMENT_ACTION) {
                // The action is dispatched by the adapter from the DECLARED
                // element, so the real control must be the framework's generic
                // action button in the declared enabled state. A raw
                // business-action token or a different enabled state would mean
                // the control the user sees disagrees with the declaration.
                if (node.nodeKind != CJGUI_COMPOSABLE_UI_BUTTON || node.actionName != "GENERATED_ACTION" ||
                    node.isEnabled != binding.actionEnabled) {
                    return "composite_element_binding_mismatch"
                }
            }
        }
        return ""
    }

    /// Layout properties a registered presentation declares are applied here.
    /// Only a CONTAINER presentation consumes gap/padding; a leaf presentation
    /// (label/action/field editor) gets an empty style, exactly like the
    /// handwritten builder that authors the same leaf. Applying a default gap to
    /// a leaf merely because the kind was generated made two authors of the same
    /// panel observably different.
    /// The definition a `style` reference resolves to for this build. A
    /// still-registered name is authoritative and is recorded as the latest
    /// resolution, so a legal update reaches the next successful refresh. A
    /// name that no longer resolves keeps its last committed definition for an
    /// ACCEPTED build (the instance stays as it was accepted), while a candidate
    /// gets nothing: validation refuses the candidate with
    /// `style_reference_not_registered` instead of rendering a silent default.
    private func namedStyleDefinition(reference: String, intoAcceptedTable: Bool): ?CjguiComposableUiNamedStyle {
        if (reference.size == 0) {
            return None
        }
        return match (catalog.namedStyles().forName(reference)) {
            case Some(style) =>
                // STAGED, not committed: this build may still be rejected at
                // layout/prepare/commit, and an accepted interface must keep the
                // resolution its own scene was accepted with.
                stagedNamedStyles.add(reference, style)
                Some(style)
            case None =>
                if (intoAcceptedTable) {
                    // The name is gone: the ACCEPTED interface keeps the value it
                    // was accepted with, never framework defaults.
                    resolvedNamedStyles.get(reference)
                } else {
                    None
                }
        }
    }

    /// The public viewport of one stable generated scroll instance. The declared
    /// offset is only the INITIAL request for a brand-new instance: after that the
    /// view state belongs to this instance, so re-submitting the same structure
    /// cannot silently reset a human's scroll position.
    public func scrollViewportForInstance(key: String, initialOffset: Int64): CjguiComposableUiScrollViewport {
        if (let Some(existing) <- instanceScrollViewports.get(key)) {
            return existing
        }
        let viewport = CjguiComposableUiScrollViewport()
        viewport.requestInitialOffset(initialOffset)
        instanceScrollViewports.add(key, viewport)
        return viewport
    }

    /// The shared view state of one stable generated split instance. The declared
    /// size and both minimums only SEED a new instance; afterwards the instance
    /// owns its size, so re-submitting the same structure cannot reset the layout
    /// a person just chose. The framework's ONE size rule reads and writes this
    /// object, which is also how a real divider drag reaches the next layout
    /// without inventing a business version.
    ///
    /// `firstMinimum`/`secondMinimum` are the AUTHOR's declaration, expressed
    /// explicitly: `None` means "this description does not declare the bounds" and
    /// leaves an existing instance untouched, while `Some(0)` is a legal minimum.
    /// A declaration that was removed from the description therefore falls back to
    /// the public default at the call site instead of silently keeping an old
    /// value, and a read-only size query can never rewrite the constraints.
    public func splitStateForInstance(key: String, declaredFirstSize: Int64, firstMinimum!: ?Int64 = None,
        secondMinimum!: ?Int64 = None): CjguiComposableUiSplitState {
        if (let Some(existing) <- instanceSplitStates.get(key)) {
            // The instance already exists: the declaration may still have changed
            // its CONSTRAINTS, which must be consumed. The person's current size is
            // preserved and clamped by the ONE size rule on the next solve.
            if (let Some(first) <- firstMinimum) {
                let second = match (secondMinimum) {
                    case Some(value) => value
                    case None => first
                }
                if (candidateViewStateStagingActive && !buildIntoAcceptedTable) {
                    // A candidate build must not publish a re-declaration into an
                    // object the ACCEPTED scene is still using.
                    existing.stageBoundsDeclaration(first, second)
                    candidateTouchedSplitStates.add(existing)
                } else {
                    existing.declareBounds(first, second)
                }
            }
            return existing
        }
        let first = match (firstMinimum) {
            case Some(value) => value
            case None => 0
        }
        let second = match (secondMinimum) {
            case Some(value) => value
            case None => first
        }
        let state = CjguiComposableUiSplitState(declaredFirstSize, first, second)
        instanceSplitStates.add(key, state)
        return state
    }

    /// The ACTIVE page of one generated tab container instance. The declaration's
    /// initial page only seeds a NEW instance; afterwards the person's page is the
    /// instance's own window view state.
    public func tabsStateForInstance(key: String, declaredPage: String): CjguiComposableUiTabsState {
        if (let Some(existing) <- instanceTabsStates.get(key)) {
            return existing
        }
        let state = CjguiComposableUiTabsState(declaredPage)
        instanceTabsStates.add(key, state)
        return state
    }

    /// The first-pane size of one stable generated split instance: the declared
    /// value seeds a NEW instance, and the instance's own current size is returned
    /// afterwards. This is a READ: it declares no bounds and can therefore never
    /// rewrite the constraints of an existing instance.
    public func splitSizeForInstance(key: String, declaredFirstSize: Int64): Int64 {
        return splitStateForInstance(key, declaredFirstSize).firstSize()
    }

    /// Records the size a human divider drag (or the keyboard size rule) produced
    /// for one instance. The framework/scoped split owns the ONE size rule; this
    /// only stores its result for the next build.
    public func updateSplitSizeForInstance(key: String, firstSize: Int64): Unit {
        splitStateForInstance(key, firstSize).setFirstSize(firstSize)
    }

    /// Drops the view state of instances no longer present in the accepted
    /// structure, so removing or re-identifying a split releases it.
    public func retainSplitSizesFor(keys: ArrayList<String>): Unit {
        retainInstanceViewStatesFor(keys)
    }

    /// Restores the instance view-state tables to the snapshot taken when the
    /// candidate refresh began, dropping everything an abandoned build created.
    /// A re-declaration staged on a SURVIVING instance is given back first: the
    /// tables are shallow copies, so restoring them alone would leave the shared
    /// object holding the candidate's declaration.
    private func restoreStagedInstanceViewStates(): Unit {
        discardStagedInstanceViewStates()
        if (let Some(snapshot) <- stagedInstanceScrollViewports) {
            instanceScrollViewports = snapshot
        }
        if (let Some(snapshot) <- stagedInstanceSplitStates) {
            instanceSplitStates = snapshot
        }
        if (let Some(snapshot) <- stagedInstanceTabsStates) {
            instanceTabsStates = snapshot
        }
        stagedInstanceScrollViewports = None
        stagedInstanceSplitStates = None
        stagedInstanceTabsStates = None
        candidateViewStateStagingActive = false
    }

    /// Publishes the re-declarations this candidate staged for SURVIVING
    /// instances. Called in the same transaction that accepts the scene, so an
    /// accepted structure and its bounds/page are never observed apart.
    private func commitStagedInstanceViewStates(): Unit {
        for (state in candidateTouchedSplitStates) {
            state.commitStagedBoundsDeclaration()
        }
        for (state in candidateTouchedTabsStates) {
            state.commitStagedReconcile()
        }
        candidateTouchedSplitStates = ArrayList<CjguiComposableUiSplitState>()
        candidateTouchedTabsStates = ArrayList<CjguiComposableUiTabsState>()
    }

    /// Gives back every re-declaration this candidate staged, leaving the objects
    /// the accepted scene is still using exactly as accepted. A person's own
    /// pending selection is a LIVE value, not staged state, so it survives.
    private func discardStagedInstanceViewStates(): Unit {
        for (state in candidateTouchedSplitStates) {
            state.discardStagedBoundsDeclaration()
        }
        for (state in candidateTouchedTabsStates) {
            state.discardStagedReconcile()
        }
        candidateTouchedSplitStates = ArrayList<CjguiComposableUiSplitState>()
        candidateTouchedTabsStates = ArrayList<CjguiComposableUiTabsState>()
    }

    /// Releases the per-instance view state (scroll viewports AND split sizes) of
    /// every generated instance the accepted structure no longer contains, so a
    /// removed or re-identified element leaves nothing behind for the next scene
    /// to inherit.
    public func retainInstanceViewStatesFor(keys: ArrayList<String>): Unit {
        let keptViewports = HashMap<String, CjguiComposableUiScrollViewport>()
        let keptSplits = HashMap<String, CjguiComposableUiSplitState>()
        let keptTabs = HashMap<String, CjguiComposableUiTabsState>()
        for (key in keys) {
            if (let Some(viewport) <- instanceScrollViewports.get(key)) {
                keptViewports.add(key, viewport)
            }
            if (let Some(state) <- instanceSplitStates.get(key)) {
                keptSplits.add(key, state)
            }
            if (let Some(state) <- instanceTabsStates.get(key)) {
                keptTabs.add(key, state)
            }
        }
        // An instance that leaves the accepted description must not keep a staged
        // declaration armed: the object is no longer reachable through the holder,
        // but a caller may still hold the reference.
        for ((key, state) in instanceSplitStates) {
            if (keptSplits.get(key).isNone()) {
                state.discardStagedBoundsDeclaration()
            }
        }
        for ((key, state) in instanceTabsStates) {
            if (keptTabs.get(key).isNone()) {
                state.discardStagedReconcile()
            }
        }
        instanceScrollViewports = keptViewports
        instanceSplitStates = keptSplits
        instanceTabsStates = keptTabs
    }

    /// How many published image identities this holder still holds, observed
    /// through the shared catalog. Observation only: no raster path or native
    /// handle is exposed.
    public func liveImageIdentityHoldCount(): Int64 {
        return catalog.liveImageIdentityHoldCount()
    }

    /// Releases every identity this holder still owns (the accepted scene's and,
    /// if an attempt was in flight, the pending candidate's). Called exactly once
    /// from the window's dispose path, so a shared catalog does not keep another
    /// window's references alive; calling it again is a no-op.
    public func releaseAcceptedImageIdentities(): Unit {
        releaseCandidateImageHolds()
        releaseAcceptedImageHolds()
        acceptedImageBindings = HashMap<String, CjguiGeneratedUiImageResourceSpec>()
    }

    /// Releases the holds the ACCEPTED set owns. Used by the commit transfer and
    /// by dispose.
    private func releaseAcceptedImageHolds(): Unit {
        for ((_, spec) in acceptedImageBindings) {
            catalog.releaseImageIdentity(spec.key, spec.version)
        }
    }

    /// Releases ONLY the pending candidate's holds. The accepted set is never
    /// touched here, so a rejected or superseded attempt cannot drop a reference
    /// the accepted interface still needs.
    private func releaseCandidateImageHolds(): Unit {
        for ((_, spec) in candidateImageBindings) {
            catalog.releaseImageIdentity(spec.key, spec.version)
        }
        candidateImageBindings = HashMap<String, CjguiGeneratedUiImageResourceSpec>()
    }

    /// Opens the style staging area for the refresh about to be built.
    public func beginStyleRefresh(): Unit {
        stagedNamedStyles = HashMap<String, CjguiComposableUiNamedStyle>()
    }

    /// Promotes the resolutions of an ACCEPTED scene and drops every record no
    /// longer referenced by the accepted structure, so the retained set is
    /// bounded by what is really in use.
    public func commitStyleRefresh(): Unit {
        let staged = stagedNamedStyles
        stagedNamedStyles = HashMap<String, CjguiComposableUiNamedStyle>()
        let referenced = match (accepted) {
            case Some(structure) => referencedStyleNames(structure)
            case None => ArrayList<String>()
        }
        let kept = HashMap<String, CjguiComposableUiNamedStyle>()
        for (name in referenced) {
            if (let Some(style) <- staged.get(name)) {
                kept.add(name, style)
            } else if (let Some(style) <- resolvedNamedStyles.get(name)) {
                kept.add(name, style)
            }
        }
        resolvedNamedStyles = kept
    }

    /// Discards the resolutions of a rejected build; the committed map is
    /// untouched.
    public func rollbackStyleRefresh(): Unit {
        stagedNamedStyles = HashMap<String, CjguiComposableUiNamedStyle>()
    }

    private func referencedStyleNames(spec: CjguiGeneratedUiNodeSpec): ArrayList<String> {
        let names = ArrayList<String>()
        collectReferencedStyleNames(spec, names)
        return names
    }

    private func collectReferencedStyleNames(spec: CjguiGeneratedUiNodeSpec, names: ArrayList<String>): Unit {
        // `style` covers the node itself; `titleStyle` covers a tabs container's
        // title row. Both are named-style references with the same lifetime, so
        // both keep their definition while the structure references them.
        for (propertyName in ["style", "titleStyle"]) {
            let reference = spec.property(propertyName)
            if (reference.size > 0) {
                var known = false
                for (existing in names) {
                    if (existing == reference) {
                        known = true
                        break
                    }
                }
                if (!known) {
                    names.add(reference)
                }
            }
        }
        for (child in spec.children) {
            collectReferencedStyleNames(child, names)
        }
    }

    /// The named base style of one node, or None when no `style` reference is
    /// declared or the reference no longer resolves (validation refuses the
    /// latter before a candidate is received).
    private func namedBaseStyle(properties: HashMap<String, String>, intoAcceptedTable: Bool): ?CjguiComposableUiStyle {
        return match (namedStyleDefinition(propertyOf(properties, "style"), intoAcceptedTable)) {
            case Some(style) => Some(style.base)
            case None => None
        }
    }

    /// The interaction paint of one node's named style (empty when none). A named
    /// style is the ONLY way a generated node gets interaction paint, so an
    /// external author cannot invent a second state machine.
    private func interactionStyleFor(spec: CjguiGeneratedUiNodeSpec, intoAcceptedTable: Bool): CjguiComposableUiInteractionStyle {
        return match (namedStyleDefinition(spec.property("style"), intoAcceptedTable)) {
            case Some(style) => style.interaction
            case None => CjguiComposableUiInteractionStyle()
        }
    }

    private func declaredColor(properties: HashMap<String, String>, name: String, fallback: CjguiComposableUiColor): CjguiComposableUiColor {
        let declared = propertyOf(properties, name)
        if (declared.size == 0) {
            return fallback
        }
        return match (cjguiComposableUiParseColorToken(declared)) {
            case Some(color) => color
            case None => fallback
        }
    }

    /// Resolves the declared outer shadow with the shared three-way contract:
    ///  - an ABSENT property INHERITS the base (a node's unrelated declaration
    ///    must not erase a named style's effect);
    ///  - an explicit `none` or the empty string CLEARS it (returns None);
    ///  - a legal token REPLACES it.
    /// Malformed text is refused as a whole candidate by the validator before
    /// this mapping runs; should one reach here defensively, the base is kept.
    private func declaredShadowOf(properties: HashMap<String, String>, fallback: ?CjguiComposableUiShadowStyle): ?CjguiComposableUiShadowStyle {
        if (let None <- properties.get("shadow")) {
            return fallback
        }
        let declared = propertyOf(properties, "shadow")
        if (cjguiComposableUiEffectTokenIsNone(declared)) {
            return None
        }
        return match (cjguiComposableUiParseShadowToken(declared)) {
            case Some(value) => Some(value)
            case None => fallback
        }
    }

    /// Same three-way contract as `declaredShadowOf` for the linear gradient.
    private func declaredGradientOf(properties: HashMap<String, String>, fallback: ?CjguiComposableUiLinearGradient): ?CjguiComposableUiLinearGradient {
        if (let None <- properties.get("gradient")) {
            return fallback
        }
        let declared = propertyOf(properties, "gradient")
        if (cjguiComposableUiEffectTokenIsNone(declared)) {
            return None
        }
        return match (cjguiComposableUiParseGradientToken(declared)) {
            case Some(value) => Some(value)
            case None => fallback
        }
    }

    /// Same three-way contract as the existing encoded style effects. Absence
    /// inherits a named base group; empty/none clears it; a valid token replaces.
    private func declaredEffectGroupOf(properties: HashMap<String, String>, fallback: ?CjguiComposableUiEffectGroup): ?CjguiComposableUiEffectGroup {
        if (let None <- properties.get("effectGroup")) {
            return fallback
        }
        let declared = propertyOf(properties, "effectGroup")
        if (cjguiComposableUiEffectTokenIsNone(declared)) {
            return None
        }
        return cjguiComposableUiParseEffectGroupToken(declared)
    }

    /// Resolution order: framework default -> named base style -> the node's own
    /// explicit properties -> (later, at paint time) the interaction-state
    /// overrides. Only a DECLARED property overrides the named base, so a
    /// reference does not reset values the author did not mention.
    private func styleFromDeclaredProperties(properties: HashMap<String, String>, container: Bool,
        intoAcceptedTable: Bool): CjguiComposableUiStyle {
        let named = namedBaseStyle(properties, intoAcceptedTable)
        let base = match (named) {
            case Some(value) => value
            case None => CjguiComposableUiStyle()
        }
        var gap: Int64 = match (named) {
            case Some(value) => value.gap
            case None =>
                if (container) {
                    4
                } else {
                    0
                }
        }
        if (let Some(value) <- parseGeneratedInteger(propertyOf(properties, "gap"))) {
            gap = value
        }
        var padding: Int64 = base.padding
        if (let Some(value) <- parseGeneratedInteger(propertyOf(properties, "padding"))) {
            padding = value
        }
        let fixedWidth = declaredStyleValue(properties, "fixedWidth", base.fixedWidth)
        let fixedHeight = declaredStyleValue(properties, "fixedHeight", base.fixedHeight)
        let minWidth = declaredStyleValue(properties, "minWidth", base.minWidth)
        let maxWidth = declaredStyleValue(properties, "maxWidth", base.maxWidth)
        let minHeight = declaredStyleValue(properties, "minHeight", base.minHeight)
        let maxHeight = declaredStyleValue(properties, "maxHeight", base.maxHeight)
        let growX = declaredStyleValue(properties, "growX", base.growX)
        let growY = declaredStyleValue(properties, "growY", base.growY)
        let fontSize = Float64(declaredStyleValue(properties, "fontSize", Int64(base.fontSize)))
        let fontWeight = declaredStyleValue(properties, "fontWeight", base.fontWeight)
        let borderWidth = declaredStyleValue(properties, "borderWidth", base.borderWidth)
        let alignX = declaredAlignmentOf(properties, "alignX", base.alignX)
        let alignY = declaredAlignmentOf(properties, "alignY", base.alignY)
        let translateX = if (let Some(token) <- properties.get("translateX")) {
            if (token.size == 0) { 0.0 } else {
                match (cjguiComposableUiParseTranslationScalar(token)) {
                    case Some(value) => value
                    case None => base.translateX
                }
            }
        } else { base.translateX }
        let translateY = if (let Some(token) <- properties.get("translateY")) {
            if (token.size == 0) { 0.0 } else {
                match (cjguiComposableUiParseTranslationScalar(token)) {
                    case Some(value) => value
                    case None => base.translateY
                }
            }
        } else { base.translateY }
        // The rebuilt style carries the base's named effect rejection through, so
        // a definition the shared contract already refused can never be laundered
        // into a clean `None` by the ordinary property-resolution rebuild. The
        // window refuses such a candidate before the accepted scene, exactly like
        // a handwritten illegal effect.
        return CjguiComposableUiStyle(background: declaredColor(properties, "background", base.background),
            border: declaredColor(properties, "border", base.border),
            textColor: declaredColor(properties, "textColor", base.textColor), padding: padding, gap: gap,
            fixedWidth: fixedWidth, fixedHeight: fixedHeight, growX: growX, growY: growY, borderWidth: borderWidth,
            fontSize: fontSize, fontWeight: fontWeight, minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight,
            maxHeight: maxHeight, alignX: alignX, alignY: alignY, cornerRadius: base.cornerRadius,
            offsetX: base.offsetX, offsetY: base.offsetY, translateX: translateX, translateY: translateY,
            wheelScrollable: base.wheelScrollable, scrollContentAlignY: base.scrollContentAlignY,
            pointerInteractive: base.pointerInteractive,
            clipsContent: base.clipsContent, shadow: declaredShadowOf(properties, base.shadow),
            gradient: declaredGradientOf(properties, base.gradient),
            effectGroup: declaredEffectGroupOf(properties, base.effectGroup), effectRejection: base.effectRejection)
    }

    private func propertyOf(properties: HashMap<String, String>, name: String): String {
        if (let Some(value) <- properties.get(name)) {
            return value
        }
        return ""
    }

    private func declaredStyleValue(properties: HashMap<String, String>, name: String, fallback: Int64): Int64 {
        let parsed = parseGeneratedInteger(propertyOf(properties, name))
        return match (parsed) {
            case Some(value) => value
            case None => fallback
        }
    }

    private func declaredAlignmentOf(properties: HashMap<String, String>, name: String, fallback: Int64): Int64 {
        let declared = propertyOf(properties, name)
        if (declared == "start") {
            return CJGUI_COMPOSABLE_UI_ALIGN_START
        }
        if (declared == "center") {
            return CJGUI_COMPOSABLE_UI_ALIGN_CENTER
        }
        if (declared == "end") {
            return CJGUI_COMPOSABLE_UI_ALIGN_END
        }
        if (declared == "stretch") {
            return CJGUI_COMPOSABLE_UI_ALIGN_STRETCH
        }
        return fallback
    }

    private func styleFor(spec: CjguiGeneratedUiNodeSpec, intoAcceptedTable: Bool): CjguiComposableUiStyle {
        let declared = match (catalog.componentFor(spec.kind)) {
            case Some(value) => value
            case None => CjguiGeneratedUiComponentSpec("", ArrayList<CjguiGeneratedUiPropertySpec>(), false)
        }
        let presentation = declared.presentation
        if (presentation == CJGUI_GENERATED_PRESENTATION_COMPOSITE) {
            // A composite's own factory owns its internal layout; the framework
            // only passes the declared properties through the shared context.
            return CjguiComposableUiStyle()
        }
        let isContainer = presentation == CJGUI_GENERATED_PRESENTATION_VERTICAL || presentation ==
            CJGUI_GENERATED_PRESENTATION_HORIZONTAL
        // The scroll container and the generated split consume the shared leaf
        // style vocabulary exactly like a label (`consumesStyleProperty` accepts
        // it for them), so their RESOLUTION must not silently drop it: a declared
        // `fixedHeight`, growth, alignment, font or paint has to reach the node
        // the framework really builds.
        if (presentation == CJGUI_GENERATED_PRESENTATION_SCROLL || presentation == CJGUI_GENERATED_PRESENTATION_SPLIT) {
            return styleFromDeclaredProperties(spec.properties, isContainer, intoAcceptedTable)
        }
        if (!isContainer && presentation != CJGUI_GENERATED_PRESENTATION_LABEL && presentation !=
            CJGUI_GENERATED_PRESENTATION_ACTION && presentation != CJGUI_GENERATED_PRESENTATION_IMAGE && presentation !=
            "FIELD_TEXT" && presentation != "FIELD_INTEGER" && presentation != "FIELD_BOOLEAN") {
            return CjguiComposableUiStyle()
        }
        return styleFromDeclaredProperties(spec.properties, isContainer, intoAcceptedTable)
    }

    /// The accepted spec for a stable key, or None when that key is not part
    /// of the currently accepted structure. Event routing uses this to verify
    /// kind/field/binding before touching the business owner.
    public func acceptedNodeForKey(key: String): ?CjguiGeneratedUiNodeSpec {
        if (let Some(structure) <- accepted) {
            return findNode(structure, key)
        }
        return None
    }

    private func findNode(spec: CjguiGeneratedUiNodeSpec, key: String): ?CjguiGeneratedUiNodeSpec {
        if (spec.key == key) {
            return Some(spec)
        }
        for (child in spec.children) {
            if (let Some(found) <- findNode(child, key)) {
                return Some(found)
            }
        }
        return None
    }

    /// Resolves the accepted action for a generated node key (used by the
    /// consumer's event routing so a stale key never maps to another action).
    public func actionNameForKey(key: String): String {
        if (let Some(structure) <- accepted) {
            return actionNameIn(structure, key)
        }
        return ""
    }

    private func actionNameIn(spec: CjguiGeneratedUiNodeSpec, key: String): String {
        if (spec.key == key) {
            return spec.actionName
        }
        for (child in spec.children) {
            let found = actionNameIn(child, key)
            if (!found.isEmpty()) {
                return found
            }
        }
        return ""
    }
}

/// One decoded candidate (or a specific decode failure).
public class CjguiGeneratedUiDecoded {
    public let ok: Bool
    public let reason: String
    public let root: ?CjguiGeneratedUiNodeSpec

    public init(ok: Bool, reason: String, root: ?CjguiGeneratedUiNodeSpec) {
        this.ok = ok
        this.reason = reason
        this.root = root
    }
}

/// Hex alphabet for encoding arbitrary text (labels/captions) on one protocol
/// token, so a caption containing any character can never split a line.
private let CJGUI_GENERATED_UI_HEX_DIGITS: Array<String> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B",
    "C", "D", "E", "F"]

private func cjguiGeneratedUiHexEncode(text: String): String {
    let builder = StringBuilder()
    for (byte in text.toArray()) {
        let value = Int64(byte)
        builder.append(CJGUI_GENERATED_UI_HEX_DIGITS[value / 16])
        builder.append(CJGUI_GENERATED_UI_HEX_DIGITS[value % 16])
    }
    return builder.toString()
}

/// One accepted generated instance an external caller can address by its
/// DECLARED key: the composite element (when the instance is a composite), the
/// accepted component identity, its binding references and the geometry the
/// window really accepted. It is a read-only projection with no native handle.
public class CjguiGeneratedUiAcceptedInstance {
    public let key: String
    public let elementKey: String
    public let role: String
    public let nodeId: Int64
    public let semanticId: String
    public let kindToken: String
    public let fieldId: String
    public let actionName: String
    public let label: String
    public let visible: Bool
    public let bounds: CjguiComposableUiRect
    /// Logical image resource this accepted node references ("" when none) and
    /// the exact version it was accepted with. An external reader therefore
    /// learns WHICH application resource the window accepted without ever
    /// seeing or supplying a local path.
    public let imageResourceId: String
    public let imageResourceVersion: Int64
    /// Last sampled preparation state of that binding: loading / ready / failed
    /// (or "unrequested" when no sampling happened yet). It distinguishes
    /// "the scene accepted this reference" from "the raster is ready", and it
    /// never exposes a path or a native handle.
    public let imageResourceState: String
    /// Canonical accepted effect group declaration (`none` when no group is
    /// present). This reads the accepted scene style; it does not claim that a
    /// renderer has completed or presented the effect.
    public let effectGroupToken: String
    public let controlRole: String
    public let controlSelected: Bool
    public let controlExpandable: Bool
    public let controlExpanded: Bool
    public let controlEnabled: Bool
    public let controlLevel: Int64
    public let controlRowKey: String
    public let controlParentKey: String

    public init(key: String, elementKey: String, role: String, nodeId: Int64, semanticId: String, kindToken: String,
        fieldId: String, actionName: String, label: String, visible: Bool, bounds: CjguiComposableUiRect,
        imageResourceId!: String = "", imageResourceVersion!: Int64 = 0, imageResourceState!: String = "unrequested",
        effectGroupToken!: String = "none", controlRole!: String = "none",
        controlSelected!: Bool = false, controlExpandable!: Bool = false,
        controlExpanded!: Bool = false, controlEnabled!: Bool = true, controlLevel!: Int64 = 0,
        controlRowKey!: String = "", controlParentKey!: String = "") {
        this.key = key
        this.elementKey = elementKey
        this.role = role
        this.nodeId = nodeId
        this.semanticId = semanticId
        this.kindToken = kindToken
        this.fieldId = fieldId
        this.actionName = actionName
        this.label = label
        this.visible = visible
        this.bounds = bounds
        this.imageResourceId = imageResourceId
        this.imageResourceVersion = imageResourceVersion
        this.imageResourceState = imageResourceState
        this.effectGroupToken = effectGroupToken
        this.controlRole = controlRole
        this.controlSelected = controlSelected
        this.controlExpandable = controlExpandable
        this.controlExpanded = controlExpanded
        this.controlEnabled = controlEnabled
        this.controlLevel = controlLevel
        this.controlRowKey = controlRowKey
        this.controlParentKey = controlParentKey
    }
}

/// The presentation token of one accepted node kind. A client uses it to decide
/// whether an accepted instance is an editor, a button or a container without
/// interpreting a private numeric enum.
public func cjguiGeneratedUiKindToken(nodeKind: Int64): String {
    if (nodeKind == CJGUI_COMPOSABLE_UI_VERTICAL) {
        return "vertical"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_HORIZONTAL) {
        return "horizontal"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_TEXT) {
        return "label"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_BUTTON) {
        return "action"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_TEXT_INPUT) {
        return "textInput"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_INTEGER_INPUT) {
        return "integerInput"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_BOOLEAN_INPUT) {
        return "booleanInput"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_SCROLL_AREA) {
        return "scrollArea"
    }
    if (nodeKind == CJGUI_COMPOSABLE_UI_IMAGE) {
        return "image"
    }
    return "unknown"
}

public func cjguiGeneratedUiControlRoleToken(role: Int64): String {
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_TAB_GROUP) { return "tab_group" }
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_TAB) { return "tab" }
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_SCROLL_AREA) { return "scroll_area" }
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_TREE) { return "outline" }
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_TREE_ROW) { return "row" }
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_BUTTON) { return "button" }
    if (role == CJGUI_COMPOSABLE_UI_SEMANTIC_CHECKBOX) { return "checkbox" }
    return "none"
}

/// Every accepted generated instance of one window, addressed by its declared
/// key. `visible` is the accepted clipped intersection with area on an enabled
/// node: a projection of the accepted layout, never a claim about GPU
/// presentation.
public func cjguiGeneratedUiAcceptedInstances(window: CjguiComposableUiWindow, holder: CjguiGeneratedUiStructureHolder): ArrayList<CjguiGeneratedUiAcceptedInstance> {
    let result = ArrayList<CjguiGeneratedUiAcceptedInstance>()
    for (node in window.acceptedSceneNodes()) {
        let key = holder.keyForNodeId(node.nodeId)
        if (key.size == 0) {
            continue
        }
        var elementKey = ""
        var role = ""
        if (let Some(element) <- holder.compositeElementForNodeId(node.nodeId)) {
            elementKey = element.elementKey
            role = element.role
        }
        let publicActionName = if (node.actionName == "GENERATED_ACTION" && elementKey.size == 0) {
            holder.actionNameForKey(key)
        } else {
            node.actionName
        }
        let visible = node.bounds.width > 0 && node.bounds.height > 0 &&
            node.clip.width > 0 && node.clip.height > 0
        result.add(
            CjguiGeneratedUiAcceptedInstance(key, elementKey, role, node.nodeId, node.semanticId,
                cjguiGeneratedUiKindToken(node.nodeKind), node.fieldId, publicActionName, node.label, visible,
                node.bounds, imageResourceId: node.imageResourceId, imageResourceVersion: node.imageResourceVersion,
                imageResourceState: holder.imageResourceState(node.imageResourceId, node.imageResourceVersion),
                effectGroupToken: if (let Some(group) <- node.style.effectGroup) {
                    cjguiComposableUiEffectGroupToken(group)
                } else {
                    "none"
                }, controlRole: cjguiGeneratedUiControlRoleToken(node.semanticRole),
                controlSelected: node.semanticSelected, controlExpandable: node.semanticExpandable,
                controlExpanded: node.semanticExpanded, controlEnabled: node.isEnabled,
                controlLevel: node.semanticLevel, controlRowKey: node.semanticKey,
                controlParentKey: node.semanticParentKey))
    }
    return result
}

/// Hard decode ceilings. They are looser than every catalog default the framework
/// installs, so a legal candidate is never rejected here, and they are enforced
/// before any container grows: a short number in the candidate text can no longer
/// drive an allocation, and a rejected candidate leaves the accepted structure
/// untouched because `decode` returns no partial root.
public let CJGUI_GENERATED_UI_DECODE_MAX_DEPTH: Int64 = 32
public let CJGUI_GENERATED_UI_DECODE_MAX_NODES: Int64 = 4096
public let CJGUI_GENERATED_UI_DECODE_MAX_PROPERTIES_PER_NODE: Int64 = 32
public let CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH: Int64 = 4096
public let CJGUI_GENERATED_UI_DECODE_MAX_BYTES: Int64 = 262144

/// Strict bounded decimal parse for a decode depth: digits only (no sign, no
/// whitespace), and overflow-safe - a value above `limit` is rejected instead of
/// wrapping into a small number that would pass a later bound check.
private func parseDecodeDepthStrict(value: String, limit: Int64): ?Int64 {
    if (value.size == 0) {
        return None
    }
    var result: Int64 = 0
    for (byte in value.toArray()) {
        if (byte < 48 || byte > 57) {
            return None
        }
        let digit = Int64(byte - 48)
        if (result > (limit - digit) / 10) {
            return None
        }
        result = result * 10 + digit
    }
    if (result > limit) {
        return None
    }
    return Some(result)
}

/// Replaceable line-based encoding for capability descriptions, accepted
/// structures and candidates. The value model above is the core contract; a
/// JSON or S-expression adapter may replace this text format without changing
/// validation, expansion or state-continuation behavior.
public class CjguiGeneratedUiEncoding {
    /// The style-DEFINITION section a client re-reads after a `STYLES` change.
    /// It is the same directory text `describe` publishes, so an application
    /// keeps ONE definition and ONE encoder instead of a second style table.
    public static func stylesPayload(catalog: CjguiGeneratedUiCapabilityCatalog): String {
        // The revision line is ALWAYS present: a legally EMPTY directory is then
        // distinguishable from a missing/truncated section, and a client can see
        // that the directory it re-read is the one the change reported.
        return "STYLE_REVISION ${catalog.namedStyles().revision()}\n" + catalog.namedStyles().describe()
    }

    public static func describe(catalog: CjguiGeneratedUiCapabilityCatalog): String {
        let builder = StringBuilder()
        builder.append("GENERATED_UI 1\n")
        builder.append("STYLE_REVISION ${catalog.namedStyles().revision()}\n")
        builder.append(catalog.namedStyles().describe())
        builder.append(
            "BOUNDS ${catalog.maxDepth} ${catalog.maxNodes} ${catalog.maxPropertiesPerNode} " +
                "${catalog.maxStringLength}\n")
        builder.append("SEMANTIC_PROPERTY semanticRole outline:scrollArea,row:action " +
            "semanticLabel semanticSelected semanticExpandable semanticExpanded semanticLevel " +
            "semanticRowKey semanticParentKey disabled stability=experimental\n")
        builder.append("PLATFORM_ACCENT ${CJGUI_COMPOSABLE_UI_PLATFORM_SYSTEM_ACCENT_COLOR} " +
            "scope=window source=system,fixed color=srgb8 status=PLATFORM " +
            "support=macos_appkit,ohos_unverified stability=experimental\n")
        builder.append(catalog.motionRuleRegistry().describe())
        if (catalog.windowBackgroundEnabled()) {
            // This property belongs to the structure root, not to a component
            // presentation. Its grammar and support labels come from the same
            // public policy contract that the validator consumes.
            builder.append("WINDOW_BACKGROUND_PROPERTY windowBackground STRING root_only=1 " +
                "encoding=${CjguiGeneratedUiEncoding.windowBackgroundEncoding()} " +
                "default=${CjguiWindowBackgroundPolicy.OPAQUE} omitted=${CjguiWindowBackgroundPolicy.OPAQUE} " +
                "stability=${CjguiWindowBackgroundPolicy.STABILITY} " +
                "support=${CjguiWindowBackgroundPolicy.BACKEND_SUPPORT}\n")
        }
        for (kind in catalog.componentKinds()) {
            if (let Some(spec) <- catalog.componentFor(kind)) {
                builder.append(
                    "COMPONENT ${spec.kind} ${if (spec.allowsChildren) { 1 } else { 0 }} " + "${spec.childLimit}\n")
                for (property in spec.properties) {
                    // The optional trailing tokens publish an enumerated value
                    // list and the effective default, so an external reader never
                    // has to guess either.
                    let extras = StringBuilder()
                    if (property.values.size > 0) {
                        extras.append(" values=")
                        var valueIndex: Int64 = 0
                        while (valueIndex < property.values.size) {
                            if (valueIndex > 0) {
                                extras.append(",")
                            }
                            extras.append(property.values[valueIndex])
                            valueIndex += 1
                        }
                    }
                    if (property.defaultValue.size > 0) {
                        extras.append(" default=${property.defaultValue}")
                    }
                    // Structured-value discovery: grammar, unit, domain, the
                    // `none`/omitted meaning, the stability marker and the
                    // backend support surface. A client that only reads this
                    // line can still assemble a legal value, and the tokens come
                    // from the same constants acceptance uses.
                    if (property.encoding.size > 0) {
                        extras.append(" encoding=${property.encoding}")
                    }
                    if (property.unit.size > 0) {
                        extras.append(" unit=${property.unit}")
                    }
                    if (property.valueRange.size > 0) {
                        extras.append(" range=${property.valueRange}")
                    }
                    if (property.semantics.size > 0) {
                        extras.append(" semantics=${property.semantics}")
                    }
                    if (property.stability.size > 0) {
                        extras.append(" stability=${property.stability}")
                    }
                    if (property.backendSupport.size > 0) {
                        extras.append(" support=${property.backendSupport}")
                    }
                    builder.append(
                        "PROPERTY ${spec.kind} ${property.name} ${property.valueType} " +
                            "${if (property.required) { 1 } else { 0 }} ${property.minimum} ${property.maximum} " +
                            "${property.maxLength}${extras.toString()}\n")
                }
            }
        }
        // Application composites are published as their own declaration, beside
        // the derived COMPONENT line: which elements exist, what each element
        // binds (field and the writer's ARGUMENT name), what a preset writes, and
        // which action/label it carries. An external caller can therefore compose
        // an instance of the kind without reading the application source. The
        // element label is the LAST token (labels may contain spaces); every
        // other field is a single token, `none` when unset.
        for (kind in catalog.compositeKinds()) {
            if (let Some(composite) <- catalog.compositeFor(kind)) {
                builder.append(
                    "COMPOSITE ${composite.kind} " + "children=${if (composite.allowsChildren) { 1 } else { 0 }} " +
                        "child_limit=${composite.childLimit} " + "expanded_nodes=${composite.expandedNodeLimit} " +
                        "expanded_depth=${composite.expandedDepthLimit}\n")
                for (element in composite.elements) {
                    builder.append(
                        "ELEMENT ${composite.kind} ${element.elementKey} ${element.role} " +
                            "parent=${if (element.parentKey.size > 0) { element.parentKey } else { "root" }} " +
                            "field=${if (element.fieldId.size > 0) { element.fieldId } else { "none" }} " +
                            "argument=${if (element.argumentName.size > 0) { element.argumentName } else { "none" }} " +
                            "preset=${if (element.presetValue.size > 0) { element.presetValue } else { "none" }} " +
                            "action=${if (element.actionName.size > 0) { element.actionName } else { "none" }} " +
                            "label=${element.label}\n")
                }
            }
        }
        for (name in catalog.actionNames()) {
            if (let Some(spec) <- catalog.actionFor(name)) {
                // The action's declared ARGUMENT names come before its label,
                // which stays last because it may contain spaces.
                var argumentNames = ""
                var argumentIndex: Int64 = 0
                while (argumentIndex < spec.parameterNames.size) {
                    if (argumentIndex > 0) {
                        argumentNames += ","
                    }
                    argumentNames += spec.parameterNames[argumentIndex]
                    argumentIndex += 1
                }
                builder.append(
                    "ACTION ${spec.name} " + "argument=${if (argumentNames.size > 0) { argumentNames } else { "none" }} " +
                        "${spec.label}\n")
            }
        }
        // One line per declared field, carrying everything an external caller
        // needs to use it: the business type (editor kind), the generated input
        // kind that presents it, the shared resource it binds, the declared
        // constraints, the owner operation that performs a write and the ARGUMENT
        // name that operation takes, and whether that write is currently callable.
        // The first two tokens stay `FIELD <id>` so existing readers keep working;
        // the added tokens replace nothing, and the human label is last because it
        // may contain spaces.
        for (fieldId in catalog.fieldIds()) {
            if (let Some(field) <- catalog.fieldFor(fieldId)) {
                builder.append(
                    "FIELD ${field.fieldId} ${field.editorKind} resource=${field.resourceId} " +
                        "writer=${if (field.writeActionName.size > 0) { field.writeActionName } else { "none" }} " +
                        "required=${if (field.required) { 1 } else { 0 }} " +
                        "min=${field.minimum} max=${field.maximum} " + "maxlen=${field.maximumLength} " +
                        "callable=${if (field.isWritable()) { 1 } else { 0 }} " +
                        "argument=${if (field.argumentName.size > 0) { field.argumentName } else { "none" }} " +
                        "input=${field.inputKind()} label=${field.label}\n")
            } else {
                builder.append(
                    "FIELD ${fieldId} unknown writer=none required=0 min=0 max=0 maxlen=0 " +
                        "callable=0 argument=none input= label=\n")
            }
        }
        // One line per registered image resource, published from the SAME table
        // the generated builder resolves against. The human name is last because
        // it may contain spaces.
        for (spec in catalog.imageResourceSpecs()) {
            // Discovery publishes the logical identity, type, version and human
            // name. The application's resolved raster path stays IN the
            // application: an external caller references the key, never a path.
            builder.append("IMAGE_RESOURCE ${spec.key} ${spec.contentType} ${spec.version} ${spec.name}\n")
        }
        builder.append("END")
        return builder.toString()
    }

    private static func windowBackgroundEncoding(): String {
        return "${CjguiWindowBackgroundPolicy.OPAQUE}|${CjguiWindowBackgroundPolicy.SYSTEM_CONTENT_AREA}"
    }

    /// Line protocol for accepted generated instances. One `INSTANCE` line per
    /// accepted node, addressed by its DECLARED key; `element`/`role` identify a
    /// composite element, `effectGroup` is the canonical accepted declaration,
    /// and the label is the LAST token because a caption may contain spaces.
    /// This does not assert completed renderer presentation.
    public static func acceptedInstancesPayload(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): String {
        let builder = StringBuilder()
        var index: Int64 = 0
        while (index < instances.size) {
            let instance = instances[index]
            if (index > 0) {
                builder.append("\n")
            }
            builder.append(
                "INSTANCE ${instance.key} " +
                    "element=${if (instance.elementKey.size > 0) { instance.elementKey } else { "-" }} " +
                    "role=${if (instance.role.size > 0) { instance.role } else { "-" }} " +
                    "id=${instance.nodeId} kind=${instance.kindToken} semantic=${instance.semanticId} " +
                    "field=${if (instance.fieldId.size > 0) { instance.fieldId } else { "-" }} " +
                    "action=${if (instance.actionName.size > 0) { instance.actionName } else { "-" }} " +
                    "resource=${if (instance.imageResourceId.size > 0) { instance.imageResourceId } else { "-" }} " +
                    "resource_version=${instance.imageResourceVersion} " +
                    "resource_state=${if (instance.imageResourceId.size > 0) { instance.imageResourceState } else { "-" }} " +
                    "effectGroup=${instance.effectGroupToken} " +
                    "control_role=${instance.controlRole} selected=${if (instance.controlSelected) { 1 } else { 0 }} " +
                    "expandable=${if (instance.controlExpandable) { 1 } else { 0 }} " +
                    "expanded=${if (instance.controlExpanded) { 1 } else { 0 }} " +
                    "enabled=${if (instance.controlEnabled) { 1 } else { 0 }} level=${instance.controlLevel} " +
                    "row_key=${if (instance.controlRowKey.size > 0) { instance.controlRowKey } else { "-" }} " +
                    "parent_key=${if (instance.controlParentKey.size > 0) { instance.controlParentKey } else { "-" }} " +
                    "visible=${if (instance.visible) { 1 } else { 0 }} " +
                    "bounds=${instance.bounds.x},${instance.bounds.y}," +
                    "${instance.bounds.width},${instance.bounds.height} " +
                    "label_hex=${if (instance.label.size > 0) { cjguiGeneratedUiHexEncode(instance.label) } else { "-" }}")
            index += 1
        }
        return builder.toString()
    }

    /// The transport rejects an EMPTY field on ANY one-line protocol response
    /// (`client.parse_response` -> "response field is malformed"), so an empty
    /// property value can never be written as a trailing space. The structure
    /// protocol therefore gives the empty string an explicit, non-empty token
    /// (`\e`) and - to stay reversible - doubles the leading backslash of any
    /// value that already begins with one. Decoding strips the escape. This keeps
    /// `none`, the empty string and an ABSENT property three distinguishable
    /// states: `none`, `""` (encoded as `\e`) and no property line at all.
    private static let CJGUI_GENERATED_UI_EMPTY_VALUE_TOKEN: String = "\\e"

    /// Encode one property value for the accepted-structure payload. Empty is
    /// the only value that cannot ride the protocol literally; a value that
    /// already starts with a backslash is escaped so the mapping is lossless.
    public static func encodePropertyValue(value: String): String {
        if (value.size == 0) {
            return CJGUI_GENERATED_UI_EMPTY_VALUE_TOKEN
        }
        if (value[0] == 92) {
            return "\\" + value
        }
        return value
    }

    /// Inverse of `encodePropertyValue`. An empty token (a legacy trailing space
    /// that older clients still submit) is read as the empty string too, so the
    /// pair stays backward compatible.
    public static func decodePropertyValue(token: String): String {
        if (token == CJGUI_GENERATED_UI_EMPTY_VALUE_TOKEN) {
            return ""
        }
        if (token.size > 0 && token[0] == 92) {
            return token[1..token.size]
        }
        return token
    }

    public static func encode(structure: ?CjguiGeneratedUiNodeSpec, version: Int64): String {
        let builder = StringBuilder()
        builder.append("STRUCTURE ${version}\n")
        if (let Some(root) <- structure) {
            encodeNode(root, 0, builder)
        }
        builder.append("END")
        return builder.toString()
    }

    private static func encodeNode(node: CjguiGeneratedUiNodeSpec, depth: Int64, builder: StringBuilder): Unit {
        builder.append("NODE ${depth} ${node.key} ${node.kind}")
        if (node.fieldId.size > 0) {
            builder.append(" field=${node.fieldId}")
        }
        if (node.actionName.size > 0) {
            builder.append(" action=${node.actionName}")
        }
        builder.append("\n")
        for ((name, value) in node.properties) {
            builder.append("PROPERTY ${depth} ${node.key} ${name} ${encodePropertyValue(value)}\n")
        }
        for (child in node.children) {
            encodeNode(child, depth + 1, builder)
        }
    }

    /// Strict, bounded parse of one candidate structure.
    ///
    /// EVERY budget is checked BEFORE its container grows, so a short number in
    /// the text can never drive a large allocation, and a depth is a real
    /// non-negative decimal bounded by the decode ceiling rather than a
    /// parse-as-zero or a silently wrapped value. The line stream must be fully
    /// consumed: a missing `END`, non-empty content after `END`, a skipped depth
    /// level (a node whose parent level has no node), a property targeting a
    /// different node, a repeated property name and an unknown line are
    /// rejections, not silently ignored input. A rejected candidate never yields
    /// a partial root, so callers cannot accidentally submit half a structure.
    public static func decode(candidate: String): CjguiGeneratedUiDecoded {
        if (candidate.size > CJGUI_GENERATED_UI_DECODE_MAX_BYTES) {
            return CjguiGeneratedUiDecoded(false, "candidate_too_large", None)
        }
        let lines = candidate.split("\n")
        if (lines.size < 2 || lines[0] != "GENERATED_UI_STRUCTURE 1") {
            return CjguiGeneratedUiDecoded(false, "invalid_header", None)
        }
        // Pending nodes per depth keep parent/child relationships without a
        // second pass; the root is the depth-0 node. `seenProperties` is the
        // parallel per-node property-name set, so a repeated name is rejected and
        // the per-node count is enforced before the map grows.
        let stack = ArrayList<ArrayList<CjguiGeneratedUiNodeSpec>>()
        let seenProperties = ArrayList<ArrayList<HashSet<String>>>()
        var root: ?CjguiGeneratedUiNodeSpec = None
        var nodeCount: Int64 = 0
        var endSeen = false
        var index: Int64 = 1
        while (index < lines.size) {
            let line = lines[index]
            if (line.size == 0) {
                index += 1
                continue
            }
            if (endSeen) {
                return CjguiGeneratedUiDecoded(false, "trailing_content:${index}", None)
            }
            if (line == "END") {
                endSeen = true
                index += 1
                continue
            }
            let fields = line.split(" ")
            if (fields[0] == "NODE") {
                if (fields.size < 4) {
                    return CjguiGeneratedUiDecoded(false, "malformed_node:${index}", None)
                }
                // NODE <depth> <key> <kind> field=<id> action=<name>
                let depth = match (parseDecodeDepthStrict(fields[1], 1000000)) {
                    case Some(value) => value
                    case None => -1
                }
                if (depth < 0) {
                    return CjguiGeneratedUiDecoded(false, "malformed_node_depth:${index}", None)
                }
                if (depth > CJGUI_GENERATED_UI_DECODE_MAX_DEPTH) {
                    return CjguiGeneratedUiDecoded(false, "depth_budget_exceeded:${index}", None)
                }
                let key = fields[2]
                let kind = fields[3]
                if (key.size > CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH || kind.size >
                    CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH) {
                    return CjguiGeneratedUiDecoded(false, "node_text_too_long:${index}", None)
                }
                nodeCount += 1
                if (nodeCount > CJGUI_GENERATED_UI_DECODE_MAX_NODES) {
                    return CjguiGeneratedUiDecoded(false, "node_budget_exceeded:${index}", None)
                }
                var fieldId = ""
                var actionName = ""
                var fieldSeen = false
                var actionSeen = false
                var tokenIndex: Int64 = 4
                while (tokenIndex < fields.size) {
                    let token = fields[tokenIndex]
                    if (token.startsWith("field=")) {
                        // A repeated or empty binding token is a malformed
                        // description: silently taking the last one would hide
                        // which field the author really meant.
                        if (fieldSeen) {
                            return CjguiGeneratedUiDecoded(false, "duplicate_node_field:${index}", None)
                        }
                        fieldSeen = true
                        fieldId = token[6..token.size]
                        if (fieldId.size == 0) {
                            return CjguiGeneratedUiDecoded(false, "empty_node_field:${index}", None)
                        }
                    } else if (token.startsWith("action=")) {
                        if (actionSeen) {
                            return CjguiGeneratedUiDecoded(false, "duplicate_node_action:${index}", None)
                        }
                        actionSeen = true
                        actionName = token[7..token.size]
                        if (actionName.size == 0) {
                            return CjguiGeneratedUiDecoded(false, "empty_node_action:${index}", None)
                        }
                    } else {
                        // An unknown extra token is not a comment: dropping it
                        // would accept a description the framework never defined.
                        return CjguiGeneratedUiDecoded(false, "unknown_node_token:${index}", None)
                    }
                    tokenIndex += 1
                }
                let node = CjguiGeneratedUiNodeSpec(key, kind, fieldId: fieldId, actionName: actionName)
                // Return to this depth's own level: deeper levels belong to a
                // sibling branch that is now closed, so a later PROPERTY at that
                // depth can never attach to a stale node.
                while (stack.size > depth + 1) {
                    let _ = stack.remove(at: stack.size - 1)
                    let _ = seenProperties.remove(at: seenProperties.size - 1)
                }
                while (stack.size <= depth) {
                    stack.add(ArrayList<CjguiGeneratedUiNodeSpec>())
                    seenProperties.add(ArrayList<HashSet<String>>())
                }
                if (depth > 0) {
                    if (stack[depth - 1].size == 0) {
                        return CjguiGeneratedUiDecoded(false, "orphan_node:${index}", None)
                    }
                    stack[depth - 1][stack[depth - 1].size - 1].children.add(node)
                } else if (root.isSome()) {
                    return CjguiGeneratedUiDecoded(false, "multiple_roots:${index}", None)
                } else {
                    root = Some(node)
                }
                stack[depth].add(node)
                seenProperties[depth].add(HashSet<String>())
            } else if (fields[0] == "PROPERTY") {
                if (fields.size < 5) {
                    return CjguiGeneratedUiDecoded(false, "malformed_property:${index}", None)
                }
                let depth = match (parseDecodeDepthStrict(fields[1], 1000000)) {
                    case Some(value) => value
                    case None => -1
                }
                if (depth < 0) {
                    return CjguiGeneratedUiDecoded(false, "malformed_property_depth:${index}", None)
                }
                if (depth > CJGUI_GENERATED_UI_DECODE_MAX_DEPTH) {
                    return CjguiGeneratedUiDecoded(false, "depth_budget_exceeded:${index}", None)
                }
                let key = fields[2]
                let name = fields[3]
                if (name.size > CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH || name.size == 0) {
                    return CjguiGeneratedUiDecoded(false, "malformed_property_name:${index}", None)
                }
                if (depth >= stack.size || stack[depth].size == 0) {
                    return CjguiGeneratedUiDecoded(false, "orphan_property:${index}", None)
                }
                let targetIndex = stack[depth].size - 1
                let target = stack[depth][targetIndex]
                if (target.key != key) {
                    return CjguiGeneratedUiDecoded(false, "property_key_mismatch:${index}", None)
                }
                let names = seenProperties[depth][targetIndex]
                if (names.contains(name)) {
                    return CjguiGeneratedUiDecoded(false, "duplicate_property:${index}", None)
                }
                if (names.size >= CJGUI_GENERATED_UI_DECODE_MAX_PROPERTIES_PER_NODE) {
                    return CjguiGeneratedUiDecoded(false, "property_budget_exceeded:${index}", None)
                }
                // Values may contain spaces: take everything after the fourth
                // space (PROPERTY depth key name value...).
                var spacesSeen = 0
                var scan: Int64 = 0
                var rawValue = ""
                while (scan < line.size) {
                    if (line[scan] == 32) {
                        spacesSeen += 1
                        if (spacesSeen == 4) {
                            rawValue = line[scan + 1..line.size]
                            break
                        }
                    }
                    scan += 1
                }
                // The empty string rides the one-line protocol as an explicit
                // token (the transport rejects an empty field) and a leading
                // backslash is escaped, so `\e` decodes back to "". A value that
                // would still begin or end with a space cannot be framed
                // unambiguously, so it is refused instead of silently trimmed.
                let value = CjguiGeneratedUiEncoding.decodePropertyValue(rawValue)
                if (value.size > 0 && (value[0] == 32 || value[value.size - 1] == 32)) {
                    return CjguiGeneratedUiDecoded(false, "property_value_edge_space:${index}", None)
                }
                if (value.size > CJGUI_GENERATED_UI_DECODE_MAX_STRING_LENGTH) {
                    return CjguiGeneratedUiDecoded(false, "string_budget_exceeded:${index}", None)
                }
                names.add(name)
                target.properties.add(name, value)
            } else {
                return CjguiGeneratedUiDecoded(false, "unknown_line:${index}", None)
            }
            index += 1
        }
        if (!endSeen) {
            return CjguiGeneratedUiDecoded(false, "missing_end", None)
        }
        return CjguiGeneratedUiDecoded(true, "", root)
    }
}

// --- observation seam (package B3/B4) --------------------------------------
// A single atomic generated-UI snapshot and a lightweight change cursor. The
// versions below are the tracker's INTERNAL comparison sources; an external
// reader only ever passes `stream_epoch + cursor`, so "the draft changed while
// the structure stayed the same" and "the scene was resized" both produce a
// cursor instead of being invisible behind one structure version.

/// One observed change, at the cursor position where it was noticed.
public class CjguiGeneratedUiObservationChange {
    public let cursor: Int64
    public let category: String
    public let detail: String

    init(cursor: Int64, category: String, detail: String) {
        this.cursor = cursor
        this.category = category
        this.detail = detail
    }
}

/// Everything a generated-UI reader can observe, sampled at ONE moment by the
/// application that owns the state. It is deliberately a plain value: building
/// it must not build, layout or submit anything.
public class CjguiGeneratedUiObservationSource {
    /// Endpoint/window session identity. A change means a DIFFERENT endpoint:
    /// the tracker starts a new stream epoch and drops the old history.
    public let endpointIdentity: String
    /// Owner business revision (applied writes).
    public let ownerRevision: Int64
    /// Owner draft revision (draft-only edits).
    public let draftRevision: Int64
    /// Key -> owner binding revision (a rekeyed/rebound element changes this
    /// while the structure version may not move).
    public let bindingRevision: Int64
    public let acceptedStructureVersion: Int64
    public let candidateToken: Int64
    public let candidateState: String
    public let acceptedSceneVersion: Int64
    public let geometryRevision: Int64
    public let interactionRevision: Int64
    public let instanceRevision: Int64
    /// The OWNER projection (fields/draft/binding/instances) differs from the
    /// projection the accepted scene was built from: a business write has been
    /// accepted by the owner but the window has not shown it yet. It is NOT the
    /// structure candidate's state.
    public let ownerPendingScene: Bool
    /// A STRUCTURE candidate is received and waiting for the scene transaction.
    /// It is a separate fact from owner progress: a normal field write never
    /// makes a structure candidate pending, and a pending structure candidate
    /// never pretends a field change is shown.
    public let structureCandidatePending: Bool
    /// Fingerprint of the application's registered image declarations. A change
    /// means an external reference may have been withdrawn or replaced.
    public let resourceRevision: Int64
    /// Revision of the application's named-style directory. It is its OWN
    /// category: a style-directory change must reach a client without moving the
    /// business or structure version, so a client knows to re-read the style
    /// definitions while the accepted structure stays exactly what it was.
    public let styleRevision: Int64
    /// Fingerprint of the sampled preparation states of the ACCEPTED image
    /// bindings. A completion or a failure moves it, so image readiness is
    /// observable without an external structure resubmission.
    public let imageStateRevision: Int64
    /// Bounded scalar facts describing actual accepted effect presentation.
    /// This is sampled from window progress, not inferred from declarations.
    public let effectFacts: String
    public let platformFacts: String

    public init(endpointIdentity: String, ownerRevision: Int64, draftRevision: Int64, bindingRevision: Int64,
        acceptedStructureVersion: Int64, candidateToken: Int64, candidateState: String, acceptedSceneVersion: Int64,
        geometryRevision: Int64, interactionRevision: Int64, instanceRevision: Int64, ownerPendingScene: Bool,
        resourceRevision!: Int64 = 0, structureCandidatePending!: Bool = false, imageStateRevision!: Int64 = 0,
        styleRevision!: Int64 = 0, effectFacts!: String = "", platformFacts!: String = "") {
        this.endpointIdentity = endpointIdentity
        this.ownerRevision = ownerRevision
        this.draftRevision = draftRevision
        this.bindingRevision = bindingRevision
        this.acceptedStructureVersion = acceptedStructureVersion
        this.candidateToken = candidateToken
        this.candidateState = candidateState
        this.acceptedSceneVersion = acceptedSceneVersion
        this.geometryRevision = geometryRevision
        this.interactionRevision = interactionRevision
        this.instanceRevision = instanceRevision
        this.ownerPendingScene = ownerPendingScene
        this.structureCandidatePending = structureCandidatePending
        this.resourceRevision = resourceRevision
        this.styleRevision = styleRevision
        this.imageStateRevision = imageStateRevision
        this.effectFacts = effectFacts
        this.platformFacts = platformFacts
    }

    /// A source for an application that has not attached its window yet.
    public static func unknown(): CjguiGeneratedUiObservationSource {
        return CjguiGeneratedUiObservationSource("", 0, 0, 0, 0, 0, "none", 0, 0, 0, 0, false)
    }
}

/// Bounded, monotonic change cursor over one observation source.
///
/// It owns no application state: the application samples its own state into a
/// `CjguiGeneratedUiObservationSource`, and the tracker turns the difference
/// into a bounded history of categories. The history is bounded, so a cursor
/// older than the floor asks for `RESYNC_REQUIRED` instead of pretending the
/// increment is complete.
public class CjguiGeneratedUiObservationTracker {
    private let historyLimit: Int64
    private var streamEpochValue: Int64
    private var streamIdentityValue: String
    private var cursorValue: Int64
    private var history: ArrayList<CjguiGeneratedUiObservationChange>
    private var historyFloorValue: Int64
    private var lastSource: ?CjguiGeneratedUiObservationSource

    public init(historyLimit!: Int64 = 128) {
        this.historyLimit = if (historyLimit > 0) {
            historyLimit
        } else {
            128
        }
        // The stream epoch identifies ONE endpoint instance. A process-local
        // counter that restarts at a fixed value would let a client that holds
        // an old (epoch, cursor) believe a RESTARTED endpoint is the same
        // stream, so the initial value is a random nonce instead.
        let streamNonce = Int64(Random().nextUInt64() & 0x7FFFFFFFFFFFFFFF)
        this.streamEpochValue = if (streamNonce > 0) {
            streamNonce
        } else {
            1
        }
        this.streamIdentityValue = ""
        this.cursorValue = 0
        this.history = ArrayList<CjguiGeneratedUiObservationChange>()
        this.historyFloorValue = 0
        this.lastSource = None
    }

    public func streamEpoch(): Int64 {
        return streamEpochValue
    }

    public func streamIdentity(): String {
        return streamIdentityValue
    }

    public func currentCursor(): Int64 {
        return cursorValue
    }

    /// Cursors at or below this floor cannot be served incrementally.
    public func historyFloor(): Int64 {
        return historyFloorValue
    }

    /// Samples one source and records the categories that changed since the last
    /// sample. The first sample establishes the baseline and records nothing (the
    /// snapshot that accompanies it is the full state).
    public func observeSource(source: CjguiGeneratedUiObservationSource): Int64 {
        let previous = lastSource
        if (let Some(old) <- previous) {
            if (source.endpointIdentity != old.endpointIdentity) {
                // A different endpoint: its cursor space is not ours.
                streamEpochValue += 1
                streamIdentityValue = source.endpointIdentity
                history.clear()
                historyFloorValue = cursorValue
                lastSource = Some(source)
                return cursorValue
            }
        } else {
            streamIdentityValue = source.endpointIdentity
        }
        if (let Some(old) <- previous) {
            for ((category, detail) in categoriesBetween(old, source)) {
                recordChange(category, detail)
            }
        }
        lastSource = Some(source)
        return cursorValue
    }

    /// Categories implied by a source difference. A structure change also
    /// re-creates instances and the scene; the order is stable so evidence and
    /// test expectations do not depend on map iteration order.
    private func categoriesBetween(old: CjguiGeneratedUiObservationSource, current: CjguiGeneratedUiObservationSource): ArrayList<(String,
        String)> {
        let categories = ArrayList<(String, String)>()
        let structureChanged = current.acceptedStructureVersion != old.acceptedStructureVersion
        if (structureChanged) {
            categories.add(("STRUCTURE", "version=${current.acceptedStructureVersion}"))
        }
        if (current.candidateToken != old.candidateToken || current.candidateState != old.candidateState ||
            current.structureCandidatePending != old.structureCandidatePending) {
            categories.add(
                ("CANDIDATE", "token=${current.candidateToken} state=${current.candidateState} " +
                        "pending=${if (current.structureCandidatePending) { 1 } else { 0 }}"))
        }
        if (current.ownerRevision != old.ownerRevision || current.draftRevision != old.draftRevision) {
            categories.add(("FIELDS", "owner=${current.ownerRevision} draft=${current.draftRevision}"))
        }
        if (current.resourceRevision != old.resourceRevision || current.imageStateRevision != old.imageStateRevision) {
            categories.add(("RESOURCES", "revision=${current.resourceRevision} " + "state=${current.imageStateRevision}"))
        }
        // The named-style directory is reported on its own; it deliberately does
        // NOT imply STRUCTURE/SCENE/FIELDS, so a theme change never looks like a
        // business or structure change.
        if (current.styleRevision != old.styleRevision) {
            categories.add(("STYLES", "revision=${current.styleRevision}"))
        }
        if (current.effectFacts != old.effectFacts) {
            // The bounded change stream carries only the category signal. The
            // potentially multi-line facts are re-read from the guarded section.
            categories.add(("EFFECTS", "changed"))
        }
        if (current.platformFacts != old.platformFacts) {
            categories.add(("PLATFORM", "changed"))
        }
        if (current.bindingRevision != old.bindingRevision) {
            categories.add(("BINDINGS", "revision=${current.bindingRevision}"))
        }
        if (structureChanged || current.instanceRevision != old.instanceRevision) {
            categories.add(("INSTANCES", "revision=${current.instanceRevision}"))
        }
        if (structureChanged || current.acceptedSceneVersion != old.acceptedSceneVersion || current.geometryRevision != old
            .geometryRevision || current.interactionRevision != old.interactionRevision) {
            categories.add(
                ("SCENE", "scene=${current.acceptedSceneVersion} " +
                        "geometry=${current.geometryRevision} interaction=${current.interactionRevision}"))
        }
        return categories
    }

    private func recordChange(category: String, detail: String): Unit {
        cursorValue += 1
        history.add(CjguiGeneratedUiObservationChange(cursorValue, category, detail))
        while (history.size > historyLimit) {
            let expired = history[0]
            let _ = history.remove(at: 0)
            historyFloorValue = expired.cursor
        }
    }

    /// Whether a client at (streamEpoch, cursor) can be served incrementally.
    /// A stream replacement, a truncated history and a cursor from the future all
    /// ask for a fresh snapshot rather than a fabricated increment.
    public func resyncRequired(streamEpoch: Int64, cursor: Int64): Bool {
        return streamEpoch != streamEpochValue || cursor < historyFloorValue || cursor > cursorValue
    }

    /// Bounded `GET_GENERATED_UI_CHANGES` body: no tree, no fields, no geometry.
    public func changesPayload(streamEpoch: Int64, cursor: Int64): String {
        let builder = StringBuilder()
        builder.append("STREAM_EPOCH ${streamEpochValue}\n")
        builder.append("STREAM_IDENTITY ${if (streamIdentityValue.size > 0) { streamIdentityValue } else { "none" }}\n")
        builder.append("SINCE ${cursor}\n")
        builder.append("CURRENT ${cursorValue}\n")
        let resync = resyncRequired(streamEpoch, cursor)
        builder.append("RESYNC_REQUIRED ${if (resync) { 1 } else { 0 }}\n")
        if (!resync) {
            for (change in history) {
                if (change.cursor > cursor) {
                    builder.append("CHANGE ${change.cursor} ${change.category} ${change.detail}\n")
                }
            }
        }
        builder.append("END")
        return builder.toString()
    }
}

/// Prefixes every non-empty line of a section payload with one marker, so one
/// response can carry the fields, the accepted structure and the accepted
/// instances of a SINGLE provider call without a second framing layer. Each line
/// stays self-describing and the client can slice the response with a prefix.
private func snapshotSection(marker: String, payload: String): String {
    if (payload.size == 0) {
        return ""
    }
    let builder = StringBuilder()
    var first = true
    for (line in payload.split("\n")) {
        if (line.size == 0) {
            continue
        }
        if (!first) {
            builder.append("\n")
        }
        builder.append("${marker} ${line}")
        first = false
    }
    return builder.toString()
}

/// ONE section of the generated-UI snapshot, read at a GUARDED cursor.
///
/// The caller resolves the cursor FIRST and only then serializes the one
/// requested section, so an invalid cursor can never force the work of building
/// three payloads. The response carries its section name and stream identity, so
/// a client can reject a section that belongs to another stream, cursor or type
/// even when the provider did not set the revision flag.
public func cjguiGeneratedUiSectionPayload(tracker: CjguiGeneratedUiObservationTracker, section: String,
    expectedCursor: Int64, payload: String): String {
    let builder = StringBuilder()
    let current = tracker.currentCursor()
    builder.append("SECTION ${section}\n")
    builder.append("STREAM_EPOCH ${tracker.streamEpoch()}\n")
    builder.append(
        "STREAM_IDENTITY ${if (tracker.streamIdentity().size > 0) { tracker.streamIdentity() } else { "none" }}\n")
    builder.append("CURSOR ${current}\n")
    if (current != expectedCursor) {
        builder.append("SNAPSHOT_REVISION_CHANGED 1")
        return builder.toString()
    }
    var marker = ""
    if (section == "FIELDS") {
        marker = "SNAPSHOT_FIELD"
    } else if (section == "STRUCTURE") {
        marker = "SNAPSHOT_STRUCTURE"
    } else if (section == "INSTANCES") {
        marker = "SNAPSHOT_INSTANCE"
    } else if (section == "STYLES") {
        // The style-definition directory is a section of its own: a client that
        // saw a STYLES change re-reads definitions without pulling a tree.
        marker = "SNAPSHOT_STYLE"
    } else if (section == "EFFECTS") {
        // Actual renderer effect mode/reason is a separate, guarded section.
        marker = "SNAPSHOT_EFFECT"
    } else if (section == "PLATFORM") {
        marker = "SNAPSHOT_PLATFORM"
    } else {
        // An unknown section is never answered with another one.
        builder.append("SNAPSHOT_REVISION_CHANGED 1")
        return builder.toString()
    }
    builder.append("SNAPSHOT_REVISION_CHANGED 0\n")
    let encoded = snapshotSection(marker, payload)
    if (encoded.size > 0) {
        builder.append(encoded)
    }
    return builder.toString()
}

/// THE consistent generated-UI snapshot: the cursor/stream identity, the
/// separated owner/scene facts, and the field/structure/instance sections the
/// application sampled in the SAME provider call.
public func cjguiGeneratedUiSnapshotPayload(tracker: CjguiGeneratedUiObservationTracker,
    source: CjguiGeneratedUiObservationSource, fieldsPayload: String, structurePayload: String,
    instancesPayload: String, stylesPayload!: String = ""): String {
    let builder = StringBuilder()
    builder.append("STREAM_EPOCH ${tracker.streamEpoch()}\n")
    builder.append(
        "STREAM_IDENTITY ${if (tracker.streamIdentity().size > 0) { tracker.streamIdentity() } else { "none" }}\n")
    builder.append("CURSOR ${tracker.currentCursor()}\n")
    builder.append("OWNER_FIELD_REVISION ${source.ownerRevision}\n")
    builder.append("OWNER_DRAFT_REVISION ${source.draftRevision}\n")
    builder.append("BINDING_REVISION ${source.bindingRevision}\n")
    builder.append("ACCEPTED_STRUCTURE_VERSION ${source.acceptedStructureVersion}\n")
    builder.append("CANDIDATE_TOKEN ${source.candidateToken}\n")
    builder.append("CANDIDATE_STATE ${if (source.candidateState.size > 0) { source.candidateState } else { "none" }}\n")
    builder.append("WINDOW_ACCEPTED_SCENE_VERSION ${source.acceptedSceneVersion}\n")
    builder.append("WINDOW_GEOMETRY_REVISION ${source.geometryRevision}\n")
    builder.append("WINDOW_INTERACTION_REVISION ${source.interactionRevision}\n")
    builder.append("INSTANCE_REVISION ${source.instanceRevision}\n")
    builder.append("RESOURCE_REVISION ${source.resourceRevision}\n")
    builder.append("STYLE_REVISION ${source.styleRevision}\n")
    builder.append("IMAGE_RESOURCE_STATE_REVISION ${source.imageStateRevision}\n")
    builder.append("OWNER_PENDING_SCENE ${if (source.ownerPendingScene) { 1 } else { 0 }}\n")
    builder.append("STRUCTURE_CANDIDATE_PENDING ${if (source.structureCandidatePending) { 1 } else { 0 }}\n")
    let sections = ArrayList<String>()
    let effectFacts = snapshotSection("SNAPSHOT_EFFECT", source.effectFacts)
    if (effectFacts.size > 0) {
        sections.add(effectFacts)
    }
    let platformFacts = snapshotSection("SNAPSHOT_PLATFORM", source.platformFacts)
    if (platformFacts.size > 0) { sections.add(platformFacts) }
    for ((marker, payload) in [("SNAPSHOT_FIELD", fieldsPayload), ("SNAPSHOT_STRUCTURE", structurePayload),
        ("SNAPSHOT_INSTANCE", instancesPayload), ("SNAPSHOT_STYLE", stylesPayload)]) {
        let encoded = snapshotSection(marker, payload)
        if (encoded.size > 0) {
            sections.add(encoded)
        }
    }
    var index = 0
    while (index < sections.size) {
        builder.append(sections[index])
        builder.append("\n")
        index += 1
    }
    builder.append("END")
    return builder.toString()
}

// --- observation fingerprints ----------------------------------------------
// The tracker compares revisions, so the application needs cheap, stable
// fingerprints of the accepted projection. They are derived from the SAME
// accepted-instance list the external identity read publishes - never from a
// second hand-maintained counter that could drift from the real geometry.

// A bounded 30-bit FNV-1a accumulator. Cangjie integer multiplication throws on
// overflow, and a fingerprint must never take a live application down, so the
// state is masked on every step: 2^30 * 16777619 < 2^54 fits in Int64. This is a
// change detector, not a cryptographic hash.
private let CJGUI_GENERATED_UI_FNV_OFFSET: Int64 = 2166136261
private let CJGUI_GENERATED_UI_FNV_PRIME: Int64 = 16777619
private let CJGUI_GENERATED_UI_FNV_MASK: Int64 = 0x3FFFFFFF

private func fingerprintAccumulate(hash: Int64, value: Int64): Int64 {
    let state = (hash ^ (value & CJGUI_GENERATED_UI_FNV_MASK)) & CJGUI_GENERATED_UI_FNV_MASK
    return (state * CJGUI_GENERATED_UI_FNV_PRIME) & CJGUI_GENERATED_UI_FNV_MASK
}

private func fingerprintMix(value: Int64): Int64 {
    var hash = fingerprintAccumulate(CJGUI_GENERATED_UI_FNV_OFFSET, value)
    var index = 0
    while (index < 8) {
        hash = fingerprintAccumulate(hash, (value >> (index * 8)) & 0xFF)
        index += 1
    }
    return hash
}

private func fingerprintText(text: String): Int64 {
    var hash = CJGUI_GENERATED_UI_FNV_OFFSET
    for (byte in text.toArray()) {
        hash = fingerprintAccumulate(hash, Int64(byte))
    }
    return hash
}

/// Fingerprint of what the window ACCEPTED as the generated geometry: the
/// declared keys with their node identity and bounds. A resize changes it even
/// when the structure version does not.
public func cjguiGeneratedUiGeometryRevision(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): Int64 {
    var hash = CJGUI_GENERATED_UI_FNV_OFFSET & CJGUI_GENERATED_UI_FNV_MASK
    for (instance in instances) {
        hash = fingerprintAccumulate(hash, fingerprintText(instance.key))
        hash = fingerprintAccumulate(hash, fingerprintMix(instance.nodeId))
        hash = fingerprintAccumulate(hash, fingerprintMix(instance.bounds.x))
        hash = fingerprintAccumulate(hash, fingerprintMix(instance.bounds.y))
        hash = fingerprintAccumulate(hash, fingerprintMix(instance.bounds.width))
        hash = fingerprintAccumulate(hash, fingerprintMix(instance.bounds.height))
        hash = fingerprintAccumulate(hash, fingerprintMix(if (instance.visible) {
            1
        } else {
            0
        }))
    }
    return hash
}

/// Fingerprint of the key -> owner bindings, WITHOUT node identity and WITHOUT
/// counting unbound elements: a pure re-layout that adds a label (no field, no
/// action) must not report a rebind, while the same declared key pointing at a
/// different owner field must. The number of BOUND elements is mixed in, so
/// adding or removing a bound element changes the revision too.
public func cjguiGeneratedUiBindingRevision(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): Int64 {
    var hash = CJGUI_GENERATED_UI_FNV_OFFSET
    var bound: Int64 = 0
    for (instance in instances) {
        if (instance.fieldId.size == 0 && instance.actionName.size == 0) {
            continue
        }
        bound += 1
        hash = hash ^ fingerprintText(
            "${instance.key}|${instance.elementKey}|${instance.role}|" + "${instance.fieldId}|${instance.actionName}")
    }
    return hash ^ fingerprintMix(bound)
}

/// Fingerprint of the accepted instance IDENTITY set (which declared keys exist
/// and what node identity each one owns).
public func cjguiGeneratedUiInstanceRevision(instances: ArrayList<CjguiGeneratedUiAcceptedInstance>): Int64 {
    var hash = CJGUI_GENERATED_UI_FNV_OFFSET
    for (instance in instances) {
        hash = hash ^ fingerprintText(instance.key)
        hash = hash ^ fingerprintMix(instance.nodeId)
        hash = hash ^ fingerprintText("${instance.controlRole}|${instance.controlRowKey}|" +
            "${instance.controlParentKey}|${instance.controlSelected}|${instance.controlExpandable}|" +
            "${instance.controlExpanded}|${instance.controlEnabled}|${instance.controlLevel}|${instance.label}")
    }
    return hash
}
