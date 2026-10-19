/*
 * runtime/cjgui/platforms/linux/tests/desktop_input_driver.c
 *
 * Linux 验收驱动：在来宾 X11 会话里找 CJGUI 窗口，向它投递真实输入，并把窗口
 * 内容抓成 PPM 供人眼核对。与 macOS 的 desktop_input_driver.swift 同一职责：
 * 消费方的期望由**独立输入**产生，不把被测实现的输出当正确答案。
 *
 * 用法（DISPLAY=:0）：
 *   driver find  [title-substring]            列出/匹配窗口
 *   driver key   <keysym-hex|char>            投递一次 KeyPress+KeyRelease
 *   driver text  <ascii-string>               逐字符投递（ASCII 直输）
 *   driver click <x> <y> [button]             投递 ButtonPress+Release
 *   driver move  <x> <y>                      投递 MotionNotify
 *   driver scroll <up|down> <count>           投递 Button 4/5
 *   driver resize <w> <h>                     XResizeWindow + 等待生效
 *   driver shot  <out.ppm>                    抓窗口内容
 *   driver close                              投递 WM_DELETE_WINDOW
 *   driver title                              打印窗口标题
 *
 * 说明：
 *   - 按键走 XSendEvent 到目标窗口（锁屏会话里 XTest 注入会被 grab 吃掉，
 *     这一点由窗口模块的自测证实；XSendEvent 是服务端投递的真实 KeyPress/ButtonPress）。
 *   - 坐标是**窗口内**像素坐标，驱动自己负责换算成 root 坐标。
 *   - 抓图用 XGetImage，读的是窗口 drawable 的内容，不是屏幕合成结果。
 */

/* 特性测试宏必须出现在任何 include 之前，否则 nanosleep 不可见。 */
#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <time.h>

static void driver_sleep_us(long microseconds) {
    struct timespec ts;
    ts.tv_sec = microseconds / 1000000L;
    ts.tv_nsec = (microseconds % 1000000L) * 1000L;
    nanosleep(&ts, NULL);
}
#include <X11/Xatom.h>
#include <X11/keysym.h>

static Display *display;
static Window target;

static int is_candidate(Display *dpy, Window window, const char *needle) {
    char *name = NULL;
    if (XFetchName(dpy, window, &name) && name) {
        int hit = needle == NULL || needle[0] == '\0' || strstr(name, needle) != NULL;
        if (hit) fprintf(stderr, "candidate 0x%lx title=%s\n", (unsigned long)window, name);
        XFree(name);
        return hit;
    }
    // _NET_WM_NAME (UTF8_STRING) 优先。
    Atom utf8 = XInternAtom(dpy, "UTF8_STRING", False);
    Atom property = XInternAtom(dpy, "_NET_WM_NAME", False);
    Atom type = None;
    int format = 0;
    unsigned long items = 0, after = 0;
    unsigned char *data = NULL;
    if (XGetWindowProperty(dpy, window, property, 0, 1024, False, utf8, &type, &format, &items, &after,
                           &data) == Success && data) {
        int hit = needle == NULL || needle[0] == '\0' || strstr((char *)data, needle) != NULL;
        if (hit) fprintf(stderr, "candidate 0x%lx _NET_WM_NAME=%s\n", (unsigned long)window, (char *)data);
        XFree(data);
        return hit;
    }
    return 0;
}

static Window find_window(Display *dpy, Window root, const char *needle, int depth) {
    Window rootReturn = 0, parentReturn = 0, *children = NULL;
    unsigned int count = 0;
    if (!XQueryTree(dpy, root, &rootReturn, &parentReturn, &children, &count)) return 0;
    Window found = 0;
    for (unsigned int i = 0; i < count && !found; i += 1) {
        if (is_candidate(dpy, children[i], needle)) { found = children[i]; break; }
        if (depth < 4) found = find_window(dpy, children[i], needle, depth + 1);
    }
    if (children) XFree(children);
    return found;
}

static int window_geometry(int *x, int *y, int *width, int *height) {
    Window rootReturn = 0;
    int rx = 0, ry = 0;
    unsigned int w = 0, h = 0, border = 0, depth = 0;
    if (!XGetGeometry(display, target, &rootReturn, &rx, &ry, &w, &h, &border, &depth)) return -1;
    XTranslateCoordinates(display, target, rootReturn, 0, 0, x, y, &(Window){0});
    *width = (int)w;
    *height = (int)h;
    return 0;
}

static unsigned int g_modifiers = 0;

