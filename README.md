# Certamen 2 Inteligencia de Negocios

## Caso seleccionado
**Mueblería Albarrán** - Implementación de Inteligencia de Negocios para la gestión y análisis de ventas.

## Integrantes y sección
*   Lucas Hernández Gálvez
*   Oscar Vicencio
*   Felipe Molina
*   Paralelo: 300

## Descripción del problema
Mueblería Albarrán es una empresa del rubro de fabricación y venta de muebles que ha experimentado un crecimiento acelerado en los últimos años gracias a su visión vanguardista. Sin embargo, debido a este rápido crecimiento, la gerencia enfrenta dificultades para consolidar la información proveniente de sus distintas sucursales. Actualmente, los datos de ventas, clientes, empleados y productos se encuentran en una base de datos puramente transaccional, lo que dificulta el análisis histórico, el cruce de variables y la identificación de oportunidades comerciales.

## Objetivo del proyecto
Diseñar e implementar una solución integral de Inteligencia de Negocios (BI) que centralice y consolide la información transaccional de Mueblería Albarrán en un modelo dimensional. Esta solución permitirá analizar métricas comerciales críticas, optimizar el rendimiento de la fuerza de ventas, entender el comportamiento demográfico de los clientes y facilitar la toma de decisiones estratégicas mediante visualizaciones interactivas.

## KPI definidos
Para medir el éxito y apoyar la toma de decisiones de Mueblería Albarrán, se han definido los siguientes Indicadores Clave de Desempeño (KPIs):

1.  **Ingreso Total por Línea de Producto (Mensual/Trimestral):** 
    *   *Justificación:* Permite identificar cuáles son las categorías de muebles más rentables y cuáles generan pérdidas, optimizando así el inventario y las estrategias de marketing.
2.  **Ticket Promedio de Venta:** 
    *   *Justificación:* Mide el monto promedio que gasta un cliente en cada compra. Ayuda a evaluar si las estrategias de venta cruzada (cross-selling) de los vendedores están funcionando.
3.  **Rendimiento en Ventas por Vendedor:**
    *   *Justificación:* Identifica a los empleados con mejor y peor desempeño comercial, permitiendo aplicar esquemas de incentivos, comisiones o detectar necesidades de capacitación.
4.  **Distribución de Ventas por Demografía y Zona Geográfica:**
    *   *Justificación:* Analiza los ingresos generados según rango etario y comuna del cliente. Es vital para dirigir campañas publicitarias específicas al segmento que más compra.

## Modelo dimensional
Aplicando la metodología de Ralph Kimball, se ha diseñado un modelo dimensional tipo **Estrella**, definido mediante los siguientes 4 pasos:

### 1. Proceso de negocio
El proceso de negocio seleccionado es la **Gestión de Ventas** (Facturación/Boletas). Específicamente, el acto en el cual un cliente compra uno o más productos, atendido por un vendedor en una sucursal física, en una fecha determinada.

### 2. Granularidad
El nivel de detalle máximo (grano) establecido para la tabla de hechos es: **Una fila por cada producto individual dentro de una transacción de venta** (equivalente al detalle de la boleta o factura). Esta granularidad fina permite el máximo nivel de desglose analítico.

### 3. Dimensiones
El modelo cuenta con las siguientes dimensiones descriptivas, incorporando claves subrogadas (Surrogate Keys):
*   `DimTiempo`: Dimensión calendario autogenerada.
*   `DimCliente`: Historial y demografía de compradores (SCD Tipo 1).
*   `DimProducto`: Detalle y jerarquía de muebles y categorías (SCD Tipo 2 por cambio de precios).
*   `DimEmpleado`: Historial del personal de ventas y sus cargos (SCD Tipo 2).
*   `DimSucursal`: Ubicación geográfica y comunas (SCD Tipo 1).
*   `DimTipoDocumento`: Tipo de comprobante (Boleta, Factura).

### 4. Tabla de hechos y medidas
La tabla central es `FactVentas`.
*   **Medidas aditivas:** `cantidad`, `monto_bruto`, `monto_descuento`, `monto_neto`.
*   **Medidas no aditivas:** `precio_unitario`, `descuento_original`.
*   **Dimensiones degeneradas:** `venta_id`, `numero_documento`.

## Proceso ETL Fase 1
El proceso de Extracción, Transformación y Carga fue desarrollado utilizando SQL Server Integration Services (SSIS). 
*   **Extracción:** Se consumen los datos desde la base transaccional (`Albarran.bak`).
*   **Transformación:** Se realizan limpiezas de datos (estandarización de sexos y estados civiles), concatenación de nombres, cálculos de edad de clientes y antigüedad de empleados, y asignación de registros a miembros desconocidos (ID -1) para mantener la integridad referencial.
*   **Carga:** Se pueblan primero las dimensiones y finalmente la tabla de hechos `FactVentas` en la base de datos `DW_Albarran`.

## Tecnologías utilizadas
*   **Base de Datos Transaccional y Data Warehouse:** Microsoft SQL Server (SSMS).
*   **Proceso ETL:** Visual Studio con extensión SQL Server Integration Services (SSIS).
*   **Control de Versiones y Documentación:** Git y GitHub.

## Estructura del repositorio
```text
CERTAMEN2-BI/
├── README.md
├── docs/
│   ├── CASO_SEMESTRAL_BI.pdf
│   └── presentacion_fase1.pptx
├── modelo-dimensional/
│   ├── Script_DW_Albarran.sql
│   └── Diagrama_DW_Albarran.png
├── database/
│   ├── backup_transaccional/
│   │   └── Albarran.bak
│   └── backup_dimensional/
│       └── DW_Albarran.bak
├── etl/
    └── proyecto_ssis_albarran/


