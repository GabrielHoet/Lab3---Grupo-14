; =============================================================================
; CALCULADORA DE LOGARITMO EN CUALQUIER BASE (Q8.7 - ALGORITMO DE BORCHARDT)
; Arquitectura: LC-3 Assembly
; Formato Punto Fijo: Q8.7 (1.0 = 128 / x0080, 2.0 = 256 / x0100)
; =============================================================================
; Rango de entrada: x > 0 (representado en Q8.7)
; Propiedad: log_b(x) = ln(x) / ln(b)
; Reducción de Rango: ln(x) = ln(m) + k * ln(2),  m en [1.0, 2.0)
; =============================================================================

        .ORIG x3000

; -----------------------------------------------------------------------------
; PROGRAMA PRINCIPAL (MAIN DE PRUEBA)
; -----------------------------------------------------------------------------
MAIN
        ; 1. Calcular ln(x)
        LD R0, INPUT_X              ; R0 = x_q8_7
        JSR LN_GENERAL_Q8_7
        ST R0, RESULT_LN_X          ; Guardar ln(x)

        ; 2. Calcular ln(b)
        LD R0, INPUT_BASE           ; R0 = base_q8_7
        JSR LN_GENERAL_Q8_7
        ST R0, RESULT_LN_BASE       ; Guardar ln(b)

        ; 3. Realizar Cambio de Base: log_b(x) = (ln(x) << 7) / ln(b)
        LD R0, RESULT_LN_X
        LD R1, RESULT_LN_BASE
        
        ; Chequeo de división por cero
        ADD R1, R1, #0
        BRz DIV_BY_ZERO

        JSR CALC_LOG_BASE_Q8_7
        ST R0, RESULT_LOG_B_X
        HALT

DIV_BY_ZERO
        LD R0, MASK_ERR
        ST R0, RESULT_LOG_B_X
        HALT

; -----------------------------------------------------------------------------
; VARIABLES DE PRUEBA Y RESULTADOS
; -----------------------------------------------------------------------------
INPUT_X         .FILL #256          ; Ejemplo: x = 2.0 en Q8.7 (2.0 * 128 = 256)
INPUT_BASE      .FILL #1280         ; Ejemplo: b = 10.0 en Q8.7 (10.0 * 128 = 1280)
RESULT_LN_X     .BLKW #1            ; Almacena ln(x) en Q8.7
RESULT_LN_BASE  .BLKW #1            ; Almacena ln(b) en Q8.7
RESULT_LOG_B_X  .BLKW #1            ; Almacena log_b(x) en Q8.7
MASK_ERR        .FILL xFFFF

; =============================================================================
; SUBRUTINA: LN_GENERAL_Q8_7
; Entrada:  R0 = x_q8_7 (entero Q8.7)
; Salida:   R0 = ln(x) (entero Q8.7)
; =============================================================================
LN_GENERAL_Q8_7
        ST R7, LNG_SAVE_R7
        ST R1, LNG_SAVE_R1
        ST R2, LNG_SAVE_R2
        ST R3, LNG_SAVE_R3
        ST R4, LNG_SAVE_R4

        ADD R1, R0, #0              ; R1 = x_norm
        AND R2, R2, #0              ; R2 = k = 0

        LD R3, VAL_Q_TWO            ; R3 = 256

        ; Bucle 1: while (x_norm >= 256) { x_norm >>= 1; k++; }
LNG_LOOP_UP
        NOT R4, R3
        ADD R4, R4, #1              ; R4 = -256
        ADD R4, R1, R4              ; x_norm - 256
        BRn LNG_CHECK_DOWN          ; Si x_norm < 256, salir del bucle 1

        ; x_norm >>= 1
        ADD R0, R1, #0
        JSR SHIFT_RIGHT_1
        ADD R1, R0, #0
        ADD R2, R2, #1              ; k++
        BR LNG_LOOP_UP

LNG_CHECK_DOWN
        LD R3, VAL_Q_ONE            ; R3 = 128
        ; Bucle 2: while (x_norm < 128) { x_norm <<= 1; k--; }
