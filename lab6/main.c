#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "sobel.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

int main(int argc, char **argv) {

    if (argc != 4) {
        fprintf(stderr, "Использование: %s <c|asm|simd> <обезьяна.jpg> <output.jpg>\n", argv[0]);
        return 1;
    }

    const char *mode = argv[1];
    const char *input_filename = argv[2];
    const char *output_filename = argv[3];

    int width, height, channels;
    uint8_t *in = stbi_load(input_filename, &width, &height, &channels, 1);
    
    if (!in) {
        fprintf(stderr, "Ошибка: не удалось загрузить %s\n", input_filename);
        return 1;
    }

    uint8_t *out = (uint8_t *)calloc(width * height, 1);

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    if (strcmp(mode, "c") == 0) {
        sobel_c(in, out, width, height);
    } else if (strcmp(mode, "asm") == 0) {
        sobel_asm(in, out, width, height);
    }else if (strcmp(mode, "simd") == 0) {
        sobel_simd(in, out, width, height);
    } else {
        fprintf(stderr, "Ошибка: неизвестный режим '%s'. Используйте 'c' или 'asm' или 'simd'\n", mode);
        return 1;
    }

    clock_gettime(CLOCK_MONOTONIC, &end);
    double time_spent = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1E9;
    
    printf("Режим: %s | Разрешение: %dx%d | Время: %.6f сек\n", mode, width, height, time_spent);

    stbi_write_jpg(output_filename, width, height, 1, out, 100);

    stbi_image_free(in);
    free(out);
    
    return 0;
}
