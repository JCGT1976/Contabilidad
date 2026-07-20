-- =====================================================================
-- SIF-Contabilidad — Setup inicial de tablas base
-- Fecha: 2026-07-20
-- Ejecutar en Supabase SQL Editor > New query
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. EMPRESAS del grupo MI Global
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cont_empresas (
  id BIGSERIAL PRIMARY KEY,
  codigo TEXT UNIQUE NOT NULL,               -- ARIITRANST/AUTOBOT/BOUGHTS/COMERCIAL/INTERNACIONAL
  nombre_corto TEXT NOT NULL,
  nombre_fiscal TEXT NOT NULL,
  rfc TEXT NOT NULL,
  regimen_fiscal TEXT,                       -- ej. "601 - General de Ley Personas Morales"
  giro TEXT,                                 -- ej. "Autotransporte federal de carga"
  regimen_especial TEXT,                     -- ej. "IMMEX", "Régimen General"
  moneda_funcional TEXT NOT NULL DEFAULT 'MXN',
  domicilio_fiscal TEXT,
  fecha_inicio_operaciones DATE,
  representante_legal TEXT,
  contacto_email TEXT,
  activa BOOLEAN NOT NULL DEFAULT true,
  orden_presentacion INT DEFAULT 0,
  color_hex TEXT DEFAULT '#002855',          -- para gráficas
  notas TEXT,
  fecha_creo TIMESTAMPTZ NOT NULL DEFAULT now(),
  usuario_creo TEXT
);

CREATE INDEX IF NOT EXISTS idx_cont_empresas_codigo ON cont_empresas(codigo);

-- ---------------------------------------------------------------------
-- 2. PERÍODOS CONTABLES (mensuales)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cont_periodos (
  id BIGSERIAL PRIMARY KEY,
  empresa_id BIGINT NOT NULL REFERENCES cont_empresas(id) ON DELETE CASCADE,
  anio INT NOT NULL CHECK (anio BETWEEN 2000 AND 2100),
  mes INT NOT NULL CHECK (mes BETWEEN 1 AND 12),
  estatus TEXT NOT NULL DEFAULT 'abierto'
    CHECK (estatus IN ('abierto','cerrado','auditado','reabierto')),
  fecha_apertura DATE,
  fecha_cierre TIMESTAMPTZ,
  usuario_cerro TEXT,
  fecha_reapertura TIMESTAMPTZ,
  usuario_reabrio TEXT,
  motivo_reapertura TEXT,
  notas TEXT,
  UNIQUE(empresa_id, anio, mes)
);

CREATE INDEX IF NOT EXISTS idx_cont_periodos_emp_anio ON cont_periodos(empresa_id, anio, mes);

-- ---------------------------------------------------------------------
-- 3. CATÁLOGO DE CUENTAS (con agrupador SAT)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cont_catalogo_cuentas (
  id BIGSERIAL PRIMARY KEY,
  empresa_id BIGINT NOT NULL REFERENCES cont_empresas(id) ON DELETE CASCADE,
  codigo TEXT NOT NULL,                      -- ej. '1105-001-0001'
  nombre TEXT NOT NULL,
  nivel SMALLINT NOT NULL CHECK (nivel BETWEEN 1 AND 8),
  cuenta_padre_id BIGINT REFERENCES cont_catalogo_cuentas(id),
  codigo_agrupador_sat TEXT NOT NULL,        -- ej. '102.01'
  naturaleza CHAR(1) NOT NULL CHECK (naturaleza IN ('D','A')),
  tipo TEXT NOT NULL
    CHECK (tipo IN ('activo','pasivo','capital','ingreso','costo','gasto','rif','orden')),
  acepta_movimientos BOOLEAN NOT NULL DEFAULT false,
  moneda TEXT DEFAULT 'MXN',
  es_intercompania BOOLEAN NOT NULL DEFAULT false,
  empresa_contraparte_id BIGINT REFERENCES cont_empresas(id),
  activa BOOLEAN NOT NULL DEFAULT true,
  fecha_creo TIMESTAMPTZ NOT NULL DEFAULT now(),
  usuario_creo TEXT,
  UNIQUE(empresa_id, codigo)
);

CREATE INDEX IF NOT EXISTS idx_cont_cuentas_emp_codigo ON cont_catalogo_cuentas(empresa_id, codigo);
CREATE INDEX IF NOT EXISTS idx_cont_cuentas_agrupador ON cont_catalogo_cuentas(codigo_agrupador_sat);
CREATE INDEX IF NOT EXISTS idx_cont_cuentas_padre ON cont_catalogo_cuentas(cuenta_padre_id);