LNG_LOOP_DOWN
        NOT R4, R3
        ADD R4, R4, #1              ; R4 = -128
        ADD R4, R1, R4              ; x_norm - 128
        BRzp LNG_EVAL_KERNEL        ; Si x_norm >= 128, salir del bucle 2

        ADD R1, R1, R1              ; x_norm <<= 1
        ADD R2, R2, #-1             ; k--
        BR LNG_LOOP_DOWN

LNG_EVAL_KERNEL
        ; 1. Evaluar borchardt_kernel(x_norm)
        ADD R0, R1, #0              ; Pasar x_norm en R0
        JSR BORCHARDT_KERNEL        ; Retorna ln(m) en R0

        ; 2. Calcular k * LN2_Q8_7 (89)
        ST R0, LNG_TEMP_LNM
        ADD R0, R2, #0              ; R0 = k
        LD R1, CONST_LN2            ; R1 = 89
        JSR MULT_SIGNED             ; R0 = k * 89

        ; 3. Recomposición: ln_m + (k * 89)
        LD R1, LNG_TEMP_LNM
        ADD R0, R0, R1              ; R0 = ln_m + (k * 89)

        LD R7, LNG_SAVE_R7
        LD R1, LNG_SAVE_R1
        LD R2, LNG_SAVE_R2
        LD R3, LNG_SAVE_R3
        LD R4, LNG_SAVE_R4
        RET

LNG_SAVE_R7     .BLKW #1
LNG_SAVE_R1     .BLKW #1
LNG_SAVE_R2     .BLKW #1
LNG_SAVE_R3     .BLKW #1
LNG_SAVE_R4     .BLKW #1
LNG_TEMP_LNM    .BLKW #1
VAL_Q_ONE       .FILL #128
VAL_Q_TWO       .FILL #256
CONST_LN2       .FILL #89

; =============================================================================
; SUBRUTINA: BORCHARDT_KERNEL
; Entrada:  R0 = x_norm (en rango [128, 255])
; Salida:   R0 = ln(x_norm) en Q8.7
; =============================================================================
BORCHARDT_KERNEL
        ST R7, BK_SAVE_R7
        ST R1, BK_SAVE_R1
        ST R2, BK_SAVE_R2
        ST R3, BK_SAVE_R3
        ST R4, BK_SAVE_R4
        ST R5, BK_SAVE_R5

        ST R0, BK_X_NORM            ; Guardar x_norm original

        ; a = (x_norm + 128) >> 1
        LD R1, VAL_Q_ONE
        ADD R0, R0, R1
        JSR SHIFT_RIGHT_1
        ST R0, BK_A                 ; BK_A = a

        ; b = leer_raiz_norm_Q8_7(x_norm)
        LD R0, BK_X_NORM
        JSR LEER_RAIZ_NORM_Q8_7
        ST R0, BK_B                 ; BK_B = b

        ; Bucle 4 iteraciones
        AND R5, R5, #0              ; R5 = contador i = 0

BK_FOR_LOOP
        ADD R4, R5, #-4
        BRzp BK_LOOP_END            ; Si i >= 4, salir

        ; nuevoA = (a + b) >> 1
        LD R0, BK_A
        LD R1, BK_B
        ADD R0, R0, R1
        JSR SHIFT_RIGHT_1
        ST R0, BK_NUEVO_A

        ; prod = (nuevoA * b + 64) >> 7
        LD R0, BK_NUEVO_A
        LD R1, BK_B
        JSR MULT_UNSIGNED           ; R0 = nuevoA * b
        LD R1, CONST_64
        ADD R0, R0, R1              ; + 64 (redondeo)
        JSR SHIFT_RIGHT_7           ; >> 7
        ST R0, BK_PROD

        ; nuevoB = leer_raiz_norm_Q8_7(prod)
        JSR LEER_RAIZ_NORM_Q8_7
        ST R0, BK_NUEVO_B

        ; a = nuevoA, b = nuevoB
        LD R0, BK_NUEVO_A
        ST R0, BK_A
        LD R0, BK_NUEVO_B
        ST R0, BK_B

        ADD R5, R5, #1              ; i++
        BR BK_FOR_LOOP

