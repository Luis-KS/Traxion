public with sharing class ConversorNumeroTexto {
    private static final List<String> units = new List<String> {
        '', 'uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve', 'diez', 'once', 'doce', 'trece',
        'catorce', 'quince', 'dieciséis', 'diecisiete', 'dieciocho', 'diecinueve'
    };

    private static final List<String> tens = new List<String> {
        '', '', 'veinte', 'treinta', 'cuarenta', 'cincuenta', 'sesenta', 'setenta', 'ochenta', 'noventa'
    };

    private static final List<String> hundreds = new List<String> {
        '', 'ciento', 'doscientos', 'trescientos', 'cuatrocientos', 'quinientos', 'seiscientos', 'setecientos', 'ochocientos', 'novecientos'
    };

    public static String convertToWord(Integer numero) {
        if (numero == 0) {
            return 'cero';
        }
        if (numero < 0) {
            return 'menos ' + convertToWord(Math.abs(numero));
        }

        String words = '';

        if ((numero / 1000000) > 0) {
            words += convertToWord(numero / 1000000) + ' millones ';
            numero = math.mod(numero, 1000000);
        }

        if ((numero / 1000) > 0) {
            words += convertToWord(numero / 1000) + ' mil ';
            numero = math.mod(numero, 1000);
        }

        if ((numero / 100) > 0) {
            if (numero == 100) {
                words += 'cien';
            } else {
                words += hundreds[numero / 100] + ' ';
            }
            numero = math.mod(numero, 100);
        }

        if (numero > 0) {
            if (numero < 20) {
                words += units[numero];
            } else {
                words += tens[numero / 10] + ' ' + units[math.mod(numero, 10)];
            }
        }
        return words.trim();
    }
}