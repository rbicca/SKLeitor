# SKLeitor

Efetua a deteção de código de barras de boleto padrão Febraban
usando a tecnologia MLKit do Google.
Componente compatível com Dart 3.

## Para usar no seu projeto Flutter

- No seu pubspec.yaml, adicione as seguintes dependências
  google_ml_kit: ^0.16.1
  google_mlkit_barcode_scanning: ^0.8.0
  camera: ^0.10.5+2

- Adicione os arquivos, dentro da estrutura do seu projeto
    sk_leitor_funcoes_febraban.dart
    sk_leitor_globals.dart
    sk_leitor.dart

- Main.dart
  import 'package:camera/camera.dart';
  import 'sk_leitor.dart';
  import 'sk_leitor_globals.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
    runApp(const MyApp());
  }

  - Chame a tela de leitura e aguarde o resultado  
  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {return const SKLeitor();}));

  ### Autor: Ronaldo Melchiades Bicca
             ronaldo@softkuka.com.br
  ### Softkuka Softwares LTDA

