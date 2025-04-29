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
