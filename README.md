<<<<<<< HEAD
# Proyecto 3 - Logística y Transporte de Envíos

## Archivo Markdown

Este archivo es un documento en formato Markdown. Markdown permite escribir texto con estructura simple usando títulos, listas y enlaces para que la documentación sea legible tanto en código como en vista previa.

Puedes abrirlo en línea en [markdownlivepreview.com](https://markdownlivepreview.com/) o instalar una extensión de visualización de Markdown en VS Code para verlo renderizado dentro del editor.

## Enlace del repositorio

Repositorio: ________________________________

## Objetivo del modelo

El modelo busca gestionar de forma consistente y trazable:

- clientes
- direcciones
- regiones
- rutas
- envíos
- seguimiento de eventos
- estados operativos
- métricas y reportes

## Contexto del diseño

La solución fue modelada con enfoque de Tercera Forma Normal (3FN), integridad referencial, trazabilidad histórica y facilidad de consulta analítica. El objetivo no es solo guardar datos, sino permitir operación, auditoría y consulta de negocio.

### Por qué existen las tablas

- `region`: agrupa las direcciones para facilitar reportes territoriales y segmentación geográfica.
- `direccion`: evita repetir datos de ubicación en cada envío y permite reutilizar puntos de origen o destino.
- `cliente`: centraliza la información de remitentes y destinatarios.
- `estado_envio`: define los estados operativos posibles del envío y evita valores inconsistentes.
- `tipo_evento_seguimiento`: clasifica el tipo de movimiento o evento registrado en la trazabilidad.
- `repartidor`: representa al actor operativo que ejecuta o registra eventos de seguimiento.
- `ruta`: modela el trayecto entre dos direcciones y soporta métricas logísticas.
- `envio`: concentra la transacción principal del negocio y enlaza cliente, dirección, ruta y estado actual.
- `seguimiento`: guarda el historial de eventos del envío para dar trazabilidad completa.
- `envio_evento_log`: funciona como bitácora complementaria para dejar evidencia de cambios automáticos o acciones relevantes.

### Por qué existen las vistas

- `v_envios_activos`: simplifica la consulta de envíos que siguen operativos y excluye los ya cerrados.
- `v_tiempos_entrega`: calcula tiempos reales de entrega para análisis de eficiencia.
- `v_historial_seguimiento`: consolida el historial de eventos en una sola consulta legible.
- `v_estadisticas_por_cliente`: resume actividad por cliente para análisis y evaluación comercial.

### Por qué existen los procedimientos almacenados

- `sp_registrar_envio`: encapsula el alta de un envío y reduce errores al registrar la operación.
- `sp_registrar_seguimiento`: centraliza la inserción de eventos de trazabilidad.
- `sp_consultar_historial_envio`: devuelve el detalle completo del seguimiento de un envío específico.
- `sp_obtener_indicadores_entrega`: calcula indicadores de operación en un rango de fechas.

### Por qué existen los triggers

- `trg_envio_bu_fecha_actualizacion`: mantiene automáticamente la fecha de última modificación del envío.
- `trg_envio_bi_validar_consistencia`: valida reglas básicas antes de insertar un envío.
- `trg_ruta_bi_validar_consistencia`: impide que una ruta tenga el mismo origen y destino.
- `trg_ruta_bu_validar_consistencia`: aplica la misma validación cuando la ruta se actualiza.
- `trg_seguimiento_bi_validar_consistencia`: controla coherencia entre evento, estado y fechas.
- `trg_seguimiento_ai_actualiza_envio`: sincroniza el estado actual del envío cuando se agrega un seguimiento.

## Archivos incluidos

- `logistica_envios.sql`: script principal para crear la base de datos, cargar datos de prueba y generar tablas, vistas, procedimientos y triggers.
- `ejecución_logistica_envios.sql`: archivo de validación con consultas para revisar tablas, vistas, procedimientos, triggers y ejecuciones de prueba.

## Estructura del modelo

- Región
- Dirección
- Cliente
- Estado_Envio
- Tipo_Evento_Seguimiento
- Repartidor
- Ruta
- Envío
- Seguimiento
- Envío_Evento_Log

## Relaciones principales

- Región 1:N Dirección
- Cliente 1:N Envío como remitente
- Cliente 1:N Envío como destinatario
- Dirección 1:N Envío como origen
- Dirección 1:N Envío como destino
- Ruta 1:N Envío
- Estado_Envio 1:N Envío
- Envío 1:N Seguimiento
- Estado_Envio 1:N Seguimiento
- Repartidor 1:N Seguimiento
- Dirección 1:N Seguimiento

## Cómo ejecutar la entrega

1. Ejecuta primero `logistica_envios.sql` en MySQL 8+.
2. Luego ejecuta `ejecución_logistica_envios.sql` para validar tablas, vistas, procedimientos y triggers.
3. Revisa las salidas de `SELECT`, `CALL` e información de `information_schema` para confirmar que todo quedó creado.
4. Si algún `CALL` devuelve error, corrige el script principal antes de evaluar la entrega.

## Qué valida el archivo de ejecución

El archivo `ejecución_logistica_envios.sql` incluye:

- conteo y consulta de cada tabla
- consulta de cada vista
- ejecución de procedimientos almacenados
- verificación de tablas, rutinas y triggers en `information_schema`

## Consultas analíticas sugeridas

- total de envíos por cliente
- región con más envíos
- promedio de tiempo de entrega
- entregas por mes
- envíos pendientes
- top 10 clientes
- tiempo promedio por ruta
- distribución de estados

## Observación final

El modelo está preparado para crecer sin romper la estructura base. Si en el futuro se requiere una operación más compleja, se puede ampliar con tablas de vehículos, centros de distribución, rutas multietapa y auditoría técnica adicional.
=======
# Logistica_envios
>>>>>>> e1cdbc06aad936fceb22fe5ad42726f3fe43623b
