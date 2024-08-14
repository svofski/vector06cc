#include <stdint.h>
#include <string.h>

#include "matrix.h"

#define VVOD_BV     (1<<0)
#define SBROS_BV    (1<<1)
#define OSD_BV      (1<<2)
#define PAUSE_BV    (1<<3)
//                  (1<<4)
#define SS_BV       (1<<5)
#define US_BV       (1<<6)
#define RUSLAT_BV   (1<<7)

// HID modifier bits
#define KEY_MOD_LCTRL  0x01
#define KEY_MOD_LSHIFT 0x02
#define KEY_MOD_LALT   0x04
#define KEY_MOD_LMETA  0x08
#define KEY_MOD_RCTRL  0x10
#define KEY_MOD_RSHIFT 0x20
#define KEY_MOD_RALT   0x40
#define KEY_MOD_RMETA  0x80

// HID scancodes
#define KEY_A             0x04 // Keyboard a and A
#define KEY_B             0x05 // Keyboard b and B
#define KEY_C             0x06 // Keyboard c and C
#define KEY_D             0x07 // Keyboard d and D
#define KEY_E             0x08 // Keyboard e and E
#define KEY_F             0x09 // Keyboard f and F
#define KEY_G             0x0a // Keyboard g and G
#define KEY_H             0x0b // Keyboard h and H
#define KEY_I             0x0c // Keyboard i and I
#define KEY_J             0x0d // Keyboard j and J
#define KEY_K             0x0e // Keyboard k and K
#define KEY_L             0x0f // Keyboard l and L
#define KEY_M             0x10 // Keyboard m and M
#define KEY_N             0x11 // Keyboard n and N
#define KEY_O             0x12 // Keyboard o and O
#define KEY_P             0x13 // Keyboard p and P
#define KEY_Q             0x14 // Keyboard q and Q
#define KEY_R             0x15 // Keyboard r and R
#define KEY_S             0x16 // Keyboard s and S
#define KEY_T             0x17 // Keyboard t and T
#define KEY_U             0x18 // Keyboard u and U
#define KEY_V             0x19 // Keyboard v and V
#define KEY_W             0x1a // Keyboard w and W
#define KEY_X             0x1b // Keyboard x and X
#define KEY_Y             0x1c // Keyboard y and Y
#define KEY_Z             0x1d // Keyboard z and Z

#define KEY_1             0x1e // Keyboard 1 and !
#define KEY_2             0x1f // Keyboard 2 and @
#define KEY_3             0x20 // Keyboard 3 and #
#define KEY_4             0x21 // Keyboard 4 and $
#define KEY_5             0x22 // Keyboard 5 and %
#define KEY_6             0x23 // Keyboard 6 and ^
#define KEY_7             0x24 // Keyboard 7 and &
#define KEY_8             0x25 // Keyboard 8 and *
#define KEY_9             0x26 // Keyboard 9 and (
#define KEY_0             0x27 // Keyboard 0 and )
#define KEY_ENTER	  0x28 // Keyboard Return (ENTER)
#define KEY_ESC	          0x29 // Keyboard ESCAPE
#define KEY_BACKSPACE     0x2a // Keyboard DELETE (Backspace)
#define KEY_TAB	          0x2b // Keyboard Tab
#define KEY_SPACE	  0x2c // Keyboard Spacebar
#define KEY_MINUS	  0x2d // Keyboard - and _
#define KEY_EQUAL	  0x2e // Keyboard = and +
#define KEY_LEFTBRACE     0x2f // Keyboard [ and {
#define KEY_RIGHTBRACE    0x30 // Keyboard ] and }
#define KEY_BACKSLASH     0x31 // Keyboard \ and |
#define KEY_HASHTILDE     0x32 // Keyboard Non-US # and ~
#define KEY_SEMICOLON     0x33 // Keyboard ; and :
#define KEY_APOSTROPHE    0x34 // Keyboard ' and "
#define KEY_GRAVE	  0x35 // Keyboard ` and ~
#define KEY_COMMA	  0x36 // Keyboard , and <
#define KEY_DOT	          0x37 // Keyboard . and >
#define KEY_SLASH	  0x38 // Keyboard / and ?
#define KEY_CAPSLOCK	  0x39 // Keyboard Caps Lock

#define KEY_F1	          0x3a // Keyboard F1
#define KEY_F2	          0x3b // Keyboard F2
#define KEY_F3	          0x3c // Keyboard F3
#define KEY_F4	          0x3d // Keyboard F4
#define KEY_F5	          0x3e // Keyboard F5
#define KEY_F6	          0x3f // Keyboard F6
#define KEY_F7	          0x40 // Keyboard F7
#define KEY_F8	          0x41 // Keyboard F8
#define KEY_F9	          0x42 // Keyboard F9
#define KEY_F10	          0x43 // Keyboard F10
#define KEY_F11	          0x44 // Keyboard F11
#define KEY_F12	          0x45 // Keyboard F12

