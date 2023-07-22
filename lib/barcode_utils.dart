// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'dados_boleto.dart';

Orientation getOrientation(size) {
  return size.width > size.height
      ? Orientation.landscape
      : Orientation.portrait;
}

clearMask(String code) {
  final String cleanCode = code.replaceAll('.', '').replaceAll(' ', '');
  return cleanCode;
}

validateBoleto(String codigo) {
  if (codigo.isEmpty && !RegExp(r'(\d)+').hasMatch(codigo)) {
    return false;
  }
  final cod = clearMask(codigo);
  if (int.parse(cod[0]) == 8) return boletoArrecadacao(cod);
  return boletoBancario(cod);
}

boletoBancario(codigo) {
  final cod = clearMask(codigo);
  if (cod.length == 44) return boletoBancarioCodigoBarras(cod);
  if (cod.length == 47) return boletoBancarioLinhaDigitavel(codigo);
  return false;
}

boletoBancarioCodigoBarras(String codigo) {
  final cod = clearMask(codigo);
  if (!RegExp(r'^[0-9]{44}$').hasMatch(cod)) return false;
  final dv = cod[4];
  final bloco = cod.substring(0, 4) + cod.substring(5);
  return modulo11Bancario(bloco) == int.parse(dv);
}

boletoBancarioLinhaDigitavel(String codigo) {
  final cod = clearMask(codigo);
  if (!RegExp(r'^[0-9]{47}$').hasMatch(cod)) return false;
  final blocos = [
    {
      'num': cod.substring(0, 9),
      'DV': cod.substring(9, 10),
    },
    {
      'num': cod.substring(10, 20),
      'DV': cod.substring(20, 21),
    },
    {
      'num': cod.substring(21, 31),
      'DV': cod.substring(31, 32),
    },
  ];
  final validBlocos =
      blocos.every((e) => modulo10(e['num']) == int.parse(e['DV']));
  final validDV =
      boletoBancarioCodigoBarras(convertToBoletoBancarioCodigoBarras(cod));
  return validBlocos && validDV;
}

modulo11Bancario(String bloco) {
  List codigo = bloco.split('').reversed.toList();
  var multiplicador = 2;
  var somatorio = codigo.fold(0, (acc, current) {
    var soma = int.parse(current) * multiplicador;
    multiplicador = multiplicador == 9 ? 2 : multiplicador + 1;
    return acc + soma;
  });
  var restoDivisao = somatorio % 11;
  var dv = 11 - restoDivisao;
  if (dv == 0 || dv == 10 || dv == 11) return 1;
  return dv;
}

modulo10(String bloco) {
  var codigo = bloco.split('').reversed.toList();
  var index = 0;
  var somatorio = codigo.fold(0, (acc, current) {
    var soma = int.parse(current) * (((index + 1) % 2) + 1);
    soma = (soma > 9 ? (soma / 10).truncate() + (soma % 10) : soma);
    index = index + 1;
    return acc + soma;
  });
  return (double.parse((somatorio / 10).toString()).ceil() * 10) - somatorio;
}

convertToBoletoBancarioCodigoBarras(String codigo) {
  var cod = clearMask(codigo);
  var codigoBarras = '';
  codigoBarras += cod.substring(0, 3); // Identificação do banco
  codigoBarras += cod.substring(3, 4); // Código da moeda
  codigoBarras += cod.substring(32, 33); // DV
  codigoBarras += cod.substring(33, 37); // Fator Vencimento
  codigoBarras += cod.substring(37, 47); // Valor nominal
  codigoBarras += cod.substring(4, 9); // Campo Livre Bloco 1
  codigoBarras += cod.substring(10, 20); // Campo Livre Bloco 2
  codigoBarras += cod.substring(21, 31); // Campo Livre Bloco 3
  return codigoBarras;
}

convertToBoletoArrecadacaoCodigoBarras(String codigo) {
  final cod = clearMask(codigo);
  var codigoBarras = '';
  for (var index = 0; index < 4; index++) {
    final start = (11 * (index)) + index;
    final end = (11 * (index + 1)) + index;
    codigoBarras += cod.substring(start, end);
  }
  return codigoBarras;
}

modulo11Arrecadacao(String bloco) {
  List codigo = bloco.split('').reversed.toList();
  var multiplicador = 2;
  var somatorio = codigo.fold(0, (acc, current) {
    var soma = int.parse(current) * multiplicador;
    multiplicador = multiplicador == 9 ? 2 : multiplicador + 1;
    return acc + soma;
  });
  var restoDivisao = int.parse(somatorio.toString()) % 11;

  if (restoDivisao == 0 || restoDivisao == 1) {
    return 0;
  }
  if (restoDivisao == 10) {
    return 1;
  }
  var dv = 11 - restoDivisao;
  return dv;
}

