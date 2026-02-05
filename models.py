"""
SQLAlchemy models for SOAT Connect Lawyer Registry (v2.0 - Future-Proof).

Includes: Legal Organizations (Bufetes), Subscription Plans, Subscriptions,
Lawyers, Certifications, Reviews, Event Log, Audit Log.
"""
from sqlalchemy import (
    Column, Integer, String, Boolean, Date, Text, ARRAY,
    ForeignKey, CheckConstraint, Numeric
)
from sqlalchemy.dialects.postgresql import UUID, JSONB, TIMESTAMP, INET
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime

Base = declarative_base()


# ============================================================================
# 1. Legal Organizations (Bufetes)
# ============================================================================
class OrganizacionLegal(Base):
    """Law firms, legal consultancies, legal organizations."""
    __tablename__ = 'organizaciones_legales'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nombre_legal = Column(String(300), nullable=False)
    nombre_comercial = Column(String(300), nullable=True)
    tipo_organizacion = Column(String(50), nullable=False, default='bufete')
    nit = Column(String(20), unique=True, nullable=True)
    digito_verificacion = Column(String(1), nullable=True)
    representante_legal = Column(String(200), nullable=True)
    email_corporativo = Column(String(255), nullable=False)
    telefono_corporativo = Column(String(20), nullable=True)
    sitio_web = Column(String(500), nullable=True)
    direccion = Column(Text, nullable=True)
    departamento = Column(String(100), nullable=True)
    municipio = Column(String(100), nullable=True)
    codigo_postal = Column(String(10), nullable=True)
    pais = Column(String(50), default='Colombia')
    latitud = Column(Numeric(10, 7), nullable=True)
    longitud = Column(Numeric(10, 7), nullable=True)
    tamano = Column(String(30), nullable=True)
    numero_abogados = Column(Integer, default=1)
    especialidades_principales = Column(ARRAY(String), default=[])
    logo_url = Column(String(500), nullable=True)
    descripcion = Column(Text, nullable=True)
    estado = Column(String(20), default='activo')
    verificado = Column(Boolean, default=False)
    fecha_verificacion = Column(TIMESTAMP(timezone=True), nullable=True)
    metadata = Column(JSONB, default={})
    schema_version = Column(Integer, default=1)
    source_of_truth = Column(String(50), default='manual')
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    updated_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    abogados = relationship("Abogado", back_populates="organizacion")
    suscripciones = relationship("SuscripcionLegal", back_populates="organizacion")

    __table_args__ = (
        CheckConstraint(
            "tipo_organizacion IN ('bufete', 'consultorio_juridico', 'corporacion_legal', 'ong_legal', 'otro')",
            name='check_tipo_org_legal'
        ),
        CheckConstraint(
            "estado IN ('activo', 'inactivo', 'suspendido', 'pendiente_verificacion')",
            name='check_estado_org_legal'
        ),
    )

    def __repr__(self):
        return f"<OrganizacionLegal(id={self.id}, nombre='{self.nombre_legal}')>"


# ============================================================================
# 2. Subscription Plans
# ============================================================================
class PlanSuscripcionLegal(Base):
    """Subscription plans: Starter, Pro, Enterprise for lawyers/firms."""
    __tablename__ = 'planes_suscripcion_legal'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    codigo = Column(String(30), unique=True, nullable=False)
    nombre = Column(String(100), nullable=False)
    descripcion = Column(Text, nullable=True)
    tipo_cliente = Column(String(30), nullable=False, default='abogado')
    precio_mensual = Column(Numeric(12, 2), default=0)
    precio_anual = Column(Numeric(12, 2), default=0)
    moneda = Column(String(3), default='COP')
    max_abogados = Column(Integer, nullable=True)
    max_casos_activos = Column(Integer, nullable=True)
    max_consultas_mes = Column(Integer, nullable=True)
    max_documentos = Column(Integer, nullable=True)
    features = Column(JSONB, default={})
    activo = Column(Boolean, default=True)
    visible = Column(Boolean, default=True)
    orden_display = Column(Integer, default=0)
    version = Column(Integer, default=1)
    metadata = Column(JSONB, default={})
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    updated_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    suscripciones = relationship("SuscripcionLegal", back_populates="plan")

    __table_args__ = (
        CheckConstraint("tipo_cliente IN ('abogado', 'bufete', 'todos')", name='check_tipo_cliente_legal'),
    )

    def __repr__(self):
        return f"<PlanSuscripcionLegal(codigo='{self.codigo}', nombre='{self.nombre}')>"


