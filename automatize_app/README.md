# Automatize – app Flutter

Como rodar:

    flutter create automatize_app      # gera android/ios/etc.
    # copie a pasta lib/ e o pubspec.yaml deste projeto por cima
    flutter pub get
    flutter run

API: o app procura a FastAPI em http://10.0.2.2:8000 (emulador Android). Se não achar,
entra em modo demonstração (dados de exemplo). Toque na nuvem no topo da tela inicial
para trocar o endereço. Em celular real, use o IP do computador na rede (ex.: http://192.168.0.10:8000)
e rode a API com `uvicorn app.main:app --host 0.0.0.0`.

Android: para HTTP sem TLS, em android/app/src/main/AndroidManifest.xml adicione
`<uses-permission android:name="android.permission.INTERNET"/>` e `android:usesCleartextTraffic="true"` na tag <application>.

Contrato esperado da API:
- GET  /produtos            -> [{id, nome, preco, estoque}]
- GET  /vendas              -> [{produto_id, quantidade, valor, data}]
- POST /vendas              {produto_id, quantidade}
- POST /producoes           {produto_id, quantidade}
