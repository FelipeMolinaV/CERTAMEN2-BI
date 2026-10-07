/* =====================================================================
   DW_Albarran - Modelo dimensional (ESTRELLA) - Mueblería Albarrán
   Metodología: Kimball
   Proceso de negocio : Ventas
   Granularidad       : 1 fila = 1 producto dentro de 1 venta (detalle_ventas)
   Motor              : SQL Server
   ===================================================================== */

USE master;
GO
IF DB_ID('DW_Albarran') IS NULL
    CREATE DATABASE DW_Albarran;
GO
USE DW_Albarran;
GO

/* ---------------------------------------------------------------------
   0. Limpieza (permite re-ejecutar el script)
   --------------------------------------------------------------------- */
IF OBJECT_ID('dbo.FactVentas')        IS NOT NULL DROP TABLE dbo.FactVentas;
IF OBJECT_ID('dbo.DimTiempo')         IS NOT NULL DROP TABLE dbo.DimTiempo;
IF OBJECT_ID('dbo.DimCliente')        IS NOT NULL DROP TABLE dbo.DimCliente;
IF OBJECT_ID('dbo.DimProducto')       IS NOT NULL DROP TABLE dbo.DimProducto;
IF OBJECT_ID('dbo.DimEmpleado')       IS NOT NULL DROP TABLE dbo.DimEmpleado;
IF OBJECT_ID('dbo.DimSucursal')       IS NOT NULL DROP TABLE dbo.DimSucursal;
IF OBJECT_ID('dbo.DimTipoDocumento')  IS NOT NULL DROP TABLE dbo.DimTipoDocumento;
GO

/* ---------------------------------------------------------------------
   1. DIMENSIONES
   Convención: sk_* = clave sustituta (surrogate key)
               *_id = clave natural del sistema transaccional
   --------------------------------------------------------------------- */

/* ---- DimTiempo (clave inteligente yyyymmdd) ---- */
CREATE TABLE dbo.DimTiempo (
    sk_tiempo         INT          NOT NULL,   -- yyyymmdd
    fecha             DATE         NOT NULL,
    anio              SMALLINT     NOT NULL,
    trimestre         TINYINT      NOT NULL,
    nombre_trimestre  VARCHAR(10)  NOT NULL,   -- 'T1 2026'
    mes               TINYINT      NOT NULL,
    nombre_mes        VARCHAR(20)  NOT NULL,
    anio_mes          INT          NOT NULL,   -- 202610 (ordena bien en cubos)
    semana_anio       TINYINT      NOT NULL,
    dia_mes           TINYINT      NOT NULL,
    dia_semana        TINYINT      NOT NULL,   -- 1 = lunes ... 7 = domingo
    nombre_dia        VARCHAR(20)  NOT NULL,
    es_fin_de_semana  BIT          NOT NULL,
    CONSTRAINT PK_DimTiempo PRIMARY KEY CLUSTERED (sk_tiempo),
    CONSTRAINT UQ_DimTiempo_fecha UNIQUE (fecha)
);
GO

/* ---- DimCliente (Tipo 1: se sobrescribe) ---- */
CREATE TABLE dbo.DimCliente (
    sk_cliente        INT IDENTITY(1,1) NOT NULL,
    cliente_id        INT           NOT NULL,   -- NK
    nombre_completo   VARCHAR(200)  NOT NULL,
    nombre            VARCHAR(100)  NULL,
    apellido_paterno  VARCHAR(100)  NULL,
    apellido_materno  VARCHAR(100)  NULL,
    sexo              VARCHAR(20)   NOT NULL,   -- estandarizado en ETL
    fecha_nacimiento  DATE          NULL,
    edad              SMALLINT      NULL,       -- calculada al momento de la carga
    rango_etario      VARCHAR(20)   NOT NULL,   -- '18-25','26-35',...,'Sin dato'
    estado_civil      VARCHAR(30)   NOT NULL,   -- estandarizado en ETL
    fecha_carga       DATETIME      NOT NULL CONSTRAINT DF_DimCliente_carga DEFAULT (GETDATE()),
    CONSTRAINT PK_DimCliente PRIMARY KEY CLUSTERED (sk_cliente),
    CONSTRAINT UQ_DimCliente_nk UNIQUE (cliente_id)
);
GO

