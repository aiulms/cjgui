// EGL/GLES renderer for the two self-drawn cards.
//
// Display ownership follows the EGL specification: the display is a
// process-wide object owned by a module-level holder and initialized once;
// surface recreation only destroys this renderer's own surface/context and
// never calls eglTerminate. Teardown order is: delete GL objects while the
// context is still current, unbind, destroy surface, destroy context.
#ifndef CARDS_RENDER_H
#define CARDS_RENDER_H

#include "cards_owner.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>

#include <cstdint>

namespace ohos_gui_smoke {

class CardsRenderer {
public:
    bool surfaceCreated(void *nativeWindow, uint64_t surfaceId, int width, int height);
    void surfaceChanged(int width, int height);
    void surfaceDestroyed();
    // Draws only when the owner version or the surface size changed.
    bool drawIfDirty(CardsOwner &owner, uint64_t surfaceId);
    bool valid() const { return surface_ != EGL_NO_SURFACE && context_ != EGL_NO_CONTEXT; }
    // Final application teardown: the last owner releases the display.
    static void teardownDisplay();

private:
    bool ensureDisplay();
    bool initEgl(void *nativeWindow);
    bool initProgram();
    void releaseGlObjects();
    void drawLocked(CardsOwner &owner);

    EGLDisplay display_ = EGL_NO_DISPLAY;
    EGLContext context_ = EGL_NO_CONTEXT;
    EGLSurface surface_ = EGL_NO_SURFACE;
    int width_ = 0;
    int height_ = 0;
    int64_t drawnVersion_ = -1;
    uint64_t boundSurfaceId_ = 0;
    GLuint program_ = 0;
    GLuint vertexBuffer_ = 0;
};

}  // namespace ohos_gui_smoke

#endif  // CARDS_RENDER_H
