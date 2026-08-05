// Dispara la descarga de un archivo en el navegador a partir de un stream
// que viene del servidor (Blazor Server no puede simplemente poner el JWT
// en un <a href>, asi que el archivo se trae por la API ya autenticada y
// se entrega aqui como Blob).
window.nexoDescargarArchivo = async (nombreArchivo, tipoContenido, streamRef) => {
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
