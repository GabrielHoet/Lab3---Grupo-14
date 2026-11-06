#include <stdio.h>
#include <stdint.h>

#define Q_ONE      128    /* 1.0 en Q8.7 */
#define Q_TWO      256    /* 2.0 en Q8.7 */
#define LN2_Q87    89     /* ln(2) en Q8.7 (~0.693 * 128) */

/* Tabla reducida de 128 elementos para el rango [1.0, 2.0) */
static const uint16_t tablaSqrt[128] = {
	128, 128, 129, 129, 130, 130, 131, 131, 132, 132, 133, 133, 134, 134, 135, 135,
		136, 136, 137, 137, 138, 138, 139, 139, 140, 140, 141, 141, 142, 142, 143, 143,
		144, 144, 145, 145, 146, 146, 147, 147, 148, 148, 149, 149, 150, 150, 151, 151,
		152, 152, 153, 153, 154, 154, 155, 155, 156, 156, 157, 157, 158, 158, 159, 159,
		160, 160, 161, 161, 162, 162, 163, 163, 164, 164, 165, 165, 166, 166, 167, 167,
		168, 168, 169, 169, 170, 170, 171, 171, 172, 172, 173, 173, 174, 174, 175, 175,
		176, 176, 177, 177, 178, 178, 179, 179, 180, 180, 180, 181, 181, 182, 182, 183,
		183, 184, 184, 185, 185, 185, 186, 186, 187, 187, 187, 188, 188, 189, 189, 190
};

/* 1. Lectura O(1) de la tabla */
static uint16_t leer_raiz(uint16_t x) {
	if (x <= 128) return 128;
	if (x >= 255) return tablaSqrt[127];
	return tablaSqrt[x - 128];
}

/* 2. Núcleo iterativo de Borchardt en rango [1.0, 2.0) */
static int16_t borchardt_kernel(uint16_t x) {
	uint16_t a = (x + Q_ONE) >> 1;
	uint16_t b = leer_raiz(x);
	
	for (int i = 0; i < 4; i++) {
		uint16_t nuevoA = (a + b) >> 1;
		uint16_t prod = (uint16_t)(((uint32_t)nuevoA * b + 64) >> 7);
		b = leer_raiz(prod);
		a = nuevoA;
	}
	
	uint16_t M = (a + b) >> 1;
	return (int16_t)((((int32_t)(x - Q_ONE) << 7) + (M >> 1)) / M);
}

/* 3. Logaritmo natural con normalización por desplazamientos */
int16_t ln_q87(int16_t x) {
	int16_t k = 0;
	while (x >= Q_TWO) { x >>= 1; k++; }
	while (x < Q_ONE)  { x <<= 1; k--; }
	return borchardt_kernel((uint16_t)x) + (k * LN2_Q87);
}

/* 4. División en Q8.7 para el cambio de base */
int16_t div_q87(int16_t num, int16_t den) {
	return (int16_t)(((int32_t)num << 7) / den);
}

/* 5. Logaritmo en cualquier base */
int16_t log_base_q87(int16_t x, int16_t base) {
	return div_q87(ln_q87(x), ln_q87(base));
}

int main(void) {
	float x_in, b_in;
	
	printf("Ingrese numero (x): ");
	scanf("%f", &x_in);
	printf("Ingrese base (b): ");
	scanf("%f", &b_in);
	
	/* Conversión limpia a Q8.7 */
	int16_t x_q87 = (int16_t)(x_in * 128.0f + 0.5f);
	int16_t b_q87 = (int16_t)(b_in * 128.0f + 0.5f);
	
	/* Cálculo */
	int16_t res_q87 = log_base_q87(x_q87, b_q87);
	
	/* Salida simplificada */
	printf("\nEntrada Q8.7 (entero): %d\n", x_q87);
	printf("Base Q8.7 (entero):    %d\n", b_q87);
	printf("Resultado Q8.7 (ent):  %d\n", res_q87);
	printf("Resultado decimal:     %.4f\n", (float)res_q87 / 128.0f);
	
	return 0;
}
