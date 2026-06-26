-- ====================================================================
-- FASE 1: CREACIÓN DE USUARIO BASE Y ASIGNACIÓN DE PRIVILEGIOS MÍNIMOS
-- DESCRIPCIÓN: Configuración inicial de acceso controlado para la app.
-- ====================================================================

-- 0. POLÍTICA DE SEGURIDAD PARA ROOT (Aislamiento de la cuenta Administradora)
ALTER USER 'root'@'localhost' IDENTIFIED BY 'MI_CONTRASENA_ROOT_SUPER_SEGURA';

-- 1. CREACIÓN DEL USUARIO INTERNO
CREATE USER 'usuario1'@'192.168.0.212' IDENTIFIED BY 'VALOR_SEGURO_O_VARIABLE_ENTORNO';

-- 2. ASIGNACIÓN DE PRIVILEGIOS MÍNIMOS INICIALES
GRANT SELECT, INSERT, UPDATE ON biblioteca_remota.* TO 'usuario1'@'192.168.0.212';

-- 3. AUDITORÍA Y VERIFICACIÓN INICIAL
SHOW GRANTS FOR 'usuario1'@'192.168.0.212';


-- ====================================================================
-- FASE 2: GESTIÓN DEL CICLO DE VIDA DE ACCESOS Y ESCALACIÓN CONTROLADA
-- DESCRIPCIÓN: Simulación de errores DDL, mantenimiento temporal 
--              y aislamiento de un rol de solo lectura.
-- ====================================================================

-- 1. CAMBIO DE CONTRASEÑA DEL USUARIO REMOTO
ALTER USER 'cliente_bd'@'192.168.1.50' IDENTIFIED BY 'NUEVA_CONTRASENA_SEGURO_O_VARIABLE';
FLUSH PRIVILEGES;

-- 2. CREACIÓN DE SEGUNDO USUARIO (ROL DE SOLO LECTURA)
CREATE USER 'lector_bd'@'192.168.1.50' IDENTIFIED BY 'CONTRASENA_LECTOR_SEGURA';
GRANT SELECT ON biblioteca_remota.* TO 'lector_bd'@'192.168.1.50';
FLUSH PRIVILEGES;

-- 3. COMPROBACIÓN DE PRIVILEGIOS (ROL: LECTOR_BD)
SELECT * FROM biblioteca_remota.libros;
-- INSERT INTO biblioteca_remota.libros (titulo) VALUES ('Libro de Prueba'); -- Operación denegada intencionalmente

-- 4. CREACIÓN DE TABLA 'PRESTAMOS' (EJECUTADO COMO ROOT / DBA)
CREATE TABLE biblioteca_remota.prestamos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    libro_id INT,
    fecha_prestamo DATE
);

-- 5. SIMULACIÓN DE FALLO DDL DESDE USUARIO REMOTO
-- CREATE TABLE biblioteca_remota.tabla_prueba (id INT); -- Código de error 1142 esperado (CREATE command denied)

-- 6. CONCESIÓN TEMPORAL DEL PERMISO 'CREATE'
GRANT CREATE ON biblioteca_remota.* TO 'cliente_bd'@'192.168.1.50';
FLUSH PRIVILEGES;

-- 7. VALIDACIÓN DE LA ESCALACIÓN DE PRIVILEGIOS
CREATE TABLE biblioteca_remota.prestamos_historico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    detalle TEXT
);

-- 8. REVOCACIÓN DEL PERMISO 'CREATE'
REVOKE CREATE ON biblioteca_remota.* FROM 'cliente_bd'@'192.168.1.50';
FLUSH PRIVILEGES;