-- ---------------------------------------------------------------------
-- 4. BALANZAS MENSUALES (snapshot para carga histórica + calculada en vivo)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cont_balanzas (
  id BIGSERIAL PRIMARY KEY,
  empresa_id BIGINT NOT NULL REFERENCES cont_empresas(id) ON DELETE CASCADE,
  periodo_id BIGINT NOT NULL REFERENCES cont_periodos(id) ON DELETE CASCADE,
  cuenta_id BIGINT NOT NULL REFERENCES cont_catalogo_cuentas(id) ON DELETE CASCADE,
  saldo_inicial_debe NUMERIC(18,2) NOT NULL DEFAULT 0,
  saldo_inicial_haber NUMERIC(18,2) NOT NULL DEFAULT 0,
  cargos_periodo NUMERIC(18,2) NOT NULL DEFAULT 0,
  abonos_periodo NUMERIC(18,2) NOT NULL DEFAULT 0,
  saldo_final_debe NUMERIC(18,2) NOT NULL DEFAULT 0,
  saldo_final_haber NUMERIC(18,2) NOT NULL DEFAULT 0,
  origen TEXT NOT NULL DEFAULT 'importado'
    CHECK (origen IN ('sistema','importado','manual','ajuste')),
  fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  usuario_actualizacion TEXT,
  UNIQUE(empresa_id, periodo_id, cuenta_id)
);

CREATE INDEX IF NOT EXISTS idx_cont_balanzas_emp_per ON cont_balanzas(empresa_id, periodo_id);
CREATE INDEX IF NOT EXISTS idx_cont_balanzas_cuenta ON cont_balanzas(cuenta_id);

-- ---------------------------------------------------------------------
-- 5. Seed empresas MI Global (edita los datos según necesites)
-- ---------------------------------------------------------------------
INSERT INTO cont_empresas
  (codigo, nombre_corto, nombre_fiscal, rfc, giro, regimen_especial, moneda_funcional, orden_presentacion, color_hex)
VALUES
  ('ARIITRANST', 'Ariitranst', 'Ariitranst (RAZÓN SOCIAL COMPLETA)', 'XAXX010101000',
   'Autotransporte federal de carga', 'SCT/SICT', 'MXN', 1, '#0057B8'),
  ('AUTOBOT', 'Autobot', 'Autobot (RAZÓN SOCIAL COMPLETA)', 'XAXX010101000',
   'Maquiladora industrial', 'IMMEX', 'MXN', 2, '#003876'),
  ('INTERNACIONAL', 'Internacional', 'MI Tech Internacional (RAZÓN SOCIAL COMPLETA)', 'XAXX010101000',
   'Maquiladora industrial', 'IMMEX', 'MXN', 3, '#002855'),
  ('BOUGHTS', 'Boughts', 'Boughts (RAZÓN SOCIAL COMPLETA)', 'XAXX010101000',
   'Comercio', 'Régimen General', 'MXN', 4, '#1e40af'),
  ('COMERCIAL', 'Comercial', 'Comercial (RAZÓN SOCIAL COMPLETA)', 'XAXX010101000',
   'Comercio', 'Régimen General', 'MXN', 5, '#3730a3')
ON CONFLICT (codigo) DO NOTHING;

-- ---------------------------------------------------------------------
-- 6. RLS (Row-Level Security) — abierto para authenticated (ajustar luego)
-- ---------------------------------------------------------------------
ALTER TABLE cont_empresas          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cont_periodos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cont_catalogo_cuentas  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cont_balanzas          ENABLE ROW LEVEL SECURITY;

CREATE POLICY cont_empresas_all ON cont_empresas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY cont_periodos_all ON cont_periodos
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY cont_cuentas_all ON cont_catalogo_cuentas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY cont_balanzas_all ON cont_balanzas
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ---------------------------------------------------------------------
-- VERIFICACIÓN
-- ---------------------------------------------------------------------
SELECT 'cont_empresas' AS tabla, COUNT(*) AS filas FROM cont_empresas
UNION ALL SELECT 'cont_periodos', COUNT(*) FROM cont_periodos
UNION ALL SELECT 'cont_catalogo_cuentas', COUNT(*) FROM cont_catalogo_cuentas
UNION ALL SELECT 'cont_balanzas', COUNT(*) FROM cont_balanzas;
