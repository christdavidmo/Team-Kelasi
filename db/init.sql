-- =============================================================================
-- SKULA — Script d'initialisation de la base de données PostgreSQL
-- Architecture Multi-Tenant | Version 3.0
-- =============================================================================

-- Extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- Pour gen_random_uuid()

-- =============================================================================
-- 1. TABLE : TENANT_ETABLISSEMENT (table racine — aucune FK externe)
-- =============================================================================
CREATE TABLE IF NOT EXISTS tenant_etablissement (
    school_id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nom_etablissement   VARCHAR(255) NOT NULL,
    statut_tenant       VARCHAR(50)  NOT NULL CHECK (statut_tenant IN ('Créé', 'Actif', 'Suspendu', 'Archivé')),
    type_etablissement  VARCHAR(100) NOT NULL,
    pays                VARCHAR(100) NOT NULL,
    ville               VARCHAR(150) NOT NULL,
    adresse             TEXT,
    telephone           VARCHAR(30),
    email_contact       VARCHAR(255),
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP
);

-- =============================================================================
-- 2. TABLE : UTILISATEUR
-- =============================================================================
CREATE TABLE IF NOT EXISTS utilisateur (
    user_id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id           UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    nom                 VARCHAR(150) NOT NULL,
    prenom              VARCHAR(150) NOT NULL,
    email               VARCHAR(255) NOT NULL UNIQUE,
    mot_de_passe_hash   VARCHAR(255) NOT NULL,
    genre               VARCHAR(10)  CHECK (genre IN ('M', 'F')),
    telephone           VARCHAR(30),
    photo_url           TEXT,
    created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMP
);

