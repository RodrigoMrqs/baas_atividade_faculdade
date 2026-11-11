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