#define KEY_SYSRQ	  0x46 // Keyboard Print Screen
#define KEY_SCROLLLOCK    0x47 // Keyboard Scroll Lock
#define KEY_PAUSE	  0x48 // Keyboard Pause
#define KEY_INSERT	  0x49 // Keyboard Insert
#define KEY_HOME	  0x4a // Keyboard Home
#define KEY_PAGEUP	  0x4b // Keyboard Page Up
#define KEY_DELETE	  0x4c // Keyboard Delete Forward
#define KEY_END	          0x4d // Keyboard End
#define KEY_PAGEDOWN	  0x4e // Keyboard Page Down
#define KEY_RIGHT	  0x4f // Keyboard Right Arrow
#define KEY_LEFT	  0x50 // Keyboard Left Arrow
#define KEY_DOWN	  0x51 // Keyboard Down Arrow
#define KEY_UP	          0x52 // Keyboard Up Arrow

#define KEY_NUMLOCK	  0x53 // Keyboard Num Lock and Clear
#define KEY_KPSLASH	  0x54 // Keypad /
#define KEY_KPASTERISK    0x55 // Keypad *
#define KEY_KPMINUS	  0x56 // Keypad -
#define KEY_KPPLUS	  0x57 // Keypad +
#define KEY_KPENTER	  0x58 // Keypad ENTER
#define KEY_KP1	          0x59 // Keypad 1 and End
#define KEY_KP2	          0x5a // Keypad 2 and Down Arrow
#define KEY_KP3	          0x5b // Keypad 3 and PageDn
#define KEY_KP4	          0x5c // Keypad 4 and Left Arrow
#define KEY_KP5	          0x5d // Keypad 5
#define KEY_KP6	          0x5e // Keypad 6 and Right Arrow
#define KEY_KP7	          0x5f // Keypad 7 and Home
#define KEY_KP8	          0x60 // Keypad 8 and Up Arrow
#define KEY_KP9	          0x61 // Keypad 9 and Page Up
#define KEY_KP0	          0x62 // Keypad 0 and Insert
#define KEY_KPDOT	  0x63 // Keypad . and Delete

#define KEY_102ND         0x64 // Keyboard Non-US \ and |
#define KEY_COMPOSE       0x65 // Keyboard Application
#define KEY_POWER         0x66 // Keyboard Power
#define KEY_KPEQUAL       0x67 // Keypad =

// these keys are not sent in reports, at least not in BOOT mode on my keyboard
#define KEY_LEFTCTRL      0xe0 // Keyboard Left Control
#define KEY_LEFTSHIFT     0xe1 // Keyboard Left Shift
#define KEY_LEFTALT       0xe2 // Keyboard Left Alt
#define KEY_LEFTMETA      0xe3 // Keyboard Left GUI
#define KEY_RIGHTCTRL     0xe4 // Keyboard Right Control
#define KEY_RIGHTSHIFT    0xe5 // Keyboard Right Shift
#define KEY_RIGHTALT      0xe6 // Keyboard Right Alt
#define KEY_RIGHTMETA     0xe7 // Keyboard Right GUI

uint16_t keymap[256];

matrix_t matrix;

static void apply_key(uint8_t code);
static void init_map();
static void key_down(uint8_t hid_mods, uint8_t scan);
static void matrix_reset();