/* ---- DimProducto (incluye Categoría -> estrella; Tipo 2 por cambio de precio) ---- */
CREATE TABLE dbo.DimProducto (
    sk_producto       INT IDENTITY(1,1) NOT NULL,
    producto_id       INT           NOT NULL,   -- NK
    nombre_producto   VARCHAR(200)  NOT NULL,
    descripcion       VARCHAR(500)  NULL,
    categoria_id      INT           NULL,
    categoria         VARCHAR(100)  NOT NULL,
    precio_lista      DECIMAL(18,2) NULL,
    rango_precio      VARCHAR(20)   NOT NULL,   -- 'Económico','Medio','Premium','Sin dato'
    fecha_inicio      DATE          NOT NULL,   -- vigencia SCD2
    fecha_fin         DATE          NULL,
    es_vigente        BIT           NOT NULL CONSTRAINT DF_DimProducto_vig DEFAULT (1),
    fecha_carga       DATETIME      NOT NULL CONSTRAINT DF_DimProducto_carga DEFAULT (GETDATE()),
    CONSTRAINT PK_DimProducto PRIMARY KEY CLUSTERED (sk_producto)
);
CREATE INDEX IX_DimProducto_nk ON dbo.DimProducto (producto_id, es_vigente);
GO

/* ---- DimEmpleado (rol: Vendedor; incluye Cargo; Tipo 2 por cambio de cargo/sueldo) ---- */
CREATE TABLE dbo.DimEmpleado (
    sk_empleado       INT IDENTITY(1,1) NOT NULL,
    empleado_id       INT           NOT NULL,   -- NK
    nombre_completo   VARCHAR(250)  NOT NULL,
    nombre            VARCHAR(100)  NULL,
    apellido_paterno  VARCHAR(100)  NULL,
    apellido_materno  VARCHAR(100)  NULL,
    cargo_id          INT           NULL,
    cargo             VARCHAR(100)  NOT NULL,
    fecha_contrato    DATE          NULL,
    antiguedad_anios  SMALLINT      NULL,       -- calculada al momento de la carga
    rango_antiguedad  VARCHAR(20)   NOT NULL,   -- '<1 año','1-3 años','3-5 años','>5 años'
    sueldo_base       DECIMAL(18,2) NULL,
    fecha_inicio      DATE          NOT NULL,   -- vigencia SCD2
    fecha_fin         DATE          NULL,
    es_vigente        BIT           NOT NULL CONSTRAINT DF_DimEmpleado_vig DEFAULT (1),
    fecha_carga       DATETIME      NOT NULL CONSTRAINT DF_DimEmpleado_carga DEFAULT (GETDATE()),
    CONSTRAINT PK_DimEmpleado PRIMARY KEY CLUSTERED (sk_empleado)
);
CREATE INDEX IX_DimEmpleado_nk ON dbo.DimEmpleado (empleado_id, es_vigente);
GO

/* ---- DimSucursal (incluye Comuna -> estrella; Tipo 1) ---- */
CREATE TABLE dbo.DimSucursal (
    sk_sucursal       INT IDENTITY(1,1) NOT NULL,
    sucursal_id       INT           NOT NULL,   -- NK
    sucursal          VARCHAR(150)  NOT NULL,
    comuna_id         INT           NULL,
    comuna            VARCHAR(100)  NOT NULL,
    fecha_carga       DATETIME      NOT NULL CONSTRAINT DF_DimSucursal_carga DEFAULT (GETDATE()),
    CONSTRAINT PK_DimSucursal PRIMARY KEY CLUSTERED (sk_sucursal),
    CONSTRAINT UQ_DimSucursal_nk UNIQUE (sucursal_id)
);
GO

