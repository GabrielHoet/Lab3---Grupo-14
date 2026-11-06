Calculadora de Logaritmo en Cualquier Base Algoritmo de Borchardt LC-3

Descripcion del Proyecto
Este programa implementa en lenguaje ensamblador de la arquitectura LC-3 el calculo de logaritmos en cualquier base, resolviendo la identidad matematica:
log_b(x) = ln(x) / ln(b)

Para el calculo del logaritmo natural ln, se utiliza el Algoritmo de Borchardt junto con reduccion de rango ln(x) = ln(m) + k * ln(2) donde m esta en el intervalo [1.0, 2.0) y una tabla de busqueda en memoria LUT de 128 elementos para las raices cuadradas.

Especificaciones Tecnicas y Formato

* Formato de Punto Fijo: Q8.7 (1 bit de signo, 8 bits para la parte entera y 7 bits para la parte fraccionaria).
  * Factor de escala: 1.0 = 128 (#128 en decimal o x0080 en hexadecimal).
  * Valor de prueba para x = 2.0: #256 (2.0 * 128).
  * Valor de prueba para la base b = 10.0: #1280 (10.0 * 128).

Rangos de Operacion y Precision

1. Rango de Entradas Validas:
   * x > 0 representado en formato Q8.7.
   * Base b > 0 y b diferente de 1 con proteccion contra division por cero.
2. Rango de Salidas:
   * El resultado se almacena en formato Q8.7 en la direccion de memoria designada (RESULT_LOG_B_X).
3. Precision Alcanzada:
   * La resolucion fraccionaria esta limitada a 7 bits (1/128 aprox 0.0078125).
   * Ejemplo de prueba integrada log_10(2.0):
     * Valor teorico aprox 0.3010
     * Valor obtenido por el programa: 39 / 128 aprox 0.3046 (error menor al 1 por ciento en la aproximacion por punto fijo).

Mapa de Memoria de Pruebas Main

* INPUT_X (x300D): #256 (x = 2.0)
* INPUT_BASE (x300E): #1280 (b = 10.0)
* RESULT_LN_X (x300F): #89 (ln(2.0) aprox 0.6953)
* RESULT_LN_BASE (x3010): #295 (ln(10.0) aprox 2.3046)
* RESULT_LOG_B_X (x3011): #39 (log_10(2.0) aprox 0.3046)

Estado de Pruebas
* Estado: Codigo probado y verificado exitosamente sin errores de ensamblado ni de ejecucion en el simulador oficial de LC-3.
