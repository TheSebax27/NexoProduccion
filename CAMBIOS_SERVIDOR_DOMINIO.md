# NEXO ERP — Guía de cambio de servidor o dominio
Actualizado: Sep 2026

---

## CAMBIO DE DOMINIO DE LA API
(ej: de api.insumar.com.co a api.nuevocliente.com)

Solo 2 archivos fuente. El deploy regenera todo lo demás.

### 1. NexoApi/appsettings.Production.json
```
"ApiBaseUrl": "https://api.nuevocliente.com"
```
→ Lo usa el servicio para generar el appsettings del agente en cada instalación.

### 2. NexoWeb/appsettings.Production.json
```
"NexoApi": {
  "BaseUrl": "http://localhost:81/",        ← NO CAMBIAR (URL interna del servidor)
  "PublicUrl": "https://api.nuevocliente.com"  ← CAMBIAR ESTO
}
```
→ PublicUrl es la URL que el browser del usuario usa para descargar el instalador del agente.

### Después del cambio
```
.\deploy.ps1
```
Subir Publish\Api\ y Publish\Web\ al servidor y reciclar ambos Application Pools en IIS.

---

## CAMBIO DE SERVIDOR COMPLETO (nueva máquina)

Aplica todo lo anterior MÁS los siguientes cambios:

### 3. NexoApi/appsettings.Production.json — conexión a BD
```
"ConnectionStrings": {
  "AdminDb": "Server=NUEVA-IP;Database=admin_services;User Id=...;Password=...;TrustServerCertificate=True;"
}
```
→ IMPORTANTE: mantener la misma Jwt:Key del servidor anterior.
   Si cambia, todos los usuarios quedan deslogueados y los tokens del agente se invalidan.

### 4. Si cambia el puerto de IIS (no es 81)
En NexoWeb/appsettings.json (base) Y en NexoWeb/appsettings.Production.json:
```
"NexoApi": {
  "BaseUrl": "http://localhost:NUEVO_PUERTO/"
}
```

---

## CHECKLIST IIS EN NUEVO SERVIDOR

1. Instalar ASP.NET Core Hosting Bundle (.NET 10)
2. Crear Application Pools en modo "No Managed Code"
   - ApiNexo  → para la API
   - NexoWeb  → para la Web
3. Crear sitios en IIS:
   - ApiNexo  → binding http:*:81:  → ruta: C:\inetpub\wwwroot\apiNexo
   - NexoWeb  → binding https:*:443:dominio.com → ruta: C:\inetpub\wwwroot\nexoWeb
4. Correr .\deploy.ps1 en la máquina de desarrollo
5. Copiar Publish\Api\ y Publish\Web\ a sus rutas en IIS
6. Dar permiso de escritura en la carpeta logs\ de cada sitio a la cuenta del Pool
7. Instalar certificado SSL para el dominio en IIS (solo NexoWeb, la API es HTTP interno)
8. Reciclar ambos pools y probar el login

---

## PASOS DE DEPLOY ESTÁNDAR (sin cambio de infraestructura)

```
.\deploy.ps1             # genera Publish\Api\ y Publish\Web\
.\deploy.ps1 -Solo Web   # solo si no cambió la API
.\deploy.ps1 -Solo Api   # solo si no cambió la Web
```

IMPORTANTE: no editar archivos en Publish\ directamente — el deploy los borra y regenera.
Excepción: los appsettings.Production.json en el servidor se pueden editar en vivo sin recompilar.

---

## MAPA DE PROXIES DE IMAGEN
(el browser nunca llama a localhost:81 directamente — todo pasa por el servidor Blazor)

  /api/catalogo/articulos/{id}/imagen    → localhost:81/api/catalogo/articulos/{id}/imagen
  /api/rrhh/empleados/{id}/foto          → localhost:81/api/rrhh/empleados/{id}/foto
  /api/marketing/combos/{id}/imagen      → localhost:81/api/marketing/combos/{id}/imagen
  /api/produccion/maquinaria/{id}/foto   → localhost:81/api/produccion/maquinaria/{id}/foto
  /api/rrhh/asistencia/qr-imagen         → localhost:81/api/rrhh/asistencia/qr-imagen

Foto de perfil y logo de empresa: se sirven como data:image/...;base64,... — no necesitan proxy.
Uploads de imagen: son server-side (JSON base64) — el browser nunca ve localhost:81.

---

## NOTAS CRÍTICAS

- ASPNETCORE_ENVIRONMENT=Production está fijado en NexoApi/web.config — no tocar.
  Si no está, el instalador del agente genera config apuntando a localhost:7144.

- El agente instalado en el cliente apunta a la URL pública (https://api.insumar.com.co).
  Si se cambia el dominio de la API, los clientes con agente instalado deben REINSTALARLO.
  (El agente no depende del SQL Server directamente, solo de la API pública.)

- Al migrar servidor, conservar la misma Jwt:Key para no invalidar sesiones activas.
