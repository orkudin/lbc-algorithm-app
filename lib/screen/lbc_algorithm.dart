import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lbc_algorithm/widgets/lbc_decryption.dart';
import 'package:lbc_algorithm/widgets/lbc_encryption.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConverterType {
  encryption,
  decrypton,
}

// ignore: camel_case_types
class LBC_AlgorithmScreen extends StatefulWidget {
  const LBC_AlgorithmScreen({super.key});

  @override
  State<LBC_AlgorithmScreen> createState() => _LBC_AlgorithmScreenState();
}

// ignore: camel_case_types
class _LBC_AlgorithmScreenState extends State<LBC_AlgorithmScreen> {
  final _formKey = GlobalKey<FormState>();
  var _selectDislayType;

  final _plainTextController = TextEditingController();
  final _masterKeyController = TextEditingController();

  ConverterType _selectedConverterType = ConverterType.encryption;

  String _selectedFileNameKey = '';
  String _selectedFileNameData = '';

  String _data = '';
  int _dataFileLength = 0;
  String _masterKey = '';
  int _masterKeyFileLength = 0;

  String? errorMessage;

  @override
  void dispose() {
    _plainTextController.dispose();
    _masterKeyController.dispose();
    super.dispose();
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _selectDislayType = _selectedConverterType;
      });

      if (_plainTextController.text.isNotEmpty && _dataFileLength < 5000) {
        _data = _plainTextController.text;
      }

      if (_masterKeyController.text.isNotEmpty) {
        _masterKey = _masterKeyController.text;
      }

      if (_selectDislayType == ConverterType.encryption) {
        errorMessage = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => LBC_encryption(
              data: _data,
              masterKey: _masterKey,
              saveFile: saveFile,
            ),
          ),
        );
      } else if (_selectDislayType == ConverterType.decrypton) {
        errorMessage = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => LBC_decryption(
              data: _data,
              masterKey: _masterKey,
              saveFile: saveFile,
            ),
          ),
        );
      }

      if (errorMessage != null) {
        // Обработка ошибки, полученной со второго экрана
        _showScaffoldMessenger(errorMessage.toString());
      }
    }
  }

  void _resetData() {
    _formKey.currentState!.reset();
    _plainTextController.text = "";
    // _masterKeyController.text = "";
    setState(() {
      _selectedFileNameData = "";
      _selectedFileNameKey = "";
      _data = '';
      _dataFileLength = 0;
      // _masterKey = '';
    });
  }

  void _showScaffoldMessenger(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  void _pickAndReadFile(String converterType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      String fileContents = await _readFileContents(filePath);

      if (fileContents.length > 20 && converterType == 'masterkey') {
        _showScaffoldMessenger('Неверный размер мастер-ключа');
      }

      //Имя импортированного файла
      setState(() {
        converterType == 'data'
            ? _selectedFileNameData = result.files.single.name
            : _selectedFileNameKey = result.files.single.name;
      });
      _showScaffoldMessenger(converterType == 'data'
          ? 'Данные импортированы'
          : 'Мастер ключ импортирован');

      if (converterType == 'data') {
        // _plainTextController.text = fileContents;
        _data = fileContents;
        setState(() {
          _dataFileLength = _data.length;
          if (_dataFileLength < 5000) {
            _plainTextController.text = _data;
          }
        });
      } else if (converterType == 'masterkey') {
        if (isHexMasterKey(fileContents)) {
          _masterKeyController.text = fileContents;
          _masterKey = fileContents;
        } else {
          _showScaffoldMessenger(
              'Неверный hex мастер-ключ. Необходимая длина не более 20 байт');
          _selectedFileNameKey = '';
        }
      }
    }
  }

  bool isHexMasterKey(String masterKey) {
    // Проверяем, что длина строки не больше 20 символов и строка не пустая
    if (masterKey.length <= 20 && masterKey.isNotEmpty) {
      // Проверяем, что строка состоит только из шестнадцатеричных символов
      return RegExp(r'^[0-9A-Fa-f]*$').hasMatch(masterKey);
    } else {
      return false;
    }
  }
  //瑑견㞸뱩惀ᱝ張�웆�

  Future<String> _readFileContents(String filePath) async {
    try {
      final file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      _showScaffoldMessenger("Ошибка при чтении файла");
      return '';
    }
  }

  void saveFile(String content) async {
    String? fileName = await showFileNameDialog(context);
    if (fileName != null && fileName.isNotEmpty) {
      await saveFileWithFilePicker(content, fileName);
    } else {
      _showScaffoldMessenger('Отмена сохранения');
    }
  }

  Future<void> saveFileWithFilePicker(String content, String fileName) async {
    final hasPermission = await requestStoragePermission();

    if (!hasPermission) {
      // Директория не выбрана, обработайте этот случай соответствующим образом
      _showScaffoldMessenger('Отказ в доступе');
      return;
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    String filePath = '$selectedDirectory/$fileName.txt';
    File file = File(filePath);
    await file.writeAsString(content);
    _showScaffoldMessenger('Документ сохранён');
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 30) {
      var status = await Permission.manageExternalStorage.status;
      if (status.isDenied ||
          status.isRestricted ||
          status.isPermanentlyDenied) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    } else {
      var status = await Permission.storage.status;
      if (status.isDenied ||
          status.isRestricted ||
          status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }

  Future<String?> showFileNameDialog(BuildContext context) async {
    String? fileName;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 79, 56, 83),
          title: const Text('Введите название файла'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Название файла',
              suffixText: '.txt',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                fileName = controller.text;
                Navigator.of(context).pop();
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LBC-3 Алгоритм')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Выберите тип конвертера',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonFormField(
                    dropdownColor: const Color.fromARGB(255, 88, 54, 116),
                    value: _selectedConverterType,
                    items: [
                      for (final converterType in ConverterType.values)
                        DropdownMenuItem(
                          value: converterType,
                          child: Row(
                            children: [
                              Text(
                                converterType == ConverterType.encryption
                                    ? 'Шифрование'
                                    : 'Расшифрование',
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedConverterType = value!;
                        setState(() {
                          _selectedFileNameData = "";
                          _data = '';
                          _dataFileLength = 0;
                          _plainTextController.text = '';
                        });
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                          onPressed: () => _pickAndReadFile('masterkey'),
                          child: const Text(
                            'Выбрать мастер-ключ',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_selectedFileNameKey.isNotEmpty)
                          Text(
                            'Выбранный файл: $_selectedFileNameKey',
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                          ),
                          onPressed: () => _pickAndReadFile('data'),
                          child: Text(
                            _selectedConverterType == ConverterType.encryption
                                ? 'Выбрать открытый текст'
                                : 'Выбрать зашифрованный текст',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_selectedFileNameData.isNotEmpty)
                          Text(
                            'Выбранный файл: ${_selectedFileNameData}',
                            style: TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text(
                  'Мастер Ключ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 70,
                  child: TextFormField(
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                    ],
                    //fa43c5050daa8586
                    //fa43c5050daa8586
                    controller: _masterKeyController,
                    decoration: const InputDecoration(
                      label: Text(
                          'Введите hex мастер-ключ длиной не более 20 байт'),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите мастер-ключ';
                      } else if (value.length > 20) {
                        return 'Необоходимая длина ключа не более 20 байт';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _masterKeyController.text = value!;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedConverterType == ConverterType.encryption
                      ? 'Открытый Текст ${_dataFileLength == 0 ? '' : '($_dataFileLength символов)'} '
                      : 'Зашифрованный Текст',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: _dataFileLength < 5000
                      ? TextFormField(
                          controller: _plainTextController,
                          expands: true,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            label: Text(_selectedConverterType ==
                                    ConverterType.encryption
                                ? 'Введите открытый текст'
                                : 'Введите зашифрованный текст'),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _selectedConverterType ==
                                      ConverterType.encryption
                                  ? 'Введите открытый текст'
                                  : 'Введите зашифрованный текст';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _plainTextController.text = value!;
                          },
                        )
                      : DecoratedBox(
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
                              '${_data.substring(0, 5000)}',
                              style: TextStyle(fontSize: 16),
                              showCursor: true,
                              cursorColor: Colors.blue,
                              cursorWidth: 2,
                              cursorRadius: Radius.circular(2),
                            ),
                          ),
                        ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 48, 105, 67),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                        ),
                        child: Text(
                          _selectedConverterType == ConverterType.encryption
                              ? 'Начать Шифрование'
                              : 'Начать Расшифрование',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 185, 74, 66),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                        ),
                        child: Text(
                          _selectedConverterType == ConverterType.encryption
                              ? 'Стереть открытый текст'
                              : 'Стереть зашифрованный текст',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                // content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
