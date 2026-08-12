-- Ejecutar SOLO en Supabase SQL Editor si AMIR no aparece
-- Fuerza la inserción de AMIR eliminando primero si existe

DELETE FROM cont_empresas WHERE codigo = 'AMIR';

INSERT INTO cont_empresas
  (codigo, nombre_corto, nombre_fiscal, rfc, giro, regimen_especial, moneda_funcional, orden_presentacion, color_hex, activa)
VALUES
  ('AMIR', 'Amir', 'Amir Tafreshi', 'XAXX010101000', 'Consultoría y servicios', 'Régimen General', 'MXN', 0, '#ff6b6b', true);

SELECT * FROM cont_empresas WHERE codigo = 'AMIR';
