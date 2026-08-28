namespace NexoSyncAgent;

public static class ColombiaUtils
{
    // Pesos DIAN para calcular el dígito de verificación del NIT colombiano.
    // El último dígito usa peso 3, el penúltimo 7, y así hacia la izquierda.
    private static readonly int[] _pesos = [71, 67, 59, 53, 47, 43, 41, 37, 29, 23, 19, 17, 13, 7, 3];

    /// <summary>
    /// Calcula el dígito de verificación de un NIT colombiano.
    /// Retorna null si el NIT es nulo, vacío o tiene más de 15 dígitos.
    /// </summary>
    public static int? CalcularDigitoVerificacion(string? nit)
    {
        if (string.IsNullOrWhiteSpace(nit)) return null;

        var digitos = new string(nit.Where(char.IsDigit).ToArray());
        if (digitos.Length == 0 || digitos.Length > _pesos.Length) return null;

        int suma = 0;
        for (int i = 0; i < digitos.Length; i++)
        {
            int indicePeso = _pesos.Length - digitos.Length + i;
            suma += (digitos[i] - '0') * _pesos[indicePeso];
        }

        int residuo = suma % 11;
        return residuo == 0 || residuo == 1 ? residuo : 11 - residuo;
    }
}
