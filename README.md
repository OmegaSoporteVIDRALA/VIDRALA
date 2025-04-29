<h1 align="center">🚀 CI/CD Salesforce - Powered by GitHub Actions</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Build-Automated-blue?style=for-the-badge&logo=github-actions" alt="Build Status">
  <img src="https://img.shields.io/badge/Salesforce-Deployment-success?style=for-the-badge&logo=salesforce" alt="Salesforce Deployment">
</p>

<p align="center">
  <b>Automated validation, testing, and deployment for Salesforce metadata and Apex code using GitHub Actions.</b>
</p>

🎯 Flujo de PR:

            Al crear una PR hacia integra, uat o main:

                        1.Si hay clases en la carpeta específica (force-app/main/default/pmd/):
                                    Ejecutar validación PMD.
                                    Si PMD falla ➔ falla la PR (no se puede mergear).

                        2.Si PMD pasa:
                                    Buscar clases de test en la misma carpeta (force-app/main/default/pmd/).
                                    Si hay tests, lanzar validación de componentes y esas clases test (checkonly RunSpecifiedTests ).
                                    Si no hay tests, simplemente validar que los componentes Salesforce se puedan desplegar (checkonly).

                        3.Si todas las validaciones van bien, permitir completar la PR.

🎯 Flujo de Deploy:

            Cuando se complete la PR (merge) en integra, uat o main:
            Hacer un despliegue real (force:source:deploy) en el entorno correspondiente.


📖 README - GitHub Actions: Validación y Despliegue Salesforce

🚀 Introducción
            Este repositorio automatiza la validación y el despliegue de cambios en Salesforce usando GitHub Actions.
            El proceso está dividido en dos flujos:
                        validate.yml ➔ Valida cambios en las Pull Requests.
                        deploy.yml ➔ Despliega automáticamente si la validación fue exitosa.

🔍 validate.yml (Validación)
Este flujo se activa cuando se crea o actualiza una Pull Request (PR) hacia las ramas:

integra

uat

main

Pasos principales:

Instala PMD para análisis estático de código Apex.

Revisa si hay clases Apex en una carpeta específica (src/classes):

Si hay, ejecuta PMD.

Si PMD encuentra errores, falla la PR.

Detecta automáticamente el entorno de Salesforce:

PR a integra o uat ➔ Login a test.salesforce.com (Sandbox).

PR a main ➔ Login a login.salesforce.com (Producción).

Se conecta a Salesforce usando JWT.

Realiza un CheckOnly:

Si hay clases de test (src/classes/tests), corre RunSpecifiedTests.

Si no hay tests, realiza despliegue NoTestRun.

🚀 deploy.yml (Despliegue)
Este flujo se activa solo si la validación fue exitosa.

Pasos principales:

Detecta la rama de destino (head_branch).

Carga las claves Salesforce correctas según la rama:

integra ➔ Sandbox Integra

uat ➔ Sandbox UAT

main ➔ Producción

Autentica usando JWT.

Despliega los componentes del package.xml en Salesforce.

🛡️ Variables y Secrets usados
Debes configurar los siguientes secrets en GitHub:


Secrets	Descripción	Para qué entorno
SFDX_CLIENT_ID_INTEGRA	Client ID OAuth JWT	Integra
SFDX_USERNAME_INTEGRA	Username Salesforce	Integra
SFDX_JWT_KEY_INTEGRA	Private key JWT	Integra
SFDX_CLIENT_ID_UAT	Client ID OAuth JWT	UAT
SFDX_USERNAME_UAT	Username Salesforce	UAT
SFDX_JWT_KEY_UAT	Private key JWT	UAT
SFDX_CLIENT_ID_PROD	Client ID OAuth JWT	Producción
SFDX_USERNAME_PROD	Username Salesforce	Producción
SFDX_JWT_KEY_PROD	Private key JWT	Producción


