/* Compile with the Windows native and common header directories on -I.
 * Exercises the actual focus helper with an owned Win32 HWND. */
#include "cjgui_windows_renderer.c"
static int failures;
static void check(const char *name, int pass) {
    printf("FOCUS_CASE %s pass=%d\n", name, !!pass);
    if (!pass) ++failures;
}
int main(void) {
    CjguiWindowsRendererSession *s = &g_sessions[0];
    memset(s, 0, sizeof(*s));
    s->token = 9876; s->occupied = 1;
    s->hwnd = CreateWindowExW(0, L"STATIC", L"CJGUI owned focus fixture",
        WS_POPUP | WS_VISIBLE, 24, 24, 100, 80, NULL, NULL, GetModuleHandleW(NULL), NULL);
    check("own_hwnd_created", s->hwnd != NULL);
    CjguiWindowsSceneNode nodes[2] = {0};
    for (int i = 0; i < 2; ++i) {
        nodes[i].hasNode = 1;
        nodes[i].node.nodeId = i ? 23 : 4;
        nodes[i].node.resourceId = i ? 104 : 102;
        nodes[i].node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
        nodes[i].node.isInteractive = 1;
        nodes[i].value = i ? "independent" : "abcde\nFGHIJ\n";
    }
    s->acceptedScene.nodes = nodes; s->acceptedScene.count = 2;
    check("first_focus_establishes_body", focus_composable_node_impl(s->token, 4) == 0 &&
        s->selectionStart16 == 12 && s->selectionEnd16 == 12 && GetFocus() == s->hwnd);
    s->selectionStart16 = s->selectionEnd16 = 2;
    check("registration_preserves_pointer_caret", focus_composable_node_impl(s->token, 4) == 0 &&
        s->selectionStart16 == 2 && s->selectionEnd16 == 2);
    s->selectionStart16 = 2; s->selectionEnd16 = 9;
    check("same_focus_preserves_nonempty_selection", focus_composable_node_impl(s->token, 4) == 0 &&
        s->selectionStart16 == 2 && s->selectionEnd16 == 9);
    nodes[0].node.isReadOnly = 1;
    s->selectionStart16 = 2; s->selectionEnd16 = 9;
    check("readonly_refusal_preserves_selection", focus_composable_node_impl(s->token, 4) ==
        CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED && s->selectionStart16 == 2 && s->selectionEnd16 == 9);
    nodes[0].node.isReadOnly = 0;
    check("other_owner_establishes_new_proxy", focus_composable_node_impl(s->token, 23) == 0 &&
        s->selectionStart16 == 11 && s->selectionEnd16 == 11 &&
        !strcmp((const char *)s->proxyValueUtf8, "independent"));
    check("return_focus_does_not_borrow_other_range", focus_composable_node_impl(s->token, 4) == 0 &&
        s->selectionStart16 == 12 && s->selectionEnd16 == 12);
    s->selectionStart16 = 2; s->selectionEnd16 = 9;
    nodes[0].value = "changed";
    check("changed_body_resets_old_range", focus_composable_node_impl(s->token, 4) == 0 &&
        s->selectionStart16 == 7 && s->selectionEnd16 == 7 &&
        !strcmp((const char *)s->proxyValueUtf8, "changed"));
    s->selectionStart16 = 1; s->selectionEnd16 = 3;
    nodes[0].node.resourceId = 103;
    check("changed_resource_resets_old_range", focus_composable_node_impl(s->token, 4) == 0 &&
        s->selectionStart16 == 7 && s->selectionEnd16 == 7 && s->focusedResourceId == 103);
    s->selectionStart16 = 1; s->selectionEnd16 = 3;
    SetFocus(NULL);
    check("same_proxy_regains_os_focus_without_reset", focus_composable_node_impl(s->token, 4) == 0 &&
        GetFocus() == s->hwnd && s->selectionStart16 == 1 && s->selectionEnd16 == 3);
    DestroyWindow(s->hwnd); free(s->proxyValueUtf8); memset(s, 0, sizeof(*s));
    printf("OBSERVATION_UNIT failures=%d\n", failures);
    return failures ? 1 : 0;
}
