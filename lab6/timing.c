#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include "sobel.h"

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

double get_time() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1E9;
}

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Использование: %s <обезьяна.jpg>\n", argv[0]);
        return 1;
    }

    const char *input_filename = argv[1];
    int input_width, input_height, input_channels;
    
    uint8_t *input = stbi_load(input_filename, &input_width, &input_height, &input_channels, 1);
    if (!input) {
        fprintf(stderr, "Ошибка: не удалось загрузить %s\n", input_filename);
        return 1;
    }

    printf("Исходное изображение: %dx%d\n", input_width, input_width);
    printf("Resolution\tC_Time_sec\tASM_Time_sec\tSIMD_Time_sec\n");

    int sizes[] = {200, 500, 700, 1000, 1250, 1500, 1750, 2000};
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);

    for (int i = 0; i < num_sizes; i++) {
        int width = sizes[i];
        int height = sizes[i];

        if (width > input_width || height > input_height) {
            fprintf(stderr, "Пропуск %dx%d: исходное изображение слишком маленькое\n", width, height);
            continue;
        }

        size_t total_pixels = (size_t)width * height;
        uint8_t *in = (uint8_t *)malloc(total_pixels);
        uint8_t *out = (uint8_t *)calloc(total_pixels, 1);

        for (int y = 0; y < height; y++) {
            memcpy(&in[y * width], &input[y * input_width], width);
        }

        sobel_c(in, out, width, height);

        double start, end, time_c, time_asm, time_simd;

        start = get_time();
        sobel_c(in, out, width, height);
        end = get_time();
        time_c = end - start;

        start = get_time();
        sobel_asm(in, out, width, height);
        end = get_time();
        time_asm = end - start;

        start = get_time();
        sobel_simd(in, out, width, height);
        end = get_time();
        time_simd = end - start;

        printf("%dx%d\t%.6f\t%.6f\t%.6f\n", width, height, time_c, time_asm, time_simd);

        free(in);
        free(out);
    }

    stbi_image_free(input);
    return 0;
}
