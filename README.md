# 🛡️ Laboratorio Práctico: Control de Accesos, Privilegio Mínimo y Hardening de Base de Datos

## 📝 Descripción del Proyecto
Este laboratorio práctico está enfocado en la seguridad, gestión de usuarios y control de accesos en entornos relacionales (MariaDB / MySQL 8.4). 

El objetivo es desplegar un usuario seguro desde cero, aplicar el **Principio de Privilegio Mínimo**, gestionar el ciclo de vida de los permisos, documentar errores de denegación de servicios DDL (Data Definition Language) y aplicar técnicas reales de hardening.

---

## 💻 Código SQL del Laboratorio (Plantilla de Auditoría)

> ⚠️ **Nota de Seguridad:** El script se encuentra estructurado mediante etiquetas `/* ... */` y `--` para evitar ejecuciones accidentales en entornos de producción. Las contraseñas reales se han sustituido por placeholders.

```sql
-- ====================================================================
-- FASE 1: CREACIÓN DE USUARIO BASE Y ASIGNACIÓN DE PRIVILEGIOS MÍNIMOS
-- DESCRIPCIÓN: Configuración inicial de acceso controlado para la app.
-- ====================================================================

/*
-- 0. POLÍTICA DE SEGURIDAD PARA ROOT (Aislamiento de la cuenta Administradora)
-- Configuración para que el usuario administrador solo inicie sesión de forma local.
-- Esto bloquea intentos de acceso remoto a la cuenta 'root'.
ALTER USER 'root'@'localhost' IDENTIFIED BY 'MI_CONTRASENA_ROOT';

-- 1. CREACIÓN DEL USUARIO INTERNO
-- Restricción de acceso a la IP privada '192.168.0.212' (red local segura).
-- IMPORTANTE: Uso de placeholder para la contraseña por seguridad.
CREATE USER 'usuario1'@'192.168.0.212' 
IDENTIFIED BY 'VALOR_SEGURO_O_VARIABLE_ENTORNO';

-- 2. ASIGNACIÓN DE PRIVILEGIOS MÍNIMOS INICIALES
-- Concesión exclusiva de permisos de lectura (SELECT) y escritura básica (INSERT, UPDATE).
-- Restricción intencional de DELETE y DROP para proteger la integridad de los datos.
GRANT SELECT, INSERT, UPDATE
ON biblioteca_remota.*
TO 'usuario1'@'192.168.0.212';

-- 3. AUDITORÍA Y VERIFICACIÓN INICIAL
-- Verificación de la correcta aplicación de los privilegios asignados.
SHOW GRANTS FOR 'usuario1'@'192.168.0.212';
*/


-- ====================================================================
-- FASE 2: GESTIÓN DEL CICLO DE VIDA DE ACCESOS Y ESCALACIÓN CONTROLADA
-- DESCRIPCIÓN: Simulación de errores DDL, mantenimiento temporal 
--              y aislamiento de un rol de solo lectura.
-- ====================================================================

/*
-- 1. CAMBIO DE CONTRASEÑA DEL USUARIO REMOTO
-- Actualización de credenciales por directivas de rotación de seguridad.
ALTER USER 'cliente_bd'@'192.168.1.50' 
IDENTIFIED BY 'NUEVA_CONTRASENA_SEGURO_O_VARIABLE';

FLUSH PRIVILEGES; -- Recarga de las tablas de permisos en memoria RAM.


-- 2. CREACIÓN DE SEGUNDO USUARIO (ROL DE SOLO LECTURA)
-- Implementación del principio de privilegio mínimo mediante un perfil de consulta.
CREATE USER 'lector_bd'@'192.168.1.50' 
IDENTIFIED BY 'CONTRASENA_LECTOR_SEGURA';

GRANT SELECT 
ON biblioteca_remota.* 
TO 'lector_bd'@'192.168.1.50';

FLUSH PRIVILEGES;


-- 3. COMPROBACIÓN DE PRIVILEGIOS (ROL: LECTOR_BD)
-- Auditoría del comportamiento del usuario limitado para validar restricciones.
-- --------------------------------------------------------------------
-- Operación Exitosa: Lectura de registros permitida.
SELECT * FROM biblioteca_remota.libros;

-- Operación Fallida: El motor deniega la acción ("INSERT command denied").
-- INSERT INTO biblioteca_remota.libros (titulo) VALUES ('Libro de Prueba');


-- 4. CREACIÓN DE TABLA 'PRESTAMOS' (EJECUTADO COMO ROOT / DBA)
-- Despliegue de estructuras base desde la cuenta de administración central.
-- --------------------------------------------------------------------
CREATE TABLE biblioteca_remota.prestamos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    libro_id INT,
    fecha_prestamo DATE
);


-- 5. SIMULACIÓN DE FALLO DDL DESDE USUARIO REMOTO
-- --------------------------------------------------------------------
-- Ejecución desde 'cliente_bd' para validar el bloqueo de infraestructura:
-- CREATE TABLE biblioteca_remota.tabla_prueba (id INT);

-- ANÁLISIS DEL ERROR:
-- El servidor devuelve el código de error 1142: "CREATE command denied".
-- Al contar únicamente con permisos de manipulación de datos (DML: SELECT, INSERT, UPDATE),
-- el usuario carece de permisos de definición (DDL: CREATE), protegiendo el esquema.


-- 6. CONCESIÓN TEMPORAL DEL PERMISO 'CREATE'
-- Escalación controlada de privilegios orientada a una ventana de mantenimiento.
-- --------------------------------------------------------------------
GRANT CREATE 
ON biblioteca_remota.* 
TO 'cliente_bd'@'192.168.1.50';

FLUSH PRIVILEGES;


-- 7. VALIDACIÓN DE LA ESCALACIÓN DE PRIVILEGIOS
-- Confirmación de que el usuario remoto puede alterar el esquema del servidor con éxito.
-- --------------------------------------------------------------------
-- Ejecutado desde 'cliente_bd' (Operación exitosa):
CREATE TABLE biblioteca_remota.prestamos_historico (
    id INT AUTO_INCREMENT PRIMARY KEY,
    detalle TEXT
);


-- 8. REVOCACIÓN DEL PERMISO 'CREATE'
-- Cierre de la ventana de mantenimiento para retornar al estado seguro original.
-- --------------------------------------------------------------------
REVOKE CREATE 
ON biblioteca_remota.* 
FROM 'cliente_bd'@'192.168.1.50';

FLUSH PRIVILEGES; -- Aplicación inmediata de los cambios en el servidor.
*/
```

