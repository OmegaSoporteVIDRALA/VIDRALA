<!-- Banner image -->
<!-- Banner image -->
<p align="center">
  <img src="assets/vidrala.jpg" alt="CI/CD Salesforce Vidrala"/>
</p>

# 🚀 CI/CD Salesforce Vidrala - Powered by GitHub Actions

<p align="center">
            
  <img src="https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/pr_validacion.yml/badge.svg" alt="Validate Workflow Status">
  <img src="https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/deploy.yml/badge.svg" alt="Deploy Workflow Status">
</p>

---

# ⚙️ GitHub Actions – Salesforce Component Validation and Deployment

Este repositorio utiliza **GitHub Actions** para automatizar la validación de código Apex con **PMD** y el posterior despliegue con **Salesforce CLI (`sf`)**, siguiendo buenas prácticas CI/CD.

This repository uses **GitHub Actions** to automate Apex code validation with **PMD** and subsequent deployment using **Salesforce CLI (`sf`)**, following CI/CD best practices.

## 📁 Workflows Structure / Estructura de Workflows

### 1. `📝 Validate Salesforce PR`
Se ejecuta automáticamente al crear o actualizar una PR. / This workflow runs automatically when a pull request is created or updated.

- 🧪 **Validación de metadata Salesforce** / **Salesforce metadata validation**
- 🧹 **Análisis estático con PMD** / **Static analysis with PMD**
- ✅ Guarda resultados si hay errores de PMD / Saves results as artifact if PMD errors exist
- ❌ Muestra errores y detiene ejecución / Shows violations and stops pipeline

> Solo se ejecuta si hay clases `.cls` modificadas / Only runs if `.cls` classes are changed.

### 2. `🚀 Deploy after Merge to Integra or UAT`
Se ejecuta tras hacer merge hacia `integra` o `uat`. / Runs after merging into `integra` or `uat` branches.

- ⚡ **Quick deploy** con `deploymentId` validado / Quick deploy using validated `deploymentId`
- 👀 Verificación de integridad / Integrity verification
- 📦 Despliegue completo si la validación fue exitosa / Full deployment if validation succeeded

## 🔍 PMD Validation / Validación con PMD

- Versión **PMD 6.55.0**
- Analiza `./pmd/classes` / Scans `./pmd/classes`
- Reporte en formato **JSON** / Report in **JSON** format
- Reglas excluidas vía `ruleset.xml` / Rules excluded using `ruleset.xml`
- Si hay errores / If violations exist:
  - 📝 Subido como artifact / Uploaded as artifact
  - 🛑 Detiene el pipeline / Stops the pipeline

## 🧩 Project Requirements / Requisitos del Proyecto

- Directorio `./pmd/classes` con clases Apex / Apex classes in `./pmd/classes`
- Archivo `ruleset.xml` personalizado / Custom `ruleset.xml`
- Salesforce CLI (`sf`) autenticado / Authenticated Salesforce CLI (`sf`)

## 📂 Artifacts Generated / Artifacts Generados

- `pmd-report.json`: errores PMD / PMD violations
- `deployment-id.txt`: ID para quick deploy / ID for quick deploy

## 📌 Recommendations / Recomendaciones

- Mantener actualizado el `ruleset.xml` / Keep `ruleset.xml` updated
- Verificar autenticación de Salesforce / Check Salesforce authentication
- Usar Annotations en GitHub Actions para ver errores / Use GitHub Actions Annotations to view errors