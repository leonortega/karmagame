# Tasks

## 1. Scaffold y HUD base

- [x] 1.1 Crear `index.html` (canvas 960×600, HUD vida/karma/PA/tiempo/especie, log 5 entradas, overlay juicio con botón) y verificar que abre en navegador sin errores de consola
- [x] 1.2 Crear `style.css` (barras, polaridad karma, log good/bad/info, overlay) y verificar visualmente HUD legible a 960px
- [x] 1.3 Crear `game.js` con `SPECIES`, `TUNING`, `newRun`, game-loop con `dt` clamp y `node --check game.js` pasando sin errores

## 2. Karma-core (atributos y decisiones)

- [x] 2.1 Implementar drenaje de hambre y muerte a Vida 0 que abre juicio, y verificar que sin comer la Vida cae ~16 en 10s y al llegar a 0 aparece el overlay
- [x] 2.2 Implementar clamp de Karma -100…+100 y PA por supervivencia (~20/min), y verificar forzando valores extremos que el clamp y el acumulado por 60s son correctos
- [x] 2.3 Implementar comer sostenible (+15 Vida/+5 PA) vs último fruto (+20 Vida/-15 Karma, arbusto muerto permanente), y verificar ambos casos más que el arbusto no regenera en la misma vida
- [x] 2.4 Implementar grito altruista (+30 Karma/+50 PA, cd 10s, lure 5s) con Oruga bloqueada y picado de Halcón (+5/+10/+10 con repeler), y verificar cada rama incluyendo grito en cooldown ignorado

## 3. Ecosistema 2D

- [x] 3.1 Implementar mundo 1600×1200, cámara seguidora con clamp y controles WASD/flechas+E/Q/R, y verificar que el jugador no sale de bordes y la cámara no muestra fuera del mundo
- [x] 3.2 Implementar 7 arbustos × 3 frutos con spawn por vida y render vivo/muerto, y verificar conteo inicial y estado gris permanente al agotar
- [x] 3.3 Implementar 3 depredadores (vagar/perseguir, daño 28 + invuln 1s, Oruga con +velocidad rival) y verificar persecución al acercarse y un solo golpe por segundo
- [x] 3.4 Implementar 4 congéneres (vagar/huir tras grito) y render de visión del jugador, y verificar que tras Q huyen de depredadores

## 4. Reencarnación y juicio

- [x] 4.1 Implementar matriz (Halcón si Karma≥50 y PA≥100; Oruga si Karma≤-50; si no lateral Ratón↔Ardilla) con texto de razón, y verificar los tres casos con valores límite (50/100, -50, neutral)
- [x] 4.2 Implementar arrastre (Karma 20% redondeado, PA intacta) y regeneración de mundo con Vida llena, y verificar que +50/-50 previos arrancan en +10/-10 con misma PA y entidades frescas
- [x] 4.3 Implementar overlay de juicio (stats, razón, siguiente forma, últimas 4 causas, botón + tecla R) y log causal con polaridad, y verificar que la información coincide con la vida recién terminada

## 5. Verificación de jugabilidad y balance

- [x] 5.1 Jugar ruta egoísta (agotar arbustos hasta morir) y verificar que el juicio ofrece Oruga con razón de involución
- [x] 5.2 Jugar ruta altruista sin gastar (2 gritos + sobrevivir ~2 min hasta PA≥100 y Karma≥50) y verificar que el juicio ofrece Halcón
- [x] 5.3 Ejecutar `openspec validate "karma-reincarnation-mvp" --strict` y verificar cero errores antes de dar por listo el apply

## 6. Tienda mid-life (PA como moneda)

- [x] 6.1 Implementar wallet de PA (débito inmediato, rechazo sin fondos, nunca negativa) y verificar comprando con saldo exacto, insuficiente y doble compra del mismo stat
- [x] 6.2 Implementar overlay de tienda en tiempo real (tecla B abre/cierra, 1-4 compra, Escape cierra, mundo sigue vivo) y verificar que un depredador puede dañar mientras la tienda está abierta y que morir con la tienda abierta abre el juicio
- [x] 6.3 Implementar las 4 adaptaciones per-life no apilables (zarpas 50, estómago 30, olfato 25, voz 35 con lure 2s en el siguiente grito) y verificar cada efecto más que la muerte las elimina
- [x] 6.4 Implementar Choose-form 15 PA en el juicio y matriz con saldo restante, y verificar que gastar 50 de 120 PA deja 70 y bloquea el ascenso, y que elegir forma descuenta del saldo arrastrado
