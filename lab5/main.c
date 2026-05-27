#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"


void crop_c(const uint8_t *in_ptr, uint8_t *out_ptr, int in_stride, int row_bytes, int out_h);
extern void crop_asm(const uint8_t *in_ptr, uint8_t *out_ptr, int in_stride, int row_bytes, int out_h);


double get_time() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);  // запрашивает у ядра монотонный таймер с точностью  10^9
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

int main(int argc, char** argv) {
    if (argc != 7) {
        printf("Использование: %s <input.png> <output.png> <x1> <y1> <x2> <y2>\n", argv[0]);
        return 1;
    }

    const char *input_file = argv[1];
    const char *output_file = argv[2];
    int x1 = atoi(argv[3]);
    int y1 = atoi(argv[4]);
    int x2 = atoi(argv[5]);
    int y2 = atoi(argv[6]);

    int x_start = x1 < x2 ? x1 : x2;
    int y_start = y1 < y2 ? y1 : y2;
    int x_end = x1 > x2 ? x1 : x2;
    int y_end = y1 > y2 ? y1 : y2;
                        
    int width, height, channels;
    uint8_t *img = stbi_load(input_file, &width, &height, &channels, 0);
    if (!img) {
        printf("Ошибка: не удалось загрузить изображение %s\n", input_file);
        return 1;
    }

    if (x_start < 0 || y_start < 0 || x_end > width || y_end > height || x_start == x_end || y_start == y_end) {
        printf("Ошибка: некорректные координаты для обрезки. Убедитесь, что они находятся в пределах %dx%d\n", width, height);
        stbi_image_free(img);
        return 1;
    }

    int out_w = x_end - x_start;
    int out_h = y_end - y_start;
    int row_bytes = out_w * channels;   
    int in_stride = width * channels;

    uint8_t *out_img_c = (uint8_t *)malloc(out_w * out_h * channels);
    uint8_t *out_img_asm = (uint8_t *)malloc(out_w * out_h * channels);

    // указатель на начало нужной области
    const uint8_t *start_ptr = img + (y_start * width + x_start) * channels;

    int iterations = 100; 
    
    double start_t = get_time();
    for (int i = 0; i < iterations; ++i) {
        crop_c(start_ptr, out_img_c, in_stride, row_bytes, out_h);
    }
    double end_t = get_time();
    double time_c = (end_t - start_t) / iterations;    

    start_t = get_time();
    for (int i = 0; i < iterations; ++i) {
        crop_asm(start_ptr, out_img_asm, in_stride, row_bytes, out_h);
    }
    end_t = get_time();
    double time_asm = (end_t - start_t) / iterations;

    printf("Размер области: %dx%d\n", out_w, out_h);
    printf("C Time:   %.6f sec\n", time_c);
    printf("ASM Time: %.6f sec\n", time_asm);

    if (!stbi_write_png(output_file, out_w, out_h, channels, out_img_c, row_bytes)) {
        printf("Ошибка: не удалось сохранить файл.\n");
    }

    free(out_img_c);
    free(out_img_asm);
    stbi_image_free(img);
    return 0;
}
