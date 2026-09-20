#include "cards_render.h"

#include <hilog/log.h>

namespace ohos_gui_smoke {

namespace {
constexpr uint32_t LOG_DOMAIN = 0xD001C00;
constexpr const char *LOG_TAG = "CardsRender";
constexpr float kCardWidth = 160.0f;
constexpr float kCardHeight = 120.0f;

// Module-level display owner: one eglInitialize/eglTerminate per process.
EGLDisplay g_display = EGL_NO_DISPLAY;
bool g_displayInitialized = false;

const GLfloat *colorFor(float colorIndex, bool selected) {
    static GLfloat blue[4] = {0.20f, 0.45f, 0.90f, 1.0f};
    static GLfloat orange[4] = {0.95f, 0.55f, 0.15f, 1.0f};
    static GLfloat dimBlue[4] = {0.20f, 0.45f, 0.90f, 0.55f};
    static GLfloat dimOrange[4] = {0.95f, 0.55f, 0.15f, 0.55f};
    if (colorIndex > 0.5f) {
        return selected ? orange : dimOrange;
    }
    return selected ? blue : dimBlue;
}
}  // namespace

bool CardsRenderer::ensureDisplay() {
    if (g_displayInitialized) {
        display_ = g_display;
        return display_ != EGL_NO_DISPLAY;
    }
    display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display_ == EGL_NO_DISPLAY) return false;
    if (!eglInitialize(display_, nullptr, nullptr)) {
        display_ = EGL_NO_DISPLAY;
        return false;
    }
    g_display = display_;
    g_displayInitialized = true;
    return true;
}

bool CardsRenderer::initProgram() {
    const char *vertexSource =
        "attribute vec2 a_pos;\n"
        "attribute vec4 a_color;\n"
        "varying vec4 v_color;\n"
        "void main() { gl_Position = vec4(a_pos, 0.0, 1.0); v_color = a_color; }\n";
    const char *fragmentSource =
        "precision mediump float;\n"
        "varying vec4 v_color;\n"
        "void main() { gl_FragColor = v_color; }\n";
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexSource, nullptr);
    glCompileShader(vertexShader);
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentSource, nullptr);
    glCompileShader(fragmentShader);
    program_ = glCreateProgram();
    glAttachShader(program_, vertexShader);
    glAttachShader(program_, fragmentShader);
    glLinkProgram(program_);
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    GLint linked = 0;
    glGetProgramiv(program_, GL_LINK_STATUS, &linked);
    if (!linked) {
        releaseGlObjects();
        return false;
    }
    glGenBuffers(1, &vertexBuffer_);
    return true;
}

bool CardsRenderer::initEgl(void *nativeWindow) {
    // Stepwise acquisition with a single rollback path. Every failure
    // releases what this renderer already obtained; the shared display is
    // never terminated here.
    if (!ensureDisplay()) return false;
    const EGLint configAttribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_NONE};
    EGLConfig config = nullptr;
    EGLint numConfigs = 0;
    if (!eglChooseConfig(display_, configAttribs, &config, 1, &numConfigs) || numConfigs < 1) return false;
    const EGLint contextAttribs[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
    context_ = eglCreateContext(display_, config, EGL_NO_CONTEXT, contextAttribs);
    if (context_ == EGL_NO_CONTEXT) return false;
    surface_ = eglCreateWindowSurface(display_, config, nativeWindow, nullptr);
    if (surface_ == EGL_NO_SURFACE) {
        eglDestroyContext(display_, context_);
        context_ = EGL_NO_CONTEXT;
        return false;
    }
    if (!eglMakeCurrent(display_, surface_, surface_, context_)) {
        eglDestroySurface(display_, surface_);
        surface_ = EGL_NO_SURFACE;
        eglDestroyContext(display_, context_);
        context_ = EGL_NO_CONTEXT;
        return false;
    }
    if (!initProgram()) {
        eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroySurface(display_, surface_);
        surface_ = EGL_NO_SURFACE;
        eglDestroyContext(display_, context_);
        context_ = EGL_NO_CONTEXT;
        return false;
    }
    return true;
}

bool CardsRenderer::surfaceCreated(void *nativeWindow, uint64_t surfaceId, int width, int height) {
    if (!initEgl(nativeWindow)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, "egl init failed");
        return false;
    }
    boundSurfaceId_ = surfaceId;
    surfaceChanged(width, height);
    return true;
}

void CardsRenderer::releaseGlObjects() {
    if (program_) {
        glDeleteProgram(program_);
        program_ = 0;
    }
    if (vertexBuffer_) {
        glDeleteBuffers(1, &vertexBuffer_);
        vertexBuffer_ = 0;
    }
}