static void init_map()
{
    // Keyboard encoding matrix:
    //   │ 7   6   5   4   3   2   1   0
    // ──┼───────────────────────────────
    // 7 │SPC  ^   ]   \   [   Z   Y   X
    // 6 │ W   V   U   T   S   R   Q   P
    // 5 │ O   N   M   L   K   J   I   H
    // 4 │ G   F   E   D   C   B   A   @
    // 3 │ /   .   =   ,   ;   :   9   8
    // 2 │ 7   6   5   4   3   2   1   0
    // 1 │F5  F4  F3  F2  F1  AP2 CTP ^\ -
    // 0 │DN  RT  UP  LT  ЗАБ ВК  ПС  TAB

    static int keymap_tab[] = {
            /* scancode        {row:4,bit:8}  */
            KEY_SPACE,         0x780,
            KEY_GRAVE,         0x740,
            KEY_RIGHTBRACE,    0x720,
            KEY_BACKSLASH,     0x710,
            KEY_LEFTBRACE,     0x708,
            KEY_Z,             0x704,
            KEY_Y,             0x702,
            KEY_X,             0x701,

            KEY_W,             0x680,
            KEY_V,             0x640,
            KEY_U,             0x620,
            KEY_T,             0x610,
            KEY_S,             0x608,
            KEY_R,             0x604,
            KEY_Q,             0x602,
            KEY_P,             0x601,

            KEY_O,             0x580,
            KEY_N,             0x540,
            KEY_M,             0x520,
            KEY_L,             0x510,
            KEY_K,             0x508,
            KEY_J,             0x504,
            KEY_I,             0x502,
            KEY_H,             0x501,

            KEY_G,             0x480,
            KEY_F,             0x440,
            KEY_E,             0x420,
            KEY_D,             0x410,
            KEY_C,             0x408,
            KEY_B,             0x404,
            KEY_A,             0x402,
            KEY_MINUS,         0x401, // 189:-@

            KEY_SLASH,         0x380,
            KEY_DOT,           0x340,
            KEY_EQUAL,         0x320,
            KEY_COMMA,         0x310,
            KEY_SEMICOLON,     0x308,
            KEY_APOSTROPHE,    0x304,
            KEY_9,             0x302,
            KEY_8,             0x301,

            KEY_7,             0x280,
            KEY_6,             0x240,
            KEY_5,             0x220,
            KEY_4,             0x210,
            KEY_3,             0x208,
            KEY_2,             0x204,
            KEY_1,             0x202,
            KEY_0,             0x201,

            KEY_F5,            0x180,
            KEY_F4,            0x140,
            KEY_F3,            0x120,
            KEY_F2,            0x110,
            KEY_F1,            0x108,
            KEY_ESC,           0x104, // AR2
            KEY_END,           0x102, // CTP  ~ End
            KEY_HOME,          0x101, // ^\ ? ~ Home
            KEY_DOWN,          0x080,
            KEY_RIGHT,         0x040,
            KEY_UP,            0x020,
            KEY_LEFT,          0x010,
            KEY_BACKSPACE,     0x008,
            KEY_ENTER,         0x004,
            KEY_RIGHTALT,      0x002, // PS
            KEY_TAB,           0x001,
    };

    for (unsigned i = 0; i < sizeof(keymap_tab)/sizeof(keymap_tab[0]); i += 2) {
        int scan = keymap_tab[i];
        uint32_t rowbit = keymap_tab[i + 1];
        keymap[scan] = rowbit;
    }
}

static void key_down(uint8_t hid_mods, uint8_t scan)
{
    if ((hid_mods & KEY_MOD_LCTRL) || (hid_mods & KEY_MOD_RCTRL)) {
        matrix.modkeys |= US_BV;
    }
    if ((hid_mods & KEY_MOD_LSHIFT) || (hid_mods & KEY_MOD_RSHIFT)) {
        matrix.modkeys |= SS_BV;
    }
    if (hid_mods & KEY_MOD_LMETA) {
        matrix.modkeys |= RUSLAT_BV;  // left winkey = RUS/LAT
    }
    if (hid_mods & KEY_MOD_RALT) {  
        apply_key(KEY_RIGHTALT);            // right alt = PS
    }

    switch (scan) {
        case KEY_F6:  // backup RUS/LAT
            matrix.modkeys |= RUSLAT_BV;
            break;
        case KEY_F11:
            matrix.modkeys |= VVOD_BV;
            break;
        case KEY_F12:
            matrix.modkeys |= SBROS_BV;
            break;
        case KEY_SCROLLLOCK:
            matrix.modkeys |= OSD_BV;
            break;
        case KEY_PAUSE:
            matrix.modkeys |= PAUSE_BV;
            break;
        default:
            apply_key(scan);
            break;
    }
}

static void apply_key(uint8_t code)
{
    uint16_t rowbit = keymap[code];
    if (rowbit == 0) {
        return;
    }

    int row = (rowbit >> 8) & 0377;
    int bit = rowbit & 0377;

    if (row > 7) {
        return;
    }

    matrix.rows[row] |= bit;
};

static void matrix_reset()
{
    memset(&matrix, 0, sizeof(matrix));
}

void matrix_init()
{
    init_map();
}

// process hid report and set corresponding bits in v06c matrix + modifier reg
// mod keys + 6 pressed scancodes
void matrix_setkeys(uint8_t hid_mods, const uint8_t * scancodes)
{
    matrix_reset();
    for (int i = 0; i < 6; ++i) {
        key_down(hid_mods, scancodes[i]);
    }
}

matrix_t * matrix_getdata()
{
    return &matrix;
}