# ============================================================================
# 3. Subscriptions
# ============================================================================
class SuscripcionLegal(Base):
    """Active subscriptions for lawyers/firms."""
    __tablename__ = 'suscripciones_legales'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    abogado_id = Column(UUID(as_uuid=True), nullable=True)
    organizacion_id = Column(UUID(as_uuid=True), ForeignKey('organizaciones_legales.id', ondelete='SET NULL'), nullable=True)
    plan_id = Column(UUID(as_uuid=True), ForeignKey('planes_suscripcion_legal.id'), nullable=False)
    estado = Column(String(30), default='activa')
    fecha_inicio = Column(TIMESTAMP(timezone=True), nullable=False, default=datetime.utcnow)
    fecha_fin = Column(TIMESTAMP(timezone=True), nullable=True)
    fecha_proximo_cobro = Column(TIMESTAMP(timezone=True), nullable=True)
    periodo_facturacion = Column(String(20), default='mensual')
    es_trial = Column(Boolean, default=False)
    dias_trial = Column(Integer, default=14)
    monto_actual = Column(Numeric(12, 2), nullable=True)
    moneda = Column(String(3), default='COP')
    metodo_pago = Column(JSONB, default={})
    consultas_usadas_mes = Column(Integer, default=0)
    casos_activos_actual = Column(Integer, default=0)
    limites_custom = Column(JSONB, default={})
    motivo_cancelacion = Column(Text, nullable=True)
    fecha_cancelacion = Column(TIMESTAMP(timezone=True), nullable=True)
    metadata = Column(JSONB, default={})
    schema_version = Column(Integer, default=1)
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    updated_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    organizacion = relationship("OrganizacionLegal", back_populates="suscripciones")
    plan = relationship("PlanSuscripcionLegal", back_populates="suscripciones")

    __table_args__ = (
        CheckConstraint(
            "estado IN ('trial', 'activa', 'pausada', 'cancelada', 'vencida', 'pendiente_pago')",
            name='check_estado_suscripcion_legal'
        ),
    )

    def __repr__(self):
        return f"<SuscripcionLegal(id={self.id}, estado='{self.estado}')>"


