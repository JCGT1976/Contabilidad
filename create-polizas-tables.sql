-- EJECUTAR EN SUPABASE SQL EDITOR
-- Crear tablas de pólizas contables

CREATE TABLE IF NOT EXISTS cont_polizas (
  id BIGSERIAL PRIMARY KEY,
  empresa_id BIGINT NOT NULL REFERENCES cont_empresas(id) ON DELETE CASCADE,
  periodo_id BIGINT NOT NULL REFERENCES cont_periodos(id) ON DELETE CASCADE,
  numero_poliza TEXT NOT NULL,
  tipo_poliza TEXT NOT NULL CHECK (tipo_poliza IN ('Ingresos','Egresos','Diario')),
  fecha_poliza DATE NOT NULL,
  concepto TEXT NOT NULL,
  referencia_xml TEXT,
  status TEXT NOT NULL DEFAULT 'borrador' CHECK (status IN ('borrador','revisada','contabilizada','anulada')),
  usuario_creo TEXT NOT NULL,
  fecha_creo TIMESTAMPTZ NOT NULL DEFAULT now(),
  usuario_reviso TEXT,
  fecha_reviso TIMESTAMPTZ,
  usuario_contabilizo TEXT,
  fecha_contabilizo TIMESTAMPTZ,
  notas TEXT,
  UNIQUE(empresa_id, periodo_id, numero_poliza)
);

CREATE TABLE IF NOT EXISTS cont_polizas_detalles (
  id BIGSERIAL PRIMARY KEY,
  poliza_id BIGINT NOT NULL REFERENCES cont_polizas(id) ON DELETE CASCADE,
  renglon_num INT NOT NULL,
  cuenta_id BIGINT NOT NULL REFERENCES cont_catalogo_cuentas(id),
  concepto_detalle TEXT,
  debe NUMERIC(18,2) NOT NULL DEFAULT 0,
  haber NUMERIC(18,2) NOT NULL DEFAULT 0,
  moneda TEXT NOT NULL DEFAULT 'MXN',
  referencia_cfdi TEXT,
  nif_aplicada TEXT,
  usuario_creo TEXT NOT NULL,
  fecha_creo TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cont_polizas_emp_per ON cont_polizas(empresa_id, periodo_id);
CREATE INDEX IF NOT EXISTS idx_cont_polizas_tipo ON cont_polizas(tipo_poliza);
CREATE INDEX IF NOT EXISTS idx_cont_polizas_fecha ON cont_polizas(fecha_poliza);
CREATE INDEX IF NOT EXISTS idx_cont_polizas_status ON cont_polizas(status);
CREATE INDEX IF NOT EXISTS idx_cont_polizas_det_poliza ON cont_polizas_detalles(poliza_id);
CREATE INDEX IF NOT EXISTS idx_cont_polizas_det_cuenta ON cont_polizas_detalles(cuenta_id);

ALTER TABLE cont_polizas ENABLE ROW LEVEL SECURITY;
ALTER TABLE cont_polizas_detalles ENABLE ROW LEVEL SECURITY;

CREATE POLICY cont_polizas_all ON cont_polizas FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY cont_polizas_detalles_all ON cont_polizas_detalles FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Verificar
SELECT COUNT(*) FROM cont_polizas;
SELECT COUNT(*) FROM cont_polizas_detalles;
