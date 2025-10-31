import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOCX Page Formatter',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF285570),
          secondary: Color(0xFFcbcac7),
          tertiary: Color(0xFFfaf7f6),
          surface: Color(0xFFe3ded7),
        ),
      ),
      home: const FormatterPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FormatterPage extends StatefulWidget {
  const FormatterPage({super.key});

  @override
  State<FormatterPage> createState() => _FormatterPageState();
}

class _FormatterPageState extends State<FormatterPage> {
  bool _isLoading = false;
  String _fileName = 'No file selected';
  Uint8List? _fileBytes;
  String _selectedFont = 'Calibri';
  bool _isJustified = false;
  Uint8List? _processedFileBytes;

  final _topMarginController = TextEditingController(text: '25.4');
  final _bottomMarginController = TextEditingController(text: '25.4');
  final _leftMarginController = TextEditingController(text: '25.4');
  final _rightMarginController = TextEditingController(text: '25.4');
  final _headerMarginController = TextEditingController(text: '12.7');
  final _footerMarginController = TextEditingController(text: '12.7');
  final _lineSpacingController = TextEditingController(text: '1.5');

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        _fileBytes = result.files.single.bytes;
        _processedFileBytes = null;
      });
    }
  }

  Future<void> _processFile() async {
    if (_fileBytes == null) {
      _showError('Please select a file first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _processedFileBytes = null;
    });

    try {
      var uri = Uri.parse('http://127.0.0.1:5000/process');
      var request = http.MultipartRequest('POST', uri);

      request.fields['top_margin'] = _topMarginController.text;
      request.fields['bottom_margin'] = _bottomMarginController.text;
      request.fields['left_margin'] = _leftMarginController.text;
      request.fields['right_margin'] = _rightMarginController.text;
      request.fields['header_margin'] = _headerMarginController.text;
      request.fields['footer_margin'] = _footerMarginController.text;
      request.fields['line_spacing'] = _lineSpacingController.text;
      request.fields['font_style'] = _selectedFont;
      request.fields['alignment'] = _isJustified ? 'justify' : 'left';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _fileBytes!,
          filename: _fileName,
        ),
      );

      var streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final fileBytes = await streamedResponse.stream.toBytes();
        setState(() {
          _processedFileBytes = fileBytes;
          _showError('File processed successfully! Click Download to save.', false);
        });
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        _showError('Server Error: $responseBody', true);
      }
    } catch (e) {
      _showError('An error occurred: $e', true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _triggerDownload(Uint8List fileBytes, String fileName) {
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'formatted_$fileName')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showError(String message, [bool isError = true]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF285570),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _topMarginController.dispose();
    _bottomMarginController.dispose();
    _leftMarginController.dispose();
    _rightMarginController.dispose();
    _headerMarginController.dispose();
    _footerMarginController.dispose();
    _lineSpacingController.dispose();
    super.dispose();
  }

  Widget _buildCompactTextField(TextEditingController controller, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFcbcac7)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFe3ded7),
      body: Row(
        children: [
          // Left Sidebar - Info Panel
          Container(
            width: 320,
            color: const Color(0xFF285570),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Document Formatter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Professional formatting for DOCX files',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoItem(
                    Icons.tune,
                    'Custom Margins',
                    'Set precise page margins in millimeters',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.format_line_spacing,
                    'Line Spacing',
                    'Adjust spacing between lines',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.font_download,
                    'Font Selection',
                    'Choose from multiple font families',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.format_align_justify,
                    'Text Alignment',
                    'Apply justified or left alignment',
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Standard margins: 25.4mm = 1 inch\n• Single spacing: 1.0\n• Double spacing: 2.0\n• Header/Footer: 12.7mm typical',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // File Upload Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Document',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _pickFile,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _fileBytes != null ? const Color(0xFF285570) : const Color(0xFFcbcac7),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _fileBytes != null
                                      ? const Color(0xFF285570).withOpacity(0.05)
                                      : const Color(0xFFfaf7f6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _fileBytes != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                                      size: 32,
                                      color: _fileBytes != null ? const Color(0xFF285570) : const Color(0xFFcbcac7),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _fileName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _fileBytes != null ? const Color(0xFF285570) : const Color(0xFF666666),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _fileBytes != null ? 'Click to change file' : 'Click to select .docx file',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF999999),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Two Column Layout for Settings
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            child: Column(
                              children: [
                                // Font & Alignment
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Text Style',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: _selectedFont,
                                        items: ['Arial', 'Times New Roman', 'Roboto', 'Calibri']
                                            .map((font) => DropdownMenuItem(value: font, child: Text(font)))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedFont = value!;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Font Family',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFfaf7f6),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      CheckboxListTile(
                                        title: const Text('Justify Text', style: TextStyle(fontSize: 14)),
                                        value: _isJustified,
                                        onChanged: (value) {
                                          setState(() {
                                            _isJustified = value!;
                                          });
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        activeColor: const Color(0xFF285570),
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Line Spacing
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Line Spacing',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _lineSpacingController,
                                        decoration: InputDecoration(
                                          labelText: 'Spacing Value',
                                          hintText: '1.0, 1.5, 2.0',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFfaf7f6),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Right Column
                          Expanded(
                            child: Column(
                              children: [
                                // Page Margins
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Page Margins (mm)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _buildCompactTextField(_topMarginController, 'Top'),
                                          _buildCompactTextField(_bottomMarginController, 'Bottom'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _buildCompactTextField(_leftMarginController, 'Left'),
                                          _buildCompactTextField(_rightMarginController, 'Right'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Header/Footer
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Header & Footer (mm)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _buildCompactTextField(_headerMarginController, 'Header'),
                                          _buildCompactTextField(_footerMarginController, 'Footer'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Button
                      if (_isLoading)
                        Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: Color(0xFF285570)),
                              const SizedBox(height: 12),
                              const Text(
                                'Processing your document...',
                                style: TextStyle(color: Color(0xFF666666)),
                              ),
                            ],
                          ),
                        )
                      else if (_processedFileBytes != null)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF285570),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF285570).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _triggerDownload(_processedFileBytes!, _fileName),
                                  icon: const Icon(Icons.download_rounded, size: 22),
                                  label: const Text(
                                    'Download Formatted File',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF285570),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _processedFileBytes = null;
                                  _fileBytes = null;
                                  _fileName = 'No file selected';
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                foregroundColor: const Color(0xFF285570),
                                side: const BorderSide(color: Color(0xFF285570)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF285570),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF285570).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _processFile,
                            icon: const Icon(Icons.auto_fix_high, size: 22),
                            label: const Text(
                              'Process Document',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF285570),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}