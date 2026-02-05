-- ============================================================================
-- SOAT Connect - Lawyer Registry Schema (Future-Proof)
-- PostgreSQL/Supabase Database Schema
-- Version: 2.0.0
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. Organizations / Bufetes (Law Firms)
-- ============================================================================
CREATE TABLE IF NOT EXISTS organizaciones_legales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_legal VARCHAR(300) NOT NULL,
    nombre_comercial VARCHAR(300),
    tipo_organizacion VARCHAR(50) NOT NULL DEFAULT 'bufete'
        CHECK (tipo_organizacion IN ('bufete', 'consultorio_juridico', 'corporacion_legal', 'ong_legal', 'otro')),
    nit VARCHAR(20) UNIQUE,
    digito_verificacion VARCHAR(1),
    representante_legal VARCHAR(200),
    email_corporativo VARCHAR(255) NOT NULL,
    telefono_corporativo VARCHAR(20),
    sitio_web VARCHAR(500),
    direccion TEXT,
    departamento VARCHAR(100),
    municipio VARCHAR(100),
    codigo_postal VARCHAR(10),
    pais VARCHAR(50) DEFAULT 'Colombia',
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
    tamano VARCHAR(30) CHECK (tamano IN ('individual', 'pequeno', 'mediano', 'grande')),
    numero_abogados INTEGER DEFAULT 1,
    especialidades_principales TEXT[] DEFAULT '{}',
    logo_url VARCHAR(500),
    descripcion TEXT,
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'suspendido', 'pendiente_verificacion')),
    verificado BOOLEAN DEFAULT FALSE,
    fecha_verificacion TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    schema_version INTEGER DEFAULT 1,
    source_of_truth VARCHAR(50) DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_org_legales_nit ON organizaciones_legales(nit);
CREATE INDEX IF NOT EXISTS idx_org_legales_tipo ON organizaciones_legales(tipo_organizacion);
CREATE INDEX IF NOT EXISTS idx_org_legales_estado ON organizaciones_legales(estado);
CREATE INDEX IF NOT EXISTS idx_org_legales_depto ON organizaciones_legales(departamento);
CREATE INDEX IF NOT EXISTS idx_org_legales_especialidades ON organizaciones_legales USING GIN(especialidades_principales);

-- ============================================================================
-- 2. Subscription Plans (Starter / Pro / Enterprise)
-- ============================================================================
CREATE TABLE IF NOT EXISTS planes_suscripcion_legal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(30) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    tipo_cliente VARCHAR(30) NOT NULL DEFAULT 'abogado'
        CHECK (tipo_cliente IN ('abogado', 'bufete', 'todos')),
    precio_mensual NUMERIC(12,2) DEFAULT 0,
    precio_anual NUMERIC(12,2) DEFAULT 0,
    moneda VARCHAR(3) DEFAULT 'COP',
    max_abogados INTEGER,
    max_casos_activos INTEGER,
    max_consultas_mes INTEGER,
    max_documentos INTEGER,
    features JSONB DEFAULT '{}',
    activo BOOLEAN DEFAULT TRUE,
    visible BOOLEAN DEFAULT TRUE,
    orden_display INTEGER DEFAULT 0,
    version INTEGER DEFAULT 1,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO planes_suscripcion_legal (codigo, nombre, descripcion, tipo_cliente, precio_mensual, precio_anual, max_abogados, max_casos_activos, max_consultas_mes, features, orden_display)