boletoArrecadacaoCodigoBarras(String codigo) {
  var cod = clearMask(codigo);
  if (!RegExp(r'^[0-9]{44}$').hasMatch(cod) || int.parse(cod[0]) != 8)
    return false;
  var codigoMoeda = int.parse(cod[2]);
  var dv = int.parse(cod[3]);
  var bloco = cod.substring(0, 3) + cod.substring(4);
  var modulo;
  if (codigoMoeda == 6 || codigoMoeda == 7)
    modulo = modulo10;
  else if (codigoMoeda == 8 || codigoMoeda == 9)
    modulo = modulo11Arrecadacao;
  else
    return false;
  return modulo(bloco) == dv;
}

boletoArrecadacaoLinhaDigitavel(String codigo) {
  var cod = clearMask(codigo);
  if (!RegExp(r'^[0-9]{48}$').hasMatch(cod) || int.parse(cod[0]) != 8)
    return false;

  final validDV = boletoArrecadacaoCodigoBarras(
      convertToBoletoArrecadacaoCodigoBarras(cod));

  var codigoMoeda = int.parse(cod[2]);
  var modulo;
  if (codigoMoeda == 6 || codigoMoeda == 7)
    modulo = modulo10;
  else if (codigoMoeda == 8 || codigoMoeda == 9)
    modulo = modulo11Arrecadacao;
  else
    return false;

  List blocos = [];
  for (var index = 0; index < 4; index++) {
    var start = (11 * (index)) + index;
    var end = (11 * (index + 1)) + index;
    blocos.add({
      'num': cod.substring(start, end),
      'DV': cod.substring(end, end + 1),
    });
  }

  var validBlocos = blocos.every((e) => modulo(e['num']) == int.parse(e['DV']));
  return validBlocos && validDV;
}

boletoArrecadacao(codigo) {
  var cod = clearMask(codigo);
  if (cod.length == 44) return boletoArrecadacaoCodigoBarras(cod);
  if (cod.length == 48) return boletoArrecadacaoLinhaDigitavel(codigo);
  return false;
}

calcularDadosBoleto(String barcode) {
  if (validateBoleto(barcode)) {
    if (!barcode.startsWith('8')) {
      int endingData = barcode.length < 47 ? 44 : 47;
      String dados = barcode.substring(endingData - 10, endingData);
      var fatorVencimento = barcode.substring(33, 37);
      var dataVencimento = DateTime(1997, 10, 7)
          .add(Duration(days: int.parse(fatorVencimento)))
          .add(const Duration(hours: 1));
      // .add( Duration(days: 8417)).add(Duration(hours: 1));
      var valor = dados.substring(0, 10);
      valor =
          "${valor.substring(0, valor.length - 2)}.${valor.substring(valor.length - 2, valor.length)}";

      print("VALOR BOLETO >> $valor");

      return DadosBoleto(valor, dataVencimento);
    } else {
      var valor = barcode.substring(5, 16);
      var value =
          "${valor.substring(0, valor.length - 5)}${valor.substring(valor.length - 4, valor.length - 2)}.${valor.substring(valor.length - 2, valor.length)}";

      print("VALOR BOLETO >> $value");

      return DadosBoleto(value, DateTime.now());
    }
  }
  return null;
}

calculateCodebar(String barcode) {
  if (validateBoleto(barcode)) {
    if (!barcode.startsWith('8')) {
      var fatorVencimento = barcode.substring(5, 9);
      var dataVencimento = DateTime(1997, 10, 7)
          .add(Duration(days: int.parse(fatorVencimento)))
          .add(const Duration(hours: 1));
      var valor = barcode.substring(9, 19);
      valor =
          "${valor.substring(0, valor.length - 2)}.${valor.substring(valor.length - 2, valor.length)}";

      print("VALOR BARCODE >> $valor");

      return DadosBoleto(valor, dataVencimento);
    } else {
      var valor = barcode.substring(9, 15);
      valor =
          "${valor.substring(0, valor.length - 2)}.${valor.substring(valor.length - 2, valor.length)}";

      print("VALOR BARCODE >> $valor");
      print("VENCIMENTO BARCODE >> ${DateTime.now()}");

      return DadosBoleto(valor, DateTime.now());
    }
  }
  return null;
}
