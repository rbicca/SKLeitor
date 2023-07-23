# SKLeitor

Efetua a deteção de código de barras de boleto padrão Febraban.
usando a tecnologia MLKit do Google.  
Componente compatível com Dart 3.

## Para usar no seu projeto Flutter

- No seu pubspec.yaml, adicione as seguintes dependências:    
  google_ml_kit: ^0.16.1  
  google_mlkit_barcode_scanning: ^0.8.0  
  camera: ^0.10.5+2  

- Adicione os arquivos, dentro da estrutura do seu projeto:  
    sk_leitor_funcoes_febraban.dart  
    sk_leitor_globals.dart  
    sk_leitor.dart  

- Main.dart  
  import 'package:camera/camera.dart';  
  import 'sk_leitor.dart';  
  import 'sk_leitor_globals.dart';  

  Future<void> main() async {  
      &emsp;WidgetsFlutterBinding.ensureInitialized();  
      &emsp;cameras = await availableCameras();  
      &emsp;runApp(const MyApp());  
  }

  Chame a tela de leitura e aguarde o resultado.    
  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {return const SKLeitor();}));  

## Requisitos e ajustes Android
   minSdkVersion: 21  
   targetSdkVersion: 33  
   compileSdkVersion: 33  

## Requisitos e ajustes iOS
    [Adaptar seu Podfile conforme abaixo]  

    platform :ios, '12.0'   [ou mais novo]  
  
    ...  
  
    [coloque esta linha:]  
    $iOSVersion = '12.0'  [ou mais novo]  
  
    post_install do |installer|  
      [coloque estas linhas:]  
      installer.pods_project.build_configurations.each do |config|  
        config.build_settings["EXCLUDED_ARCHS[sdk=*]"] = "armv7"  
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion  
      end  
    
      installer.pods_project.targets.each do |target|  
        flutter_additional_ios_build_settings(target)  
      
        [coloque estas linhas:]  
        target.build_configurations.each do |config|  
          if Gem::Version.new($iOSVersion) > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])  
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion  
          end  
        end  
      
      end  
    end    
    
  ### Autor: Ronaldo Melchiades Bicca
             ronaldo@softkuka.com.br
  ### Softkuka Softwares LTDA

