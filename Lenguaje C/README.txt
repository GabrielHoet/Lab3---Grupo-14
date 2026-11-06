# Algoritmo de Logaritmo y Cambio de Base (Punto Fijo Q8.7)

Implementación en lenguaje C de una función de logaritmo natural y cambio de base optimizada para sistemas digitales, utilizando aritmética de punto fijo y el algoritmo de Borchardt.

--------------------------------------------------------------------------------

1. Formato de Punto Fijo (Q8.7)
* ¿Cómo funciona? Usa números enteros de 16 bits donde los últimos 7 bits representan la parte decimal y el resto la parte entera.
* Escala: Se multiplica todo por 128 (2^7).
  - Ej: 1.0 se almacena como 128.
  - Ej: 2.0 se almacena como 256.

--------------------------------------------------------------------------------

2. Rango de Valores de Entrada
* Valores aceptados: Cualquier número real positivo para x y para la base b.
* Normalización: El código toma el número y lo ajusta automáticamente mediante desplazamientos de bits (>> y <<) para dejarlo siempre dentro del rango [1.0, 2.0), que es el rango que maneja de forma ultra rápida la tabla interna de raíces (tablaSqrt).

--------------------------------------------------------------------------------

3. Rango de Valores de Salida
* Resultado: Devuelve un número entero (int16_t) en formato Q8.7.
* Cómo pasarlo a decimal: Para ver el resultado real en pantalla, simplemente se toma el valor entero obtenido y se divide entre 128.0.

--------------------------------------------------------------------------------

4. Cómo verificar el funcionamiento
1. Compilar el programa:
   gcc log_borchardt.c -o log_borchardt

2. Ejecutarlo:
   ./log_borchardt

3. Probar con valores de ejemplo (por ejemplo, x = 8 y base b = 2 debería dar un resultado decimal de 3.0).
