-- ============================================================================
-- SOAT Connect - Lawyer Registry Schema
-- PostgreSQL/Supabase Database Schema
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- Main table: abogados (Lawyers)
-- ============================================================================
CREATE TABLE IF NOT EXISTS abogados (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- ========================================================================
    -- Personal Identification
    -- ========================================================================
    tipo_documento VARCHAR(20) NOT NULL CHECK (tipo_documento IN ('CC', 'CE', 'PASAPORTE')),
    numero_documento VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    genero VARCHAR(20) CHECK (genero IN ('Masculino', 'Femenino', 'Otro', 'Prefiero no decir')),
    
    -- ========================================================================
    -- Professional Credentials (Colombian Law Requirements)
    -- ========================================================================
    -- Tarjeta Profesional de Abogado - issued by Consejo Superior de la Judicatura
    tarjeta_profesional VARCHAR(50) UNIQUE NOT NULL,
    -- University that granted the law degree
    universidad VARCHAR(200) NOT NULL,
    -- Graduation date
    fecha_grado DATE NOT NULL,
    -- Optional: Bar Association (Colegio de Abogados)
    colegio_abogados VARCHAR(200),
    -- Optional: Bar Association membership number
    numero_colegiatura VARCHAR(50),
    
    -- ========================================================================
    -- Contact Information
    -- ========================================================================
    email VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    telefono_alternativo VARCHAR(20),
    direccion_oficina TEXT NOT NULL,
    departamento VARCHAR(100) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(10),
    
    -- ========================================================================
    -- Geographic Coverage
    -- ========================================================================
    -- Departments where the lawyer provides services
    departamentos_cobertura TEXT[] NOT NULL DEFAULT '{}',
    -- Specific municipalities (optional, for more granular coverage)
    municipios_cobertura TEXT[] DEFAULT '{}',
    -- Whether the lawyer offers national coverage
    cobertura_nacional BOOLEAN DEFAULT FALSE,
    
    -- ========================================================================
    -- Professional Details
    -- ========================================================================
    -- Areas of specialization
    especialidades TEXT[] NOT NULL DEFAULT '{}',
    -- Years of professional experience
    anos_experiencia INTEGER CHECK (anos_experiencia >= 0),
    -- Number of SOAT cases handled (self-reported, updated over time)
    casos_soat_atendidos INTEGER DEFAULT 0 CHECK (casos_soat_atendidos >= 0),
    -- Description of services offered
    descripcion_servicios TEXT,
    -- Hourly rate or fee structure (optional)
    tarifa_consulta VARCHAR(100),
    -- Languages spoken
    idiomas TEXT[] DEFAULT ARRAY['Español'],
    
    -- ========================================================================
    -- Business Information
    -- ========================================================================
    -- Law firm name (if applicable)
    nombre_bufete VARCHAR(200),
    -- Type of practice
    tipo_practica VARCHAR(50) CHECK (tipo_practica IN ('Independiente', 'Bufete', 'Consultorio Jurídico', 'Otro')),
    -- NIT of the law firm (Colombian tax ID for businesses)
    nit_bufete VARCHAR(20),
    -- Website
    sitio_web VARCHAR(255),
    -- LinkedIn profile
    linkedin VARCHAR(255),
    
    -- ========================================================================
    -- Verification Status
    -- ========================================================================
    -- Verification state
    estado_verificacion VARCHAR(20) DEFAULT 'pendiente' 
        CHECK (estado_verificacion IN ('pendiente', 'en_revision', 'verificado', 'rechazado', 'suspendido')),
    -- Documents uploaded for verification (stored as JSON with URLs)
    documentos_verificacion JSONB DEFAULT '{}',
    -- When verification was completed
    fecha_verificacion TIMESTAMP WITH TIME ZONE,
    -- Who performed the verification (admin user ID)
    verificado_por UUID,
    -- Notes from verification process
    notas_verificacion TEXT,
    -- Reason for rejection (if applicable)
    motivo_rechazo TEXT,
    
    -- ========================================================================
    -- Terms and Consent
    -- ========================================================================
    acepta_terminos BOOLEAN NOT NULL DEFAULT FALSE,
    acepta_tratamiento_datos BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_aceptacion_terminos TIMESTAMP WITH TIME ZONE,
    
    -- ========================================================================
    -- Account Status
    -- ========================================================================
    activo BOOLEAN DEFAULT TRUE,
    fecha_ultimo_acceso TIMESTAMP WITH TIME ZONE,
    
    -- ========================================================================
    -- Authentication (linked to Supabase Auth)
    -- ========================================================================
    auth_user_id UUID UNIQUE,
    
    -- ========================================================================
    -- Timestamps
    -- ========================================================================
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

-- Email lookup (for login/authentication)
CREATE INDEX IF NOT EXISTS idx_abogados_email ON abogados(email);

-- Professional card lookup (for verification)
CREATE INDEX IF NOT EXISTS idx_abogados_tarjeta_profesional ON abogados(tarjeta_profesional);

-- Document number lookup
CREATE INDEX IF NOT EXISTS idx_abogados_numero_documento ON abogados(numero_documento);

-- Geographic filtering
CREATE INDEX IF NOT EXISTS idx_abogados_departamento ON abogados(departamento);
CREATE INDEX IF NOT EXISTS idx_abogados_municipio ON abogados(municipio);

-- Status filtering
CREATE INDEX IF NOT EXISTS idx_abogados_estado_verificacion ON abogados(estado_verificacion);
CREATE INDEX IF NOT EXISTS idx_abogados_activo ON abogados(activo);

-- Coverage search (GIN index for array containment queries)
CREATE INDEX IF NOT EXISTS idx_abogados_departamentos_cobertura ON abogados USING GIN(departamentos_cobertura);
CREATE INDEX IF NOT EXISTS idx_abogados_municipios_cobertura ON abogados USING GIN(municipios_cobertura);
CREATE INDEX IF NOT EXISTS idx_abogados_especialidades ON abogados USING GIN(especialidades);

-- Auth user lookup
CREATE INDEX IF NOT EXISTS idx_abogados_auth_user_id ON abogados(auth_user_id);

-- ============================================================================
-- Trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_abogados_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_abogados_updated_at ON abogados;
CREATE TRIGGER trigger_abogados_updated_at
    BEFORE UPDATE ON abogados
    FOR EACH ROW
    EXECUTE FUNCTION update_abogados_updated_at();

-- ============================================================================
-- Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE abogados ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view verified and active lawyers (for public directory)
CREATE POLICY "Abogados verificados son públicos"
    ON abogados
    FOR SELECT
    USING (estado_verificacion = 'verificado' AND activo = TRUE);

-- Policy: Lawyers can view and update their own profile
CREATE POLICY "Abogados pueden ver su propio perfil"
    ON abogados
    FOR SELECT
    USING (auth.uid() = auth_user_id);

CREATE POLICY "Abogados pueden actualizar su propio perfil"
    ON abogados
    FOR UPDATE
    USING (auth.uid() = auth_user_id)
    WITH CHECK (auth.uid() = auth_user_id);

-- Policy: Anyone can insert (register) - verification happens later
CREATE POLICY "Cualquiera puede registrarse como abogado"
    ON abogados
    FOR INSERT
    WITH CHECK (TRUE);

-- ============================================================================
-- Supporting Tables
-- ============================================================================

-- Table for tracking lawyer certifications and continuing education
CREATE TABLE IF NOT EXISTS abogados_certificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    abogado_id UUID NOT NULL REFERENCES abogados(id) ON DELETE CASCADE,
    nombre_certificacion VARCHAR(200) NOT NULL,
    institucion VARCHAR(200) NOT NULL,
    fecha_obtencion DATE NOT NULL,
    fecha_vencimiento DATE,
    url_certificado VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_certificaciones_abogado ON abogados_certificaciones(abogado_id);

-- Table for lawyer reviews/ratings (from clients)
CREATE TABLE IF NOT EXISTS abogados_valoraciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    abogado_id UUID NOT NULL REFERENCES abogados(id) ON DELETE CASCADE,
    usuario_id UUID,  -- Optional: link to user who left review
    calificacion INTEGER NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario TEXT,
    caso_tipo VARCHAR(50),  -- Type of case: SOAT, accidente, etc.
    fecha_servicio DATE,
    verificado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_valoraciones_abogado ON abogados_valoraciones(abogado_id);
CREATE INDEX IF NOT EXISTS idx_valoraciones_calificacion ON abogados_valoraciones(calificacion);

-- Enable RLS on supporting tables
ALTER TABLE abogados_certificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE abogados_valoraciones ENABLE ROW LEVEL SECURITY;

-- Policies for certifications
CREATE POLICY "Certificaciones visibles para abogados verificados"
    ON abogados_certificaciones
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM abogados 
            WHERE abogados.id = abogado_id 
            AND estado_verificacion = 'verificado' 
            AND activo = TRUE
        )
    );

