# Proposal

## Why

Validar en semanas (no meses) si el loop nacer → decidir (egoísta/altruista) → morir → reencarnar es legible y divertido. Un MVP web 2D sin dependencias permite probar las reglas de karma antes de invertir en Godot/Unity 3D.

## What Changes

- Prototipo web 2D top-down jugable en canvas (960×600, mundo 1600×1200 con cámara).
- Tres atributos por criatura: Vida/Energía, Karma Ecológico (-100…+100), Puntos de Adaptación (PA).
- Nodos de comida (arbustos con 3 frutos, muerte permanente al agotar), 3 depredadores perseguidores, 4 congéneres.
- Dos decisiones instrumentadas: comer último fruto (egoísta) y gritar para alertar (altruista, con coste/beneficio).
- Tienda mid-life en tiempo real (tecla B, compra con 1-4): PA como moneda que se gasta en 4 adaptaciones per-life no apilables (zarpas 50, estómago 30, olfato 25, voz 35); el mundo sigue vivo mientras compras.
- Pantalla de Juicio con matriz de reencarnación sobre el saldo restante de PA y causa-efecto visible, más reencarnación en 4 formas (Oruga/Ratón/Ardilla/Halcón) con item Choose-form (15 PA) para elegir lateral.
- HUD (vida, karma, PA, tiempo, especie) y log de últimos 5 eventos.

## Capabilities

### New Capabilities

- `karma-core`: atributos Vida/Karma/PA, drenaje de hambre, ganancia de PA por supervivencia, wallet de PA con gasto sin deuda, 4 adaptaciones per-life no apilables, tuning configurable, clamp de rangos.
- `ecosystem-2d`: mundo, cámara, controles WASD/flechas+E/Q/B/1-4, overlay de tienda en tiempo real sin pausa, arbustos, depredadores con IA vagar/perseguir, congéneres, colisiones y daño con invulnerabilidad.
- `reincarnation`: matriz de juicio sobre saldo restante de PA (ascenso/lateral/involución), arrastre de karma 20% entre vidas, PA restante persistente, item Choose-form (15 PA), pantalla de juicio con historial causal y selección de siguiente especie.

### Modified Capabilities

Ninguna (proyecto sin specs previas).

## Impact

- Código nuevo: `index.html` (incluye overlay de tienda), `style.css`, `game.js` vanilla (cero dependencias).
- Sin APIs, backend ni migraciones. Riesgo bajo; balance inicial (precios 50/30/25/35/15) documentado en diseño y ajustable vía constantes.
