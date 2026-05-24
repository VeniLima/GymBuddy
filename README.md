<p align="center">
  <img src="assets/crown.svg" width="100" alt="GymBuddy Logo">
</p>

<h1 align="center">GymBuddy</h1>

<p align="center">
  <strong>O seu parceiro definitivo de treinos e acompanhamento de resultados!</strong><br>
  Aplicativo de fitness open-source focado em simplicidade, gamificação e controle absoluto dos seus dados, feito em Flutter.
</p>

---

## 🚀 Sobre o Projeto

O **GymBuddy** foi desenvolvido para usuários que desejam rastrear sua evolução na academia de forma totalmente privada, gratuita e poderosa. Desde iniciantes até atletas avançados, o aplicativo oferece tudo que você precisa para gerenciar suas rotinas, calcular métricas avançadas (como 1RM Estimado) e explorar uma biblioteca imensa de novos exercícios.

## ✨ Principais Funcionalidades

- 💪 **Treinos Dinâmicos**: Inicie treinos vazios, crie rotinas personalizadas e acompanhe suas séries com suporte avançado a **Superséries (Supersets)**.
- 📚 **Biblioteca Offline Premium**: Integração nativa com a base do `free-exercise-db`, oferecendo mais de **800 exercícios** com instruções detalhadas, grupos musculares, mecânica e **imagens demonstrativas** sem depender da internet para buscar os dados básicos.
- 🏆 **Gamificação e Conquistas**: Sistema de *Achievements* para mantê-lo motivado a bater seus Recordes Pessoais (PRs) e manter a consistência de treinos.
- ⏱️ **Descanso Inteligente**: Temporizador de descanso automático por exercício, adaptado para exercícios multiarticulares ou isolados, ou 100% customizável de acordo com seu ritmo.
- 📊 **Estatísticas e Gráficos**: Gráficos de evolução para 1RM (Repetição Máxima Estimada), volume máximo, peso levantado, além de calendários de consistência (heatmap).
- 💾 **Controle Total dos seus Dados**: Funcionalidade completa de **Backup & Restauração** via JSON. Nunca perca seu histórico! Exporte facilmente planilhas **CSV** para visualizar no Excel ou Google Sheets.
- 🌍 **Multilíngue**: Suporte completo a **Português** e **Inglês**.
- ⚖️ **Acompanhamento Corporal**: Registre seu peso e veja a evolução do seu IMC diretamente no painel.

## 🛠️ Tecnologias Utilizadas

- **[Flutter](https://flutter.dev/)**: Framework principal para UI de alta performance e suporte multiplataforma.
- **[SQLite (sqflite)](https://pub.dev/packages/sqflite)**: Banco de dados relacional offline ultrarrápido para salvar todos os dados locais.
- **[fl_chart](https://pub.dev/packages/fl_chart)**: Gráficos vetoriais modernos e responsivos.
- **[share_plus](https://pub.dev/packages/share_plus) & [file_picker](https://pub.dev/packages/file_picker)**: Para compartilhamento de arquivos de exportação e seleção de backups.

## 📥 Como Baixar e Testar (Para Usuários)

Acesse a aba [**Releases**](https://github.com/VeniLima/GymBuddy/releases) no GitHub e faça o download da versão `.apk` mais recente.
1. Baixe o arquivo `app-release.apk` no seu celular Android.
2. Autorize a instalação de aplicativos de fontes desconhecidas se solicitado.
3. Instale e comece a treinar!

## 💻 Como Rodar o Projeto (Para Desenvolvedores)

Se você quer ajudar a construir o GymBuddy ou compilar a sua própria versão a partir do código fonte:

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão 3.2.0 ou superior).
- Um emulador Android/iOS ou um dispositivo físico conectado.

### Instalação

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/VeniLima/GymBuddy.git
   cd GymBuddy
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo:**
   ```bash
   flutter run
   ```

### Gerando o seu próprio APK (Release)
Para gerar uma build pronta para uso em produção no Android, rode:
```bash
flutter build apk --release
```
O arquivo será gerado em: `build/app/outputs/flutter-apk/app-release.apk`.

## 🧪 Rodando os Testes
O projeto conta com mais de 50 testes de unidade e widget para assegurar estabilidade (banco de dados, traduções, views etc). Para rodar os testes localmente:
```bash
flutter test
```

## 🤝 Contribuindo

Sinta-se à vontade para fazer um *fork* do projeto e enviar pull requests. Toda ajuda é bem-vinda, seja para:
- Adicionar novos recursos.
- Corrigir bugs.
- Melhorar ou adicionar novas traduções.

---
**Desenvolvido com 💙 para a comunidade de Fitness e Open-Source.**
