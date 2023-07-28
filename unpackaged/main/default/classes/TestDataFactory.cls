@isTest
public class TestDataFactory {
    
    public static Programas__c createSingleProgram(String name, String programId, String inventario) {
        Programas__c p = new Programas__c();
        p.Name = name;
        p.Programa_ID__c = programId;
        p.Inventario__c = inventario;
        insert p;
        return p;
    }
    
    public static List<Programas__c> createMultiplePrograms(String name, String programId, String inventario, Integer quantity) {
        List<Programas__c> programList = new List<Programas__c>();
        for(Integer i = 0; i < quantity; i++) {
            Programas__c p = new Programas__c(
                Name = name + i, 
                Programa_ID__c = programId + i, 
                Inventario__c = inventario);
            programList.add(p);
        }
        
        insert programList;
        return programList;
    }
    
    public static Entrega__c createSingleDelivery(String status) {
        String code = '';
        while (code.length() < 10) {
            Integer randomNumber = (Integer)Math.round(Math.random() * 9);
            code += String.valueOf(randomNumber);
        }
        Entrega__c e = new Entrega__c(
        	Name = '100-' + code,
            Estado__c = status
        );
        Insert e;
        return e;
    }

    public static Order__c createSingleOrder() {
        Entrega__c delivery = createSingleDelivery('Asignado');
        Account acc = createSingleAccount('AGUASCALIENTES');
        Contact contact = createSingleContactRelatedToAccount(acc.Id, 'Louise', 'Santana', 'Todas');
        Datetime limitDate = Datetime.newInstanceGMT(2023, 6, 30, 0, 0, 0);
        
        Order__c order = new Order__c(
            Fecha_Limite_de_Entrega__c = limitDate,
            Tipo_de_Pedido__c = 'Ordinario',
            Total_de_Piezas__c = 0,
            Estatus__c = 'Procesando',
            Contacto__c = contact.Id,
            UMU__c = acc.Id,
            Entrega__c = delivery.Id
        );
        
        System.debug(delivery);
        System.debug(acc);
        
        insert order;
        return order;
    }
    
    public static Subalmacen__c createSingleSubalmacen(String num, String name) {
        Subalmacen__c subalmacen = new Subalmacen__c(
            Numero_de_Subalmacen__c =  num,
            Name = name,
            Email__c = 'test@email.com'
        );
        
        insert subalmacen;
        return subalmacen;
    }
    
    public static Product2 createSingleProduct2(String name) {
        String code = '';
        while (code.length() < 12) {
            Integer randomNumber = (Integer)Math.round(Math.random() * 9);
            code += String.valueOf(randomNumber);
        }
        
        Subalmacen__c subalmacen = createSingleSubalmacen('100', 'GENERAL');
        
        Programas__c program = createSingleProgram('Programa de Prueba', 'S035', 'Ordinario');
        Product2 p = new Product2(
            Name = name,
            Product_Code_ID__c = code,
            Description__c = name,
            Enable__c = 1,
            Fraction__c = 'No Controlado',
            Sicora_Classification__c = 'REGULAR',
            Simple_Classification__c =  'HEALING MATERIAL',
            Programa__c = program.Id,
            Subalmacen__c = subalmacen.Id
        );
            
        insert p;
        return p;
    }
    
    public static List<Product2> createMultipleProduct2(String name, Integer quantity) {
        List<Product2> productList = new List<Product2>();
        Programas__c program = createSingleProgram('Programa de Prueba', 'S035', 'Ordinario');
        Subalmacen__c subalmacen = createSingleSubalmacen('100', 'GENERAL');
        
        for(Integer i = 0; i < quantity; i++) {
            String code = '';
            while (code.length() < 12) {
                Integer randomNumber = (Integer)Math.round(Math.random() * 9);
                code += String.valueOf(randomNumber);
            }
        
            Product2 p = new Product2(
                Name = name + i,
                Product_Code_ID__c = code,
                Description__c = name,
                Enable__c = 1,
                Fraction__c = 'No Controlado',
                Sicora_Classification__c = 'REGULAR',
                Simple_Classification__c =  'HEALING MATERIAL',
                Programa__c = program.Id,
                Subalmacen__c = subalmacen.Id
            );
            productList.add(p);
        }
        
        system.debug(productList);
        
        insert productList;
        return productList;
    }
    
    public static Account createSingleAccount(String accountName) {
        Account acc = new Account();
        acc.Name = accountName;
        acc.Clave_Presupuestal__c = '00120400';
        acc.Estado__c = 'Aguascalientes';
        acc.Ciudad__c = 'Aguascalientes';
        acc.Delegaci_n__c  = '001-AGUASCALIENTES';
        acc.UMU__c = '001';
        insert acc;
        return acc;
    }

    public static DPN__c createSingleDPN(String accountId) {
        DPN__c dpn = new DPN__c();
        dpn.Account__c = accountId;
        dpn.Estatus__c = 'Activo';
        insert dpn; 
        return dpn;
    }  
    
    public static DPN__c createSingleDPN2(String accountId) {
        DPN__c dpn = new DPN__c();
        dpn.Account__c = accountId;
        dpn.Estatus__c = 'No Ordinario';
        insert dpn; 
        return dpn;
    } 

    public static DPN_Line_Item__c createSingleDPNLineItem(String dpnId, String productId) {
        DPN_Line_Item__c dpnLine = new DPN_Line_Item__c(
            DPN__c = dpnId,
            Product__c = productId,
            L_mite_Mensual__c = 50
        );
        insert dpnLine; 
        return dpnLine;
    } 
    