void CardsRenderer::surfaceChanged(int width, int height) {
    width_ = width;
    height_ = height;
    if (display_ == EGL_NO_DISPLAY || surface_ == EGL_NO_SURFACE) return;
    eglMakeCurrent(display_, surface_, surface_, context_);
    glViewport(0, 0, width, height);
    drawnVersion_ = -1;  // force one redraw for the new size
}

void CardsRenderer::surfaceDestroyed() {
    // GL objects are released while the context is still current; only then
    // are the EGL surface/context unbound and destroyed. The shared display
    // is left alive (owned at module level).
    if (display_ != EGL_NO_DISPLAY && surface_ != EGL_NO_SURFACE && context_ != EGL_NO_CONTEXT) {
        eglMakeCurrent(display_, surface_, surface_, context_);
        releaseGlObjects();
        eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroySurface(display_, surface_);
        eglDestroyContext(display_, context_);
    }
    surface_ = EGL_NO_SURFACE;
    context_ = EGL_NO_CONTEXT;
    display_ = EGL_NO_DISPLAY;  // this renderer no longer holds a reference
    drawnVersion_ = -1;
    boundSurfaceId_ = 0;
}

void CardsRenderer::teardownDisplay() {
    // Application exit path: called when the last renderer is gone.
    if (g_display != EGL_NO_DISPLAY && g_displayInitialized) {
        eglTerminate(g_display);
    }
    g_display = EGL_NO_DISPLAY;
    g_displayInitialized = false;
}

bool CardsRenderer::drawIfDirty(CardsOwner &owner, uint64_t surfaceId) {
    if (display_ == EGL_NO_DISPLAY || surface_ == EGL_NO_SURFACE) return false;
    if (boundSurfaceId_ != surfaceId) return false;
    CardState cards[2];
    int64_t version = 0;
    int selected = 0;
    owner.snapshot(cards, &version, &selected);
    if (version == drawnVersion_) return false;
    eglMakeCurrent(display_, surface_, surface_, context_);
    drawLocked(owner);
    if (!eglSwapBuffers(display_, surface_)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, "swap failed");
        return false;
    }
    drawnVersion_ = version;
    return true;
}

void CardsRenderer::drawLocked(CardsOwner &owner) {
    CardState cards[2];
    int64_t version = 0;
    int selected = 0;
    owner.snapshot(cards, &version, &selected);
    glClearColor(0.05f, 0.08f, 0.12f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    if (width_ <= 0 || height_ <= 0) return;
    GLfloat vertices[2 * 6 * 6];  // 2 cards * 6 vertices * (x, y, r, g, b, a)
    int offset = 0;
    for (int i = 0; i < 2; ++i) {
        float left = cards[i].x - kCardWidth / 2.0f;
        float bottom = cards[i].y - kCardHeight / 2.0f;
        float x0 = (left / width_) * 2.0f - 1.0f;
        float x1 = ((left + kCardWidth) / width_) * 2.0f - 1.0f;
        float y0 = 1.0f - ((bottom + kCardHeight) / height_) * 2.0f;
        float y1 = 1.0f - (bottom / height_) * 2.0f;
        const GLfloat *color = colorFor(cards[i].colorIndex, selected == i);
        const GLfloat quad[6][6] = {
            {x0, y0, color[0], color[1], color[2], color[3]},
            {x1, y0, color[0], color[1], color[2], color[3]},
            {x1, y1, color[0], color[1], color[2], color[3]},
            {x0, y0, color[0], color[1], color[2], color[3]},
            {x1, y1, color[0], color[1], color[2], color[3]},
            {x0, y1, color[0], color[1], color[2], color[3]},
        };
        for (int v = 0; v < 6; ++v) {
            for (int c = 0; c < 6; ++c) vertices[offset++] = quad[v][c];
        }
    }
    glUseProgram(program_);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
    GLint posLoc = glGetAttribLocation(program_, "a_pos");
    GLint colorLoc = glGetAttribLocation(program_, "a_color");
    glEnableVertexAttribArray(posLoc);
    glVertexAttribPointer(posLoc, 2, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), nullptr);
    glEnableVertexAttribArray(colorLoc);
    glVertexAttribPointer(colorLoc, 4, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat),
                          reinterpret_cast<void *>(2 * sizeof(GLfloat)));
    glDrawArrays(GL_TRIANGLES, 0, 12);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

}  // namespace ohos_gui_smoke