/* ---- DimTipoDocumento (dimensión pequeña: boleta, factura, etc.) ---- */
CREATE TABLE dbo.DimTipoDocumento (
    sk_tipo_documento INT IDENTITY(1,1) NOT NULL,
    tipo_documento    VARCHAR(50)   NOT NULL,
    CONSTRAINT PK_DimTipoDocumento PRIMARY KEY CLUSTERED (sk_tipo_documento),
    CONSTRAINT UQ_DimTipoDocumento UNIQUE (tipo_documento)
);
GO

/* ---------------------------------------------------------------------
   2. MIEMBROS DESCONOCIDOS (sk = -1)
   Evitan perder hechos cuando falla un lookup en el ETL.
   --------------------------------------------------------------------- */
SET IDENTITY_INSERT dbo.DimCliente ON;
INSERT INTO dbo.DimCliente (sk_cliente, cliente_id, nombre_completo, sexo, rango_etario, estado_civil)
VALUES (-1, -1, 'Desconocido', 'Sin dato', 'Sin dato', 'Sin dato');
SET IDENTITY_INSERT dbo.DimCliente OFF;

SET IDENTITY_INSERT dbo.DimProducto ON;
INSERT INTO dbo.DimProducto (sk_producto, producto_id, nombre_producto, categoria, rango_precio, fecha_inicio)
VALUES (-1, -1, 'Desconocido', 'Sin categoría', 'Sin dato', '1900-01-01');
SET IDENTITY_INSERT dbo.DimProducto OFF;

SET IDENTITY_INSERT dbo.DimEmpleado ON;
INSERT INTO dbo.DimEmpleado (sk_empleado, empleado_id, nombre_completo, cargo, rango_antiguedad, fecha_inicio)
VALUES (-1, -1, 'Desconocido', 'Sin cargo', 'Sin dato', '1900-01-01');
SET IDENTITY_INSERT dbo.DimEmpleado OFF;

SET IDENTITY_INSERT dbo.DimSucursal ON;
INSERT INTO dbo.DimSucursal (sk_sucursal, sucursal_id, sucursal, comuna)
VALUES (-1, -1, 'Desconocida', 'Sin comuna');
SET IDENTITY_INSERT dbo.DimSucursal OFF;

SET IDENTITY_INSERT dbo.DimTipoDocumento ON;
INSERT INTO dbo.DimTipoDocumento (sk_tipo_documento, tipo_documento)
VALUES (-1, 'Sin dato');
SET IDENTITY_INSERT dbo.DimTipoDocumento OFF;
GO

/* ---------------------------------------------------------------------
   3. TABLA DE HECHOS
   Grano: una fila por producto dentro de cada venta.
   Aditivas: cantidad, monto_bruto, monto_descuento, monto_neto
   No aditiva: precio_unitario, descuento_original (no se suman)
   Dimensiones degeneradas: venta_id, numero_documento
   --------------------------------------------------------------------- */
CREATE TABLE dbo.FactVentas (
    -- Claves foráneas a dimensiones
    sk_tiempo          INT           NOT NULL,
    sk_cliente         INT           NOT NULL,
    sk_producto        INT           NOT NULL,
    sk_empleado        INT           NOT NULL,   -- vendedor
    sk_sucursal        INT           NOT NULL,
    sk_tipo_documento  INT           NOT NULL,
    -- Dimensiones degeneradas
    venta_id           INT           NOT NULL,
    numero_documento   VARCHAR(50)   NULL,
    -- Medidas
    cantidad           INT           NOT NULL,
    precio_unitario    DECIMAL(18,2) NOT NULL,   -- precio efectivamente cobrado
    descuento_original DECIMAL(18,4) NOT NULL,   -- tal como viene del origen
    monto_bruto        DECIMAL(18,2) NOT NULL,   -- cantidad * precio_unitario
    monto_descuento    DECIMAL(18,2) NOT NULL,   -- ver nota de descuento en el ETL
    monto_neto         DECIMAL(18,2) NOT NULL,   -- monto_bruto - monto_descuento
    fecha_carga        DATETIME      NOT NULL CONSTRAINT DF_FactVentas_carga DEFAULT (GETDATE()),

    CONSTRAINT PK_FactVentas PRIMARY KEY CLUSTERED (venta_id, sk_producto),

    CONSTRAINT FK_Fact_Tiempo    FOREIGN KEY (sk_tiempo)         REFERENCES dbo.DimTiempo(sk_tiempo),
    CONSTRAINT FK_Fact_Cliente   FOREIGN KEY (sk_cliente)        REFERENCES dbo.DimCliente(sk_cliente),
    CONSTRAINT FK_Fact_Producto  FOREIGN KEY (sk_producto)       REFERENCES dbo.DimProducto(sk_producto),
    CONSTRAINT FK_Fact_Empleado  FOREIGN KEY (sk_empleado)       REFERENCES dbo.DimEmpleado(sk_empleado),
    CONSTRAINT FK_Fact_Sucursal  FOREIGN KEY (sk_sucursal)       REFERENCES dbo.DimSucursal(sk_sucursal),
    CONSTRAINT FK_Fact_TipoDoc   FOREIGN KEY (sk_tipo_documento) REFERENCES dbo.DimTipoDocumento(sk_tipo_documento),

    CONSTRAINT CK_Fact_cantidad  CHECK (cantidad > 0)
);
GO

