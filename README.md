# SOAT Connect - Lawyer Registry Data Model

Data model for lawyer registration in the SOAT Connect platform, designed for Colombian lawyers who handle SOAT (Seguro Obligatorio de Accidentes de Tránsito) claims.

## Colombian Lawyer Requirements

### Legal Requirements for Practicing Law in Colombia

To be a valid lawyer in Colombia and process SOAT claims, the following are required:

1. **Tarjeta Profesional de Abogado** (Professional Lawyer Card)
   - Issued by the Consejo Superior de la Judicatura (CSJ)
   - Required to practice law in Colombia
   - Format: Typically 6-digit number or alphanumeric code

2. **Cédula de Ciudadanía** (National ID)
   - Colombian national identification document
   - Required for all legal proceedings

3. **University Degree**
   - Title: "Abogado" (Lawyer)
   - From a university recognized by the Ministry of Education
   - Must be registered with the Ministry

4. **Professional Registration**
   - Registration with the Consejo Superior de la Judicatura
   - Active status (no suspensions or sanctions)
   - Can be verified at: https://sirna.ramajudicial.gov.co/

5. **Optional: Bar Association Membership**
   - Membership in a Colegio de Abogados (Bar Association)
   - Not mandatory but adds credibility

### Requirements for SOAT Claims Processing

1. **Specialization in Civil/Insurance Law** (recommended)
2. **Knowledge of Traffic Law** (Código Nacional de Tránsito - Ley 769 de 2002)
3. **Experience with insurance claims** (Ley 45 de 1990)
4. **Understanding of SOAT regulations** (Decreto 663 de 1993)
5. **Geographic coverage** (municipalities/departments served)

## Data Model Overview

### Main Entity: `abogados` (Lawyers)

Contains all lawyer registration information including:

| Category | Fields |
|----------|--------|
| **Personal ID** | tipo_documento, numero_documento, nombres, apellidos |
| **Professional** | tarjeta_profesional, universidad, fecha_grado, colegio_abogados |
| **Contact** | email, telefono, direccion, departamento, municipio |
| **Geographic** | departamentos_cobertura, municipios_cobertura |
| **Professional** | especialidades, anos_experiencia, casos_soat_atendidos |
| **Business** | nombre_bufete, tipo_practica, sitio_web |
| **Verification** | estado_verificacion, documentos_verificacion |
| **Terms** | acepta_terminos, fecha_aceptacion |

## Files

| File | Description |
|------|-------------|
| `schema.sql` | PostgreSQL/Supabase schema with RLS policies |
| `models.py` | SQLAlchemy ORM models |
| `database.py` | Database connection and operations |
| `deploy.sh` | Deployment script for Supabase |
| `requirements.txt` | Python dependencies |

## Deployment

### Prerequisites

- Supabase account with project created
- Python 3.10+
- Environment variables set

### Environment Variables

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_KEY="your-service-role-key"
```

### Deploy to Supabase

```bash
# Make executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### Manual Deployment

1. Go to Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste contents of `schema.sql`
4. Run the query

## Schema Details

### Table: `abogados`

```sql
CREATE TABLE abogados (
    id UUID PRIMARY KEY,
    -- Personal identification
    tipo_documento VARCHAR NOT NULL,
    numero_documento VARCHAR UNIQUE NOT NULL,
    nombres VARCHAR NOT NULL,
    apellidos VARCHAR NOT NULL,
    fecha_nacimiento DATE,
    genero VARCHAR,
    
    -- Professional credentials
    tarjeta_profesional VARCHAR UNIQUE NOT NULL,
    universidad VARCHAR NOT NULL,
    fecha_grado DATE NOT NULL,
    colegio_abogados VARCHAR,
    numero_colegiatura VARCHAR,
    
    -- Contact information
    email VARCHAR UNIQUE NOT NULL,
    telefono VARCHAR NOT NULL,
    telefono_alternativo VARCHAR,
    direccion_oficina TEXT NOT NULL,
    departamento VARCHAR NOT NULL,
    municipio VARCHAR NOT NULL,
    
    -- Geographic coverage
    departamentos_cobertura TEXT[],
    municipios_cobertura TEXT[],
    cobertura_nacional BOOLEAN DEFAULT FALSE,
    
    -- Professional details
    especialidades TEXT[],
    anos_experiencia INTEGER,
    casos_soat_atendidos INTEGER DEFAULT 0,
    descripcion_servicios TEXT,
    
    -- Business information
    nombre_bufete VARCHAR,
    tipo_practica VARCHAR,
    nit_bufete VARCHAR,
    sitio_web VARCHAR,
    
    -- Verification
    estado_verificacion VARCHAR DEFAULT 'pendiente',
    documentos_verificacion JSONB,
    fecha_verificacion TIMESTAMP,
    verificado_por VARCHAR,
    notas_verificacion TEXT,
    
    -- Terms and status
    acepta_terminos BOOLEAN NOT NULL,
    acepta_tratamiento_datos BOOLEAN NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Verification States

| State | Description |
|-------|-------------|
| `pendiente` | Awaiting document review |
| `en_revision` | Documents under review |
| `verificado` | Approved and verified |
| `rechazado` | Application rejected |
| `suspendido` | Account suspended |

### Specializations (especialidades)

- Derecho Civil
- Derecho de Seguros
- Derecho de Tránsito
- Responsabilidad Civil
- Derecho del Consumidor
- Derecho Médico
- Derecho Laboral

## Indexes

The schema includes indexes for:
- `email` - Fast lookup for login
- `tarjeta_profesional` - Unique professional ID lookup
- `numero_documento` - National ID lookup
- `departamento`, `municipio` - Geographic filtering
- `estado_verificacion` - Status filtering
- GIN index on `departamentos_cobertura` for array searches

## Row Level Security (RLS)

The schema includes RLS policies for:
- Public read access for verified lawyers
- Self-management for own profile
- Admin access for verification management

## Migration

To add this table to an existing database:

```sql
-- Run schema.sql in Supabase SQL Editor
-- Or use the migration file in deployment/
```

## API Integration

This data model is used by the `soat-conecta-lawyer-registry` API.

See the API documentation for endpoint details.