// Descarga un archivo a partir de un string base64 (usado para archivos de texto
// generados en el servidor como appsettings.json).
window.nexoDescargarArchivo = (nombreArchivo, tipoContenido, base64) => {
    // Deteccion: si es un DotNetStreamReference (objeto) usamos arrayBuffer;
    // si es string, asumimos base64.
    if (typeof base64 === 'string') {
        const bytes = Uint8Array.from(atob(base64), c => c.charCodeAt(0));
        const blob = new Blob([bytes], { type: tipoContenido });
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = nombreArchivo;
        document.body.appendChild(anchor);
        anchor.click();
        anchor.remove();
        URL.revokeObjectURL(url);
        return;
    }
    // Fallback legacy: streamRef
    base64.arrayBuffer().then(buffer => {
        const blob = new Blob([buffer], { type: tipoContenido });
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = nombreArchivo;
        document.body.appendChild(anchor);
        anchor.click();
        anchor.remove();
        URL.revokeObjectURL(url);
    });
};

// Navega el navegador a una URL de descarga directa (el servidor envía Content-Disposition: attachment).
window.nexoDescargarUrl = (url) => { window.location.href = url; };

// Version legacy (stream) — mantenida para compatibilidad con otras pantallas.
window.nexoDescargarArchivoStream = async (nombreArchivo, tipoContenido, streamRef) => {
    const arrayBuffer = await streamRef.arrayBuffer();
    const blob = new Blob([arrayBuffer], { type: tipoContenido });
    const url = URL.createObjectURL(blob);

    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = nombreArchivo;
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();

    URL.revokeObjectURL(url);
};