BK_LOOP_END
        ; M = (a + b) >> 1
        LD R0, BK_A
        LD R1, BK_B
        ADD R0, R0, R1
        JSR SHIFT_RIGHT_1
        ST R0, BK_M                 ; BK_M = M

        ; num = ((x_norm - 128) << 7) + (M >> 1)
        LD R0, BK_X_NORM
        LD R1, VAL_Q_ONE
        NOT R1, R1
        ADD R1, R1, #1
        ADD R0, R0, R1              ; x_norm - 128
        JSR SHIFT_LEFT_7            ; << 7
        
        LD R1, BK_M
        ST R0, BK_TEMP_NUM
        ADD R0, R1, #0
        JSR SHIFT_RIGHT_1           ; M >> 1
        LD R1, BK_TEMP_NUM
        ADD R0, R0, R1              ; num en R0

        ; return num / M
        LD R1, BK_M
        JSR DIV_UNSIGNED            ; R0 = num / M

        LD R7, BK_SAVE_R7
        LD R1, BK_SAVE_R1
        LD R2, BK_SAVE_R2
        LD R3, BK_SAVE_R3
        LD R4, BK_SAVE_R4
        LD R5, BK_SAVE_R5
        RET

BK_SAVE_R7      .BLKW #1
BK_SAVE_R1      .BLKW #1
BK_SAVE_R2      .BLKW #1
BK_SAVE_R3      .BLKW #1
BK_SAVE_R4      .BLKW #1
BK_SAVE_R5      .BLKW #1
BK_X_NORM       .BLKW #1
BK_A            .BLKW #1
BK_B            .BLKW #1
BK_NUEVO_A      .BLKW #1
BK_NUEVO_B      .BLKW #1
BK_PROD         .BLKW #1
BK_M            .BLKW #1
BK_TEMP_NUM     .BLKW #1
CONST_64        .FILL #64

; =============================================================================
; SUBRUTINA: LEER_RAIZ_NORM_Q8_7
; Entrada:  R0 = x_norm
; Salida:   R0 = valor LUT
; =============================================================================
LEER_RAIZ_NORM_Q8_7
        ST R1, LR_SAVE_R1
        ST R2, LR_SAVE_R2

        ; R1 = -128
        LD R1, CONST_NEG_128
        ADD R2, R0, R1              ; R2 = x_norm - 128
        
        ; if (x_norm <= 128) -> (x_norm - 128 <= 0)
        BRp LR_CHECK_MAX
        LD R0, VAL_Q_ONE            ; return 128
        BR LR_DONE

LR_CHECK_MAX
        ; if (x_norm >= 255) return tablaSqrt[127]
        LD R2, CONST_255
        NOT R2, R2
        ADD R2, R2, #1              ; -255
        ADD R2, R0, R2              ; x_norm - 255
        BRn LR_LOOKUP
        LEA R1, TABLA_SQRT
        LD R2, CONST_127
        ADD R1, R1, R2
        LDR R0, R1, #0
        BR LR_DONE

LR_LOOKUP
        ; return tablaSqrtQ8_7[x_norm - 128]
        LEA R1, TABLA_SQRT
        LD R2, CONST_NEG_128
        ADD R2, R0, R2              ; Offset = x_norm - 128
        ADD R1, R1, R2
        LDR R0, R1, #0

LR_DONE
        LD R1, LR_SAVE_R1
        LD R2, LR_SAVE_R2
        RET

LR_SAVE_R1      .BLKW #1
LR_SAVE_R2      .BLKW #1
CONST_255       .FILL #255
CONST_127       .FILL #127
CONST_NEG_128   .FILL #-128