-- Policies for reviews
CREATE POLICY "Valoraciones visibles públicamente"
    ON abogados_valoraciones
    FOR SELECT
    USING (verificado = TRUE);

-- ============================================================================
-- Useful Views
-- ============================================================================

-- View: Active verified lawyers with average rating
CREATE OR REPLACE VIEW v_abogados_activos AS
SELECT 
    a.id,
    a.nombres,
    a.apellidos,
    a.tarjeta_profesional,
    a.email,
    a.telefono,
    a.departamento,
    a.municipio,
    a.departamentos_cobertura,
    a.especialidades,
    a.anos_experiencia,
    a.casos_soat_atendidos,
    a.nombre_bufete,
    a.tipo_practica,
    a.sitio_web,
    a.descripcion_servicios,
    a.tarifa_consulta,
    COALESCE(
        (SELECT AVG(calificacion)::NUMERIC(3,2) 
         FROM abogados_valoraciones 
         WHERE abogado_id = a.id AND verificado = TRUE),
        0
    ) as calificacion_promedio,
    COALESCE(
        (SELECT COUNT(*) 
         FROM abogados_valoraciones 
         WHERE abogado_id = a.id AND verificado = TRUE),
        0
    ) as total_valoraciones,
    a.created_at
FROM abogados a
WHERE a.estado_verificacion = 'verificado' 
AND a.activo = TRUE;

-- ============================================================================
-- Sample Data (for development/testing)
-- ============================================================================

-- Uncomment to insert sample data
/*
INSERT INTO abogados (
    tipo_documento, numero_documento, nombres, apellidos,
    tarjeta_profesional, universidad, fecha_grado,
    email, telefono, direccion_oficina, departamento, municipio,
    departamentos_cobertura, especialidades, anos_experiencia,
    nombre_bufete, tipo_practica,
    acepta_terminos, acepta_tratamiento_datos, fecha_aceptacion_terminos,
    estado_verificacion
) VALUES (
    'CC', '1234567890', 'María', 'González Pérez',
    '123456', 'Universidad Nacional de Colombia', '2015-06-15',
    'maria.gonzalez@example.com', '+573001234567', 'Carrera 7 #45-67 Oficina 301',
    'Cundinamarca', 'Bogotá',
    ARRAY['Cundinamarca', 'Boyacá', 'Meta'],
    ARRAY['Derecho de Seguros', 'Derecho de Tránsito', 'Responsabilidad Civil'],
    9,
    'González & Asociados', 'Bufete',
    TRUE, TRUE, CURRENT_TIMESTAMP,
    'verificado'
);
*/
