USE logistica_envios;

-- Archivo de validación para la entrega.
-- Ejecútalo después de cargar logistica_envios.sql.
-- Sirve para comprobar tablas, vistas, procedimientos, triggers y objetos del esquema.

-- Validación de tablas base
SELECT 'region' AS tabla, COUNT(*) AS total_registros FROM region;
SELECT * FROM region ORDER BY id_region;

SELECT 'direccion' AS tabla, COUNT(*) AS total_registros FROM direccion;
SELECT * FROM direccion ORDER BY id_direccion;

SELECT 'cliente' AS tabla, COUNT(*) AS total_registros FROM cliente;
SELECT * FROM cliente ORDER BY id_cliente;

SELECT 'estado_envio' AS tabla, COUNT(*) AS total_registros FROM estado_envio;
SELECT * FROM estado_envio ORDER BY id_estado_envio;

SELECT 'tipo_evento_seguimiento' AS tabla, COUNT(*) AS total_registros FROM tipo_evento_seguimiento;
SELECT * FROM tipo_evento_seguimiento ORDER BY id_tipo_evento;

SELECT 'repartidor' AS tabla, COUNT(*) AS total_registros FROM repartidor;
SELECT * FROM repartidor ORDER BY id_repartidor;

SELECT 'ruta' AS tabla, COUNT(*) AS total_registros FROM ruta;
SELECT * FROM ruta ORDER BY id_ruta;

SELECT 'envio' AS tabla, COUNT(*) AS total_registros FROM envio;
SELECT * FROM envio ORDER BY id_envio;

SELECT 'seguimiento' AS tabla, COUNT(*) AS total_registros FROM seguimiento;
SELECT * FROM seguimiento ORDER BY id_seguimiento;

SELECT 'envio_evento_log' AS tabla, COUNT(*) AS total_registros FROM envio_evento_log;
SELECT * FROM envio_evento_log ORDER BY id_log;

-- Validación de vistas
SELECT 'v_envios_activos' AS vista, COUNT(*) AS total_registros FROM v_envios_activos;
SELECT * FROM v_envios_activos ORDER BY id_envio;

SELECT 'v_tiempos_entrega' AS vista, COUNT(*) AS total_registros FROM v_tiempos_entrega;
SELECT * FROM v_tiempos_entrega ORDER BY id_envio;

SELECT 'v_historial_seguimiento' AS vista, COUNT(*) AS total_registros FROM v_historial_seguimiento;
SELECT * FROM v_historial_seguimiento ORDER BY id_seguimiento;

SELECT 'v_estadisticas_por_cliente' AS vista, COUNT(*) AS total_registros FROM v_estadisticas_por_cliente;
SELECT * FROM v_estadisticas_por_cliente ORDER BY id_cliente;

-- Ejecución de procedimientos almacenados
CALL sp_registrar_envio(
  'ENV-9999',
  1,
  2,
  1,
  3,
  1,
  5.250,
  'Prueba de validación',
  2500.00,
  '2026-06-20 10:00:00',
  450.00,
  'Registro de prueba'
);

CALL sp_registrar_seguimiento(
  1,
  2,
  2,
  1,
  1,
  '2026-06-20 11:00:00',
  'Punto de recogida',
  'Seguimiento de prueba'
);

CALL sp_consultar_historial_envio(1);

CALL sp_obtener_indicadores_entrega('2026-02-01', '2026-02-28');

-- Verificación de objetos creados en el esquema
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'logistica_envios'
ORDER BY table_type, table_name;

SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'logistica_envios'
ORDER BY routine_type, routine_name;

SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'logistica_envios'
ORDER BY event_object_table, trigger_name;