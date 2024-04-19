import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lbc_algorithm/functions/functions.dart';

class LBC_decryption extends StatefulWidget {
  const LBC_decryption(
      {super.key,
      required this.data,
      required this.masterKey,
      required this.saveFile});
  final data;
  final masterKey;
  final void Function(String content) saveFile;

  @override
  State<LBC_decryption> createState() => _LBC_decryptionState();
}

class _LBC_decryptionState extends State<LBC_decryption> {
  late String data;
  late String masterKey;
  late String decryptedText;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    masterKey = widget.masterKey;
    try {
      decryptData();
    } catch (e) {
      String errorMessage =
          'Ошибка конвертации, проверьте формат данных или тип конвертации';
      Navigator.of(context).pop(errorMessage);
    }
  }

  void decryptData() {
    print('data: $data');
    print('masterKey: $masterKey');
    //////-----------Генерация раундовых ключей---------------///////
    //Мастер-ключ (80 бит).
    String checkedMasterKeyHex = checkLengthHexMasterKey(masterKey);
    List<List<int>> generatedRoundKeys =
        generateRoundKeys(checkedMasterKeyHex, 20);

    List<Uint16List> encryptedBlocksFromFile =
        convertHexStringIntoCharCodeList(data);
    //////-----------Получение зашифрованных данных из строки в массив charCode--------------------------///////

    //Дешифровака данных из файла "encrypted_data.txt"
    List<Uint16List> decryptedBlocks =
        decryptBlocks(encryptedBlocksFromFile, generatedRoundKeys[19]);
    for (int i = generatedRoundKeys.length - 2; i >= 0; i--) {
      decryptedBlocks = decryptBlocks(decryptedBlocks, generatedRoundKeys[i]);
    }
    ;
    //////-----------Дешифрование зашифрованных данных на основе ключа--------------------------///////

    //Расшифровка массива charCode в открытый текст
    decryptedText = convertCharCodeListIntoPlainText(decryptedBlocks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расшифрование | LBC-3 Алгоритм')),
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
                    widget.saveFile(decryptedText);
                  },
                  child: Text('Сохранить полностью расшифрованный текст'),
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
                'Превью расшифрованного текста',
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
                    decryptedText.length < 1500
                        ? '${decryptedText}'
                        : '${decryptedText.substring(0, 1500)}...',
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