static void send_key(KeySym keysym, int press) {
    KeyCode code = XKeysymToKeycode(display, keysym);
    if (code == 0) { fprintf(stderr, "no keycode for keysym 0x%lx\n", (unsigned long)keysym); return; }
    XKeyEvent event;
    memset(&event, 0, sizeof(event));
    event.display = display;
    event.window = target;
    event.root = DefaultRootWindow(display);
    event.subwindow = None;
    event.time = CurrentTime;
    event.x = 1;
    event.y = 1;
    event.x_root = 1;
    event.y_root = 1;
    event.same_screen = True;
    event.keycode = code;
    event.state = g_modifiers;
    event.type = press ? KeyPress : KeyRelease;
    XSendEvent(display, target, True, press ? KeyPressMask : KeyReleaseMask, (XEvent *)&event);
    XFlush(display);
}

static void send_button(int x, int y, unsigned int button, int press) {
    XButtonEvent event;
    memset(&event, 0, sizeof(event));
    event.display = display;
    event.window = target;
    event.root = DefaultRootWindow(display);
    event.subwindow = None;
    event.time = CurrentTime;
    event.x = x;
    event.y = y;
    event.x_root = x;
    event.y_root = y;
    event.same_screen = True;
    event.button = button;
    event.state = 0;
    event.type = press ? ButtonPress : ButtonRelease;
    XSendEvent(display, target, True, press ? ButtonPressMask : ButtonReleaseMask, (XEvent *)&event);
    XFlush(display);
}

static void send_motion(int x, int y) {
    XMotionEvent event;
    memset(&event, 0, sizeof(event));
    event.display = display;
    event.window = target;
    event.root = DefaultRootWindow(display);
    event.subwindow = None;
    event.time = CurrentTime;
    event.x = x;
    event.y = y;
    event.x_root = x;
    event.y_root = y;
    event.same_screen = True;
    event.state = 0;
    event.type = MotionNotify;
    XSendEvent(display, target, True, PointerMotionMask, (XEvent *)&event);
    XFlush(display);
}

static KeySym keysym_for_char(char c) {
    if (c >= 'a' && c <= 'z') return XK_a + (c - 'a');
    if (c >= 'A' && c <= 'Z') return XK_A + (c - 'A');
    if (c >= '0' && c <= '9') return XK_0 + (c - '0');
    switch (c) {
        case ' ': return XK_space;
        case '\n': return XK_Return;
        case '.': return XK_period;
        case ',': return XK_comma;
        case '-': return XK_minus;
        case '_': return XK_underscore;
        case '#': return XK_numbersign;
        default: return NoSymbol;
    }
}