# ============================================================================
# 4. Lawyers (Extended)
# ============================================================================
class Abogado(Base):
    """Lawyer registration with future-proof fields."""
    __tablename__ = 'abogados'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Organization & Subscription
    organizacion_id = Column(UUID(as_uuid=True), ForeignKey('organizaciones_legales.id', ondelete='SET NULL'), nullable=True)
    suscripcion_id = Column(UUID(as_uuid=True), ForeignKey('suscripciones_legales.id', ondelete='SET NULL'), nullable=True)

    # Personal Identification
    tipo_documento = Column(String(20), nullable=False)
    numero_documento = Column(String(20), unique=True, nullable=False)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    fecha_nacimiento = Column(Date, nullable=True)
    genero = Column(String(20), nullable=True)
    identity_proofs = Column(JSONB, default=[])

    # Professional Credentials
    tarjeta_profesional = Column(String(50), unique=True, nullable=False)
    universidad = Column(String(200), nullable=False)
    fecha_grado = Column(Date, nullable=False)
    colegio_abogados = Column(String(200), nullable=True)
    numero_colegiatura = Column(String(50), nullable=True)

    # Contact
    email = Column(String(255), unique=True, nullable=False)
    telefono = Column(String(20), nullable=False)
    telefono_alternativo = Column(String(20), nullable=True)
    direccion_oficina = Column(Text, nullable=False)
    departamento = Column(String(100), nullable=False)
    municipio = Column(String(100), nullable=False)
    codigo_postal = Column(String(10), nullable=True)
    pais = Column(String(50), default='Colombia')
    latitud = Column(Numeric(10, 7), nullable=True)
    longitud = Column(Numeric(10, 7), nullable=True)

    # Coverage
    departamentos_cobertura = Column(ARRAY(String), nullable=False, default=[])
    municipios_cobertura = Column(ARRAY(String), nullable=True, default=[])
    cobertura_nacional = Column(Boolean, default=False)

    # Professional Details
    especialidades = Column(ARRAY(String), nullable=False, default=[])
    anos_experiencia = Column(Integer, nullable=True)
    casos_soat_atendidos = Column(Integer, default=0)
    descripcion_servicios = Column(Text, nullable=True)
    tarifa_consulta = Column(String(100), nullable=True)
    idiomas = Column(ARRAY(String), default=['Español'])

    # Availability
    disponibilidad = Column(JSONB, default={})
    acepta_casos_emergencia = Column(Boolean, default=False)

    # Business
    nombre_bufete = Column(String(200), nullable=True)
    tipo_practica = Column(String(50), nullable=True)
    nit_bufete = Column(String(20), nullable=True)
    sitio_web = Column(String(255), nullable=True)
    linkedin = Column(String(255), nullable=True)

    # Verification
    estado_verificacion = Column(String(20), default='pendiente')
    documentos_verificacion = Column(JSONB, default={})
    fecha_verificacion = Column(TIMESTAMP(timezone=True), nullable=True)
    verificado_por = Column(UUID(as_uuid=True), nullable=True)
    notas_verificacion = Column(Text, nullable=True)
    motivo_rechazo = Column(Text, nullable=True)

    # Terms
    acepta_terminos = Column(Boolean, nullable=False, default=False)
    acepta_tratamiento_datos = Column(Boolean, nullable=False, default=False)
    fecha_aceptacion_terminos = Column(TIMESTAMP(timezone=True), nullable=True)

    # Account
    activo = Column(Boolean, default=True)
    fecha_ultimo_acceso = Column(TIMESTAMP(timezone=True), nullable=True)

    # Performance (cached)
    calificacion_promedio = Column(Numeric(3, 2), default=0)
    total_valoraciones = Column(Integer, default=0)
    tasa_respuesta = Column(Numeric(5, 2), default=0)
    tiempo_respuesta_promedio = Column(Integer, default=0)

    # AI & Scoring
    perfil_scoring = Column(JSONB, default={})
    segmento = Column(String(50), nullable=True)

    # Auth
    auth_user_id = Column(UUID(as_uuid=True), unique=True, nullable=True)

    # Future-proof
    metadata = Column(JSONB, default={})
    tags = Column(ARRAY(String), default=[])
    schema_version = Column(Integer, default=1)
    source_of_truth = Column(String(50), default='web_form')

    # Timestamps
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    updated_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    organizacion = relationship("OrganizacionLegal", back_populates="abogados")
    certificaciones = relationship("AbogadoCertificacion", back_populates="abogado", cascade="all, delete-orphan")
    valoraciones = relationship("AbogadoValoracion", back_populates="abogado", cascade="all, delete-orphan")

    __table_args__ = (
        CheckConstraint("tipo_documento IN ('CC', 'CE', 'PASAPORTE')", name='check_tipo_documento'),
        CheckConstraint("estado_verificacion IN ('pendiente', 'en_revision', 'verificado', 'rechazado', 'suspendido')", name='check_estado_verificacion'),
        CheckConstraint("tipo_practica IN ('Independiente', 'Bufete', 'Consultorio Jurídico', 'Otro') OR tipo_practica IS NULL", name='check_tipo_practica'),
        CheckConstraint("anos_experiencia >= 0 OR anos_experiencia IS NULL", name='check_anos_experiencia'),
        CheckConstraint("casos_soat_atendidos >= 0", name='check_casos_soat'),
    )

    def __repr__(self):
        return f"<Abogado(id={self.id}, nombre='{self.nombres} {self.apellidos}', tarjeta='{self.tarjeta_profesional}')>"