-- Índices de apoyo para joins y para el procesamiento del cubo
CREATE INDEX IX_Fact_Tiempo   ON dbo.FactVentas (sk_tiempo);
CREATE INDEX IX_Fact_Cliente  ON dbo.FactVentas (sk_cliente);
CREATE INDEX IX_Fact_Producto ON dbo.FactVentas (sk_producto);
CREATE INDEX IX_Fact_Empleado ON dbo.FactVentas (sk_empleado);
CREATE INDEX IX_Fact_Sucursal ON dbo.FactVentas (sk_sucursal);
GO

/* ---------------------------------------------------------------------
   4. POBLAR DimTiempo (2015-01-01 a 2030-12-31)
   Ajustar el rango si las ventas del origen quedan fuera.
   --------------------------------------------------------------------- */
SET LANGUAGE Spanish;
SET DATEFIRST 1;   -- lunes = 1
GO

;WITH fechas AS (
    SELECT CAST('2015-01-01' AS DATE) AS f
    UNION ALL
    SELECT DATEADD(DAY, 1, f) FROM fechas WHERE f < '2030-12-31'
)
INSERT INTO dbo.DimTiempo
    (sk_tiempo, fecha, anio, trimestre, nombre_trimestre, mes, nombre_mes,
     anio_mes, semana_anio, dia_mes, dia_semana, nombre_dia, es_fin_de_semana)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), f, 112)),
    f,
    YEAR(f),
    DATEPART(QUARTER, f),
    'T' + CAST(DATEPART(QUARTER, f) AS VARCHAR(1)) + ' ' + CAST(YEAR(f) AS VARCHAR(4)),
    MONTH(f),
    UPPER(LEFT(DATENAME(MONTH, f), 1)) + SUBSTRING(DATENAME(MONTH, f), 2, 20),
    YEAR(f) * 100 + MONTH(f),
    DATEPART(WEEK, f),
    DAY(f),
    DATEPART(WEEKDAY, f),
    UPPER(LEFT(DATENAME(WEEKDAY, f), 1)) + SUBSTRING(DATENAME(WEEKDAY, f), 2, 20),
    CASE WHEN DATEPART(WEEKDAY, f) IN (6, 7) THEN 1 ELSE 0 END
FROM fechas
OPTION (MAXRECURSION 0);
GO

-- Verificación rápida
SELECT 'DimTiempo' AS tabla, COUNT(*) AS filas FROM dbo.DimTiempo
UNION ALL SELECT 'DimCliente',       COUNT(*) FROM dbo.DimCliente
UNION ALL SELECT 'DimProducto',      COUNT(*) FROM dbo.DimProducto
UNION ALL SELECT 'DimEmpleado',      COUNT(*) FROM dbo.DimEmpleado
UNION ALL SELECT 'DimSucursal',      COUNT(*) FROM dbo.DimSucursal
UNION ALL SELECT 'DimTipoDocumento', COUNT(*) FROM dbo.DimTipoDocumento
UNION ALL SELECT 'FactVentas',       COUNT(*) FROM dbo.FactVentas;
GO