-- =============================================================================
-- 3. MODULE RBAC — ROLE, PERMISSION, jointures
-- =============================================================================
CREATE TABLE IF NOT EXISTS role (
    role_id     SERIAL      PRIMARY KEY,
    nom_role    VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS permission (
    permission_id   SERIAL      PRIMARY KEY,
    code            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT
);

CREATE TABLE IF NOT EXISTS utilisateur_role (
    user_id         UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE CASCADE,
    role_id         INTEGER     NOT NULL REFERENCES role(role_id) ON DELETE RESTRICT,
    assigned_at     TIMESTAMP   NOT NULL DEFAULT NOW(),
    assigned_by     UUID        REFERENCES utilisateur(user_id) ON DELETE SET NULL,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS role_permission (
    role_id         INTEGER     NOT NULL REFERENCES role(role_id) ON DELETE CASCADE,
    permission_id   INTEGER     NOT NULL REFERENCES permission(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- =============================================================================
-- 4. MODULE STRUCTURE SCOLAIRE
-- Ordre : SECTION → LEVEL → ACADEMIC_YEAR → TERM → CLASS → GROUP
-- =============================================================================
CREATE TABLE IF NOT EXISTS section (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    name        VARCHAR(100) NOT NULL,
    description TEXT,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS level (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    section_id  UUID        NOT NULL REFERENCES section(id) ON DELETE RESTRICT,
    name        VARCHAR(50)  NOT NULL,
    order_index INTEGER     NOT NULL DEFAULT 0,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS academic_year (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    label       VARCHAR(50)  NOT NULL,
    start_date  DATE        NOT NULL,
    end_date    DATE        NOT NULL,
    is_current  BOOLEAN     NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_academic_year_dates CHECK (end_date > start_date)
);

CREATE TABLE IF NOT EXISTS term (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    academic_year_id UUID        NOT NULL REFERENCES academic_year(id) ON DELETE RESTRICT,
    name             VARCHAR(50)  NOT NULL,
    start_date       DATE        NOT NULL,
    end_date         DATE        NOT NULL,
    CONSTRAINT chk_term_dates CHECK (end_date > start_date)
);

CREATE TABLE IF NOT EXISTS class (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    level_id         UUID        NOT NULL REFERENCES level(id) ON DELETE RESTRICT,
    academic_year_id UUID        NOT NULL REFERENCES academic_year(id) ON DELETE RESTRICT,
    name             VARCHAR(100) NOT NULL,
    effectif_max     INTEGER,
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at       TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "group" (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    class_id    UUID        NOT NULL REFERENCES class(id) ON DELETE RESTRICT,
    name        VARCHAR(50)  NOT NULL,
    effectif_max INTEGER,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP
);

-- =============================================================================
-- 5. MODULE ACADÉMIQUE — ACTEURS
-- Ordre : PARENT → STUDENT → PARENT_STUDENT → TEACHER
-- =============================================================================
CREATE TABLE IF NOT EXISTS parent (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    user_id     UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    nom         VARCHAR(150) NOT NULL,
    prenom      VARCHAR(150) NOT NULL,
    telephone   VARCHAR(30),
    lien_parente VARCHAR(50) NOT NULL CHECK (lien_parente IN ('Père', 'Mère', 'Tuteur', 'Autre')),
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id       UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    user_id         UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    group_id        UUID        NOT NULL REFERENCES "group"(id) ON DELETE RESTRICT,
    matricule       VARCHAR(50)  NOT NULL UNIQUE,
    date_naissance  DATE        NOT NULL,
    lieu_naissance  VARCHAR(150),
    genre           VARCHAR(10)  CHECK (genre IN ('M', 'F')),
    statut          VARCHAR(50)  NOT NULL DEFAULT 'Actif' CHECK (statut IN ('Actif', 'Diplômé', 'Exclu', 'Transféré')),
    photo_url       TEXT,
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parent_student (
    parent_id           UUID        NOT NULL REFERENCES parent(id) ON DELETE CASCADE,
    student_id          UUID        NOT NULL REFERENCES student(id) ON DELETE CASCADE,
    school_id           UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    lien_parente        VARCHAR(50)  NOT NULL,
    is_primary_contact  BOOLEAN     NOT NULL DEFAULT FALSE,
    PRIMARY KEY (parent_id, student_id)
);

CREATE TABLE IF NOT EXISTS teacher (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id       UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    user_id         UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    specialite      VARCHAR(150),
    date_embauche   DATE,
    statut          VARCHAR(50)  NOT NULL DEFAULT 'Actif' CHECK (statut IN ('Actif', 'Congé', 'Retraité', 'Démissionnaire')),
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMP
);

-- =============================================================================
-- 6. MODULE PÉDAGOGIQUE — SUBJECT, CLASS_TEACHER_SUBJECT
-- =============================================================================
CREATE TABLE IF NOT EXISTS subject (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    section_id  UUID        REFERENCES section(id) ON DELETE SET NULL,
    name        VARCHAR(150) NOT NULL,
    coefficient FLOAT       NOT NULL DEFAULT 1,
    description TEXT,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_teacher_subject (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    group_id         UUID        NOT NULL REFERENCES "group"(id) ON DELETE RESTRICT,
    teacher_id       UUID        NOT NULL REFERENCES teacher(id) ON DELETE RESTRICT,
    subject_id       UUID        NOT NULL REFERENCES subject(id) ON DELETE RESTRICT,
    academic_year_id UUID        NOT NULL REFERENCES academic_year(id) ON DELETE RESTRICT,
    is_main_teacher  BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 7. TABLE : GRADE (Notes)
-- =============================================================================
CREATE TABLE IF NOT EXISTS grade (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id       UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    student_id      UUID        NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    subject_id      UUID        NOT NULL REFERENCES subject(id) ON DELETE RESTRICT,
    teacher_id      UUID        NOT NULL REFERENCES teacher(id) ON DELETE RESTRICT,
    group_id        UUID        NOT NULL REFERENCES "group"(id) ON DELETE RESTRICT,
    term_id         UUID        NOT NULL REFERENCES term(id) ON DELETE RESTRICT,
    value           FLOAT       NOT NULL CHECK (value >= 0),
    note_sur        FLOAT       NOT NULL DEFAULT 20 CHECK (note_sur > 0),
    type_evaluation VARCHAR(50)  NOT NULL CHECK (type_evaluation IN ('Devoir', 'Composition', 'Interrogation', 'Contrôle')),
    commentaire     TEXT,
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 8. TABLE : REPORT (Bulletin)
-- =============================================================================
CREATE TABLE IF NOT EXISTS report (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    student_id       UUID        NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    group_id         UUID        NOT NULL REFERENCES "group"(id) ON DELETE RESTRICT,
    term_id          UUID        NOT NULL REFERENCES term(id) ON DELETE RESTRICT,
    academic_year_id UUID        NOT NULL REFERENCES academic_year(id) ON DELETE RESTRICT,
    average          FLOAT       NOT NULL,
    rank             INTEGER,
    appreciation     TEXT,
    generated_at     TIMESTAMP   NOT NULL DEFAULT NOW(),
    document_url     TEXT
);

-- =============================================================================
-- 9. MODULE VIE SCOLAIRE — ATTENDANCE, DISCIPLINE
-- =============================================================================
CREATE TABLE IF NOT EXISTS attendance (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    student_id  UUID        NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    group_id    UUID        NOT NULL REFERENCES "group"(id) ON DELETE RESTRICT,
    teacher_id  UUID        NOT NULL REFERENCES teacher(id) ON DELETE RESTRICT,
    subject_id  UUID        REFERENCES subject(id) ON DELETE SET NULL,
    date        DATE        NOT NULL,
    status      VARCHAR(50)  NOT NULL CHECK (status IN ('Présent', 'Absent', 'Retard', 'Exclu')),
    justifie    BOOLEAN     NOT NULL DEFAULT FALSE,
    motif       TEXT,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS discipline (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id       UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    student_id      UUID        NOT NULL REFERENCES student(id) ON DELETE RESTRICT,
    reported_by     UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    type_incident   VARCHAR(100) NOT NULL,
    description     TEXT        NOT NULL,
    sanction        VARCHAR(100) CHECK (sanction IN ('Avertissement', 'Renvoi temporaire', 'Exclusion', 'Convocation')),
    date_incident   DATE        NOT NULL,
    created_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 10. MODULE FINANCE — PAYMENT, INVOICE, SUBSCRIPTION
-- =============================================================================
CREATE TABLE IF NOT EXISTS payment (
    paiement_id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id               UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    user_id                 UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    student_id              UUID        REFERENCES student(id) ON DELETE SET NULL,
    montant                 DECIMAL(10,2) NOT NULL CHECK (montant > 0),
    statut                  VARCHAR(50)  NOT NULL DEFAULT 'En attente' CHECK (statut IN ('En attente', 'Validé', 'Rejeté', 'Remboursé')),
    date_paiement           TIMESTAMP   NOT NULL DEFAULT NOW(),
    type_paiement           VARCHAR(100) NOT NULL,
    methode_paiement        VARCHAR(50)  NOT NULL CHECK (methode_paiement IN ('Espèces', 'Mobile Money', 'Virement', 'Chèque')),
    reference_transaction   VARCHAR(100) UNIQUE,
    created_by              UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    created_at              TIMESTAMP   NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS invoice (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    paiement_id UUID        NOT NULL REFERENCES payment(paiement_id) ON DELETE RESTRICT,
    numero_recu VARCHAR(50)  NOT NULL UNIQUE,
    pdf_url     TEXT,
    generated_at TIMESTAMP  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subscription (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    plan        VARCHAR(50)  NOT NULL CHECK (plan IN ('Starter', 'Pro', 'Enterprise')),
    statut      VARCHAR(50)  NOT NULL CHECK (statut IN ('Actif', 'Expiré', 'Suspendu', 'Annulé')),
    started_at  TIMESTAMP   NOT NULL,
    expires_at  TIMESTAMP   NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_subscription_dates CHECK (expires_at > started_at)
);

-- =============================================================================
-- 11. MODULE EMPLOI DU TEMPS
-- =============================================================================
CREATE TABLE IF NOT EXISTS schedule (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id        UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    group_id         UUID        NOT NULL REFERENCES "group"(id) ON DELETE RESTRICT,
    teacher_id       UUID        NOT NULL REFERENCES teacher(id) ON DELETE RESTRICT,
    subject_id       UUID        NOT NULL REFERENCES subject(id) ON DELETE RESTRICT,
    academic_year_id UUID        NOT NULL REFERENCES academic_year(id) ON DELETE RESTRICT,
    jour_semaine     VARCHAR(20)  NOT NULL CHECK (jour_semaine IN ('Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi')),
    heure_debut      TIME        NOT NULL,
    heure_fin        TIME        NOT NULL,
    salle            VARCHAR(50),
    created_at       TIMESTAMP   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_schedule_heures CHECK (heure_fin > heure_debut)
);

-- =============================================================================
-- 12. MODULE COMMUNICATION — MESSAGE, NOTIFICATION
-- =============================================================================
CREATE TABLE IF NOT EXISTS message (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id   UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    sender_id   UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    receiver_id UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE RESTRICT,
    content     TEXT        NOT NULL,
    read        BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notification (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE CASCADE,
    school_id    UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    type         VARCHAR(50)  NOT NULL CHECK (type IN ('ABSENCE', 'NOTE', 'PAIEMENT', 'MESSAGE', 'BULLETIN')),
    content      TEXT        NOT NULL,
    status       VARCHAR(50)  NOT NULL DEFAULT 'Non lu' CHECK (status IN ('Lu', 'Non lu')),
    device_token TEXT,
    created_at   TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 13. MODULE AUTHENTIFICATION — SESSION
-- =============================================================================
CREATE TABLE IF NOT EXISTS session (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID        NOT NULL REFERENCES utilisateur(user_id) ON DELETE CASCADE,
    refresh_token TEXT        NOT NULL,
    expires_at    TIMESTAMP   NOT NULL,
    ip_address    VARCHAR(50),
    user_agent    TEXT,
    device_id     VARCHAR(100),
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 14. TABLE : AUDIT_LOG
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id     UUID        NOT NULL REFERENCES tenant_etablissement(school_id) ON DELETE RESTRICT,
    user_id       UUID        REFERENCES utilisateur(user_id) ON DELETE SET NULL,
    action        VARCHAR(100) NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'EXPORT')),
    table_cible   VARCHAR(100) NOT NULL,
    record_id     UUID        NOT NULL,
    valeur_avant  JSONB,
    valeur_apres  JSONB,
    ip_address    VARCHAR(50),
    created_at    TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 15. INDEX — Performance & Scalabilité
-- =============================================================================

-- Index simples sur school_id
CREATE INDEX idx_utilisateur_school_id       ON utilisateur(school_id);
CREATE INDEX idx_student_school_id           ON student(school_id);
CREATE INDEX idx_teacher_school_id           ON teacher(school_id);
CREATE INDEX idx_grade_school_id             ON grade(school_id);
CREATE INDEX idx_attendance_school_id        ON attendance(school_id);
CREATE INDEX idx_message_school_id           ON message(school_id);
CREATE INDEX idx_payment_school_id           ON payment(school_id);
CREATE INDEX idx_schedule_school_id          ON schedule(school_id);
CREATE INDEX idx_notification_school_id      ON notification(school_id);
CREATE INDEX idx_audit_log_school_id         ON audit_log(school_id);
CREATE INDEX idx_discipline_school_id        ON discipline(school_id);

-- Index composites (tables à forte volumétrie)
CREATE INDEX idx_grade_school_student        ON grade(school_id, student_id);
CREATE INDEX idx_grade_school_term           ON grade(school_id, term_id);
CREATE INDEX idx_grade_school_term_subject   ON grade(school_id, term_id, subject_id);
CREATE INDEX idx_attendance_school_class     ON attendance(school_id, group_id, date);
CREATE INDEX idx_audit_school_date           ON audit_log(school_id, created_at);
CREATE INDEX idx_payment_school_student      ON payment(school_id, student_id, statut);
CREATE INDEX idx_schedule_school_group_jour  ON schedule(school_id, group_id, jour_semaine);
CREATE INDEX idx_message_receiver_read       ON message(school_id, receiver_id, read);
CREATE INDEX idx_student_school_group        ON student(school_id, group_id);
CREATE INDEX idx_session_user               ON session(user_id, expires_at);

-- =============================================================================
-- 16. ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Activation du RLS sur toutes les tables transactionnelles
ALTER TABLE utilisateur            ENABLE ROW LEVEL SECURITY;
ALTER TABLE student                ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher                ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_student         ENABLE ROW LEVEL SECURITY;
ALTER TABLE class                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE "group"                ENABLE ROW LEVEL SECURITY;
ALTER TABLE section                ENABLE ROW LEVEL SECURITY;
ALTER TABLE level                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_year          ENABLE ROW LEVEL SECURITY;
ALTER TABLE term                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject                ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_teacher_subject  ENABLE ROW LEVEL SECURITY;
ALTER TABLE grade                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE report                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance             ENABLE ROW LEVEL SECURITY;
ALTER TABLE discipline             ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment                ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice                ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription           ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedule               ENABLE ROW LEVEL SECURITY;
ALTER TABLE message                ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification           ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log              ENABLE ROW LEVEL SECURITY;

-- Policies d'isolation par tenant (school_id extrait du JWT via GUC)
CREATE POLICY tenant_isolation_utilisateur   ON utilisateur           USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_student       ON student               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_teacher       ON teacher               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_parent        ON parent                USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_parent_stu    ON parent_student        USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_class         ON class                 USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_group         ON "group"               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_section       ON section               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_level         ON level                 USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_acad_year     ON academic_year         USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_term          ON term                  USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_subject       ON subject               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_cts           ON class_teacher_subject USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_grade         ON grade                 USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_report        ON report                USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_attendance    ON attendance            USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_discipline    ON discipline            USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_payment       ON payment               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_invoice       ON invoice               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_subscription  ON subscription          USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_schedule      ON schedule              USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_message       ON message               USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_notification  ON notification          USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');
CREATE POLICY tenant_isolation_audit         ON audit_log             USING (school_id = current_setting('app.current_school_id', TRUE)::UUID OR current_user = 'skula_superadmin');

-- =============================================================================
-- 17. DONNÉES DE BASE — Rôles par défaut
-- =============================================================================
INSERT INTO role (nom_role, description) VALUES
    ('SUPER_ADMIN',    'Administrateur global de la plateforme SKULA'),
    ('TENANT_ADMIN',   'Administrateur d''un établissement'),
    ('FINANCE',        'Responsable financier'),
    ('ACADEMIC_ADMIN', 'Directeur pédagogique'),
    ('SECRETARY',      'Secrétaire'),
    ('SUPERVISOR',     'Surveillant / CPE'),
    ('COUNSELOR',      'Conseiller'),
    ('TEACHER',        'Enseignant'),
    ('PARENT',         'Parent d''élève'),
    ('STUDENT',        'Élève')
ON CONFLICT (nom_role) DO NOTHING;

-- =============================================================================
-- FIN DU SCRIPT
-- Base de données SKULA initialisée avec succès.
-- 23 tables | Multi-Tenant | RLS activé | Index optimisés
-- =============================================================================
