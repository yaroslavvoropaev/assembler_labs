#include <stdint.h>

// in_ptr - указатель на начало вырезаемой области в исходном изображении
// out_ptr - указатель на начало буфера результата
// in_stride - ширина исходного изображения в байтах (width * channels)
// row_bytes - ширина вырезаемой области в байтах (out_w * channels)
// out_h - высота вырезаемой области
void crop_c(const uint8_t* in_ptr, uint8_t* out_ptr, int in_stride, int row_bytes, int out_h) {
    for (int y = 0; y < out_h; ++y) {
        for (int x = 0; x < row_bytes; ++x) {
            out_ptr[y * row_bytes + x] = in_ptr[y * in_stride + x];
        }
    }
}
