USE DW_Albarran;

GO
-- 0. ESQUEMA STG (Para staging)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg');
    PRINT 'Esquema [stg] creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'El esquema [stg] ya existe.';
END
GO

-- 1. Crear tabla staging para DimEmpleado (Fase 6)
CREATE TABLE stg.Empleado (
    empleado_id INT,
    nombre VARCHAR(100),
    apellido_paterno VARCHAR(100),
    apellido_materno VARCHAR(100),
    cargo_id INT,
    cargo VARCHAR(100),
    fecha_contrato DATE,
    sueldo_base DECIMAL(18,2),
    -- Estos tres campos los genera tu Derived Column en SSIS
    nombre_completo VARCHAR(250),
    antiguedad_anios SMALLINT,
    rango_antiguedad VARCHAR(20)
);

-- 2. Crear tabla staging para DimProducto (Fase 5)
CREATE TABLE stg.Producto (
    producto_id INT,
    nombre_producto VARCHAR(200),
    descripcion VARCHAR(500),
    categoria_id INT,
    categoria VARCHAR(100),
    precio_lista DECIMAL(18,2),
    -- Este campo lo genera tu Derived Column en SSIS
    rango_precio VARCHAR(20)
);

-- 3. TABLA STAGING: stg.stg_FactVentas (Para carga incremental y validación)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'stg_FactVentas' AND schema_id = SCHEMA_ID('stg'))
BEGIN
    SELECT TOP 0 * INTO stg.stg_FactVentas FROM dbo.FactVentas;
    PRINT 'Tabla [stg].[stg_FactVentas] creada exitosamente.';
END
ELSE
BEGIN
    PRINT 'La tabla [stg].[stg_FactVentas] ya existe.';
END
GO




