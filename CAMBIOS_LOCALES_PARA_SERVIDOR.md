# Cambios locales que deben aplicarse al subir al servidor

Este archivo registra configuraciones y ajustes hechos en desarrollo local
que NO están en el código fuente y deben replicarse en el servidor de producción.

---

## 1. NexoApi — appsettings.json (producción)

La clave `ApiBaseUrl` debe apuntar a la URL pública del servidor:

```json
"ApiBaseUrl": "https://nexo.miempresa.com"
```

En local se usaba `http://localhost:5272` (HTTP sin SSL).
En producción usar HTTPS con certificado válido — el agente NO omitirá SSL
porque el dominio no contiene "localhost".

---

## 2. NexoSyncAgent — comportamiento SSL en localhost

En `Program.cs` del agente se agregó:

```csharp
.ConfigurePrimaryHttpMessageHandler((sp) =>
{
    var baseUrl = sp.GetRequiredService<IConfiguration>()["NexoApi:BaseUrl"] ?? "";
    var handler = new HttpClientHandler();
    if (baseUrl.Contains("localhost", StringComparison.OrdinalIgnoreCase))
        handler.ServerCertificateCustomValidationCallback =
            HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
    return handler;
});
```

**En producción esto no tiene efecto** porque la URL no es localhost.
No hay que cambiar nada — funciona automáticamente.

---

## 3. NexoSyncAgent — publish como single-file self-contained

El agente debe publicarse con:

```
dotnet publish NexoSyncAgent.csproj -c Release -r win-x64
  --self-contained true
  -p:PublishSingleFile=true
  -p:IncludeNativeLibrariesForSelfExtract=true
  -o publish/
```

Razón: el instalador (`NexoInstaladorAgente.exe`) solo copia `NexoSyncAgent.exe`.
Si se publica como framework-dependent, el exe busca el `.dll` y falla.
Con single-file todo va embebido en el exe.

---

## 4. Migración SQL — ejecutar en producción antes de subir

Estos scripts deben ejecutarse UNA vez contra la BD NEXO_ERP del servidor:

| Script | Qué hace |
|--------|----------|
| `sql/migration_bidireccional_v1.sql` | Agrega columna `FechaModificacion` a `Catalogo.Tarjetas` y `Crm.Clientes` |
| `sql/migration_interval_seconds.sql` | Agrega columna `IntervalSeconds` a `Integracion.AgentesSync` |

El agente crea las tablas NEXO_* en Visions automáticamente al iniciar (TareaInicializarVisions).

---

## 5. Bug corregido — GenerarAppsettingsJson usaba clave inexistente

`IntegracionService.ActualizarConfiguracionCompletaAsync` leía `_config["NexoApi:BaseUrl"]`
pero esa clave no existe en appsettings de NexoApi. La clave correcta es `ApiBaseUrl`.
Resultado: el instalador generaba `BaseUrl: "/"` → el agente fallaba con UriFormatException.

**Ya corregido en código.** En producción, asegurarse de que `appsettings.json` de NexoApi
tenga `"ApiBaseUrl": "https://nexo.miempresa.com"`.

---

## 6. Bug corregido — PRESENTACION.FRACCIONES no existe en Visions

`TareaSincronizarCatalogos.SincronizarPresentacionesAsync` intentaba leer y escribir
la columna `FRACCIONES` de `dbo.PRESENTACION` en Visions, que no existe.
**Ya corregido** — las queries solo usan `CODIGO` y `PRESENTACION`.

---

## 7. Flujo de actualización del agente

- Botón **ACTUALIZAR** en Estado del Agente → genera nueva API key en BD + descarga el installer.
- El usuario debe **ejecutar el installer descargado** para que:
  1. Se sobreescriba el binario en `C:\NexoSyncAgent\`
  2. Se escriba el nuevo `appsettings.json` con la key fresca
- Si se hace clic en ACTUALIZAR pero no se ejecuta el installer → el agente queda con 401
  porque la key en BD ya cambió pero el servicio sigue con la anterior.
