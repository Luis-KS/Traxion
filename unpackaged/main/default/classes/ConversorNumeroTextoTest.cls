@isTest
public with sharing class ConversorNumeroTextoTest {
    @isTest
    static void testConvertToWord() {
        // Test cases with positive numbers
        System.assertEquals('cero', ConversorNumeroTexto.convertToWord(0));
        System.assertEquals('uno', ConversorNumeroTexto.convertToWord(1));
        System.assertEquals('diez', ConversorNumeroTexto.convertToWord(10));
        System.assertEquals('veinte', ConversorNumeroTexto.convertToWord(20));
        System.assertEquals('noventa nueve', ConversorNumeroTexto.convertToWord(99));
        System.assertEquals('cien', ConversorNumeroTexto.convertToWord(100));
        System.assertEquals('quinientos', ConversorNumeroTexto.convertToWord(500));
        System.assertEquals('ciento cincuenta seis mil setecientos ochenta nueve', ConversorNumeroTexto.convertToWord(156789));
        System.assertEquals('dos millones', ConversorNumeroTexto.convertToWord(2000000));
        
        // Test cases with negative numbers
        System.assertEquals('menos uno', ConversorNumeroTexto.convertToWord(-1));
        System.assertEquals('menos quinientos', ConversorNumeroTexto.convertToWord(-500));
        System.assertEquals('menos ciento cincuenta seis mil setecientos ochenta nueve', ConversorNumeroTexto.convertToWord(-156789));
                
        // Test a large number to validate performance
        System.assertEquals('dos mil millones', ConversorNumeroTexto.convertToWord(2000000000));
    }
}