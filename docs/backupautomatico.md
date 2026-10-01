# Backup Automático Local — NexoBackup

## Objetivo
Permitir a cualquier cliente de NEXO ERP tener copias de seguridad completas y restaurables
de su base de datos en su propio equipo, sin depender del agente de sincronización VISIONS.

## Arquitectura

### Flujo de descarga
1. Admin entra a Settings → tab "Seguridad" en su instancia (ej. hokma.nexo.app)
2. Hace clic en "Descargar NexoBackup"
3. API (autenticada con JWT del usuario) detecta el tenant actual
4. API lee/genera `BackupApiKey` para ese tenant desde `Seguridad.ConfiguracionBackup`
5. API construye `NexoBackup.config` on-the-fly con los datos del tenant
6. API empaqueta `NexoBackup.exe` (binario genérico) + `NexoBackup.config` en un ZIP
7. Browser descarga el ZIP — exe viene 100% pre-configurado, usuario no escribe nada

### Flujo de backup
1. Usuario descomprime el ZIP y corre `NexoBackup.exe --instalar`
2. Exe crea un Windows Scheduled Task que lo ejecuta diariamente
3. En cada ejecución:
   a. Exe llama `POST /api/backup/generar` con header `X-Backup-Key: bk_...`
   b. API ejecuta `BACKUP DATABASE [bd] TO DISK = 'C:\Windows\Temp\nexo_temp_{guid}.bak'` en SQL Server remoto
   c. API streamea el `.bak` en la respuesta HTTP
   d. Exe guarda en `C:\NexoSecurity\{tenant}_{yyyy-MM-dd_HHmm}.bak`
   e. API elimina el temporal del servidor
   f. Exe borra backups locales más antiguos si hay más de 7

### NexoBackup.config (generado por la API, específico por tenant)
```json
{
  "ApiUrl": "https://hokma.nexo.app",
  "ApiKey": "bk_a1b2c3...",
  "LocalPath": "C:\\NexoSecurity",
  "Retention": 7,
  "InactividadDias": 3,
  "HoraDiaria": "02:00"
}
```

## Triggers de backup
| Trigger | Estado | Descripción |
|---|---|---|
| Inactividad | Siempre activo | Si `MAX(UltimoLogin)` en BD >= `InactividadDias` días → backup inmediato |
| Diario | Configurable | Scheduled Task corre a `HoraDiaria` todos los días |
| Manual | Opcional | Botón "Hacer backup ahora" en Settings → `POST /api/backup/generar` directo |

## Archivos a crear

### NexoBackup (nuevo proyecto .NET 8 Console — self-contained)
- `NexoBackup/Program.cs` — entry point, lee args (`--instalar`, `--ejecutar`, `--desinstalar`)
- `NexoBackup/BackupConfig.cs` — deserializa `NexoBackup.config`
- `NexoBackup/BackupRunner.cs` — llama API, streamea .bak, gestiona retención
- `NexoBackup/SchedulerInstaller.cs` — crea/elimina Windows Scheduled Task via `schtasks`
- `NexoBackup/InactividadChecker.cs` — consulta `GET /api/backup/estado` para saber último login

### NexoApi
- `Features/Backup/BackupController.cs`
  - `POST /api/backup/generar` — valida `X-Backup-Key`, ejecuta BACKUP, streamea .bak, borra temp
  - `GET /api/backup/estado` — valida key, retorna `{ UltimoLogin, UltimoBackup, TamanoBd }`
  - `GET /api/backup/descargar-exe` — requiere JWT, genera ZIP con exe + config
- `Features/Backup/BackupService.cs` — lógica de generación, streaming, gestión de ApiKey
- `Features/Backup/BackupApiKey.cs` — modelo y generación de keys

### NexoWeb
- `Components/Pages/Settings/Seguridad.razor` — tab nuevo en Settings con:
  - Estado del último backup (fecha, tamaño)
  - Botón "Descargar NexoBackup"
  - Botón "Hacer backup ahora" (llama endpoint directo)
  - Config: toggle diario on/off, hora, días de inactividad, retención

### SQL (nexosql_compat2016.sql + migration nueva)
```sql
CREATE TABLE Seguridad.ConfiguracionBackup (
    ConfigBackupID  INT IDENTITY PRIMARY KEY,
    BackupApiKey    NVARCHAR(100) NOT NULL,
    HoraDiaria      TIME NOT NULL DEFAULT '02:00',
    InactividadDias INT NOT NULL DEFAULT 3,
    Retention       INT NOT NULL DEFAULT 7,
    UltimoBackup    DATETIME2 NULL,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT GETDATE()
);
```

## Seguridad del endpoint de backup
- El endpoint `POST /api/backup/generar` NO usa JWT (el exe no hace login de usuario)
- Usa header `X-Backup-Key` con el `BackupApiKey` del tenant
- Key es un GUID generado una sola vez por tenant, almacenado en `Seguridad.ConfiguracionBackup`
- El admin puede regenerar la key desde Settings (invalida instalaciones previas del exe)

## Características del exe
- .NET 8 self-contained single-file (~10-15MB)
- Mismo binario para todos los clientes — solo cambia `NexoBackup.config`
- Funciona en cualquier equipo Windows con acceso a internet al dominio del cliente
- No requiere VISIONS, no requiere agente de sincronización
- Argumentos:
  - `NexoBackup.exe --instalar` → crea Scheduled Task + ejecuta primer backup
  - `NexoBackup.exe --ejecutar` → corre backup ahora (lo que llama el Scheduled Task)
  - `NexoBackup.exe --desinstalar` → elimina Scheduled Task

## Retención local
- Guarda en `C:\NexoSecurity\{ApiUrl_host}_{fecha}.bak`
- Después de guardar nuevo backup, lista archivos .bak en la carpeta
- Si count > `Retention`, elimina el más antiguo (por fecha de archivo)
- Nunca borra si solo hay 1 archivo, aunque sea muy viejo

## Pendiente de decisión
- Tamaño máximo de BD tolerable para streaming HTTP (actualmente sin límite — evaluar timeout)
- Si el cliente quiere backup en ruta diferente a `C:\NexoSecurity`, configurable en `NexoBackup.config`
- Notificación por email/WhatsApp cuando backup falla (integración con sistema de notificaciones NEXO)
