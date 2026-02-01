from sqlalchemy import Column, Integer, String, Boolean, Date, Text, ARRAY, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB, TIMESTAMP
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime

Base = declarative_base()


class Abogado(Base):
    """
    SQLAlchemy model for Colombian lawyers in the SOAT Connect platform.
    
    This model represents all the information required for a lawyer to register
    and be verified on the platform to handle SOAT (traffic accident insurance) claims.
    """
    __tablename__ = 'abogados'

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # ========================================================================
    # Personal Identification
    # ========================================================================
    tipo_documento = Column(String(20), nullable=False)  # CC, CE, PASAPORTE
    numero_documento = Column(String(20), unique=True, nullable=False)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    fecha_nacimiento = Column(Date, nullable=True)
    genero = Column(String(20), nullable=True)  # Masculino, Femenino, Otro, Prefiero no decir
    
    # ========================================================================
    # Professional Credentials
    # ========================================================================
    # Tarjeta Profesional de Abogado - issued by Consejo Superior de la Judicatura
    tarjeta_profesional = Column(String(50), unique=True, nullable=False)
    universidad = Column(String(200), nullable=False)
    fecha_grado = Column(Date, nullable=False)
    colegio_abogados = Column(String(200), nullable=True)
    numero_colegiatura = Column(String(50), nullable=True)
    
    # ========================================================================
    # Contact Information
    # ========================================================================
    email = Column(String(255), unique=True, nullable=False)
    telefono = Column(String(20), nullable=False)
    telefono_alternativo = Column(String(20), nullable=True)
    direccion_oficina = Column(Text, nullable=False)
    departamento = Column(String(100), nullable=False)
    municipio = Column(String(100), nullable=False)
    codigo_postal = Column(String(10), nullable=True)
    
    # ========================================================================
    # Geographic Coverage
    # ========================================================================
    departamentos_cobertura = Column(ARRAY(String), nullable=False, default=[])
    municipios_cobertura = Column(ARRAY(String), nullable=True, default=[])
    cobertura_nacional = Column(Boolean, default=False)
    
    # ========================================================================
    # Professional Details
    # ========================================================================
    especialidades = Column(ARRAY(String), nullable=False, default=[])
    anos_experiencia = Column(Integer, nullable=True)
    casos_soat_atendidos = Column(Integer, default=0)
    descripcion_servicios = Column(Text, nullable=True)
    tarifa_consulta = Column(String(100), nullable=True)
    idiomas = Column(ARRAY(String), default=['Español'])
    
    # ========================================================================
    # Business Information
    # ========================================================================
    nombre_bufete = Column(String(200), nullable=True)
    tipo_practica = Column(String(50), nullable=True)  # Independiente, Bufete, Consultorio Jurídico, Otro
    nit_bufete = Column(String(20), nullable=True)
    sitio_web = Column(String(255), nullable=True)
    linkedin = Column(String(255), nullable=True)
    
    # ========================================================================
    # Verification Status
    # ========================================================================
    estado_verificacion = Column(String(20), default='pendiente')  # pendiente, en_revision, verificado, rechazado, suspendido
    documentos_verificacion = Column(JSONB, default={})
    fecha_verificacion = Column(TIMESTAMP(timezone=True), nullable=True)
    verificado_por = Column(UUID(as_uuid=True), nullable=True)
    notas_verificacion = Column(Text, nullable=True)
    motivo_rechazo = Column(Text, nullable=True)
    
    # ========================================================================
    # Terms and Consent
    # ========================================================================
    acepta_terminos = Column(Boolean, nullable=False, default=False)
    acepta_tratamiento_datos = Column(Boolean, nullable=False, default=False)
    fecha_aceptacion_terminos = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # ========================================================================
    # Account Status
    # ========================================================================
    activo = Column(Boolean, default=True)
    fecha_ultimo_acceso = Column(TIMESTAMP(timezone=True), nullable=True)
    
    # ========================================================================
    # Authentication
    # ========================================================================
    auth_user_id = Column(UUID(as_uuid=True), unique=True, nullable=True)
    
    # ========================================================================
    # Timestamps
    # ========================================================================
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)
    updated_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    certificaciones = relationship("AbogadoCertificacion", back_populates="abogado", cascade="all, delete-orphan")
    valoraciones = relationship("AbogadoValoracion", back_populates="abogado", cascade="all, delete-orphan")

    # Table constraints
    __table_args__ = (
        CheckConstraint(
            "tipo_documento IN ('CC', 'CE', 'PASAPORTE')",
            name='check_tipo_documento'
        ),
        CheckConstraint(
            "estado_verificacion IN ('pendiente', 'en_revision', 'verificado', 'rechazado', 'suspendido')",
            name='check_estado_verificacion'
        ),
        CheckConstraint(
            "tipo_practica IN ('Independiente', 'Bufete', 'Consultorio Jurídico', 'Otro') OR tipo_practica IS NULL",
            name='check_tipo_practica'
        ),
        CheckConstraint(
            "anos_experiencia >= 0 OR anos_experiencia IS NULL",
            name='check_anos_experiencia'
        ),
        CheckConstraint(
            "casos_soat_atendidos >= 0",
            name='check_casos_soat'
        ),
    )

    def __repr__(self):
        return f"<Abogado(id={self.id}, nombre='{self.nombres} {self.apellidos}', tarjeta='{self.tarjeta_profesional}')>"


class AbogadoCertificacion(Base):
    """
    Model for lawyer certifications and continuing education.
    """
    __tablename__ = 'abogados_certificaciones'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    abogado_id = Column(UUID(as_uuid=True), ForeignKey('abogados.id', ondelete='CASCADE'), nullable=False)
    nombre_certificacion = Column(String(200), nullable=False)
    institucion = Column(String(200), nullable=False)
    fecha_obtencion = Column(Date, nullable=False)
    fecha_vencimiento = Column(Date, nullable=True)
    url_certificado = Column(String(500), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)

    # Relationship
    abogado = relationship("Abogado", back_populates="certificaciones")

    def __repr__(self):
        return f"<Certificacion(id={self.id}, nombre='{self.nombre_certificacion}')>"


class AbogadoValoracion(Base):
    """
    Model for lawyer reviews and ratings from clients.
    """
    __tablename__ = 'abogados_valoraciones'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    abogado_id = Column(UUID(as_uuid=True), ForeignKey('abogados.id', ondelete='CASCADE'), nullable=False)
    usuario_id = Column(UUID(as_uuid=True), nullable=True)
    calificacion = Column(Integer, nullable=False)
    comentario = Column(Text, nullable=True)
    caso_tipo = Column(String(50), nullable=True)  # SOAT, accidente, etc.
    fecha_servicio = Column(Date, nullable=True)
    verificado = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP(timezone=True), default=datetime.utcnow)

    # Relationship
    abogado = relationship("Abogado", back_populates="valoraciones")

    # Constraints
    __table_args__ = (
        CheckConstraint('calificacion >= 1 AND calificacion <= 5', name='check_calificacion'),
    )

    def __repr__(self):
        return f"<Valoracion(id={self.id}, calificacion={self.calificacion})>"
