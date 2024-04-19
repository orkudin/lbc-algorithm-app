import 'dart:typed_data';

enum Action { ENCRYPT, DECRYPT }

// Функция для разделения на блоки по 64 бита и дополнения последнего блока нулями
List<Uint16List> splitIntoBlocks(Uint16List codePoints) {
  List<Uint16List> blocks = [];
  for (int i = 0; i < codePoints.length; i += 4) {
    Uint16List block = codePoints.sublist(
        i, i + 4 > codePoints.length ? codePoints.length : i + 4);
    if (block.length < 4) {
      block = padWithZeros(block, 4);
    }
    blocks.add(block);
  }
  return blocks;
}

// Функция для дополнения списка нулями до указанной длины
Uint16List padWithZeros(Uint16List list, int length) {
  Uint16List paddedList = Uint16List(length);
  paddedList.setRange(0, list.length, list);
  return paddedList;
}

// Функция шифрования блока согласно алгоритму LBC-3 (массив CharCode, мастер ключ)
List<Uint16List> encryptBlocks(
    List<Uint16List> rawBlocks, List<int> generatedKey) {
  //Зашифрованные блоки
  List<Uint16List> encryptedBlocks = [];
  for (int i = 0; i < rawBlocks.length; i++) {
    //Подблок в котором 4 по 16 бит. 1 символ = 16 бит.
    Uint16List encryptedSubBlocks = Uint16List(4);

    //Временная переменная для 𝑅𝐿(𝑆(𝐴0))
    int rlTemp = 0, rawSubBlock = 0, rawSubBlockAfter_S_transformation = 0;
    for (int j = 0; j < rawBlocks[i].length; j++) {
      rawSubBlock = rawBlocks[i][j];

      //Преобразование S. subblockAfterSBox - подблок после S преобразования
      rawSubBlockAfter_S_transformation =
          transformationS(rawSubBlock, Action.ENCRYPT);

      // Преобразование RL и Преобразование L
      if (j == 0) {
        // 𝑅𝐿(𝑆(𝐴0))
        rlTemp = transformationRL(rawSubBlockAfter_S_transformation);
        // {𝐴0} = S(A0). Сдвиг влево на 1 подблок
        encryptedSubBlocks[3] =
            rawSubBlockAfter_S_transformation ^ generatedKey[3];
      } else if (j == 1) {
        // {𝐴1} = 𝑅𝐿(𝑆(𝐴0)) ⊕ 𝑆(𝐴1). Сдвиг влево на 1 подблок.
        encryptedSubBlocks[0] =
            (rawSubBlockAfter_S_transformation ^ rlTemp) ^ generatedKey[0];
      } else
        // {A2} = S(A2),  {A3} = S(A3).Сдвиг влево на 1 подблок.
        encryptedSubBlocks[j - 1] =
            rawSubBlockAfter_S_transformation ^ generatedKey[j - 1];
    }
    encryptedBlocks.add(encryptedSubBlocks);
  }
  return encryptedBlocks;
}

// Функция дешифрования блока согласно алгоритму LBC-3 (массив CharCode, мастер ключ)
List<Uint16List> decryptBlocks(
    List<Uint16List> blocks, List<int> generatedRoundKey) {
  //Расшифрованные блоки
  List<Uint16List> decryptedBlocks = [];

  for (int i = 0; i < blocks.length; i++) {
    Uint16List substitutedSubBlock = Uint16List(4);
    int rlTemp = 0;

    for (int j = blocks[i].length - 1; j >= 0; j--) {
      //Первым делом производим сложение по модулю 2 между полублоком и ключом
      int subBlock = blocks[i][j] ^ generatedRoundKey[j];

      if (j == 3) {
        //Делаем сдвиг направо, дальше дешифруем через обратную таблицу S-блок
        substitutedSubBlock[0] = transformationS(subBlock, Action.DECRYPT);
        // И так как теперь позиция {B3} => {B0}, находим RL(B0) для дальнейшего поиска {B1} = RL(B0) ^ b1.
        rlTemp = transformationRL(subBlock);
      } else if (j == 0) {
        //При сдвиге {B0} => {B1}, следовательно ищем RL(B0) ^ B1, после дешифруем через обратную таблицу S-блок
        substitutedSubBlock[1] =
            transformationS(subBlock ^ rlTemp, Action.DECRYPT);
      } else
        substitutedSubBlock[j + 1] = transformationS(subBlock, Action.DECRYPT);
    }
    decryptedBlocks.add(substitutedSubBlock);
  }
  return decryptedBlocks;
}

//Преобразование S - для процесса шифрования и дешифрования (полублок, тип процесса)
int transformationS(int subBlock, Action type) {
  //Nibble = 4 бита (полубайт)
  int nibble = 0, subblockAfterSBox = 0;
  for (int k = 12; k >= 0; k -= 4) {
    nibble = (subBlock >> k) & 0xF;
    subblockAfterSBox |=
        ((type == Action.ENCRYPT ? sBox[nibble] : sBoxReversed[nibble]) << k);
  }
  ;
  return subblockAfterSBox;
}

// Преобразование RL - функция, только для первого полублока
int transformationRL(int aZero) {
  //Функция циклического сдвига (7 и 10)
  int shift7 = rotateLeft(aZero, 7);
  int shift10 = rotateLeft(aZero, 10);
  int result = aZero ^ shift7 ^ shift10;
  return result;
}

