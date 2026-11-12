import sys
from PIL import Image

# ASCII gradient from darkest to lightest
ASCII_CHARS = " .:-=+*#%@"

def resize_image(image, new_width=100):
    width, height = image.size
    # 0.55 aspect ratio correction for terminal fonts
    aspect_ratio = height / width * 0.55
    new_height = int(new_width * aspect_ratio)
    return image.resize((new_width, new_height))

def grayify(image):
    return image.convert("L")

def pixels_to_ascii(image):
    pixels = image.getdata()
    characters = "".join([ASCII_CHARS[pixel * len(ASCII_CHARS) // 256] for pixel in pixels])
    return characters

def generate_c_file(ascii_str, width, filename="main.c"):
    lines = [ascii_str[i:i+width] for i in range(0, len(ascii_str), width)]
    
    c_code = """#include <stdint.h>

// 6551 UART registers at $8400
#define UART_DATA    (*(volatile uint8_t *)0x8400)
#define UART_STATUS  (*(volatile uint8_t *)0x8401)
#define TDRE 0x10  // Transmitter Data Register Empty

// Send a single character
void uart_putchar(char c) {
    while ((UART_STATUS & TDRE) == 0);
    UART_DATA = c;
}

// Send a null-terminated string
void uart_puts(const char *str) {
    while (*str) {
        uart_putchar(*str++);
    }
}

const char *art[] = {
"""
    
    for line in lines:
        # Escape any potential backslashes or quotes safely
        safe_line = line.replace('\\', '\\\\').replace('"', '\\"')
        c_code += f'"{safe_line}",\n'
        
    c_code += """};

#define ART_LINES (sizeof(art) / sizeof(art[0]))

// Jump to ROM monitor at $a000
void jump_to_rom(void) {
    __asm__("jmp $a000");
}

void main(void) {
    uint16_t i;
    
    uart_puts("\\r\\n");
    
    for (i = 0; i < ART_LINES; i++) {
        uart_puts(art[i]);
        uart_puts("\\r\\n");
    }
    
    uart_puts("\\r\\nDone!\\r\\n");
    
    jump_to_rom();
}
"""
    
    with open(filename, "w", encoding="utf-8") as f:
        f.write(c_code)
    print(f"Successfully generated {filename} with {len(lines)} lines of art!")

def main():
    img_path = sys.argv[1] if len(sys.argv) > 1 else "input.png"
    width = int(sys.argv[2]) if len(sys.argv) > 2 else 95  # fits standard terminal widths cleanly
    
    try:
        image = Image.open(img_path)
    except Exception as e:
        print(f"Error opening image '{img_path}': {e}")
        sys.exit(1)
        
    image = resize_image(image, width)
    image = grayify(image)
    ascii_str = pixels_to_ascii(image)
    
    generate_c_file(ascii_str, width)

if __name__ == "__main__":
    main()