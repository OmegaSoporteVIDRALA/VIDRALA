+---------------------------+
| 1. PR creada a integra/uat/main |
+---------------------------+
            |
            v
+---------------------------+
| 2. validate.yml           |
| - Ejecuta PMD si hay clases Apex |
| - CheckOnly deploy con tests específicos |
+---------------------------+
            |
            v
+---------------------------+
| 3. Autenticación Salesforce |
| - integra/uat → Sandbox   |
| - main → Producción       |
+---------------------------+
            |
            v
+---------------------------+
| 4. Validación exitosa     |
| → Trigger a deploy.yml    |
+---------------------------+
            |
            v
+---------------------------+
| 5. deploy.yml             |
| - Autenticación según entorno |
| - Despliegue real desde package.xml |
+---------------------------+
            |
            v
+---------------------------+
| 6. Despliegue exitoso     |
+---------------------------+