VALUES 
    ('starter', 'Starter', 'Plan gratuito para abogados independientes. Perfil en directorio público, hasta 10 casos activos, notificaciones básicas.', 'abogado', 0, 0, 1, 10, 50,
     '{"perfil_directorio": true, "gestion_casos_basica": true, "notificaciones_email": true, "soporte_email": true, "analytics_basicos": true, "api_access": false, "ai_matching": false, "reportes_avanzados": false, "white_label": false, "soporte_prioritario": false}'::jsonb, 1),
    ('pro', 'Pro', 'Plan profesional. Analytics avanzados, AI matching de casos, API access, soporte prioritario, hasta 100 casos activos.', 'abogado', 149000, 1490000, 5, 100, 500,
     '{"perfil_directorio": true, "perfil_destacado": true, "gestion_casos_avanzada": true, "notificaciones_push": true, "soporte_prioritario": true, "analytics_avanzados": true, "ai_matching": true, "api_access": true, "reportes_personalizados": true, "integraciones_basicas": true, "white_label": false}'::jsonb, 2),
    ('enterprise', 'Enterprise', 'Plan empresarial para bufetes. Todo Pro + multi-sede, white-label, integraciones custom, SLA, soporte dedicado, usuarios ilimitados.', 'bufete', 599000, 5990000, NULL, NULL, NULL,
     '{"perfil_directorio": true, "perfil_destacado": true, "gestion_casos_avanzada": true, "notificaciones_push": true, "soporte_dedicado": true, "analytics_avanzados": true, "ai_matching": true, "api_access": true, "reportes_personalizados": true, "integraciones_custom": true, "white_label": true, "multi_sede": true, "sla_garantizado": true, "capacitacion_incluida": true, "dashboard_gerencial": true}'::jsonb, 3)
ON CONFLICT (codigo) DO NOTHING;