static int grab_shot(const char *path) {
    int x = 0, y = 0, width = 0, height = 0;
    if (window_geometry(&x, &y, &width, &height) != 0) return -1;
    XImage *image = XGetImage(display, target, 0, 0, (unsigned int)width, (unsigned int)height, AllPlanes, ZPixmap);
    if (!image) { fprintf(stderr, "XGetImage failed\n"); return -1; }
    FILE *file = fopen(path, "wb");
    if (!file) { XDestroyImage(image); return -1; }
    fprintf(file, "P6\n%d %d\n255\n", width, height);
    for (int row = 0; row < height; row += 1) {
        for (int column = 0; column < width; column += 1) {
            unsigned long pixel = XGetPixel(image, column, row);
            unsigned char rgb[3];
            rgb[0] = (unsigned char)((pixel >> 16) & 0xFFu);
            rgb[1] = (unsigned char)((pixel >> 8) & 0xFFu);
            rgb[2] = (unsigned char)(pixel & 0xFFu);
            fwrite(rgb, 1, 3, file);
        }
    }
    fclose(file);
    XDestroyImage(image);
    printf("shot %s %dx%d\n", path, width, height);
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: driver <command> ...\n"); return 2; }
    const char *title = getenv("CJGUI_DRIVER_TITLE");
    if (!title) title = "CJGUI";
    display = XOpenDisplay(NULL);
    if (!display) { fprintf(stderr, "cannot open display\n"); return 3; }
    Window root = DefaultRootWindow(display);
    target = find_window(display, root, title, 0);
    if (!target) {
        fprintf(stderr, "no window matching '%s'\n", title);
        XCloseDisplay(display);
        return 4;
    }
    printf("target 0x%lx title-match=%s\n", (unsigned long)target, title);

    const char *command = argv[1];
    if (strcmp(command, "find") == 0) {
        int x = 0, y = 0, w = 0, h = 0;
        if (window_geometry(&x, &y, &w, &h) == 0) printf("geometry root=(%d,%d) size=%dx%d\n", x, y, w, h);
    } else if (strcmp(command, "title") == 0) {
        char *name = NULL;
        if (XFetchName(display, target, &name) && name) { printf("title=%s\n", name); XFree(name); }
    } else if (strcmp(command, "key") == 0 && argc >= 3) {
        KeySym keysym = (KeySym)strtoul(argv[2], NULL, 0);
        if (strlen(argv[2]) == 1 && keysym == 0) keysym = keysym_for_char(argv[2][0]);
        send_key(keysym, 1);
        driver_sleep_us(15000);
        send_key(keysym, 0);
    } else if (strcmp(command, "keymod") == 0 && argc >= 4) {
        // keymod <keysym> <shift-mask>：带修饰位投递一次按键（用于 Shift+方向扩展选区）。
        g_modifiers = (unsigned int)strtoul(argv[3], NULL, 0);
        KeySym keysym = (KeySym)strtoul(argv[2], NULL, 0);
        send_key(keysym, 1);
        driver_sleep_us(15000);
        send_key(keysym, 0);
        g_modifiers = 0;
    } else if (strcmp(command, "text") == 0 && argc >= 3) {
        for (const char *p = argv[2]; *p; p += 1) {
            KeySym keysym = keysym_for_char(*p);
            if (keysym == NoSymbol) keysym = (KeySym)(unsigned char)*p;
            send_key(keysym, 1);
            driver_sleep_us(20000);
            send_key(keysym, 0);
            driver_sleep_us(20000);
        }
    } else if (strcmp(command, "click") == 0 && argc >= 4) {
        int x = atoi(argv[2]), y = atoi(argv[3]);
        unsigned int button = argc >= 5 ? (unsigned int)atoi(argv[4]) : 1u;
        send_button(x, y, button, 1);
        driver_sleep_us(30000);
        send_button(x, y, button, 0);
    } else if (strcmp(command, "move") == 0 && argc >= 4) {
        send_motion(atoi(argv[2]), atoi(argv[3]));
    } else if (strcmp(command, "scroll") == 0 && argc >= 3) {
        // scroll <up|down> <count> [x] [y]：默认落在 (10,10) 是错的——滚轮命中
        // 由坐标决定，必须能指定落点（例如滚动区中心）。
        unsigned int button = strcmp(argv[2], "up") == 0 ? 4u : 5u;
        int count = argc >= 4 ? atoi(argv[3]) : 1;
        int scrollX = argc >= 6 ? atoi(argv[4]) : 10;
        int scrollY = argc >= 6 ? atoi(argv[5]) : 10;
        for (int i = 0; i < count; i += 1) {
            send_motion(scrollX, scrollY);
            driver_sleep_us(5000);
            send_button(scrollX, scrollY, button, 1);
            driver_sleep_us(15000);
            send_button(scrollX, scrollY, button, 0);
            driver_sleep_us(15000);
        }
    } else if (strcmp(command, "resize") == 0 && argc >= 4) {
        XResizeWindow(display, target, (unsigned int)atoi(argv[2]), (unsigned int)atoi(argv[3]));
        XFlush(display);
        driver_sleep_us(200000);
        int x = 0, y = 0, w = 0, h = 0;
        window_geometry(&x, &y, &w, &h);
        printf("resized to %dx%d\n", w, h);
    } else if (strcmp(command, "shot") == 0 && argc >= 3) {
        if (grab_shot(argv[2]) != 0) { XCloseDisplay(display); return 5; }
    } else if (strcmp(command, "close") == 0) {
        Atom protocol = XInternAtom(display, "WM_PROTOCOLS", False);
        Atom deleteWindow = XInternAtom(display, "WM_DELETE_WINDOW", False);
        XEvent event;
        memset(&event, 0, sizeof(event));
        event.xclient.type = ClientMessage;
        event.xclient.window = target;
        event.xclient.message_type = protocol;
        event.xclient.format = 32;
        event.xclient.data.l[0] = (long)deleteWindow;
        event.xclient.data.l[1] = CurrentTime;
        XSendEvent(display, target, False, NoEventMask, &event);
        XFlush(display);
    } else {
        fprintf(stderr, "unknown command: %s\n", command);
        XCloseDisplay(display);
        return 2;
    }
    XSync(display, False);
    XCloseDisplay(display);
    return 0;
}
