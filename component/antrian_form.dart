import 'package:flutter/material.dart';

const Color darkBlue = Color(0xFF224480);
const Color lightGray = Color(0xFFD9D9D9);
const Color brightOrange = Color(0xFFC67B02);

class antrian_form extends StatefulWidget {
  final Function(Map<String, String> data)? onDataSaved;
  final String? nama;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;

  const antrian_form({
    super.key,
    this.onDataSaved,
    this.nama,
    this.onCancel,
    this.onClose,
  });

  @override
  State<antrian_form> createState() => _AntrianFormState();
}

class _AntrianFormState extends State<antrian_form> {
  late final TextEditingController namaController;
  final TextEditingController instansiController = TextEditingController();
  final TextEditingController keperluanLainnyaController = TextEditingController();

  String? selectedKeperluan;

  final List<String> keperluanList = [
    "Survey",
    "Konsultasi",
    "Lainnya",
  ];

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.nama);
  }

  @override
  void dispose() {
    namaController.dispose();
    instansiController.dispose();
    keperluanLainnyaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFC67B02),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Masukkan Informasi\nBerikut",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildTextField("Nama Tamu", namaController),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration("Keperluan Tamu"),
              //initialValue: selectedKeperluan,
              value: selectedKeperluan,
              items: keperluanList.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedKeperluan = value;
                });
              },
            ),
          ),
          if (selectedKeperluan == "Lainnya") ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildTextField(
                  "Tuliskan Keperluan", keperluanLainnyaController),
            )
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildTextField("Instansi Tamu", instansiController),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              String keperluan = selectedKeperluan == "Lainnya"
                  ? keperluanLainnyaController.text
                  : (selectedKeperluan ?? "-");

              final data = {
                "nama": namaController.text,
                "keperluan": keperluan,
                "instansi": instansiController.text,
              };

              if ((data["nama"]?.isEmpty ?? true) || data["keperluan"] == "-") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data Nama dan Keperluan tidak boleh kosong")),
                );
                return;
              }

              if (widget.onDataSaved != null) {
                widget.onDataSaved!(data);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Daftar Tamu"),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onCancel?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Kembali"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }
}