; =============================================================================
; SUBRUTINA: CALC_LOG_BASE_Q8_7
; Entrada:  R0 = ln(x) [Q8.7], R1 = ln(b) [Q8.7]
; Salida:   R0 = log_b(x) [Q8.7]
; =============================================================================
CALC_LOG_BASE_Q8_7
        ST R7, CLB_SAVE_R7
        ST R1, CLB_SAVE_R1
        ST R2, CLB_SAVE_R2
        ST R3, CLB_SAVE_R3
        ST R4, CLB_SAVE_R4

        ADD R2, R0, #0              ; R2 = num = ln(x)
        ADD R3, R1, #0              ; R3 = den = ln(b)

        ; num = num << 7
        ADD R0, R2, #0
        JSR SHIFT_LEFT_7
        ADD R2, R0, #0              ; R2 = num << 7

        ; Redondeo: determinar signo del resultado (num ^ den)
        ; Si num y den tienen el mismo signo, sumar den/2; si no, restar den/2
        ADD R0, R3, #0
        JSR SHIFT_RIGHT_1           ; R0 = den / 2
        
        ; Test de signos
        ADD R4, R2, #0
        BRzp CLB_NUM_POS
        ; num es negativo
        ADD R3, R3, #0
        BRn CLB_SAME_SIGN
        BR CLB_DIFF_SIGN

CLB_NUM_POS
        ; num es positivo/cero
        ADD R3, R3, #0
        BRzp CLB_SAME_SIGN
        BR CLB_DIFF_SIGN

CLB_SAME_SIGN
        ADD R2, R2, R0              ; num += den/2
        BR CLB_DO_DIV

CLB_DIFF_SIGN
        NOT R0, R0
        ADD R0, R0, #1              ; -(den/2)
        ADD R2, R2, R0              ; num -= den/2

CLB_DO_DIV
        ADD R0, R2, #0
        ADD R1, R3, #0
        JSR DIV_SIGNED              ; R0 = num / den

        LD R7, CLB_SAVE_R7
        LD R1, CLB_SAVE_R1
        LD R2, CLB_SAVE_R2
        LD R3, CLB_SAVE_R3
        LD R4, CLB_SAVE_R4
        RET

CLB_SAVE_R7     .BLKW #1
CLB_SAVE_R1     .BLKW #1
CLB_SAVE_R2     .BLKW #1
CLB_SAVE_R3     .BLKW #1
CLB_SAVE_R4     .BLKW #1

; =============================================================================
; SUBRUTINAS MATEMÁTICAS AUXILIARES (SHIFT, MULT, DIV)
; =============================================================================

; -----------------------------------------------------------------------------
; SHIFT_RIGHT_1: R0 = R0 >> 1 (Lógico no signado)
; -----------------------------------------------------------------------------
SHIFT_RIGHT_1
        ST R1, SR1_R1
        ST R7, SR1_R7

        ADD R1, R0, #0              ; R1 = dividendo
        ADD R0, R1, #0              ; R0 = dividendo
        AND R1, R1, #0
        ADD R1, R1, #2              ; R1 = divisor 2
        JSR DIV_UNSIGNED            ; R0 = R0 / 2

        LD R1, SR1_R1
        LD R7, SR1_R7
        RET

SR1_R1          .BLKW #1
SR1_R7          .BLKW #1

; -----------------------------------------------------------------------------
; SHIFT_RIGHT_7: R0 = R0 >> 7 (Lógico no signado)
; -----------------------------------------------------------------------------
SHIFT_RIGHT_7
        ST R1, SR7_R1
        ST R7, SR7_R7

        LD R1, CONST_128_DIV
        JSR DIV_UNSIGNED            ; R0 = R0 / 128

        LD R1, SR7_R1
        LD R7, SR7_R7
        RET

SR7_R1          .BLKW #1
SR7_R7          .BLKW #1
CONST_128_DIV   .FILL #128

