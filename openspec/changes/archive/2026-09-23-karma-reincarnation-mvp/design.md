# Design

## Context

Repo sin código (solo `openspec/`); se parte de cero con web vanilla para validar reglas antes de Godot. Ver `proposal.md` para motivación y `specs/` para contratos de comportamiento.

## Goals / Non-Goals

**Goals:**
- Un solo archivo JS de game-loop (`requestAnimationFrame`, `dt` clamp 0.05) con estado `state` por vida y constantes `TUNING` ajustables.
- Feedback causal inmediato (HUD + log + overlay de juicio con historial).
- Balance inicial que permita ascenso en ~2-3 min con 2 gritos y castigue agotar arbustos.

**Non-Goals:**
- Sin sprites/animaciones, sonido, persistencia en disco, backend, ni editor de niveles.
- Sin reproducción, linajes, ni migración a Godot (cambios futuros separados).

## Decisions

- **Web vanilla Canvas 2D sobre Godot directo:** cero instalación, abrir `index.html` basta; se porta la matriz ya validada. Alternativa Godot 4 descartada para MVP por fricción de setup.
- **Mundo 1600×1200 + cámara centrada, canvas 960×600:** suficiente para persecución/visión diferencial sin minimapa. Alternativa mundo = canvas descartada (no se aprecia visión del Halcón).
- **Estado por vida con `carryKarma/carryPa` explícitos:** `newRun(species, carryKarma, carryPa)`; juicio calcula `pendingNext`; reencarnar regenera mundo y aplica arrastre. Alternativa estado global mutable descartada por fugas entre vidas.
- **Tuning como tabla única:** `hungerPerSec 1.6, paPerSec 1/3, predatorDamage 28/invuln 1s, shout +30/+50 cd 10s lure 5s/450px, umbrales +50/100 y -50`. Un solo punto de balanceo.
- **Depredador vagar/perseguir por distancia + lure:** sin pathfinding; Oruga sufre +25 velocidad enemiga como presión de castigo. Suficiente para MVP.
- **Especies como datos (speed/vision/maxHp/radius/color):** Oruga 80/130/60, Ratón 150/190/100, Ardilla 175/210/90, Halcón 215/340/140 con picado que repele.
- **Tienda mid-life en tiempo real (tecla B, compra con 1-4):** el mundo sigue vivo (depredadores cazan, hambre drena) para extender el lenguaje de riesgo del grito; pausar rompería esa tensión. Alternativa tienda pausada descartada por segura y anticlimática. UI solo-teclado para comprar en <2s.
- **Adaptaciones per-life, una compra por stat, sin apilado:** zarpas 50 / estómago 30 / olfato 25 / voz 35; todo se pierde al morir. Alternativa permanente cross-life descartada porque reintroduce el trinquete de PA tras 3-4 vidas. Ninguna habilidad otorga karma: PA compra capacidad, el karma se gana.
- **Matriz evalúa saldo restante + Choose-form 15 PA en juicio:** gastar retrasa el ascenso (tradeoff real); elegir lateral da agencia sin romper el ping-pong base.

## Risks / Trade-offs

- [Halcón demasiado dominante] → Mitigación: hambre igual para todos y cooldown de picado vía `hitCd`.
- [Tienda ilegible bajo presión] → Mitigación: 4 items máximo, una línea cada uno (tecla, costo, efecto, estado); sin mouse ni scroll.
- [Muerte comprando frustra] → Mitigación: la muerte cierra la tienda y abre juicio; el log registra la última compra para explicar el saldo evaluado.
- [Halcón + zarpas imparable] → Mitigación: precios ×1.5 para Halcón o tope de velocidad total (decidir en apply, sin cambiar specs).
- [Grindeo pasivo de PA] → Mitigación: 20 PA/min exige ~5 min sin actuar; umbral 100 + karma +50 fuerza jugar altruista.
- [Muerte injusta por spawn] → Mitigación: spawns aleatorios con distancia mínima al centro; invulnerabilidad 1s.
- [Lógica en un archivo crece] → Mitigación: separar por secciones (estado, juicio, acciones, update, render, HUD); extraer módulos solo si supera ~600 líneas.

## Migration Plan

N/A (greenfield). Rollback: borrar `index.html/style.css/game.js`. Futuro port a Godot reutiliza `specs/` sin cambios de comportamiento.
