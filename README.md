# Projeto Extensionista (PEX) - Tia Lara 🚌

## Sobre o Projeto
Este projeto é um **Projeto Extensionista (PEX)** desenvolvido para a **Católica de Santa Catarina** com o objetivo de criar uma aplicação mobile para a **Transportadora Tia Lara**.

O foco principal é oferecer uma ferramenta de gerenciamento de transporte escolar que melhore a segurança e a organização durante os deslocamentos dos estudantes.

---

## Descrição do Aplicativo
O aplicativo visa atender as necessidades de transporte escolar com funcionalidades que permitem:

- Registrar o embarque e desembarque dos alunos em tempo real.
- Monitorar rotas e status das viagens.
- Registrar e consultar logs de segurança e procedimentos realizados.
- Oferecer uma interface clara e fácil de usar para motoristas e coordenadores.

---

## Tecnologias Utilizadas
- Flutter 3.x
- Dart
- Arquitetura sugerida: Clean Architecture
- Git & GitHub

---

## Estrutura do Repositório
O repositório contém:

- Código-fonte Flutter em `lib/`
- Configurações de build para Android, iOS, Linux, macOS, Windows e web
- Testes de widget em `test/`
- Workflows de CI em `.github/workflows/`
- Arquivo de release/tag em `release.yaml`

---

## Release e Versionamento
O projeto utiliza um arquivo `release.yaml` na raiz do repositório para definir a tag de release.

- A tag deve estar no formato `version: vX.Y.Z`, por exemplo `version: v1.0.0`.
- O workflow `create_tag.yml` lê este arquivo e gera a tag automaticamente quando um PR é mesclado na branch `main`.
- O workflow `validate_version.yml` valida se a tag indicada no PR já existe no remoto.

---

## Como Executar Localmente
1. Clone o repositório:
   ```bash
   git clone https://github.com/luizmmacedo/PEX_2026.git
   ```
2. Acesse a pasta do projeto:
   ```bash
   cd PEX_2026
   ```
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Execute no emulador ou dispositivo:
   ```bash
   flutter run
   ```

---

## Observações
- Para alterar a versão de release, edite `release.yaml` e atualize o valor para a próxima tag desejada.
- As tags são criadas somente após merge na branch `main`.
- Junto com a tag é criado o `RELEASE` com arquivo `APK`
- Caso a tag já exista no remoto, o workflow não criará uma nova tag duplicada.
