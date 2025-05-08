<!-- Banner image -->
<p align="center">
  <img src="assets/vidrala.jpg" alt="CI/CD Salesforce Vidrala"/>
</p>

# 🚀 CI/CD Salesforce - Powered by GitHub Actions

<p align="center">
            
  <img src="https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/pr_validacion.yml/badge.svg" alt="Validate Workflow Status">
  <img src="https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/deploy.yml/badge.svg" alt="Deploy Workflow Status">
</p>

---

<details>
<summary>🇬🇧 English</summary>

## 📦 Workflow Overview

### 1. `validate.yml`
- Runs **PMD** static analysis if Apex classes are found.
- Performs a **CheckOnly deploy** using `package.xml`.
- Executes only test classes found (if any).
- Fails the PR if validation does not pass.

### 2. `deploy.yml`
- Triggered after successful validation.
- Deploys to the correct Salesforce org depending on the PR branch:
  - `integra` → Integra sandbox
  - `uat` → UAT sandbox
  - `main` → Production org

## 🔐 Authentication

- Uses different GitHub Secrets per environment.
- Dynamic connection via JWT OAuth Flow.

## 🛠️ Technologies

- Salesforce CLI (`sfdx`)
- GitHub Actions
- PMD (Apex static analysis)
- JWT OAuth Flow

## ✅ CI/CD Status

| Workflow         | Status Badge |
|------------------|--------------|
| PR Validation    | ![Validate](https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/pr_validacion.yml/badge.svg) |
| Final Deployment | ![Deploy](https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/deploy.yml/badge.svg)     |

## 🤝 Contributing

Create a PR to the appropriate branch (`integra`, `uat`, or `main`).  
CI/CD handles the rest.

## 🔒 Security

This repo uses secrets like:
- `SF_USERNAME_INTEGRA`, `SF_JWT_KEY_INTEGRA`, etc.

⚠️ Never commit credentials.

## 📄 License

MIT

</details>

------

<details>
<summary>🇪🇸 Español</summary>

## 📦 Descripción general del flujo

### 1. `validate.yml`
- Analiza código Apex con **PMD** si existen clases.
- Realiza un **CheckOnly deploy** usando `package.xml`.
- Ejecuta solo las clases de test encontradas (si las hay).
- La PR se bloquea si falla alguna validación.

### 2. `deploy.yml`
- Se lanza si `validate.yml` termina correctamente.
- Despliega en función de la rama destino:
  - `integra` → Sandbox Integra
  - `uat` → Sandbox UAT
  - `main` → Producción

## 🔐 Autenticación

- Usa secrets de GitHub distintos para cada entorno.
- Autenticación vía JWT OAuth dinámico.

## 🛠️ Tecnologías usadas

- Salesforce CLI (`sfdx`)
- GitHub Actions
- PMD (análisis estático)
- JWT OAuth Flow

## ✅ Estado del CI/CD

| Workflow         | Estado automático |
|------------------|-------------------|
| Validación PR    | ![Validate](https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/pr_validacion.yml/badge.svg) |
| Despliegue final | ![Deploy](https://github.com/OmegaSoporteVIDRALA/VIDRALA/actions/workflows/deploy.yml/badge.svg)     |

## 🤝 Contribución

Haz PR a `integra`, `uat` o `main` según el entorno.  
El sistema validará y desplegará automáticamente.

## 🔒 Seguridad

Este repositorio utiliza `GitHub Secrets` como:
- `SF_USERNAME_INTEGRA`, `SF_JWT_KEY_INTEGRA`, etc.

Nunca subas claves al repositorio.

## 📄 Licencia

MIT

</details>
