# Circuito de Descobertas

Atividade prática do Laboratório de Programação Mobile — CESUPA.

## Resumo

Sistema para incentivar a circulação de visitantes entre os estandes do Amazon Hacking. A organização cadastra os estandes em um **painel web** e lança uma **missão surpresa** pelo Firebase Remote Config. Os visitantes usam um **app Flutter (Android)** para ver os estandes, receber a missão e registrar a visita lendo o QR code do estande. A organização acompanha os check-ins em tempo real no painel. Tudo roda no plano Firebase Spark (gratuito).

## Integrantes

- Rodrigo Marques
- Analice Johnston

## Stack do projeto

| Camada | Tecnologia |
|---|---|
| App mobile | Flutter 3.47 / Dart 3.13 (Android) |
| Leitura de QR code | mobile_scanner |
| Painel web | HTML, CSS e JavaScript (ES modules), sem build |
| Geração de QR code | qrcode-generator |
| Backend (BaaS) | Firebase (plano Spark) |
| Hospedagem do painel | Local ou Firebase Hosting |
| Distribuição do APK | Firebase App Distribution |

## Serviços Firebase utilizados

| Serviço | Uso |
|---|---|
| Authentication | E-mail/senha (admin) e sessão anônima (visitante) |
| Cloud Firestore | Estandes e check-ins |
| Remote Config | Missão surpresa (`missao_ativa`, `missao_estandes`) |
| Google Analytics (GA4) | Eventos `missao_aberta` e `checkin_concluido` (`estande_id`) |
| App Distribution | Distribuição do APK assinado |

## Projeto Firebase

- **ID do projeto:** `circuito-de-descobertas-371f9` (já configurado em `.firebaserc`)
- **Config do painel web:** `painel_web/firebase-config.js` (já preenchido)
- **Config do app Android:** `android/app/google-services.json` (já incluído)
- Regras do Firestore e Remote Config já publicados. Para republicar: `firebase deploy --only firestore:rules,remoteconfig`

O login do admin do painel (e-mail/senha) **não** fica no repositório: peça para a equipe.

## Como rodar

### Pré-requisitos

- Flutter **3.47 ou mais novo** (o `pubspec.yaml` exige Dart `^3.13.1`). Se precisar, rode `flutter upgrade`.
- Android Studio (Android SDK) e um celular Android com **depuração USB** ativada.
- `flutter doctor` sem erros na parte de Android.

### App (para testar ou gravar)

```bash
git pull
flutter pub get
flutter run          # com o celular conectado por USB
```

### Painel web

O painel usa ES modules, então precisa de um servidor local (abrir o `index.html` direto com duplo clique não funciona):

```bash
cd painel_web
python -m http.server 8000      # ou: npx serve .
```

Abra `http://localhost:8000` e entre com o e-mail/senha do admin.

## Gerar o APK de release (assinado)

### 1. Criar o keystore (só uma vez)

Dentro da pasta `android/app`:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Se o `keytool` não for encontrado no Windows, ele vem junto com o Android Studio, em `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.
- Anote as senhas. **Guarde uma cópia do `.jks` e das senhas fora do Git.** Sem eles não dá para assinar atualizações do app.

### 2. Criar `android/key.properties`

```properties
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_CHAVE
keyAlias=upload
storeFile=upload-keystore.jks
```

O `storeFile` é relativo à pasta `android/app`. O `.jks` e o `key.properties` já estão no `.gitignore`. **Não** faça commit deles.

### 3. Build

```bash
flutter build apk --release
```

O APK sai em `build/app/outputs/flutter-apk/app-release.apk`.

## Distribuir pelo App Distribution

**Pelo console:** DevOps e engajamento → **App Distribution** → app Android `br.cesupa.circuito` → arraste o `app-release.apk` → adicione o e-mail do testador → **Distribuir**.

**Pelo CLI** (com `firebase login` feito):

```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:561607257875:android:44d57d3a2919f9ff8134e6 \
  --testers "email@do.testador" \
  --release-notes "Versão para apresentação"
```

O testador recebe um e-mail para instalar o app no celular Android.
