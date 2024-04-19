import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lbc_algorithm/functions/functions.dart';

class LBC_encryption extends StatefulWidget {
  const LBC_encryption(
      {super.key,
      required this.data,
      required this.masterKey,
      required this.saveFile});
  final String data;
  final String masterKey;
  final void Function(String content) saveFile;

  @override
  State<LBC_encryption> createState() => _LBC_encryptionState();
}

class _LBC_encryptionState extends State<LBC_encryption> {
  late String data;
  late String masterKey;
  late String encryptedBlocksInHex;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    masterKey = widget.masterKey;
    try {
      encryptData();
    } catch (e) {
      String errorMessage =
          'Ошибка конвертации, проверьте формат данных или тип конвертации';
      Navigator.of(context).pop(errorMessage);
    }
  }

  void encryptData() {
    print('data: $data');
    print('masterKey: $masterKey');

    //////-----------Генерация раундовых ключей---------------///////
    //Мастер-ключ (80 бит).
    String checkedMasterKeyHex = checkLengthHexMasterKey(masterKey);
    List<List<int>> generatedRoundKeys =
        generateRoundKeys(checkedMasterKeyHex, 20);

    //////-----------Подготовка открытых данных, перевод символов Unicod в charCode, разделение на блоки по 64 бита (4 подблока по 16 бит), заполнение нулями-------------------------///////
    // Преобразование текста в список кодовых точек Unicode (UTF-16)
    Uint16List codePoints = Uint16List.fromList(data.codeUnits);
    // Разделение на блоки по 64 бита и дополнение последнего блока нулями
    List<Uint16List> rawBlocks = splitIntoBlocks(codePoints);

    //////-----------Шифрование открытых данных с использованием алгоритма LBC-3-------------///////
    //Шифрование исходных данных на основе алгоритма LBC-3 (20 итераций)
    List<Uint16List> encryptedBlocks =
        encryptBlocks(rawBlocks, generatedRoundKeys[0]);
    for (int i = 1; i < 20; i++) {
      encryptedBlocks = encryptBlocks(encryptedBlocks, generatedRoundKeys[i]);
    }

    // Перевод зашифрованных данных в HEX
    encryptedBlocksInHex =
        convertFromCharCodeListIntoHexString(encryptedBlocks);
    // print(encryptedBlocks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шифрование | LBC-3 Algorithm')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 16,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    widget.saveFile(encryptedBlocksInHex);
                  },
                  child: Text('Сохранить полностью зашифрованный текст'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 48, 105, 67),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Превью зашифрованного текста',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SelectableText(
                    encryptedBlocksInHex.length < 1500
                        ? '${encryptedBlocksInHex}'
                        : '${encryptedBlocksInHex.substring(0, 1500)}...',
                    style: TextStyle(fontSize: 16),
                    onTap: () {
                      // Обработчик события при нажатии на текст
                    },
                    showCursor: true,
                    cursorColor: Colors.blue,
                    cursorWidth: 2,
                    cursorRadius: Radius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
