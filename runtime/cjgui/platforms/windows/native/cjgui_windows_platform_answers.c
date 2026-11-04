/* cjgui_windows_platform_answers.c -- Windows answers for the frozen common core's
 * macOS AppKit/Metal/QuartzCore observation surface.
 *
 * The frozen core (sdk-17eec5e0) declares this surface in `foreign` blocks that the
 * macOS bridge implements in cjgui_native_bridge.m. Windows has no AppKit/Metal, so
 * every answer here reports "not applicable / blocked / no token" -- fail closed.
 * None of these answers claims a capability, allocates a token or performs an effect.
 * The functional renderer surface is NOT here: it lives in cjgui_windows_renderer.c
 * and is exercised by the live path.
 *
 * Generated from the core's foreign declarations by gen_platform_answers.py;
 * 237 definitions. Do not hand-edit.
 */
#include <stdint.h>

int32_t cjgui_native_bridge_appkit_class_lookup_no_object_admission(void) {
    return 1;
}
int32_t cjgui_native_bridge_appkit_import_available(void) {
    return 0;
}
int32_t cjgui_native_bridge_appkit_no_object_admission(void) {
    return 1;
}
int32_t cjgui_native_bridge_appkit_nsview_class_available(void) {
    return 0;
}
int32_t cjgui_native_bridge_appkit_nswindow_class_available(void) {
    return 0;
}
int32_t cjgui_native_bridge_appkit_platform_object_background_thread_denied(void) {
    return 1;
}
int32_t cjgui_native_bridge_appkit_platform_object_creation_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_appkit_platform_object_main_thread_admitted(void) {
    return 0;
}
int32_t cjgui_native_bridge_appkit_platform_object_main_thread_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_allocation_device_binding_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_allocation_feasibility_probe(void) {
    return 0;
}
int32_t cjgui_native_bridge_cametallayer_allocation_feasible(void) {
    return 0;
}
int32_t cjgui_native_bridge_cametallayer_allocation_no_attach_admission(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_allocation_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_allocation_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_attach_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_attach_to_nsview(uint64_t layerToken, uint64_t viewToken) {
    (void)layerToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_attachment_classify(uint64_t layerToken, uint64_t viewToken) {
    (void)layerToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_bind_metal_device(uint64_t layerToken, uint64_t deviceToken) {
    (void)layerToken;
    (void)deviceToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_class_available(void) {
    return 0;
}
int32_t cjgui_native_bridge_cametallayer_create(void * outToken) {
    (void)outToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_destroy(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_detach_from_nsview(uint64_t layerToken, uint64_t viewToken) {
    (void)layerToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_device_binding_classify(uint64_t layerToken, uint64_t deviceToken) {
    (void)layerToken;
    (void)deviceToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_device_binding_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_device_binding_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_double_destroy_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_double_detach_classify(uint64_t layerToken, uint64_t viewToken) {
    (void)layerToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_double_unbind_device_classify(uint64_t layerToken, uint64_t deviceToken) {
    (void)layerToken;
    (void)deviceToken;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_no_attach_admission(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_table_allocation_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_cametallayer_table_capacity(void) {
    return 0;
}
int32_t cjgui_native_bridge_cametallayer_table_destroy_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_cametallayer_table_empty(void) {
    return 1;
}
uint32_t cjgui_native_bridge_cametallayer_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_cametallayer_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_cametallayer_table_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_cametallayer_unbind_metal_device(uint64_t layerToken, uint64_t deviceToken) {
    (void)layerToken;
    (void)deviceToken;
    return -1;
}
int32_t cjgui_native_bridge_command_buffer_commit_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_command_buffer_create(uint64_t queueToken, void * outBufferToken) {
    (void)queueToken;
    (void)outBufferToken;
    return -1;
}
int32_t cjgui_native_bridge_command_buffer_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_command_buffer_creation_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_command_buffer_destroy(uint64_t bufferToken) {
    (void)bufferToken;
    return -1;
}
int32_t cjgui_native_bridge_command_buffer_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_command_buffer_double_destroy_classify(uint64_t bufferToken) {
    (void)bufferToken;
    return -1;
}
int32_t cjgui_native_bridge_command_buffer_encoder_creation_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_command_buffer_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_command_buffer_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_command_buffer_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_command_buffer_token_classify(uint64_t bufferToken) {
    (void)bufferToken;
    return -1;
}
int32_t cjgui_native_bridge_command_queue_create(uint64_t deviceToken, void * outQueueToken) {
    (void)deviceToken;
    (void)outQueueToken;
    return -1;
}
int32_t cjgui_native_bridge_command_queue_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_command_queue_destroy(uint64_t queueToken) {
    (void)queueToken;
    return -1;
}
int32_t cjgui_native_bridge_command_queue_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_command_queue_double_destroy_classify(uint64_t queueToken) {
    (void)queueToken;
    return -1;
}
uint32_t cjgui_native_bridge_command_queue_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_command_queue_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_command_queue_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_command_queue_token_classify(uint64_t queueToken) {
    (void)queueToken;
    return -1;
}
int32_t cjgui_native_bridge_destroy_not_supported(void) {
    return 0;
}
int32_t cjgui_native_bridge_double_destroy_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_draw_call_encoder_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_draw_call_pipeline_binding_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_draw_call_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_draw_call_vertex_binding_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_is_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_metal_default_device_available(void) {
    return 0;
}
int32_t cjgui_native_bridge_metal_default_device_create(void * outToken) {
    (void)outToken;
    return -1;
}
int32_t cjgui_native_bridge_metal_device_command_queue_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_metal_device_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_metal_device_creation_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_metal_device_destroy(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_metal_device_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_metal_device_double_destroy_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_metal_device_no_command_queue_admission(void) {
    return 1;
}
uint32_t cjgui_native_bridge_metal_device_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_metal_device_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_metal_device_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_metal_device_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_metal_import_available(void) {
    return 0;
}
uint32_t cjgui_native_bridge_no_resource_admission(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_activation_deferred(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_activation_policy_deferred(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_auto_close_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_bounded_run_loop_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_creation_deferred(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_drawable_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_event_loop_deferred(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_headless_fail_closed(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_main_thread_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_ownership_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_render_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_guard_visible_order_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_activation_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_activation_policy_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_auto_close_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_bounded_run_loop_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_drawable_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_event_loop_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_headless_fail_closed(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_main_thread_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_non_user_visible_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_render_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_singleton_creation_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_teardown_before_visible_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsapplication_shared_application_guard_visible_order_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsview_create(void * outToken) {
    (void)outToken;
    return -1;
}
int32_t cjgui_native_bridge_nsview_destroy(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_nsview_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_nsview_double_destroy_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_nsview_table_allocation_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_nsview_table_capacity(void) {
    return 0;
}
int32_t cjgui_native_bridge_nsview_table_destroy_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nsview_table_empty(void) {
    return 1;
}
uint32_t cjgui_native_bridge_nsview_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_nsview_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_nsview_table_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_nsview_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_attach(uint64_t windowToken, uint64_t viewToken) {
    (void)windowToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(uint64_t windowToken, uint64_t viewToken) {
    (void)windowToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_detach(uint64_t windowToken, uint64_t viewToken) {
    (void)windowToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify(uint64_t windowToken, uint64_t viewToken) {
    (void)windowToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify(uint64_t windowToken, uint64_t viewToken) {
    (void)windowToken;
    (void)viewToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_harness_create(void * outWindowToken) {
    (void)outWindowToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_destroy(uint64_t windowToken) {
    (void)windowToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_double_destroy_classify(uint64_t windowToken) {
    (void)windowToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_harness_present_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_nswindow_harness_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_nswindow_harness_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_nswindow_harness_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_nswindow_harness_token_classify(uint64_t windowToken) {
    (void)windowToken;
    return -1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_activation_deferred(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_application_creation_deferred(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_application_ownership_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_auto_close_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_bounded_run_loop_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_content_view_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_drawable_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_headless_fail_closed(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_render_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_nswindow_visible_order_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_blending_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_configure_no_draw(uint64_t descriptorToken) {
    (void)descriptorToken;
    return 1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_configure_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_create(void * outDescriptorToken) {
    (void)outDescriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_destroy(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_sample_count_classify(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_pipeline_descriptor_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_pipeline_descriptor_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_pipeline_descriptor_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_pipeline_descriptor_token_classify(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_state_create(uint64_t deviceToken, uint64_t descriptorToken, uint64_t vertexFunctionToken, uint64_t fragmentFunctionToken, void * outToken) {
    (void)deviceToken;
    (void)descriptorToken;
    (void)vertexFunctionToken;
    (void)fragmentFunctionToken;
    (void)outToken;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_state_creation_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_state_destroy(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_state_double_destroy_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_pipeline_state_draw_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_pipeline_state_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_pipeline_state_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_platform_object_allocation_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_platform_object_create_allocation_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_platform_object_create_no_object_admission(void) {
    return 1;
}
int32_t cjgui_native_bridge_platform_object_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_platform_object_create_requires_token_contract(void) {
    return -1;
}
int32_t cjgui_native_bridge_platform_object_create_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_quartzcore_import_available(void) {
    return 0;
}
int32_t cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_create(void * outDescriptorToken) {
    (void)outDescriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_destroy(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_double_destroy_classify(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_drawable_texture_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked(void) {
    return 1;
}
uint32_t cjgui_native_bridge_render_pass_descriptor_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_render_pass_descriptor_table_enabled(void) {
    return 0;
}
uint32_t cjgui_native_bridge_render_pass_descriptor_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_render_pass_descriptor_token_classify(uint64_t descriptorToken) {
    (void)descriptorToken;
    return -1;
}
int32_t cjgui_native_bridge_revoke_before_destroy_required(void) {
    return 1;
}
int32_t cjgui_native_bridge_shader_draw_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_shader_encoder_binding_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_shader_function_destroy(uint64_t functionToken) {
    (void)functionToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_function_double_destroy_classify(uint64_t functionToken) {
    (void)functionToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_function_lookup_fragment(uint64_t libraryToken, void * outFunctionToken) {
    (void)libraryToken;
    (void)outFunctionToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_function_lookup_vertex(uint64_t libraryToken, void * outFunctionToken) {
    (void)libraryToken;
    (void)outFunctionToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_function_missing_classify(void) {
    return 1;
}
uint32_t cjgui_native_bridge_shader_function_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_shader_function_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_shader_function_token_classify(uint64_t functionToken) {
    (void)functionToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_library_create(uint64_t deviceToken, void * outLibraryToken) {
    (void)deviceToken;
    (void)outLibraryToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_library_create_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_shader_library_destroy(uint64_t libraryToken) {
    (void)libraryToken;
    return -1;
}
int32_t cjgui_native_bridge_shader_library_destroy_requires_main_thread(void) {
    return -1;
}
int32_t cjgui_native_bridge_shader_library_double_destroy_classify(uint64_t libraryToken) {
    (void)libraryToken;
    return -1;
}
uint32_t cjgui_native_bridge_shader_library_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_shader_library_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_shader_library_token_classify(uint64_t libraryToken) {
    (void)libraryToken;
    return -1;
}
uint32_t cjgui_native_bridge_status_ok(void) {
    return -1;
}
uint32_t cjgui_native_bridge_surface_capabilities(void) {
    return -1;
}
uint32_t cjgui_native_bridge_surface_version(void) {
    return 0;
}
int32_t cjgui_native_bridge_teardown_admission(uint64_t token) {
    (void)token;
    return 0;
}
int32_t cjgui_native_bridge_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
uint64_t cjgui_native_bridge_token_invalid(void) {
    return -1;
}
uint64_t cjgui_native_bridge_token_issue(void) {
    return -1;
}
int32_t cjgui_native_bridge_token_revoke(uint64_t token) {
    (void)token;
    return -1;
}
uint32_t cjgui_native_bridge_token_table_capacity(void) {
    return 0;
}
uint32_t cjgui_native_bridge_token_table_enabled(void) {
    return 0;
}
int32_t cjgui_native_bridge_vertex_buffer_create(uint64_t deviceToken, void * outToken) {
    (void)deviceToken;
    (void)outToken;
    return -1;
}
int32_t cjgui_native_bridge_vertex_buffer_data_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_vertex_buffer_destroy(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_vertex_buffer_double_destroy_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_vertex_buffer_draw_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked(void) {
    return 1;
}
int32_t cjgui_native_bridge_vertex_buffer_layout_position_color(void) {
    return -1;
}
uint32_t cjgui_native_bridge_vertex_buffer_table_occupied_count(void) {
    return 0;
}
int32_t cjgui_native_bridge_vertex_buffer_token_classify(uint64_t token) {
    (void)token;
    return -1;
}
int32_t cjgui_native_bridge_vertex_buffer_upload_static_triangle(uint64_t token) {
    (void)token;
    return -1;
}