-- ============================================================================
-- 3. Subscriptions (Suscripciones activas para abogados/bufetes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS suscripciones_legales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    abogado_id UUID,
    organizacion_id UUID REFERENCES organizaciones_legales(id) ON DELETE SET NULL,
    plan_id UUID NOT NULL REFERENCES planes_suscripcion_legal(id),
    estado VARCHAR(30) DEFAULT 'activa'
        CHECK (estado IN ('trial', 'activa', 'pausada', 'cancelada', 'vencida', 'pendiente_pago')),
    fecha_inicio TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin TIMESTAMP WITH TIME ZONE,
    fecha_proximo_cobro TIMESTAMP WITH TIME ZONE,
    periodo_facturacion VARCHAR(20) DEFAULT 'mensual' CHECK (periodo_facturacion IN ('mensual', 'anual', 'trial')),
    es_trial BOOLEAN DEFAULT FALSE,
    dias_trial INTEGER DEFAULT 14,
    monto_actual NUMERIC(12,2),
    moneda VARCHAR(3) DEFAULT 'COP',
    metodo_pago JSONB DEFAULT '{}',
    consultas_usadas_mes INTEGER DEFAULT 0,
    casos_activos_actual INTEGER DEFAULT 0,
    limites_custom JSONB DEFAULT '{}',
    motivo_cancelacion TEXT,
    fecha_cancelacion TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    schema_version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_suscripciones_leg_abogado ON suscripciones_legales(abogado_id);
CREATE INDEX IF NOT EXISTS idx_suscripciones_leg_org ON suscripciones_legales(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_suscripciones_leg_plan ON suscripciones_legales(plan_id);
CREATE INDEX IF NOT EXISTS idx_suscripciones_leg_estado ON suscripciones_legales(estado);

-- ============================================================================
-- 4. Abogados (Extended with future-proof fields)
-- ============================================================================
CREATE TABLE IF NOT EXISTS abogados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Organization & Subscription links
    organizacion_id UUID REFERENCES organizaciones_legales(id) ON DELETE SET NULL,
    suscripcion_id UUID REFERENCES suscripciones_legales(id) ON DELETE SET NULL,
    
    -- Personal Identification
    tipo_documento VARCHAR(20) NOT NULL CHECK (tipo_documento IN ('CC', 'CE', 'PASAPORTE')),
    numero_documento VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    genero VARCHAR(20) CHECK (genero IN ('Masculino', 'Femenino', 'Otro', 'Prefiero no decir')),
    identity_proofs JSONB DEFAULT '[]',
    
    -- Professional Credentials
    tarjeta_profesional VARCHAR(50) UNIQUE NOT NULL,
    universidad VARCHAR(200) NOT NULL,
    fecha_grado DATE NOT NULL,
    colegio_abogados VARCHAR(200),
    numero_colegiatura VARCHAR(50),
    
    -- Contact
    email VARCHAR(255) UNIQUE NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    telefono_alternativo VARCHAR(20),
    direccion_oficina TEXT NOT NULL,
    departamento VARCHAR(100) NOT NULL,
    municipio VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(10),
    pais VARCHAR(50) DEFAULT 'Colombia',
    latitud NUMERIC(10,7),
    longitud NUMERIC(10,7),
    
    -- Geographic Coverage
    departamentos_cobertura TEXT[] NOT NULL DEFAULT '{}',
    municipios_cobertura TEXT[] DEFAULT '{}',
    cobertura_nacional BOOLEAN DEFAULT FALSE,
    
    -- Professional Details
    especialidades TEXT[] NOT NULL DEFAULT '{}',
    anos_experiencia INTEGER CHECK (anos_experiencia >= 0),
    casos_soat_atendidos INTEGER DEFAULT 0 CHECK (casos_soat_atendidos >= 0),
    descripcion_servicios TEXT,
    tarifa_consulta VARCHAR(100),
    idiomas TEXT[] DEFAULT ARRAY['Español'],
    
    -- Availability & Schedule
    disponibilidad JSONB DEFAULT '{}',
    -- {"lunes": {"inicio": "08:00", "fin": "18:00"}, "emergencias_24h": true}
    acepta_casos_emergencia BOOLEAN DEFAULT FALSE,
    
    -- Business Information
    nombre_bufete VARCHAR(200),
    tipo_practica VARCHAR(50) CHECK (tipo_practica IN ('Independiente', 'Bufete', 'Consultorio Jurídico', 'Otro')),
    nit_bufete VARCHAR(20),
    sitio_web VARCHAR(255),
    linkedin VARCHAR(255),
    
    -- Verification Status
    estado_verificacion VARCHAR(20) DEFAULT 'pendiente' 
        CHECK (estado_verificacion IN ('pendiente', 'en_revision', 'verificado', 'rechazado', 'suspendido')),
    documentos_verificacion JSONB DEFAULT '{}',
    fecha_verificacion TIMESTAMP WITH TIME ZONE,
    verificado_por UUID,
    notas_verificacion TEXT,
    motivo_rechazo TEXT,
    
    -- Terms and Consent
    acepta_terminos BOOLEAN NOT NULL DEFAULT FALSE,
    acepta_tratamiento_datos BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_aceptacion_terminos TIMESTAMP WITH TIME ZONE,
    
    -- Account Status
    activo BOOLEAN DEFAULT TRUE,
    fecha_ultimo_acceso TIMESTAMP WITH TIME ZONE,
    
    -- Performance & Ratings (cached)
    calificacion_promedio NUMERIC(3,2) DEFAULT 0,
    total_valoraciones INTEGER DEFAULT 0,
    tasa_respuesta NUMERIC(5,2) DEFAULT 0, -- percentage
    tiempo_respuesta_promedio INTEGER DEFAULT 0, -- minutes
    
    -- AI & Scoring
    perfil_scoring JSONB DEFAULT '{}',
    -- {"match_score": 0.85, "reliability": 0.92, "response_speed": "fast", "calculated_at": "..."}
    segmento VARCHAR(50),
    
    -- Authentication
    auth_user_id UUID UNIQUE,
    
    -- Future-proof
    metadata JSONB DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    schema_version INTEGER DEFAULT 1,
    source_of_truth VARCHAR(50) DEFAULT 'web_form',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_abogados_email ON abogados(email);
CREATE INDEX IF NOT EXISTS idx_abogados_tarjeta ON abogados(tarjeta_profesional);
CREATE INDEX IF NOT EXISTS idx_abogados_documento ON abogados(numero_documento);
CREATE INDEX IF NOT EXISTS idx_abogados_departamento ON abogados(departamento);
CREATE INDEX IF NOT EXISTS idx_abogados_municipio ON abogados(municipio);
CREATE INDEX IF NOT EXISTS idx_abogados_estado ON abogados(estado_verificacion);
CREATE INDEX IF NOT EXISTS idx_abogados_activo ON abogados(activo);
CREATE INDEX IF NOT EXISTS idx_abogados_org ON abogados(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_abogados_suscripcion ON abogados(suscripcion_id);
CREATE INDEX IF NOT EXISTS idx_abogados_auth ON abogados(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_abogados_deptos_cobertura ON abogados USING GIN(departamentos_cobertura);
CREATE INDEX IF NOT EXISTS idx_abogados_municipios_cobertura ON abogados USING GIN(municipios_cobertura);
CREATE INDEX IF NOT EXISTS idx_abogados_especialidades ON abogados USING GIN(especialidades);
CREATE INDEX IF NOT EXISTS idx_abogados_metadata ON abogados USING GIN(metadata);
CREATE INDEX IF NOT EXISTS idx_abogados_tags ON abogados USING GIN(tags);

-- ============================================================================
-- 5. Certifications
-- ============================================================================
CREATE TABLE IF NOT EXISTS abogados_certificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    abogado_id UUID NOT NULL REFERENCES abogados(id) ON DELETE CASCADE,
    nombre_certificacion VARCHAR(200) NOT NULL,
    institucion VARCHAR(200) NOT NULL,
    fecha_obtencion DATE NOT NULL,
    fecha_vencimiento DATE,
    url_certificado VARCHAR(500),
    verificado BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_certificaciones_abogado ON abogados_certificaciones(abogado_id);

-- ============================================================================
-- 6. Reviews / Ratings
-- ============================================================================
CREATE TABLE IF NOT EXISTS abogados_valoraciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    abogado_id UUID NOT NULL REFERENCES abogados(id) ON DELETE CASCADE,
    usuario_id UUID,
    calificacion INTEGER NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario TEXT,
    caso_tipo VARCHAR(50),
    fecha_servicio DATE,
    verificado BOOLEAN DEFAULT FALSE,
    respuesta_abogado TEXT,
    fecha_respuesta TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_valoraciones_abogado ON abogados_valoraciones(abogado_id);
CREATE INDEX IF NOT EXISTS idx_valoraciones_calificacion ON abogados_valoraciones(calificacion);

-- ============================================================================
-- 7. Event Log (Timestamps para todos los eventos)
-- ============================================================================
CREATE TABLE IF NOT EXISTS event_log_legal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID,
    actor_type VARCHAR(30) DEFAULT 'lawyer' CHECK (actor_type IN ('lawyer', 'admin', 'system', 'api_client', 'user')),
    organizacion_id UUID REFERENCES organizaciones_legales(id) ON DELETE SET NULL,
    event_type VARCHAR(100) NOT NULL,
    event_category VARCHAR(50) DEFAULT 'general'
        CHECK (event_category IN ('auth', 'lawyer', 'subscription', 'billing', 'case', 'document', 'ai', 'admin', 'system', 'general', 'verification')),
    resource_type VARCHAR(50),
    resource_id UUID,
    payload JSONB DEFAULT '{}',
    source VARCHAR(50) DEFAULT 'api',
    ip_address INET,
    user_agent TEXT,
    integrity_hash VARCHAR(64),
    resultado VARCHAR(20) DEFAULT 'success' CHECK (resultado IN ('success', 'failure', 'warning', 'info')),
    error_message TEXT,
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    schema_version INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_event_log_legal_actor ON event_log_legal(actor_id);
CREATE INDEX IF NOT EXISTS idx_event_log_legal_type ON event_log_legal(event_type);
CREATE INDEX IF NOT EXISTS idx_event_log_legal_category ON event_log_legal(event_category);
CREATE INDEX IF NOT EXISTS idx_event_log_legal_timestamp ON event_log_legal(event_timestamp);
CREATE INDEX IF NOT EXISTS idx_event_log_legal_resource ON event_log_legal(resource_type, resource_id);

-- ============================================================================
-- 8. Audit Log
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_log_legal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID,
    actor_type VARCHAR(30) DEFAULT 'lawyer',
    actor_email VARCHAR(255),
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_legal_actor ON audit_log_legal(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_legal_action ON audit_log_legal(action);
CREATE INDEX IF NOT EXISTS idx_audit_legal_table ON audit_log_legal(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_legal_timestamp ON audit_log_legal(action_timestamp);

-- ============================================================================
-- Triggers: Auto-update updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY['organizaciones_legales', 'planes_suscripcion_legal', 'suscripciones_legales', 'abogados'])
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trigger_updated_at_%s ON %I', t, t);
        EXECUTE format('CREATE TRIGGER trigger_updated_at_%s BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()', t, t);
    END LOOP;
END;
$$;

-- ============================================================================
-- Row Level Security
-- ============================================================================
ALTER TABLE abogados ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizaciones_legales ENABLE ROW LEVEL SECURITY;
ALTER TABLE suscripciones_legales ENABLE ROW LEVEL SECURITY;
ALTER TABLE abogados_certificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE abogados_valoraciones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Verified lawyers public" ON abogados FOR SELECT
    USING (estado_verificacion = 'verificado' AND activo = TRUE);
CREATE POLICY "Lawyers see own profile" ON abogados FOR SELECT
    USING (auth.uid() = auth_user_id);
CREATE POLICY "Lawyers update own" ON abogados FOR UPDATE
    USING (auth.uid() = auth_user_id) WITH CHECK (auth.uid() = auth_user_id);
CREATE POLICY "Anyone can register" ON abogados FOR INSERT WITH CHECK (TRUE);

CREATE POLICY "Active orgs visible" ON organizaciones_legales FOR SELECT USING (estado = 'activo');
CREATE POLICY "Anyone can register org" ON organizaciones_legales FOR INSERT WITH CHECK (TRUE);

CREATE POLICY "Certifications public" ON abogados_certificaciones FOR SELECT
    USING (EXISTS (SELECT 1 FROM abogados WHERE abogados.id = abogado_id AND estado_verificacion = 'verificado' AND activo = TRUE));
CREATE POLICY "Verified reviews public" ON abogados_valoraciones FOR SELECT USING (verificado = TRUE);

-- ============================================================================
-- View: Active verified lawyers with cached rating
-- ============================================================================
CREATE OR REPLACE VIEW v_abogados_activos AS
SELECT 
    a.id, a.nombres, a.apellidos, a.tarjeta_profesional, a.email, a.telefono,
    a.departamento, a.municipio, a.departamentos_cobertura, a.especialidades,
    a.anos_experiencia, a.casos_soat_atendidos, a.nombre_bufete, a.tipo_practica,
    a.sitio_web, a.descripcion_servicios, a.tarifa_consulta,
    a.calificacion_promedio, a.total_valoraciones,
    a.tasa_respuesta, a.tiempo_respuesta_promedio,
    a.disponibilidad, a.acepta_casos_emergencia,
    a.organizacion_id, a.suscripcion_id,
    a.perfil_scoring, a.segmento,
    ol.nombre_comercial AS nombre_organizacion,
    psl.codigo AS plan_codigo,
    a.created_at
FROM abogados a
LEFT JOIN organizaciones_legales ol ON a.organizacion_id = ol.id
LEFT JOIN suscripciones_legales sl ON a.suscripcion_id = sl.id
LEFT JOIN planes_suscripcion_legal psl ON sl.plan_id = psl.id
WHERE a.estado_verificacion = 'verificado' AND a.activo = TRUE;