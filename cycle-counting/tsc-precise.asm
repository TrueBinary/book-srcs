;
; Contador de ciclos mais "preciso", de acordo com a latência documentada
; pelo manual de otimização da Intel.
;
; Forma de uso:
;
;   TSC_READ_START();
;   f();  /* função sob teste. */
;   c = TSC_READ_END();
;
; 'c' conterá a quantidade de ciclos gastos APENAS pela chamada à função 'f'.
;
; Os alinhamentos são usados para não termos fragmentação no cache L1.
;

bits 64

; Este valor é calculado com base na latência das instruções, de acordo com
; o manual de otimização da Intel. Ele também foi verificado através da
; rotina de teste no diretório ./tests/ usando:
;
;   $ for i in {1..100}; do ./test; done
;
; O menor valor lido foi de 48, o maior foi de 112. O valor 52 aparece em
; minhas medidas algumas vezes e é condizente com o calculo do gasto dos 13.5 ciclos de máquina.
;
WASTED_CYCLES equ 52

section .data
; Essas variáveis temporárias não são exportadas!
;
; Declarações equivalentes:
;   static unsigned long count, tmp;
;
        align 8
count:  dq    0
tmp:    dq    0

section .text

global TSC_READ_START:function
global TSC_READ_END:function

  align 8
; Protótipo:
;   void TSC_READ_START(void);
;
TSC_READ_START:
  push  rbx
  prefetchw [count]   ; Tenta garantir que as duas variáveis temporárias
                      ; estejam no cache e prontas para serem escritas.
  cpuid
  rdtsc
  mov   [count],eax   ; 1.5 ciclos
  mov   [count+4],edx ; 1.5 ciclos
  pop   rbx           ; 1.5 ciclos
  ret                 ; 8 ciclos.

; Protótipo:
;   unsigned long TSC_READ_END(void);
;
  align 8
TSC_READ_END:
                      ; call para essa função toma 1 ciclo.
  rdtscp
  mov   [tmp],eax
  mov   [tmp+4],edx
  push  rbx
  cpuid
  mov   rax,[count]
  sub   rax,[tmp]
  sub   rax,WASTED_CYCLES  ; subtrai todos os "13.5" ciclos "extras".

  ; if (rax <= 0)
  ;   rax = 1;
  jg    .L1
  mov   rax,1
.L1:

  pop   rbx
  ret