; -----------------------------------------------------------------------------
; SHIFT_LEFT_7: R0 = R0 << 7
; -----------------------------------------------------------------------------
SHIFT_LEFT_7
        ADD R0, R0, R0              ; << 1
        ADD R0, R0, R0              ; << 2
        ADD R0, R0, R0              ; << 3
        ADD R0, R0, R0              ; << 4
        ADD R0, R0, R0              ; << 5
        ADD R0, R0, R0              ; << 6
        ADD R0, R0, R0              ; << 7
        RET

; -----------------------------------------------------------------------------
; MULT_UNSIGNED: R0 = R0 * R1 (16 bits)
; -----------------------------------------------------------------------------
MULT_UNSIGNED
        ST R1, MU_R1
        ST R2, MU_R2
        ST R3, MU_R3

        ADD R2, R0, #0              ; R2 = multiplicando
        ADD R3, R1, #0              ; R3 = multiplicador
        AND R0, R0, #0              ; R0 = acumulador = 0

MU_LOOP
        ADD R3, R3, #0
        BRz MU_DONE
        ADD R0, R0, R2
        ADD R3, R3, #-1
        BR MU_LOOP

MU_DONE
        LD R1, MU_R1
        LD R2, MU_R2
        LD R3, MU_R3
        RET

MU_R1           .BLKW #1
MU_R2           .BLKW #1
MU_R3           .BLKW #1

; -----------------------------------------------------------------------------
; MULT_SIGNED: R0 = R0 * R1 (16 bits signado)
; -----------------------------------------------------------------------------
MULT_SIGNED
        ST R7, MS_R7
        ST R2, MS_R2
        ST R3, MS_R3
        ST R4, MS_R4

        AND R4, R4, #0              ; Flag de signo
        ADD R2, R0, #0
        BRzp MS_CHECK_R1
        NOT R2, R2
        ADD R2, R2, #1              ; |R0|
        ADD R4, R4, #1

MS_CHECK_R1
        ADD R3, R1, #0
        BRzp MS_DO_MULT
        NOT R3, R3
        ADD R3, R3, #1              ; |R1|
        ADD R4, R4, #1

MS_DO_MULT
        ADD R0, R2, #0
        ADD R1, R3, #0
        JSR MULT_UNSIGNED           ; R0 = |R0| * |R1|

        AND R4, R4, #1              ; Si el total de negativos fue 1
        BRz MS_DONE
        NOT R0, R0
        ADD R0, R0, #1              ; Negar resultado

MS_DONE
        LD R7, MS_R7
        LD R2, MS_R2
        LD R3, MS_R3
        LD R4, MS_R4
        RET

MS_R7           .BLKW #1
MS_R2           .BLKW #1
MS_R3           .BLKW #1
MS_R4           .BLKW #1

; -----------------------------------------------------------------------------
; DIV_UNSIGNED: R0 = R0 / R1 (Cociente entero no signado)
; -----------------------------------------------------------------------------
DIV_UNSIGNED
        ST R2, DU_R2
        ST R3, DU_R3
        ST R4, DU_R4

        ADD R2, R0, #0              ; Dividendo
        ADD R3, R1, #0              ; Divisor
        AND R0, R0, #0              ; Cociente = 0

        ADD R3, R3, #0
        BRz DU_DONE                 ; Protección div por 0

        NOT R3, R3
        ADD R3, R3, #1              ; -Divisor

DU_LOOP
        ADD R4, R2, R3              ; Dividendo - Divisor
        BRn DU_DONE
        ADD R2, R4, #0              ; Actualizar dividendo
        ADD R0, R0, #1              ; Cociente++
        BR DU_LOOP

DU_DONE
        LD R2, DU_R2
        LD R3, DU_R3
        LD R4, DU_R4
        RET

DU_R2           .BLKW #1
DU_R3           .BLKW #1
DU_R4           .BLKW #1

