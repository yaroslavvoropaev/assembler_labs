#include "stdlib.h"
#include "stdint.h"
#include "stddef.h"

const int8_t Gx[3][3] = {
	{-1, 0, 1},
	{-2, 0, 2},
	{-1, 0, 1}
};

const int8_t Gy[3][3] = {
	{-1, -2, -1},
	{ 0,  0,  0},
	{ 1,  2,  1}
};

void sobel_c(uint8_t *source_image, uint8_t *result_image, size_t width, size_t height) {
	for (int y = 1; y < height - 1; y++) {
	    for (int x = 1; x < width - 1; x++) {
		    int gx = 0, gy = 0;

			for (int8_t ky = -1; ky <= 1; ky++) {
				for (int8_t kx = -1; kx <= 1; kx++) {
				    int pixel = source_image[(y + ky) * width + x + kx];
					gx += pixel * Gx[ky + 1][kx + 1];
					gy += pixel * Gy[ky + 1][kx + 1];
				}
			}

			gx = gx < 0 ? -gx : gx;
			gy = gy < 0 ? -gy : gy;

			size_t newPixel = gx + gy;
			newPixel = newPixel > 255 ? 255 : newPixel;
			result_image[y * width + x] = (unsigned char) newPixel;
		}
	}
}