---

## 🔍 Conceptos Clave Implementados

1. **Principio de Privilegio Mínimo:** Restricción de acciones críticas (`DELETE`, `DROP`, `CREATE`) en cuentas de aplicación para mitigar el impacto de incidentes de seguridad como la inyección SQL (SQLi).
2. **Segmentación Perimetral por IP:** Uso estricto de direccionamiento privado (`192.168.0.212` y `192.168.1.50`) en lugar del comodín global (`%`) para reducir el vector de ataque expuesto.
3. **Arquitectura de Memoria (FLUSH PRIVILEGES):** Sincronización manual de la tabla de privilegios desde el almacenamiento en disco hacia la memoria RAM sin interrumpir la disponibilidad del servicio.
4. **Seguridad en Repositorios (Git):** Omisión de credenciales en texto plano dentro de la documentación pública, promoviendo el uso de variables de entorno o gestores de secretos.

---

## 🌐 Arquitectura de Red y Conectividad Empresarial

Modelado de entornos de infraestructura reales para garantizar el acceso seguro a los servicios de datos:

* **Túneles VPN Corporativos:** Configuración del servidor para denegar accesos externos directos. Los administradores interactúan con el puerto nativo (`3306`) de manera cifrada a través de una red privada virtual corporativa.
* **Ofuscación de Puertos:** Modificación del archivo de configuración (`my.ini` / `my.cnf`) para desviar el tráfico del puerto estándar a puertos altos (ej: `13306`), disminuyendo el escaneo automatizado y los ataques de fuerza bruta en fases de desarrollo.
* **Servidores Bastión (Jump Servers) y Túneles SSH:** Implementación de arquitecturas en la nube donde las bases de datos residen en subredes privadas. El acceso se gestiona mediante un puente cifrado (puerto `22`) a través de una instancia intermedia securizada.

---

## 🛡️ Recomendaciones de Hardening para Entornos de Producción

Directivas aplicadas para robustecer el motor de base de datos bajo estándares de seguridad:

* **Aislamiento de la Cuenta Administradora:** Bloqueo absoluto de accesos remotos para el usuario supremo, restringiendo su uso a conexiones locales (`'root'@'localhost'`) [🗎].
* **Control de Perímetro (Firewalling):** Denegación explícita del comodín `'%'` a nivel de red, filtrando el tráfico de datos mediante políticas perimetrales estrictas.
* **Cifrado en Tránsito (TLS 1.2 / TLS 1.3):** Mitigación de ataques de interceptación de tráfico (*Man-in-the-Middle*) forzando conexiones seguras. En entornos modernos como **MySQL 8.4**, se descartan protocolos obsoletos en favor de suites de cifrado actualizadas.