; -----------------------------------------------------------------------------
; DIV_SIGNED: R0 = R0 / R1 (Cociente entero signado)
; -----------------------------------------------------------------------------
DIV_SIGNED
        ST R7, DS_R7
        ST R2, DS_R2
        ST R3, DS_R3
        ST R4, DS_R4

        AND R4, R4, #0              ; Signo flag
        ADD R2, R0, #0
        BRzp DS_CHECK_R1
        NOT R2, R2
        ADD R2, R2, #1              ; |R0|
        ADD R4, R4, #1

DS_CHECK_R1
        ADD R3, R1, #0
        BRzp DS_DO_DIV
        NOT R3, R3
        ADD R3, R3, #1              ; |R1|
        ADD R4, R4, #1

DS_DO_DIV
        ADD R0, R2, #0
        ADD R1, R3, #0
        JSR DIV_UNSIGNED

        AND R4, R4, #1
        BRz DS_DONE
        NOT R0, R0
        ADD R0, R0, #1              ; Negar cociente

DS_DONE
        LD R7, DS_R7
        LD R2, DS_R2
        LD R3, DS_R3
        LD R4, DS_R4
        RET

DS_R7           .BLKW #1
DS_R2           .BLKW #1
DS_R3           .BLKW #1
DS_R4           .BLKW #1

; =============================================================================
; TABLA DE RAÍCES CUADRADAS (LUT - 128 PALABRAS EN MEMORIA EN FORMATO Q8.7)
; Corresponde a los índices de x_norm entre 128 (1.0) y 255 (~1.992)
; =============================================================================
TABLA_SQRT
        .FILL #128
        .FILL #128
        .FILL #129
        .FILL #129
        .FILL #130
        .FILL #130
        .FILL #131
        .FILL #131
        .FILL #132
        .FILL #132
        .FILL #133
        .FILL #133
        .FILL #134
        .FILL #134
        .FILL #135
        .FILL #135
        .FILL #136
        .FILL #136
        .FILL #137
        .FILL #137
        .FILL #138
        .FILL #138
        .FILL #139
        .FILL #139
        .FILL #140
        .FILL #140
        .FILL #141
        .FILL #141
        .FILL #142
        .FILL #142
        .FILL #143
        .FILL #143
        .FILL #144
        .FILL #144
        .FILL #145
        .FILL #145
        .FILL #146
        .FILL #146
        .FILL #147
        .FILL #147
        .FILL #148
        .FILL #148
        .FILL #149
        .FILL #149
        .FILL #150
        .FILL #150
        .FILL #151
        .FILL #151
        .FILL #152
        .FILL #152
        .FILL #153
        .FILL #153
        .FILL #154
        .FILL #154
        .FILL #155
        .FILL #155
        .FILL #156
        .FILL #156
        .FILL #157
        .FILL #157
        .FILL #158
        .FILL #158
        .FILL #159
        .FILL #159
        .FILL #160
        .FILL #160
        .FILL #161
        .FILL #161
        .FILL #162
        .FILL #162
        .FILL #163
        .FILL #163
        .FILL #164
        .FILL #164
        .FILL #165
        .FILL #165
        .FILL #166
        .FILL #166
        .FILL #167
        .FILL #167
        .FILL #168
        .FILL #168
        .FILL #169
        .FILL #169
        .FILL #170
        .FILL #170
        .FILL #171
        .FILL #171
        .FILL #172
        .FILL #172
        .FILL #173
        .FILL #173
        .FILL #174
        .FILL #174
        .FILL #175
        .FILL #175
        .FILL #176
        .FILL #176
        .FILL #177
        .FILL #177
        .FILL #178
        .FILL #178
        .FILL #179
        .FILL #179
        .FILL #180
        .FILL #180
        .FILL #180
        .FILL #181
        .FILL #181
        .FILL #182
        .FILL #182
        .FILL #183
        .FILL #183
        .FILL #184
        .FILL #184
        .FILL #185
        .FILL #185
        .FILL #185
        .FILL #186
        .FILL #186
        .FILL #187
        .FILL #187
        .FILL #187
        .FILL #188
        .FILL #188
        .FILL #189
        .FILL #189
        .FILL #190

        .END