    public static DPN_Line_Item__c createSingleDPNLineItem2(String dpnId, String productId) {
        DPN_Line_Item__c dpnLine = new DPN_Line_Item__c(
            DPN__c = dpnId,
            Product__c = productId,
            L_mite_Mensual__c = 50
        );
        insert dpnLine; 
        return dpnLine;
    }

    public static D_a_de_Pedido__c createSingleOrderDate(String dpnId) {
        Date currentDate = Date.today();
        Time startTime = Time.newInstance(7, 30, 0, 0);
        Time endTime = Time.newInstance(23, 30, 0, 0);
            
        D_a_de_Pedido__c dpnLine = new D_a_de_Pedido__c(
            DPN__c = dpnId,
            Fecha__c = currentDate,
            Hora_de_Inicio__c = startTime,
            Hora_de_Fin__c = endTime
        );
        insert dpnLine; 
        return dpnLine;
    } 
    
    public static List<Account> createMultipleAccounts(String accountName, String type, String delegation, Integer quantity) {
        List<Account> accountList = new List<Account>();
        for(Integer i = 0; i < quantity; i++) {
            Account acc = new Account(
                Name = accountName + ' ' + i,
                Clave_Presupuestal__c = '00120400',
                Estado__c = 'Aguascalientes',
                Ciudad__c = 'Aguascalientes',
                Delegaci_n__c  = delegation,
                Tipo_UMU__c = type
            );
            accountList.add(acc);
        }
        
        insert accountList;
        return accountList;
    }
    
    public static Contact createSingleContactRelatedToAccount(Id accountId, String firstName, String lastName, String clave) { 
        Contact con = new Contact();
        con.FirstName = firstName;
        con.LastName = lastName;
        con.Email = 'test@email.com';
        con.Acceso_a_claves_por_clasificaci_n__c = clave;
        con.AccountId= accountId;
        insert con;
        return con;
    }
    
    public static List<Contact> createMultipleContactRelatedToAccount(Id accountId, String firstName, String lastName, Integer quantity) { 
        List<Contact> contactList = new List<Contact>();
        
        for(Integer i = 0; i < quantity; i++) {
            Contact con = new Contact(
                FirstName = firstName + ' ' + i,
                LastName = lastName + ' ' + i, 
                Acceso_a_claves_por_clasificaci_n__c = 'Todas',
                AccountId= accountId
            );
            contactList.add(con);
        }
        
        insert contactList;
        return contactList;
    }
    
    public static List<Contactos_y_Programas__c> createMultipleContactsAndPrograms(Integer quantity) {
        Programas__c program = createSingleProgram('Programa de Prueba', 'S035', 'Ordinario');
        Account acc = createSingleAccount('Test Account');
        List<Contact> contactList = createMultipleContactRelatedToAccount(acc.Id, 'Mario', 'Sanchez', quantity);
		
        List<Contactos_y_Programas__c> cpList = new List<Contactos_y_Programas__c>();
        for(Contact c : contactList) {
            Contactos_y_Programas__c cp = new Contactos_y_Programas__c(
                Contact__c = c.Id,
                Programa__c = program.Id
            );
            cpList.add(cp);
        }
        
        return cpList;        
    }
    
    public static Product2 createSingleProduct(String name, String classification) {
        
        String random12DigitString = '';
        while (random12DigitString.length() < 12) {
            Integer randomNumber = Math.mod(Math.abs(Crypto.getRandomInteger()), 10);
            random12DigitString += String.valueOf(randomNumber);
        } 
        
        Product2 clave = new Product2(); 
        clave.Name = name; 
        clave.Simple_Classification__c = classification;
        clave.Product_Code_ID__c = random12DigitString;
        clave.Fraction__c = 'No Controlado 1';

        insert clave;
        return clave; 
    }

    public static User initCommunityLoginUser(String userName) {
        
        User u;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' Limit 1];
        thisUser.UserRoleId = portalRole.id; 
		update thisUser;
        
        System.runAs (thisUser) {
            Account a = createSingleAccount('Test Account');
            
            Contact con = new Contact(
                FirstName = 'Test',
                LastName = 'Name',
                AccountId = a.Id,
                Email = 'testcontact@email.com'
            );
            insert con;
            
            AccountContactRelation acr = [
                SELECT AccountId, Account.Name  
                FROM AccountContactRelation 
                WHERE ContactId =: con.Id];
            
            Profile p = new Profile();
            try {
                p = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User'];
            } catch (Exception ex) {
                System.debug('There was an error');
            }
            
            u = new User(
                Alias = 'testUser',
                LastName = 'Testing',
                UserName = userName + '@test.com',
                ProfileId = p.Id,
                // Email = userName + '@test.com',
                Email = 'test_1@test.com',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/New_York',
                ContactId = con.Id,
                Country = 'United States'
            );

            insert u;
        }
        
        return u;
    }


    public static EmailTemplate buildTemplate(String templateName, String htmlText) {

        User thisUser = [SELECT Id
                FROM User
                WHERE Id = :UserInfo.getUserId()];

        EmailTemplate testEmail = new EmailTemplate(

                Name = ' TEST EMAIL',

                DeveloperName = templateName,

                HtmlValue = htmlText,

                Subject = 'Test Email',

                isActive = true,

                FolderId = thisUser.Id,

                TemplateType = 'Custom'

        );

        System.runAs (thisUser) { 
            insert testEmail; 
        } 

        return testEmail;
    }

}