// Функция для циклического сдвига влево на определенное количество позиций
int rotateLeft(int value, int shift) {
  return ((value << shift) | (value >> (16 - shift))) & 0xFFFF;
}

String checkLengthHexMasterKey(String hexMasterKey) {
  if (hexMasterKey.length == 0 || hexMasterKey.isEmpty) {
    throw Exception('Введите 80 битный ключ');
  } else if (hexMasterKey.length > 20) {
    throw Exception('Ключ превышает 80 бит');
  }
  return hexMasterKey.padLeft(20, '0');
}

// Функция для генерации раундовых ключей
List<List<int>> generateRoundKeys(String masterKey, int numRounds) {
  List<int> key = [];

  //Деление HEX ключа 80 бит, на 5 подблоков по 16 бит

  for (int i = 0; i < masterKey.length; i += 4) {
    key.add(int.parse(masterKey.substring(i, i + 4), radix: 16));
  }

  List<List<int>> roundKeys = [];

  for (int round = 1; round <= numRounds; round++) {
    // Этап 1: Замена первого подблока с помощью S-блока
    key[0] = sBox[key[0] >> 12] << 12 |
        sBox[(key[0] >> 8) & 0xF] << 8 |
        sBox[(key[0] >> 4) & 0xF] << 4 |
        sBox[key[0] & 0xF];

    // Добавление константы Nr к четвертому подблоку
    key[4] = (key[4] + round) & 0xFFFF;

    // Этап 2: Циклический сдвиг влево каждого подблока
    key[0] = rotateLeft(key[0], 6);
    key[1] = rotateLeft(key[1], 7);
    key[2] = rotateLeft(key[2], 8);
    key[3] = rotateLeft(key[3], 9);
    key[4] = rotateLeft(key[4], 10);

    // Этап 3: Сложение по модулю 2 с соседним правым подблоком
    key[0] ^= key[1];
    key[1] ^= key[2];
    key[2] ^= key[3];
    key[3] ^= key[4];

    // Этап 4: Циклический сдвиг влево на одну позицию
    int temp = key[0];
    key[0] = key[1];
    key[1] = key[2];
    key[2] = key[3];
    key[3] = key[4];
    key[4] = temp;

    // Добавление первых 4 подблоков в качестве раундового ключа
    roundKeys.add(key.sublist(0, 4));
  }

  return roundKeys;
}

// Функция для разделения каждого подблока на 4 подподблока по 4 бита и замены согласно S-блоку
List<Uint16List> convertHexStringIntoCharCodeList(String encryptedHex) {
  //Расшифрованные блоки
  List<Uint16List> decryptedBlocks = [];

  List<String> blocks = [];
  for (int i = 0; i < encryptedHex.length; i += 16) {
    blocks.add(encryptedHex.substring(i, i + 16));
  }

  for (int i = 0; i < blocks.length; i++) {
    Uint16List substitutedSubBlock = Uint16List(4);

    List<String> subBlocks = [
      blocks[i].substring(0, 4),
      blocks[i].substring(4, 8),
      blocks[i].substring(8, 12),
      blocks[i].substring(12, 16)
    ];

    for (int j = subBlocks.length - 1; j >= 0; j--) {
      substitutedSubBlock[j] = hexToInt(subBlocks[j]);
    }
    decryptedBlocks.add(substitutedSubBlock);
  }
  return decryptedBlocks;
}

// Функция для преобразования шестнадцатеричной строки в число
int hexToInt(String hex) {
  return int.parse(hex, radix: 16);
}

// Функция для разделения каждого подблока на 4 подподблока по 4 бита и замены согласно S-блоку
String convertFromCharCodeListIntoHexString(List<Uint16List> rawBlocks) {
  //Зашифрованные блоки
  List<String> encryptedBlocks = [];

  for (int i = 0; i < rawBlocks.length; i++) {
    //Подблок в котором 4 по 16 бит. 1 символ = 16 бит.
    List<String> encryptedSubBlocks = List<String>.filled(4, '');
    for (int j = 0; j < rawBlocks[i].length; j++) {
      encryptedSubBlocks[j] = (toHex(rawBlocks[i][j]));
    }
    encryptedBlocks.add(encryptedSubBlocks.join());
  }
  print(encryptedBlocks);
  return encryptedBlocks.join();
}

// Функция для преобразования числа в шестнадцатеричное представление
String toHex(int value) {
  return value.toRadixString(16).padLeft(4, '0');
}

// Функция для преобразования списка charCodes в текст
String convertCharCodeListIntoPlainText(List<Uint16List> uint16Lists) {
  List<int> intList = uint16Lists.expand((list) => list).toList();
  return String.fromCharCodes(intList);
}

//Таблица замены
final List<int> sBox = [
  0x9,
  0x2,
  0xA,
  0x4,
  0x0,
  0x6,
  0x7,
  0xD,
  0x5,
  0x1,
  0x8,
  0x3,
  0xE,
  0xF,
  0xB,
  0xC
];

// Обратная таблица замены
final List<int> sBoxReversed = [
  0x4,
  0x9,
  0x1,
  0xB,
  0x3,
  0x8,
  0x5,
  0x6,
  0xA,
  0x0,
  0x2,
  0xE,
  0xF,
  0x7,
  0xC,
  0xD
];