# ============================================================================
# 5. Certifications
# ============================================================================
class AbogadoCertificacion(Base):
    """Lawyer certifications and continuing education."""
    __tablename__ = 'abogados_certificaciones'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    abogado_id = Column(UUID(as_uuid=True), ForeignKey('abogados.id', ondelete='CASCADE'), nullable=False)
    nombre_certificacion = Column(String(200), nullable=False)
    institucion = Column(String(200), nullable=False)
    fecha_obtencion = Column(Date, nullable=False)
    fecha_vencimiento = Column(Date, nullable=True)
    url_certificado = Column(String(500), nullable=True)
    verificado = Column(Boolean, default=False)
    metadata = Column(JSONB, default={})
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)

    abogado = relationship("Abogado", back_populates="certificaciones")

    def __repr__(self):
        return f"<Certificacion(id={self.id}, nombre='{self.nombre_certificacion}')>"


# ============================================================================
# 6. Reviews / Ratings
# ============================================================================
class AbogadoValoracion(Base):
    """Client reviews and ratings for lawyers."""
    __tablename__ = 'abogados_valoraciones'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    abogado_id = Column(UUID(as_uuid=True), ForeignKey('abogados.id', ondelete='CASCADE'), nullable=False)
    usuario_id = Column(UUID(as_uuid=True), nullable=True)
    calificacion = Column(Integer, nullable=False)
    comentario = Column(Text, nullable=True)
    caso_tipo = Column(String(50), nullable=True)
    fecha_servicio = Column(Date, nullable=True)
    verificado = Column(Boolean, default=False)
    respuesta_abogado = Column(Text, nullable=True)
    fecha_respuesta = Column(TIMESTAMP(timezone=True), nullable=True)
    metadata = Column(JSONB, default={})
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)

    abogado = relationship("Abogado", back_populates="valoraciones")

    __table_args__ = (
        CheckConstraint('calificacion >= 1 AND calificacion <= 5', name='check_calificacion'),
    )

    def __repr__(self):
        return f"<Valoracion(id={self.id}, calificacion={self.calificacion})>"


# ============================================================================
# 7. Event Log
# ============================================================================
class EventLogLegal(Base):
    """Timestamped event log for lawyer-registry events."""
    __tablename__ = 'event_log_legal'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_id = Column(UUID(as_uuid=True), nullable=True)
    actor_type = Column(String(30), default='lawyer')
    organizacion_id = Column(UUID(as_uuid=True), ForeignKey('organizaciones_legales.id', ondelete='SET NULL'), nullable=True)
    event_type = Column(String(100), nullable=False)
    event_category = Column(String(50), default='general')
    resource_type = Column(String(50), nullable=True)
    resource_id = Column(UUID(as_uuid=True), nullable=True)
    payload = Column(JSONB, default={})
    source = Column(String(50), default='api')
    ip_address = Column(INET, nullable=True)
    user_agent = Column(Text, nullable=True)
    integrity_hash = Column(String(64), nullable=True)
    resultado = Column(String(20), default='success')
    error_message = Column(Text, nullable=True)
    event_timestamp = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    processed = Column(Boolean, default=False)
    processed_at = Column(TIMESTAMP(timezone=True), nullable=True)
    metadata = Column(JSONB, default={})
    schema_version = Column(Integer, default=1)
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)

    def __repr__(self):
        return f"<EventLogLegal(type='{self.event_type}', ts='{self.event_timestamp}')>"


# ============================================================================
# 8. Audit Log
# ============================================================================
class AuditLogLegal(Base):
    """Audit trail for lawyer-registry changes."""
    __tablename__ = 'audit_log_legal'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    actor_id = Column(UUID(as_uuid=True), nullable=True)
    actor_type = Column(String(30), default='lawyer')
    actor_email = Column(String(255), nullable=True)
    action = Column(String(50), nullable=False)
    table_name = Column(String(100), nullable=False)
    record_id = Column(UUID(as_uuid=True), nullable=True)
    old_values = Column(JSONB, nullable=True)
    new_values = Column(JSONB, nullable=True)
    changed_fields = Column(ARRAY(String), nullable=True)
    ip_address = Column(INET, nullable=True)
    user_agent = Column(Text, nullable=True)
    request_id = Column(String(100), nullable=True)
    action_timestamp = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    metadata = Column(JSONB, default={})
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)

    def __repr__(self):
        return f"<AuditLogLegal(action='{self.action}', table='{self.table_name}')>"