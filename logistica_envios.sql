CREATE DATABASE IF NOT EXISTS logistica_envios;

USE logistica_envios;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS v_envios_activos;
DROP VIEW IF EXISTS v_tiempos_entrega;
DROP VIEW IF EXISTS v_historial_seguimiento;
DROP VIEW IF EXISTS v_estadisticas_por_cliente;

DROP TRIGGER IF EXISTS trg_seguimiento_ai_actualiza_envio;
DROP TRIGGER IF EXISTS trg_envio_bu_fecha_actualizacion;
DROP TRIGGER IF EXISTS trg_seguimiento_bi_validar_consistencia;
DROP TRIGGER IF EXISTS trg_envio_bi_validar_consistencia;

DROP PROCEDURE IF EXISTS sp_registrar_envio;
DROP PROCEDURE IF EXISTS sp_registrar_seguimiento;
DROP PROCEDURE IF EXISTS sp_consultar_historial_envio;
DROP PROCEDURE IF EXISTS sp_obtener_indicadores_entrega;

DROP TABLE IF EXISTS envio_evento_log;
DROP TABLE IF EXISTS seguimiento;
DROP TABLE IF EXISTS envio;
DROP TABLE IF EXISTS ruta;
DROP TABLE IF EXISTS repartidor;
DROP TABLE IF EXISTS tipo_evento_seguimiento;
DROP TABLE IF EXISTS estado_envio;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS direccion;
DROP TABLE IF EXISTS region;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE region (
  id_region INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  codigo VARCHAR(20) NOT NULL,
  activo TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_region),
  UNIQUE KEY uk_region_nombre (nombre),
  UNIQUE KEY uk_region_codigo (codigo),
  CONSTRAINT chk_region_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE direccion (
  id_direccion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_region INT UNSIGNED NOT NULL,
  linea1 VARCHAR(150) NOT NULL,
  linea2 VARCHAR(150) NULL,
  ciudad VARCHAR(100) NOT NULL,
  provincia_estado VARCHAR(100) NULL,
  codigo_postal VARCHAR(20) NULL,
  pais VARCHAR(100) NOT NULL DEFAULT 'México',
  referencias VARCHAR(255) NULL,
  latitud DECIMAL(10,7) NULL,
  longitud DECIMAL(10,7) NULL,
  activo TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_direccion),
  KEY idx_direccion_region (id_region),
  KEY idx_direccion_ciudad (ciudad),
  CONSTRAINT fk_direccion_region
    FOREIGN KEY (id_region) REFERENCES region(id_region)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_direccion_latitud CHECK (latitud IS NULL OR (latitud BETWEEN -90 AND 90)),
  CONSTRAINT chk_direccion_longitud CHECK (longitud IS NULL OR (longitud BETWEEN -180 AND 180)),
  CONSTRAINT chk_direccion_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE cliente (
  id_cliente BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(150) NOT NULL,
  tipo_cliente ENUM('PERSONA','EMPRESA') NOT NULL DEFAULT 'PERSONA',
  email VARCHAR(150) NOT NULL,
  telefono VARCHAR(20) NULL,
  documento_identidad VARCHAR(30) NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_cliente),
  UNIQUE KEY uk_cliente_email (email),
  UNIQUE KEY uk_cliente_documento (documento_identidad),
  KEY idx_cliente_nombre (nombre),
  CONSTRAINT chk_cliente_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE estado_envio (
  id_estado_envio SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(80) NOT NULL,
  es_final TINYINT NOT NULL DEFAULT 0,
  orden_visual SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  activo TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_estado_envio),
  UNIQUE KEY uk_estado_envio_codigo (codigo),
  UNIQUE KEY uk_estado_envio_nombre (nombre),
  CONSTRAINT chk_estado_envio_final CHECK (es_final IN (0,1)),
  CONSTRAINT chk_estado_envio_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE tipo_evento_seguimiento (
  id_tipo_evento SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(80) NOT NULL,
  activo TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (id_tipo_evento),
  UNIQUE KEY uk_tipo_evento_codigo (codigo),
  UNIQUE KEY uk_tipo_evento_nombre (nombre),
  CONSTRAINT chk_tipo_evento_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE repartidor (
  id_repartidor BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(120) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  correo VARCHAR(150) NOT NULL,
  activo TINYINT NOT NULL DEFAULT 1,
  fecha_alta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_repartidor),
  UNIQUE KEY uk_repartidor_telefono (telefono),
  UNIQUE KEY uk_repartidor_correo (correo),
  KEY idx_repartidor_nombre (nombre),
  CONSTRAINT chk_repartidor_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE ruta (
   id_ruta BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   id_direccion_origen BIGINT UNSIGNED NOT NULL,
   id_direccion_destino BIGINT UNSIGNED NOT NULL,
   distancia_km DECIMAL(10,2) NOT NULL,
   tiempo_estimado_minutos INT NOT NULL,
   activo TINYINT NOT NULL DEFAULT 1,
   fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (id_ruta),
   UNIQUE KEY uk_ruta_origen_destino (id_direccion_origen, id_direccion_destino),
   KEY idx_ruta_origen (id_direccion_origen),
   KEY idx_ruta_destino (id_direccion_destino),
   CONSTRAINT fk_ruta_origen
     FOREIGN KEY (id_direccion_origen) REFERENCES direccion(id_direccion)
     ON UPDATE RESTRICT
     ON DELETE RESTRICT,
   CONSTRAINT fk_ruta_destino
     FOREIGN KEY (id_direccion_destino) REFERENCES direccion(id_direccion)
     ON UPDATE RESTRICT
     ON DELETE RESTRICT,
   CONSTRAINT chk_ruta_distancia CHECK (distancia_km > 0),
   CONSTRAINT chk_ruta_tiempo CHECK (tiempo_estimado_minutos > 0),
   CONSTRAINT chk_ruta_activo CHECK (activo IN (0,1)),
   CONSTRAINT chk_ruta_distinta CHECK (id_direccion_origen <> id_direccion_destino)
) ENGINE=InnoDB;

CREATE TABLE envio (
   id_envio BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   codigo_envio VARCHAR(30) NOT NULL,
   id_cliente_remitente BIGINT UNSIGNED NOT NULL,
   id_cliente_destinatario BIGINT UNSIGNED NOT NULL,
   id_direccion_origen BIGINT UNSIGNED NOT NULL,
   id_direccion_destino BIGINT UNSIGNED NOT NULL,
   id_ruta BIGINT UNSIGNED NULL,
   id_estado_actual SMALLINT UNSIGNED NOT NULL,
   peso_kg DECIMAL(10,3) NOT NULL,
   descripcion VARCHAR(255) NULL,
   valor_declarado DECIMAL(12,2) NULL,
   fecha_envio DATETIME NOT NULL,
   fecha_entrega DATETIME NULL,
   costo_total DECIMAL(12,2) NULL,
   observaciones VARCHAR(500) NULL,
   fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
   fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (id_envio),
   UNIQUE KEY uk_envio_codigo (codigo_envio),
   KEY idx_envio_remitente (id_cliente_remitente),
   KEY idx_envio_destinatario (id_cliente_destinatario),
   KEY idx_envio_estado (id_estado_actual),
   KEY idx_envio_fecha (fecha_envio),
   KEY idx_envio_ruta (id_ruta),
   KEY idx_envio_origen (id_direccion_origen),
   KEY idx_envio_destino (id_direccion_destino),
   CONSTRAINT fk_envio_remitente
     FOREIGN KEY (id_cliente_remitente) REFERENCES cliente(id_cliente)
     ON UPDATE RESTRICT
     ON DELETE RESTRICT,
   CONSTRAINT fk_envio_destinatario
     FOREIGN KEY (id_cliente_destinatario) REFERENCES cliente(id_cliente)
     ON UPDATE RESTRICT
     ON DELETE RESTRICT,
   CONSTRAINT fk_envio_origen
     FOREIGN KEY (id_direccion_origen) REFERENCES direccion(id_direccion)
     ON UPDATE CASCADE
     ON DELETE RESTRICT,
   CONSTRAINT fk_envio_destino
     FOREIGN KEY (id_direccion_destino) REFERENCES direccion(id_direccion)
     ON UPDATE CASCADE
     ON DELETE RESTRICT,
   CONSTRAINT fk_envio_ruta
     FOREIGN KEY (id_ruta) REFERENCES ruta(id_ruta)
     ON UPDATE CASCADE
     ON DELETE SET NULL,
   CONSTRAINT fk_envio_estado
     FOREIGN KEY (id_estado_actual) REFERENCES estado_envio(id_estado_envio)
     ON UPDATE CASCADE
     ON DELETE RESTRICT,
   CONSTRAINT chk_envio_peso CHECK (peso_kg > 0),
   CONSTRAINT chk_envio_valor CHECK (valor_declarado IS NULL OR valor_declarado >= 0),
   CONSTRAINT chk_envio_costo CHECK (costo_total IS NULL OR costo_total >= 0),
   CONSTRAINT chk_envio_fechas CHECK (fecha_entrega IS NULL OR fecha_entrega >= fecha_envio),
   CONSTRAINT chk_envio_clientes CHECK (id_cliente_remitente <> id_cliente_destinatario)
) ENGINE=InnoDB;

CREATE TABLE seguimiento (
  id_seguimiento BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_envio BIGINT UNSIGNED NOT NULL,
  id_estado_envio SMALLINT UNSIGNED NOT NULL,
  id_tipo_evento SMALLINT UNSIGNED NOT NULL,
  id_repartidor BIGINT UNSIGNED NULL,
  id_direccion BIGINT UNSIGNED NULL,
  fecha_evento DATETIME NOT NULL,
  ubicacion_texto VARCHAR(200) NULL,
  observaciones VARCHAR(500) NULL,
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_seguimiento),
  KEY idx_seguimiento_envio_fecha (id_envio, fecha_evento),
  KEY idx_seguimiento_estado (id_estado_envio),
  KEY idx_seguimiento_fecha (fecha_evento),
  KEY idx_seguimiento_repartidor (id_repartidor),
  KEY idx_seguimiento_direccion (id_direccion),
  CONSTRAINT fk_seguimiento_envio
    FOREIGN KEY (id_envio) REFERENCES envio(id_envio)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_seguimiento_estado
    FOREIGN KEY (id_estado_envio) REFERENCES estado_envio(id_estado_envio)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_seguimiento_tipo_evento
    FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento_seguimiento(id_tipo_evento)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_seguimiento_repartidor
    FOREIGN KEY (id_repartidor) REFERENCES repartidor(id_repartidor)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_seguimiento_direccion
    FOREIGN KEY (id_direccion) REFERENCES direccion(id_direccion)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE envio_evento_log (
  id_log BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_envio BIGINT UNSIGNED NOT NULL,
  accion VARCHAR(50) NOT NULL,
  detalle VARCHAR(500) NULL,
  fecha_log DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_log),
  KEY idx_log_envio_fecha (id_envio, fecha_log),
  CONSTRAINT fk_log_envio
    FOREIGN KEY (id_envio) REFERENCES envio(id_envio)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

INSERT INTO region (nombre, codigo, activo) VALUES
('Caribe', 'CARIBE', 1),
('Andina', 'ANDINA', 1),
('Pacífica', 'PACIFICA', 1),
('Orinoquía', 'ORINOQUIA', 1),
('Amazonía', 'AMAZONIA', 1);

INSERT INTO estado_envio (codigo, nombre, es_final, orden_visual, activo) VALUES
('REGISTRADO', 'Registrado', 0, 1, 1),
('RECOGIDO', 'Recogido', 0, 2, 1),
('EN_TRANSITO', 'En tránsito', 0, 3, 1),
('EN_CLASIFICACION', 'En clasificación', 0, 4, 1),
('EN_REPARTO', 'En reparto', 0, 5, 1),
('ENTREGADO', 'Entregado', 1, 6, 1),
('INCIDENCIA', 'Incidencia', 0, 7, 1),
('DEVUELTO', 'Devuelto', 1, 8, 1),
('CANCELADO', 'Cancelado', 1, 9, 1);

INSERT INTO tipo_evento_seguimiento (codigo, nombre, activo) VALUES
('REGISTRO', 'Registro', 1),
('RECOGIDA', 'Recogida', 1),
('SALIDA_ORIGEN', 'Salida de origen', 1),
('LLEGADA_CENTRO', 'Llegada a centro', 1),
('SALIDA_CENTRO', 'Salida de centro', 1),
('EN_RUTA', 'En ruta', 1),
('EN_REPARTO', 'En reparto', 1),
('ENTREGADO', 'Entregado', 1),
('INCIDENTE', 'Incidente', 1),
('REPROGRAMADO', 'Reprogramado', 1);

INSERT INTO cliente (nombre, tipo_cliente, email, telefono, documento_identidad, fecha_registro, activo) VALUES
('María Fernanda Rojas', 'PERSONA', 'maria.rojas@example.co', '3001000001', 'CC100001', '2026-01-05 09:00:00', 1),
('Juan Sebastián Gómez', 'PERSONA', 'juan.gomez@example.co', '3001000002', 'CC100002', '2026-01-07 10:00:00', 1),
('LogiAndes SAS', 'EMPRESA', 'contacto@logiandes.com.co', '3001000003', 'NIT900100001', '2026-01-10 11:00:00', 1),
('Distribuciones del Caribe SAS', 'EMPRESA', 'ventas@caribe.com.co', '3001000004', 'NIT900100002', '2026-01-12 12:00:00', 1),
('Laura Catalina Pérez', 'PERSONA', 'laura.perez@example.co', '3001000005', 'CC100005', '2026-01-15 13:00:00', 1),
('Frigoríficos del Pacífico SAS', 'EMPRESA', 'operaciones@fripacifico.com.co', '3001000006', 'NIT900100003', '2026-01-18 14:00:00', 1),
('Andrés Felipe Torres', 'PERSONA', 'andres.torres@example.co', '3001000007', 'CC100007', '2026-01-20 15:00:00', 1),
('Empaques de la Sabana SAS', 'EMPRESA', 'info@empaquesabana.com.co', '3001000008', 'NIT900100004', '2026-01-22 16:00:00', 1),
('Valentina Ruiz', 'PERSONA', 'valentina.ruiz@example.co', '3001000009', 'CC100009', '2026-01-25 17:00:00', 1),
('Carga Express Colombia SAS', 'EMPRESA', 'rrhh@cargaexpress.co', '3001000010', 'NIT900100005', '2026-01-28 18:00:00', 1);

INSERT INTO direccion (id_region, linea1, linea2, ciudad, provincia_estado, codigo_postal, pais, referencias, latitud, longitud, activo) VALUES
(1, 'Cra. 46 # 72-80', NULL, 'Barranquilla', 'Atlántico', '080001', 'Colombia', 'Cerca al centro empresarial', 10.9685400, -74.7813200, 1),
(1, 'Cll. 30 # 17-45', 'Bodega 8', 'Cartagena', 'Bolívar', '130001', 'Colombia', 'Zona industrial Mamonal', 10.3910500, -75.4794200, 1),
(2, 'Av. El Dorado # 69-76', NULL, 'Bogotá D.C.', 'Bogotá D.C.', '110111', 'Colombia', 'Torre corporativa', 4.7015900, -74.1469000, 1),
(2, 'Cra. 15 # 93-47', NULL, 'Bucaramanga', 'Santander', '680001', 'Colombia', 'Plaza principal', 7.1193000, -73.1227000, 1),
(3, 'Av. 6N # 23DN-55', NULL, 'Cali', 'Valle del Cauca', '760001', 'Colombia', 'A una cuadra del mercado', 3.4516500, -76.5320000, 1),
(3, 'Cl. 10 # 35-20', 'Interior 2', 'Buenaventura', 'Valle del Cauca', '764501', 'Colombia', 'Frente al puerto', 3.8801000, -77.0311600, 1),
(4, 'Cll. 18 # 25-60', NULL, 'Villavicencio', 'Meta', '500001', 'Colombia', 'Zona centro', 4.1420000, -73.6266000, 1),
(4, 'Cra. 29 # 20-15', NULL, 'Yopal', 'Casanare', '850001', 'Colombia', 'Cerca del parque central', 5.3377500, -72.3958600, 1),
(5, 'Av. del Rio # 15-90', NULL, 'Leticia', 'Amazonas', '910001', 'Colombia', 'Cerca al muelle', -4.2153000, -69.9406000, 1),
(5, 'Cra. 11 # 8-20', NULL, 'Florencia', 'Caquetá', '180001', 'Colombia', 'Frente a la terminal', 1.6143800, -75.6062300, 1);

INSERT INTO repartidor (nombre, telefono, correo, activo, fecha_alta) VALUES
('Julián Peña', '3102000001', 'julian.pena@logi.com.co', 1, '2026-01-05 08:00:00'),
('Natalia Santos', '3102000002', 'natalia.santos@logi.com.co', 1, '2026-01-05 08:10:00'),
('Luis Herrera', '3102000003', 'luis.herrera@logi.com.co', 1, '2026-01-05 08:20:00'),
('Paola Díaz', '3102000004', 'paola.diaz@logi.com.co', 1, '2026-01-05 08:30:00'),
('Andrés Vidal', '3102000005', 'andres.vidal@logi.com.co', 1, '2026-01-05 08:40:00');

INSERT INTO ruta (id_direccion_origen, id_direccion_destino, distancia_km, tiempo_estimado_minutos, activo, fecha_creacion) VALUES
(1, 3, 913.50, 840, 1, '2026-01-10 09:00:00'),
(3, 5, 540.20, 520, 1, '2026-01-10 09:05:00'),
(5, 7, 550.00, 540, 1, '2026-01-10 09:10:00'),
(7, 9, 1340.75, 1260, 1, '2026-01-10 09:15:00'),
(2, 4, 780.40, 720, 1, '2026-01-10 09:20:00');

INSERT INTO envio (codigo_envio, id_cliente_remitente, id_cliente_destinatario, id_direccion_origen, id_direccion_destino, id_ruta, id_estado_actual, peso_kg, descripcion, valor_declarado, fecha_envio, fecha_entrega, costo_total, observaciones, fecha_creacion, fecha_actualizacion) VALUES
('ENV-0001', 1, 3, 1, 3, 1, 6, 2.500, 'Documentos corporativos', 1500.00, '2026-02-01 09:00:00', '2026-02-03 18:20:00', 320.00, NULL, '2026-02-01 09:00:00', '2026-02-03 18:20:00'),
('ENV-0002', 2, 4, 2, 4, 5, 3, 4.300, 'Piezas electrónicas', 4500.00, '2026-02-02 10:00:00', NULL, 410.00, NULL, '2026-02-02 10:00:00', '2026-02-02 12:00:00'),
('ENV-0003', 3, 5, 3, 5, 2, 6, 1.200, 'Muestras comerciales', 800.00, '2026-02-03 11:00:00', '2026-02-05 14:10:00', 250.00, NULL, '2026-02-03 11:00:00', '2026-02-05 14:10:00'),
('ENV-0004', 4, 6, 4, 6, 2, 5, 12.000, 'Paquetería industrial', 7000.00, '2026-02-04 08:30:00', NULL, 780.00, NULL, '2026-02-04 08:30:00', '2026-02-06 17:00:00'),
('ENV-0005', 5, 7, 5, 7, 3, 6, 3.700, 'Ropa de temporada', 2200.00, '2026-02-05 09:15:00', '2026-02-07 16:40:00', 295.00, NULL, '2026-02-05 09:15:00', '2026-02-07 16:40:00'),
('ENV-0006', 6, 8, 6, 8, 4, 2, 8.600, 'Equipos de refrigeración', 15000.00, '2026-02-06 12:00:00', NULL, 900.00, NULL, '2026-02-06 12:00:00', '2026-02-06 18:00:00'),
('ENV-0007', 7, 9, 7, 9, 4, 6, 0.900, 'Paquete pequeño', 200.00, '2026-02-07 13:20:00', '2026-02-10 11:25:00', 180.00, NULL, '2026-02-07 13:20:00', '2026-02-10 11:25:00'),
('ENV-0008', 8, 10, 8, 10, 4, 3, 15.000, 'Material promocional', 3000.00, '2026-02-08 14:30:00', NULL, 1025.00, NULL, '2026-02-08 14:30:00', '2026-02-08 17:30:00'),
('ENV-0009', 9, 1, 9, 1, 4, 6, 5.200, 'Insumos varios', 1100.00, '2026-02-09 15:00:00', '2026-02-12 09:45:00', 360.00, NULL, '2026-02-09 15:00:00', '2026-02-12 09:45:00'),
('ENV-0010', 10, 2, 10, 2, 1, 4, 2.100, 'Productos sensibles', 5200.00, '2026-02-10 16:00:00', NULL, 340.00, NULL, '2026-02-10 16:00:00', '2026-02-11 08:00:00'),
('ENV-0011', 1, 4, 1, 4, 1, 6, 1.800, 'Documentos legales', 500.00, '2026-02-11 09:00:00', '2026-02-13 10:20:00', 210.00, NULL, '2026-02-11 09:00:00', '2026-02-13 10:20:00'),
('ENV-0012', 2, 5, 2, 5, 5, 3, 6.400, 'Refacciones', 1300.00, '2026-02-12 10:10:00', NULL, 620.00, NULL, '2026-02-12 10:10:00', '2026-02-12 13:10:00'),
('ENV-0013', 3, 6, 3, 6, 2, 6, 2.900, 'Muestras biológicas', 1800.00, '2026-02-13 11:25:00', '2026-02-15 18:00:00', 280.00, NULL, '2026-02-13 11:25:00', '2026-02-15 18:00:00'),
('ENV-0014', 4, 7, 4, 7, 2, 5, 11.200, 'Mercancía general', 8400.00, '2026-02-14 12:15:00', NULL, 790.00, NULL, '2026-02-14 12:15:00', '2026-02-16 08:00:00'),
('ENV-0015', 5, 8, 5, 8, 3, 6, 7.500, 'Equipos de oficina', 6000.00, '2026-02-15 13:30:00', '2026-02-18 17:30:00', 410.00, NULL, '2026-02-15 13:30:00', '2026-02-18 17:30:00'),
('ENV-0016', 6, 9, 6, 9, 4, 2, 1.100, 'Documentación interna', 150.00, '2026-02-16 14:40:00', NULL, 170.00, NULL, '2026-02-16 14:40:00', '2026-02-16 16:40:00'),
('ENV-0017', 7, 10, 7, 10, 4, 6, 4.800, 'Partes mecánicas', 2200.00, '2026-02-17 15:50:00', '2026-02-20 12:30:00', 390.00, NULL, '2026-02-17 15:50:00', '2026-02-20 12:30:00'),
('ENV-0018', 8, 1, 8, 1, 4, 3, 9.700, 'Suministros', 2700.00, '2026-02-18 16:00:00', NULL, 850.00, NULL, '2026-02-18 16:00:00', '2026-02-18 19:00:00'),
('ENV-0019', 9, 2, 9, 2, 4, 6, 0.650, 'Paquete express', 120.00, '2026-02-19 17:10:00', '2026-02-21 11:10:00', 160.00, NULL, '2026-02-19 17:10:00', '2026-02-21 11:10:00'),
('ENV-0020', 10, 3, 10, 3, 1, 4, 13.400, 'Carga consolidada', 9500.00, '2026-02-20 18:20:00', NULL, 1050.00, NULL, '2026-02-20 18:20:00', '2026-02-21 09:00:00');

INSERT INTO seguimiento (id_envio, id_estado_envio, id_tipo_evento, id_repartidor, id_direccion, fecha_evento, ubicacion_texto, observaciones, fecha_registro) VALUES
(1, 1, 1, NULL, 1, '2026-02-01 09:00:00', 'Origen registrado', 'Alta del envío', '2026-02-01 09:00:00'),
(1, 2, 2, 1, 1, '2026-02-01 11:00:00', 'Recolectado en origen', NULL, '2026-02-01 11:00:00'),
(1, 3, 6, 1, 3, '2026-02-02 09:30:00', 'En ruta a centro de clasificación', NULL, '2026-02-02 09:30:00'),
(1, 5, 7, 2, 3, '2026-02-03 10:15:00', 'Salida para entrega', NULL, '2026-02-03 10:15:00'),
(1, 6, 8, 2, 3, '2026-02-03 18:20:00', 'Entregado correctamente', NULL, '2026-02-03 18:20:00'),
(2, 1, 1, NULL, 2, '2026-02-02 10:00:00', 'Origen registrado', 'Alta del envío', '2026-02-02 10:00:00'),
(2, 2, 2, 3, 2, '2026-02-02 12:00:00', 'Recolectado', NULL, '2026-02-02 12:00:00'),
(2, 3, 6, 3, 4, '2026-02-03 08:30:00', 'En tránsito', NULL, '2026-02-03 08:30:00'),
(2, 7, 9, NULL, 4, '2026-02-04 14:00:00', 'Incidencia por dirección incompleta', 'Pendiente de validación', '2026-02-04 14:00:00'),
(3, 1, 1, NULL, 3, '2026-02-03 11:00:00', 'Origen registrado', 'Alta del envío', '2026-02-03 11:00:00'),
(3, 2, 2, 2, 3, '2026-02-03 13:00:00', 'Recolectado', NULL, '2026-02-03 13:00:00'),
(3, 3, 6, 2, 5, '2026-02-04 09:00:00', 'En tránsito', NULL, '2026-02-04 09:00:00'),
(3, 6, 8, 2, 5, '2026-02-05 14:10:00', 'Entregado', NULL, '2026-02-05 14:10:00'),
(4, 1, 1, NULL, 4, '2026-02-04 08:30:00', 'Origen registrado', 'Alta del envío', '2026-02-04 08:30:00'),
(4, 2, 2, 4, 4, '2026-02-04 10:45:00', 'Recolectado', NULL, '2026-02-04 10:45:00'),
(4, 3, 6, 4, 6, '2026-02-05 16:20:00', 'En tránsito', NULL, '2026-02-05 16:20:00'),
(4, 4, 4, 4, 6, '2026-02-06 17:00:00', 'En clasificación', NULL, '2026-02-06 17:00:00'),
(5, 1, 1, NULL, 5, '2026-02-05 09:15:00', 'Origen registrado', 'Alta del envío', '2026-02-05 09:15:00'),
(5, 2, 2, 5, 5, '2026-02-05 10:00:00', 'Recolectado', NULL, '2026-02-05 10:00:00'),
(5, 3, 6, 5, 7, '2026-02-06 15:00:00', 'En tránsito', NULL, '2026-02-06 15:00:00'),
(5, 6, 8, 5, 7, '2026-02-07 16:40:00', 'Entregado', NULL, '2026-02-07 16:40:00'),
(6, 1, 1, NULL, 6, '2026-02-06 12:00:00', 'Origen registrado', 'Alta del envío', '2026-02-06 12:00:00'),
(6, 2, 2, 1, 6, '2026-02-06 14:10:00', 'Recolectado', NULL, '2026-02-06 14:10:00'),
(6, 3, 6, 1, 8, '2026-02-07 09:45:00', 'En tránsito', NULL, '2026-02-07 09:45:00'),
(6, 5, 7, 1, 8, '2026-02-07 16:00:00', 'En reparto', NULL, '2026-02-07 16:00:00'),
(7, 1, 1, NULL, 7, '2026-02-07 13:20:00', 'Origen registrado', 'Alta del envío', '2026-02-07 13:20:00'),
(7, 2, 2, 2, 7, '2026-02-07 14:00:00', 'Recolectado', NULL, '2026-02-07 14:00:00'),
(7, 3, 6, 2, 9, '2026-02-08 18:00:00', 'En tránsito', NULL, '2026-02-08 18:00:00'),
(7, 6, 8, 2, 9, '2026-02-10 11:25:00', 'Entregado', NULL, '2026-02-10 11:25:00'),
(8, 1, 1, NULL, 8, '2026-02-08 14:30:00', 'Origen registrado', 'Alta del envío', '2026-02-08 14:30:00'),
(8, 2, 2, 3, 8, '2026-02-08 15:45:00', 'Recolectado', NULL, '2026-02-08 15:45:00'),
(8, 3, 6, 3, 10, '2026-02-09 20:00:00', 'En tránsito', NULL, '2026-02-09 20:00:00'),
(8, 7, 9, NULL, 10, '2026-02-10 09:00:00', 'Incidencia por clima', 'Retenido temporalmente', '2026-02-10 09:00:00'),
(9, 1, 1, NULL, 9, '2026-02-09 15:00:00', 'Origen registrado', 'Alta del envío', '2026-02-09 15:00:00'),
(9, 2, 2, 4, 9, '2026-02-09 16:30:00', 'Recolectado', NULL, '2026-02-09 16:30:00'),
(9, 3, 6, 4, 1, '2026-02-10 11:15:00', 'En tránsito', NULL, '2026-02-10 11:15:00'),
(9, 6, 8, 4, 1, '2026-02-12 09:45:00', 'Entregado', NULL, '2026-02-12 09:45:00'),
(10, 1, 1, NULL, 10, '2026-02-10 16:00:00', 'Origen registrado', 'Alta del envío', '2026-02-10 16:00:00'),
(10, 2, 2, 5, 10, '2026-02-10 18:00:00', 'Recolectado', NULL, '2026-02-10 18:00:00'),
(10, 4, 4, 5, 2, '2026-02-11 08:00:00', 'En clasificación', NULL, '2026-02-11 08:00:00'),
(11, 1, 1, NULL, 1, '2026-02-11 09:00:00', 'Origen registrado', 'Alta del envío', '2026-02-11 09:00:00'),
(11, 2, 2, 1, 1, '2026-02-11 11:20:00', 'Recolectado', NULL, '2026-02-11 11:20:00'),
(11, 3, 6, 1, 4, '2026-02-12 10:00:00', 'En tránsito', NULL, '2026-02-12 10:00:00'),
(11, 6, 8, 1, 4, '2026-02-13 10:20:00', 'Entregado', NULL, '2026-02-13 10:20:00'),
(12, 1, 1, NULL, 2, '2026-02-12 10:10:00', 'Origen registrado', 'Alta del envío', '2026-02-12 10:10:00'),
(12, 2, 2, 2, 2, '2026-02-12 12:00:00', 'Recolectado', NULL, '2026-02-12 12:00:00'),
(12, 3, 6, 2, 5, '2026-02-13 17:30:00', 'En tránsito', NULL, '2026-02-13 17:30:00'),
(12, 5, 7, 2, 5, '2026-02-14 09:00:00', 'En reparto', NULL, '2026-02-14 09:00:00'),
(13, 1, 1, NULL, 3, '2026-02-13 11:25:00', 'Origen registrado', 'Alta del envío', '2026-02-13 11:25:00'),
(13, 2, 2, 3, 3, '2026-02-13 13:10:00', 'Recolectado', NULL, '2026-02-13 13:10:00'),
(13, 3, 6, 3, 6, '2026-02-14 18:10:00', 'En tránsito', NULL, '2026-02-14 18:10:00'),
(13, 6, 8, 3, 6, '2026-02-15 18:00:00', 'Entregado', NULL, '2026-02-15 18:00:00'),
(14, 1, 1, NULL, 4, '2026-02-14 12:15:00', 'Origen registrado', 'Alta del envío', '2026-02-14 12:15:00'),
(14, 2, 2, 4, 4, '2026-02-14 14:00:00', 'Recolectado', NULL, '2026-02-14 14:00:00'),
(14, 3, 6, 4, 7, '2026-02-15 20:20:00', 'En tránsito', NULL, '2026-02-15 20:20:00'),
(14, 4, 4, 4, 7, '2026-02-16 08:00:00', 'En clasificación', NULL, '2026-02-16 08:00:00'),
(15, 1, 1, NULL, 5, '2026-02-15 13:30:00', 'Origen registrado', 'Alta del envío', '2026-02-15 13:30:00'),
(15, 2, 2, 5, 5, '2026-02-15 15:15:00', 'Recolectado', NULL, '2026-02-15 15:15:00'),
(15, 3, 6, 5, 8, '2026-02-16 19:00:00', 'En tránsito', NULL, '2026-02-16 19:00:00'),
(15, 6, 8, 5, 8, '2026-02-18 17:30:00', 'Entregado', NULL, '2026-02-18 17:30:00'),
(16, 1, 1, NULL, 6, '2026-02-16 14:40:00', 'Origen registrado', 'Alta del envío', '2026-02-16 14:40:00'),
(16, 2, 2, 1, 6, '2026-02-16 16:40:00', 'Recolectado', NULL, '2026-02-16 16:40:00'),
(16, 3, 6, 1, 9, '2026-02-17 12:00:00', 'En tránsito', NULL, '2026-02-17 12:00:00'),
(17, 1, 1, NULL, 7, '2026-02-17 15:50:00', 'Origen registrado', 'Alta del envío', '2026-02-17 15:50:00'),
(17, 2, 2, 2, 7, '2026-02-17 17:10:00', 'Recolectado', NULL, '2026-02-17 17:10:00'),
(17, 3, 6, 2, 10, '2026-02-18 22:00:00', 'En tránsito', NULL, '2026-02-18 22:00:00'),
(17, 6, 8, 2, 10, '2026-02-20 12:30:00', 'Entregado', NULL, '2026-02-20 12:30:00'),
(18, 1, 1, NULL, 8, '2026-02-18 16:00:00', 'Origen registrado', 'Alta del envío', '2026-02-18 16:00:00'),
(18, 2, 2, 3, 8, '2026-02-18 18:00:00', 'Recolectado', NULL, '2026-02-18 18:00:00'),
(18, 3, 6, 3, 1, '2026-02-19 22:30:00', 'En tránsito', NULL, '2026-02-19 22:30:00'),
(18, 7, 9, NULL, 1, '2026-02-20 10:00:00', 'Incidencia por falta de acceso', NULL, '2026-02-20 10:00:00'),
(19, 1, 1, NULL, 9, '2026-02-19 17:10:00', 'Origen registrado', 'Alta del envío', '2026-02-19 17:10:00'),
(19, 2, 2, 4, 9, '2026-02-19 18:20:00', 'Recolectado', NULL, '2026-02-19 18:20:00'),
(19, 3, 6, 4, 2, '2026-02-20 09:40:00', 'En tránsito', NULL, '2026-02-20 09:40:00'),
(19, 6, 8, 4, 2, '2026-02-21 11:10:00', 'Entregado', NULL, '2026-02-21 11:10:00'),
(20, 1, 1, NULL, 10, '2026-02-20 18:20:00', 'Origen registrado', 'Alta del envío', '2026-02-20 18:20:00'),
(20, 2, 2, 5, 10, '2026-02-20 19:50:00', 'Recolectado', NULL, '2026-02-20 19:50:00'),
(20, 4, 4, 5, 3, '2026-02-21 09:00:00', 'En clasificación', NULL, '2026-02-21 09:00:00');

INSERT INTO envio_evento_log (id_envio, accion, detalle, fecha_log) VALUES
(1, 'CREACION', 'Envío creado e inicializado', '2026-02-01 09:00:00'),
(1, 'ACTUALIZACION_ESTADO', 'Estado actualizado a ENTREGADO', '2026-02-03 18:20:00'),
(2, 'CREACION', 'Envío creado e inicializado', '2026-02-02 10:00:00'),
(2, 'INCIDENCIA', 'Se registró incidencia', '2026-02-04 14:00:00');

DELIMITER $$

CREATE PROCEDURE sp_registrar_envio(
  IN p_codigo_envio VARCHAR(30),
  IN p_id_cliente_remitente BIGINT UNSIGNED,
  IN p_id_cliente_destinatario BIGINT UNSIGNED,
  IN p_id_direccion_origen BIGINT UNSIGNED,
  IN p_id_direccion_destino BIGINT UNSIGNED,
  IN p_id_ruta BIGINT UNSIGNED,
  IN p_peso_kg DECIMAL(10,3),
  IN p_descripcion VARCHAR(255),
  IN p_valor_declarado DECIMAL(12,2),
  IN p_fecha_envio DATETIME,
  IN p_costo_total DECIMAL(12,2),
  IN p_observaciones VARCHAR(500)
)
BEGIN
  DECLARE v_id_estado_registrado SMALLINT UNSIGNED;

  SELECT id_estado_envio
    INTO v_id_estado_registrado
  FROM estado_envio
  WHERE codigo = 'REGISTRADO'
  LIMIT 1;

  INSERT INTO envio (
    codigo_envio,
    id_cliente_remitente,
    id_cliente_destinatario,
    id_direccion_origen,
    id_direccion_destino,
    id_ruta,
    id_estado_actual,
    peso_kg,
    descripcion,
    valor_declarado,
    fecha_envio,
    costo_total,
    observaciones
  ) VALUES (
    p_codigo_envio,
    p_id_cliente_remitente,
    p_id_cliente_destinatario,
    p_id_direccion_origen,
    p_id_direccion_destino,
    p_id_ruta,
    v_id_estado_registrado,
    p_peso_kg,
    p_descripcion,
    p_valor_declarado,
    p_fecha_envio,
    p_costo_total,
    p_observaciones
  );
END$$

CREATE PROCEDURE sp_registrar_seguimiento(
  IN p_id_envio BIGINT UNSIGNED,
  IN p_id_estado_envio SMALLINT UNSIGNED,
  IN p_id_tipo_evento SMALLINT UNSIGNED,
  IN p_id_repartidor BIGINT UNSIGNED,
  IN p_id_direccion BIGINT UNSIGNED,
  IN p_fecha_evento DATETIME,
  IN p_ubicacion_texto VARCHAR(200),
  IN p_observaciones VARCHAR(500)
)
BEGIN
  INSERT INTO seguimiento (
    id_envio,
    id_estado_envio,
    id_tipo_evento,
    id_repartidor,
    id_direccion,
    fecha_evento,
    ubicacion_texto,
    observaciones
  ) VALUES (
    p_id_envio,
    p_id_estado_envio,
    p_id_tipo_evento,
    p_id_repartidor,
    p_id_direccion,
    p_fecha_evento,
    p_ubicacion_texto,
    p_observaciones
  );
END$$

CREATE PROCEDURE sp_consultar_historial_envio(
  IN p_id_envio BIGINT UNSIGNED
)
BEGIN
  SELECT
    e.id_envio,
    e.codigo_envio,
    e.fecha_envio,
    e.fecha_entrega,
    se.nombre AS estado_actual,
    s.id_seguimiento,
    s.fecha_evento,
    tes.nombre AS tipo_evento,
    es.nombre AS estado_evento,
    r.nombre AS repartidor,
    d.linea1 AS direccion_linea1,
    d.ciudad,
    s.ubicacion_texto,
    s.observaciones
  FROM envio e
  LEFT JOIN seguimiento s ON s.id_envio = e.id_envio
  LEFT JOIN tipo_evento_seguimiento tes ON tes.id_tipo_evento = s.id_tipo_evento
  LEFT JOIN estado_envio es ON es.id_estado_envio = s.id_estado_envio
  LEFT JOIN repartidor r ON r.id_repartidor = s.id_repartidor
  LEFT JOIN direccion d ON d.id_direccion = s.id_direccion
  INNER JOIN estado_envio se ON se.id_estado_envio = e.id_estado_actual
  WHERE e.id_envio = p_id_envio
  ORDER BY s.fecha_evento, s.id_seguimiento;
END$$

CREATE PROCEDURE sp_obtener_indicadores_entrega(
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE
)
BEGIN
  SELECT
    COUNT(*) AS total_envios,
    SUM(CASE WHEN e.fecha_entrega IS NOT NULL THEN 1 ELSE 0 END) AS total_entregados,
    ROUND(AVG(CASE WHEN e.fecha_entrega IS NOT NULL THEN TIMESTAMPDIFF(HOUR, e.fecha_envio, e.fecha_entrega) END), 2) AS promedio_horas_entrega,
    ROUND(AVG(e.peso_kg), 3) AS promedio_peso_kg,
    ROUND(SUM(CASE WHEN e.fecha_entrega IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS porcentaje_entrega
  FROM envio e
  WHERE e.fecha_envio >= p_fecha_inicio
    AND e.fecha_envio < DATE_ADD(p_fecha_fin, INTERVAL 1 DAY);
END$$

CREATE TRIGGER trg_envio_bu_fecha_actualizacion
BEFORE UPDATE ON envio
FOR EACH ROW
BEGIN
  SET NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
END$$

CREATE TRIGGER trg_envio_bi_validar_consistencia
BEFORE INSERT ON envio
FOR EACH ROW
BEGIN
  IF NEW.id_cliente_remitente = NEW.id_cliente_destinatario THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El remitente y el destinatario no pueden ser el mismo cliente.';
  END IF;

  IF NEW.peso_kg <= 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El peso debe ser mayor que cero.';
  END IF;

  IF NEW.fecha_entrega IS NOT NULL AND NEW.fecha_entrega < NEW.fecha_envio THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La fecha de entrega no puede ser menor que la fecha de envío.';
  END IF;
END$$

CREATE TRIGGER trg_ruta_bi_validar_consistencia
BEFORE INSERT ON ruta
FOR EACH ROW
BEGIN
  IF NEW.id_direccion_origen = NEW.id_direccion_destino THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La dirección de origen y la de destino no pueden ser la misma.';
  END IF;
END$$

CREATE TRIGGER trg_ruta_bu_validar_consistencia
BEFORE UPDATE ON ruta
FOR EACH ROW
BEGIN
  IF NEW.id_direccion_origen = NEW.id_direccion_destino THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La dirección de origen y la de destino no pueden ser la misma.';
  END IF;
END$$

CREATE TRIGGER trg_seguimiento_bi_validar_consistencia
BEFORE INSERT ON seguimiento
FOR EACH ROW
BEGIN
  DECLARE v_fecha_envio DATETIME;
  DECLARE v_estado_final TINYINT;

  SELECT fecha_envio
    INTO v_fecha_envio
  FROM envio
  WHERE id_envio = NEW.id_envio;

  IF NEW.fecha_evento < v_fecha_envio THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La fecha del evento no puede ser menor que la fecha de envío.';
  END IF;

  SELECT es_final
    INTO v_estado_final
  FROM estado_envio
  WHERE id_estado_envio = NEW.id_estado_envio;

  IF v_estado_final = 1 AND NEW.id_tipo_evento NOT IN (
    SELECT id_tipo_evento
    FROM tipo_evento_seguimiento
    WHERE codigo IN ('ENTREGADO', 'INCIDENTE', 'REPROGRAMADO')
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Un estado final solo puede registrarse con un tipo de evento final coherente.';
  END IF;
END$$

CREATE TRIGGER trg_seguimiento_ai_actualiza_envio
AFTER INSERT ON seguimiento
FOR EACH ROW
BEGIN
  DECLARE v_codigo_estado VARCHAR(30);

  UPDATE envio
  SET id_estado_actual = NEW.id_estado_envio,
      fecha_entrega = CASE
        WHEN EXISTS (
          SELECT 1
          FROM estado_envio ee
          WHERE ee.id_estado_envio = NEW.id_estado_envio
            AND ee.codigo = 'ENTREGADO'
        ) THEN NEW.fecha_evento
        ELSE fecha_entrega
      END
  WHERE id_envio = NEW.id_envio;

  SELECT codigo
    INTO v_codigo_estado
  FROM estado_envio
  WHERE id_estado_envio = NEW.id_estado_envio;

  INSERT INTO envio_evento_log (id_envio, accion, detalle)
  VALUES (
    NEW.id_envio,
    'ACTUALIZACION_ESTADO',
    CONCAT('Se actualizó el estado actual a ', v_codigo_estado)
  );
END$$

DELIMITER ;

CREATE OR REPLACE VIEW v_envios_activos AS
SELECT
  e.id_envio,
  e.codigo_envio,
  c1.nombre AS remitente,
  c2.nombre AS destinatario,
  es.nombre AS estado_actual,
  e.fecha_envio,
  e.fecha_entrega,
  e.peso_kg,
  e.costo_total
FROM envio e
INNER JOIN cliente c1 ON c1.id_cliente = e.id_cliente_remitente
INNER JOIN cliente c2 ON c2.id_cliente = e.id_cliente_destinatario
INNER JOIN estado_envio es ON es.id_estado_envio = e.id_estado_actual
WHERE es.codigo NOT IN ('ENTREGADO','DEVUELTO','CANCELADO');

CREATE OR REPLACE VIEW v_tiempos_entrega AS
SELECT
  e.id_envio,
  e.codigo_envio,
  e.fecha_envio,
  e.fecha_entrega,
  TIMESTAMPDIFF(HOUR, e.fecha_envio, e.fecha_entrega) AS horas_entrega,
  TIMESTAMPDIFF(MINUTE, e.fecha_envio, e.fecha_entrega) AS minutos_entrega,
  r.id_ruta,
  r.distancia_km,
  r.tiempo_estimado_minutos,
  CASE
    WHEN e.fecha_entrega IS NULL THEN NULL
    ELSE ROUND(TIMESTAMPDIFF(MINUTE, e.fecha_envio, e.fecha_entrega) / NULLIF(r.tiempo_estimado_minutos,0), 2)
  END AS ratio_real_vs_estimado
FROM envio e
LEFT JOIN ruta r ON r.id_ruta = e.id_ruta
WHERE e.fecha_entrega IS NOT NULL;

CREATE OR REPLACE VIEW v_historial_seguimiento AS
SELECT
  s.id_seguimiento,
  e.codigo_envio,
  s.fecha_evento,
  tes.nombre AS tipo_evento,
  es.nombre AS estado,
  r.nombre AS repartidor,
  d.linea1,
  d.ciudad,
  reg.nombre AS region,
  s.ubicacion_texto,
  s.observaciones
FROM seguimiento s
INNER JOIN envio e ON e.id_envio = s.id_envio
INNER JOIN tipo_evento_seguimiento tes ON tes.id_tipo_evento = s.id_tipo_evento
INNER JOIN estado_envio es ON es.id_estado_envio = s.id_estado_envio
LEFT JOIN repartidor r ON r.id_repartidor = s.id_repartidor
LEFT JOIN direccion d ON d.id_direccion = s.id_direccion
LEFT JOIN region reg ON reg.id_region = d.id_region;

CREATE OR REPLACE VIEW v_estadisticas_por_cliente AS
SELECT
  c.id_cliente,
  c.nombre,
  c.tipo_cliente,
  COUNT(e.id_envio) AS total_envios,
  SUM(CASE WHEN e.fecha_entrega IS NOT NULL THEN 1 ELSE 0 END) AS total_entregados,
  SUM(CASE WHEN e.fecha_entrega IS NULL THEN 1 ELSE 0 END) AS total_pendientes,
  ROUND(AVG(CASE WHEN e.fecha_entrega IS NOT NULL THEN TIMESTAMPDIFF(HOUR, e.fecha_envio, e.fecha_entrega) END), 2) AS promedio_horas_entrega
FROM cliente c
LEFT JOIN envio e ON e.id_cliente_remitente = c.id_cliente
GROUP BY c.id_cliente, c.nombre, c.tipo_cliente;

